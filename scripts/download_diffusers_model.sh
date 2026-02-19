#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

alias_name="${DIFFUSERS_RUNTIME_ALIAS:-default}"
model_id="${MODEL_ID:-black-forest-labs/FLUX.2-klein-4B}"
runtime_root="$HOME/Library/Application Support/StoryJuicer/Diffusers/$alias_name"
cache_root="$HOME/Library/Caches/StoryJuicer/Diffusers/$alias_name"
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
    if msg:
        print(f"[{name}] {msg}", flush=True)
    else:
        print(f"[{name}]", flush=True)
'
}

printf '[INFO] Prewarming Diffusers model %s (alias=%s)\n' "$model_id" "$alias_name"

if [[ ! -x "$venv_python" ]]; then
    printf '[INFO] Runtime not initialized yet; running setup first.\n'
    DIFFUSERS_RUNTIME_ALIAS="$alias_name" MODEL_ID="$model_id" bash "$ROOT_DIR/scripts/setup_diffusers.sh"
fi

if [[ ! -f "$worker_script" ]]; then
    printf '[ERROR] Missing worker script: %s\n' "$worker_script"
    exit 1
fi

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

"$venv_python" "$worker_script" --mode prewarm --model-id "$model_id" 2>&1 | pretty_ndjson

printf '[OK] Model prewarm complete for %s\n' "$model_id"
