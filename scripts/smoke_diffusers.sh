#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

alias_name="${DIFFUSERS_RUNTIME_ALIAS:-default}"
model_id="${MODEL_ID:-black-forest-labs/FLUX.2-klein-4B}"
width="${SMOKE_WIDTH:-768}"
height="${SMOKE_HEIGHT:-768}"
steps="${SMOKE_STEPS:-4}"
guidance="${SMOKE_GUIDANCE:-1.0}"
prompt="${SMOKE_PROMPT:-A gentle childrens book illustration of a friendly fox reading under a glowing tree at dusk, warm colors, no text}"
runtime_root="$HOME/Library/Application Support/StoryFox/Diffusers/$alias_name"
cache_root="$HOME/Library/Caches/StoryFox/Diffusers/$alias_name"
venv_python="$runtime_root/venv/bin/python"
worker_script="$ROOT_DIR/Resources/Diffusers/diffusers_worker.py"

pretty_ndjson() {
    python3 -c '
import json
import sys
for raw in sys.stdin:
    line = raw.strip()
    if not line:
        continue
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        continue
    name = event.get("event", "event")
    msg = event.get("message") or event.get("error") or ""
    out = event.get("output_path")
    if msg:
        print(f"[{name}] {msg}", flush=True)
    else:
        print(f"[{name}]", flush=True)
    if out:
        print(f"[{name}] output_path={out}", flush=True)
'
}

printf '[INFO] Running Diffusers smoke test (alias=%s model=%s)\n' "$alias_name" "$model_id"

if [[ ! -x "$venv_python" ]]; then
    printf '[INFO] Runtime not initialized yet; running setup first.\n'
    DIFFUSERS_RUNTIME_ALIAS="$alias_name" MODEL_ID="$model_id" bash "$ROOT_DIR/scripts/setup_diffusers.sh"
fi

if [[ ! -f "$worker_script" ]]; then
    printf '[ERROR] Missing worker script: %s\n' "$worker_script"
    exit 1
fi

output_dir="$cache_root/smoke"
mkdir -p "$output_dir"
output_file="$output_dir/smoke-$(date +%Y%m%d-%H%M%S).png"

export HF_HOME="$cache_root"
export HF_HUB_CACHE="$cache_root/hub"
export HUGGINGFACE_HUB_CACHE="$cache_root/hub"
export HF_HUB_DISABLE_PROGRESS_BARS=1
export PYTORCH_ENABLE_MPS_FALLBACK=1
mkdir -p "$HF_HOME" "$HF_HUB_CACHE"

if [[ -n "${HF_TOKEN:-}" ]]; then
    export HUGGINGFACE_HUB_TOKEN="$HF_TOKEN"
    printf '[INFO] Using HF_TOKEN from environment for model access.\n'
fi

request_payload="$(python3 - <<PY
import json
print(json.dumps({
    "model_id": "$model_id",
    "prompt": "$prompt",
    "width": int("$width"),
    "height": int("$height"),
    "steps": int("$steps"),
    "guidance_scale": float("$guidance"),
    "seed": 1337,
    "output_path": "$output_file"
}))
PY
)"

printf '%s' "$request_payload" | "$venv_python" "$worker_script" --mode generate --model-id "$model_id" 2>&1 | pretty_ndjson

if [[ ! -f "$output_file" ]]; then
    printf '[ERROR] Smoke test failed: output image was not created at %s\n' "$output_file"
    exit 1
fi

image_info="$("$venv_python" - <<PY
from PIL import Image
img = Image.open(r"$output_file")
print(f"{img.size[0]}x{img.size[1]}")
PY
)"

printf '[OK] Smoke test image created: %s (%s)\n' "$output_file" "$image_info"
