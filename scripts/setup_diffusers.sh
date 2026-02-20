#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

alias_name="${DIFFUSERS_RUNTIME_ALIAS:-default}"
model_id="${MODEL_ID:-black-forest-labs/FLUX.2-klein-4B}"
force_setup="${FORCE_SETUP:-0}"
runtime_root="$HOME/Library/Application Support/StoryFox/Diffusers/$alias_name"
cache_root="$HOME/Library/Caches/StoryFox/Diffusers/$alias_name"
venv_root="$runtime_root/venv"
venv_python="$venv_root/bin/python"
worker_script="$ROOT_DIR/Resources/Diffusers/diffusers_worker.py"
requirements_file="$ROOT_DIR/Resources/Diffusers/diffusers-requirements.txt"
dep_stamp="diffusers=0.36.0;torch=2.10.0"
stamp_file="$runtime_root/.deps-version"

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

printf '[INFO] Setting up Diffusers runtime (alias=%s)\n' "$alias_name"

if ! command -v python3 >/dev/null 2>&1; then
    printf '[ERROR] python3 not found. Install Python 3.11+ and retry.\n'
    exit 1
fi

if ! python3 - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
then
    py_version="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")')"
    printf '[ERROR] Python %s detected. Python 3.11+ is required.\n' "$py_version"
    exit 1
fi

if [[ ! -f "$requirements_file" ]]; then
    printf '[ERROR] Missing requirements file: %s\n' "$requirements_file"
    exit 1
fi

if [[ ! -f "$worker_script" ]]; then
    printf '[ERROR] Missing worker script: %s\n' "$worker_script"
    exit 1
fi

mkdir -p "$runtime_root" "$cache_root"

if [[ ! -x "$venv_python" ]]; then
    printf '[INFO] Creating virtualenv at %s\n' "$venv_root"
    python3 -m venv "$venv_root"
fi

should_install=1
if [[ "$force_setup" != "1" ]] && [[ -f "$stamp_file" ]]; then
    current_stamp="$(tr -d '[:space:]' < "$stamp_file" || true)"
    if [[ "$current_stamp" == "$dep_stamp" ]]; then
        should_install=0
    fi
fi

if [[ "$should_install" == "1" ]]; then
    printf '[INFO] Installing pinned dependencies from %s\n' "$requirements_file"
    "$venv_python" -m pip install --upgrade pip
    "$venv_python" -m pip install --requirement "$requirements_file"
    printf '%s\n' "$dep_stamp" > "$stamp_file"
else
    printf '[INFO] Dependency stamp is current; skipping reinstall.\n'
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

printf '[INFO] Running worker health check for %s\n' "$model_id"
"$venv_python" "$worker_script" --mode health --model-id "$model_id" 2>&1 | pretty_ndjson

printf '[OK] Diffusers runtime setup complete.\n'
printf '[NEXT] Run make download-image-model (optional prewarm) and make smoke-image (generation test).\n'
