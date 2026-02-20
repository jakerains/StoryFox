#!/usr/bin/env python3
"""StoryJuicer Diffusers worker.

Reads one JSON request from stdin for generate mode and emits NDJSON events to stdout.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import traceback
from pathlib import Path
from typing import Any, Dict, Optional, Tuple


def emit(event: str, **payload: Any) -> None:
    packet: Dict[str, Any] = {"event": event}
    packet.update(payload)
    print(json.dumps(packet, ensure_ascii=False), flush=True)


def detect_device(torch_module: Any) -> Tuple[str, Any]:
    if torch_module.backends.mps.is_available():
        return "mps", torch_module.float16
    return "cpu", torch_module.float32


def _normalize_conversations_for_string_templates(conversations: Any) -> Any:
    if not isinstance(conversations, list):
        return conversations

    normalized_batch = []
    for conversation in conversations:
        if not isinstance(conversation, list):
            normalized_batch.append(conversation)
            continue

        normalized_conversation = []
        for message in conversation:
            if not isinstance(message, dict):
                normalized_conversation.append(message)
                continue

            content = message.get("content")
            if isinstance(content, list):
                text_chunks = []
                for item in content:
                    if isinstance(item, dict):
                        if item.get("type") == "text" and isinstance(item.get("text"), str):
                            text_chunks.append(item["text"])
                    elif isinstance(item, str):
                        text_chunks.append(item)

                patched_message = dict(message)
                patched_message["content"] = "\n".join(chunk for chunk in text_chunks if chunk).strip()
                normalized_conversation.append(patched_message)
            else:
                normalized_conversation.append(message)

        normalized_batch.append(normalized_conversation)

    return normalized_batch


def patch_chat_template_compat(tokenizer_like: Any) -> None:
    apply_chat_template = getattr(tokenizer_like, "apply_chat_template", None)
    if apply_chat_template is None:
        return

    if getattr(tokenizer_like, "_storyfox_chat_patch", False):
        return

    def wrapped_apply_chat_template(conversations: Any, *args: Any, **kwargs: Any) -> Any:
        try:
            return apply_chat_template(conversations, *args, **kwargs)
        except TypeError as exc:
            # Some FLUX.2-klein tokenizer templates expect string content instead of typed content arrays.
            if "can only concatenate str (not \"list\") to str" not in str(exc):
                raise
            normalized = _normalize_conversations_for_string_templates(conversations)
            return apply_chat_template(normalized, *args, **kwargs)

    setattr(tokenizer_like, "apply_chat_template", wrapped_apply_chat_template)
    setattr(tokenizer_like, "_storyfox_chat_patch", True)


def load_pipeline(model_id: str, device: str, dtype: Any) -> Tuple[Any, str]:
    # Import lazily to keep health checks fast.
    from diffusers import Flux2Pipeline

    errors = []
    candidate_classes = []

    try:
        # Some diffusers releases expose klein pipeline in submodules only.
        from diffusers import Flux2KleinPipeline

        candidate_classes.append(Flux2KleinPipeline)
    except Exception as exc:  # noqa: BLE001
        errors.append(f"Flux2KleinPipeline unavailable: {exc}")

    candidate_classes.append(Flux2Pipeline)

    for pipeline_class in candidate_classes:
        try:
            pipe = pipeline_class.from_pretrained(
                model_id,
                torch_dtype=dtype,
                low_cpu_mem_usage=False,
            )
            pipe.to(device)
            patch_chat_template_compat(pipe.tokenizer)
            return pipe, pipeline_class.__name__
        except Exception as exc:  # noqa: BLE001
            errors.append(f"{pipeline_class.__name__} failed: {exc}")

    raise RuntimeError(" | ".join(errors))


def run_health_check(model_id: str) -> None:
    import torch
    import diffusers
    import transformers

    device, _ = detect_device(torch)
    emit(
        "runtime_check",
        message=(
            f"Runtime ready. torch={torch.__version__}, diffusers={diffusers.__version__}, "
            f"transformers={transformers.__version__}, device={device}, model={model_id}"
        ),
    )
    emit("completed", message="Health check complete.")


def run_prewarm(model_id: str) -> None:
    import torch

    device, dtype = detect_device(torch)
    emit("model_loading", message=f"Loading model {model_id} on {device}...")
    _, pipeline_name = load_pipeline(model_id=model_id, device=device, dtype=dtype)
    emit("completed", message=f"Model prewarm complete via {pipeline_name}.")


def run_generate(model_id: str) -> None:
    request_text = sys.stdin.read().strip()
    if not request_text:
        raise ValueError("Missing JSON request payload on stdin.")

    request = json.loads(request_text)
    request_model_id = request.get("model_id") or model_id

    prompt = request["prompt"]
    width = int(request["width"])
    height = int(request["height"])
    steps = int(request["steps"])
    guidance_scale = float(request["guidance_scale"])
    seed = request.get("seed")
    output_path = Path(request["output_path"]).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    import torch

    device, dtype = detect_device(torch)
    emit("runtime_check", message=f"Using device={device} for local generation.")

    emit("model_loading", message=f"Loading {request_model_id}...")
    pipe, pipeline_name = load_pipeline(model_id=request_model_id, device=device, dtype=dtype)
    emit("model_loading", message=f"Loaded pipeline {pipeline_name}.")

    generation_kwargs: Dict[str, Any] = {
        "prompt": prompt,
        "height": height,
        "width": width,
        "num_inference_steps": steps,
        "guidance_scale": guidance_scale,
    }

    if seed is not None:
        generation_kwargs["generator"] = torch.Generator(device="cpu").manual_seed(int(seed))

    emit("generating", message="Generating image...")
    image = pipe(**generation_kwargs).images[0]
    image.save(output_path.as_posix())

    emit(
        "completed",
        message="Image generation complete.",
        output_path=output_path.as_posix(),
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="StoryJuicer Diffusers worker")
    parser.add_argument(
        "--mode",
        choices=["health", "prewarm", "generate"],
        required=True,
        help="Worker mode",
    )
    parser.add_argument(
        "--model-id",
        required=True,
        help="Hugging Face model ID to use",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    # Respect optional explicit cache variables set by the Swift runtime manager.
    hf_home = os.environ.get("HF_HOME")
    if hf_home:
        Path(hf_home).mkdir(parents=True, exist_ok=True)

    try:
        if args.mode == "health":
            run_health_check(args.model_id)
        elif args.mode == "prewarm":
            run_prewarm(args.model_id)
        elif args.mode == "generate":
            run_generate(args.model_id)
        else:
            raise ValueError(f"Unsupported mode: {args.mode}")
        return 0
    except Exception as exc:  # noqa: BLE001
        emit("error", error=f"{type(exc).__name__}: {exc}")
        traceback.print_exc(file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
