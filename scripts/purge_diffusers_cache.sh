#!/usr/bin/env bash
set -euo pipefail

support_root="$HOME/Library/Application Support/StoryJuicer/Diffusers"
cache_root="$HOME/Library/Caches/StoryJuicer/Diffusers"

printf '[INFO] Diffusers support path: %s\n' "$support_root"
printf '[INFO] Diffusers cache path:   %s\n' "$cache_root"

if [[ -d "$support_root" ]]; then
    printf '[INFO] Current support size: '
    du -sh "$support_root" | awk '{print $1}'
else
    printf '[INFO] Current support size: 0B\n'
fi

if [[ -d "$cache_root" ]]; then
    printf '[INFO] Current cache size:   '
    du -sh "$cache_root" | awk '{print $1}'
else
    printf '[INFO] Current cache size:   0B\n'
fi

rm -rf "$support_root" "$cache_root"

printf '[OK] Removed local Diffusers runtime/model cache data.\n'
