#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

issues=0

alias_name="${DIFFUSERS_RUNTIME_ALIAS:-default}"
model_id="${MODEL_ID:-black-forest-labs/FLUX.2-klein-4B}"
runtime_root="$HOME/Library/Application Support/StoryJuicer/Diffusers/$alias_name"
cache_root="$HOME/Library/Caches/StoryJuicer/Diffusers/$alias_name"
venv_python="$runtime_root/venv/bin/python"
worker_script="$ROOT_DIR/Resources/Diffusers/diffusers_worker.py"
requirements_file="$ROOT_DIR/Resources/Diffusers/diffusers-requirements.txt"

printf '[INFO] Diffusers runtime alias: %s\n' "$alias_name"
printf '[INFO] Model ID: %s\n' "$model_id"
printf '[INFO] Runtime root: %s\n' "$runtime_root"
printf '[INFO] Cache root: %s\n' "$cache_root"

if [[ "$(uname -m)" == "arm64" ]]; then
    printf '[OK] Apple Silicon architecture detected\n'
else
    printf '[FAIL] StoryJuicer local Diffusers target is Apple Silicon (arm64)\n'
    issues=$((issues + 1))
fi

if command -v python3 >/dev/null 2>&1; then
    printf '[OK] python3 found\n'
else
    printf '[FAIL] python3 is not installed or not in PATH\n'
    issues=$((issues + 1))
fi

if command -v python3 >/dev/null 2>&1; then
    if python3 - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
    then
        py_version="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")')"
        printf '[OK] Python version is %s (>= 3.11)\n' "$py_version"
    else
        py_version="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")')"
        printf '[FAIL] Python %s detected. Python 3.11+ is required.\n' "$py_version"
        issues=$((issues + 1))
    fi
fi

if [[ -f "$worker_script" ]]; then
    printf '[OK] Worker script exists: %s\n' "$worker_script"
else
    printf '[FAIL] Missing worker script: %s\n' "$worker_script"
    issues=$((issues + 1))
fi

if [[ -f "$requirements_file" ]]; then
    printf '[OK] Requirements file exists: %s\n' "$requirements_file"
else
    printf '[FAIL] Missing requirements file: %s\n' "$requirements_file"
    issues=$((issues + 1))
fi

if [[ -x "$venv_python" ]]; then
    printf '[OK] Managed venv python found: %s\n' "$venv_python"
else
    printf '[FAIL] Managed venv is not initialized yet (%s)\n' "$venv_python"
    issues=$((issues + 1))
fi

if [[ -x "$venv_python" ]]; then
    if "$venv_python" - <<'PY' >/dev/null 2>&1
import torch  # noqa: F401
import diffusers  # noqa: F401
import transformers  # noqa: F401
import accelerate  # noqa: F401
import safetensors  # noqa: F401
from PIL import Image  # noqa: F401
print('ok')
PY
    then
        printf '[OK] Core packages import successfully in managed venv\n'
    else
        printf '[FAIL] Core packages failed to import in managed venv\n'
        issues=$((issues + 1))
    fi

    if "$venv_python" - <<'PY' >/dev/null 2>&1
import torch
raise SystemExit(0 if torch.backends.mps.is_available() else 1)
PY
    then
        printf '[OK] MPS backend is available\n'
    else
        printf '[WARN] MPS backend unavailable. Runtime will use CPU fallback.\n'
    fi

    export HF_HOME="$cache_root"
    export HF_HUB_CACHE="$cache_root/hub"
    export HUGGINGFACE_HUB_CACHE="$cache_root/hub"
    export PYTORCH_ENABLE_MPS_FALLBACK=1
    mkdir -p "$HF_HOME" "$HF_HUB_CACHE"

    if "$venv_python" "$worker_script" --mode health --model-id "$model_id" >/dev/null 2>&1; then
        printf '[OK] Worker health check passed\n'
    else
        printf '[FAIL] Worker health check failed\n'
        issues=$((issues + 1))
    fi
fi

if (( issues > 0 )); then
    printf '\n[ERROR] Diffusers doctor failed with %d issue(s).\n' "$issues"
    printf '[NEXT] Run: make setup-diffusers\n'
    exit 1
fi

printf '\n[OK] Diffusers runtime looks ready.\n'
printf '[NEXT] Use make download-image-model then make smoke-image to fully validate generation.\n'
