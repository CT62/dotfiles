#!/usr/bin/env bash
# Theme-aware fastfetch: picks the config matching the current rice theme,
# then reveals it line by line for a quick boot-sequence effect. Kept snappy
# (short per-line delay) to match the pulse timing used elsewhere in the rice
# (see rice/border-pulse.py) rather than a slow, cheesy typewriter crawl.
set -uo pipefail

THEME=$(cat ~/.config/rice/theme 2>/dev/null || echo bw)
CONFIG=~/.config/fastfetch/config-$THEME.jsonc
[ -f "$CONFIG" ] || CONFIG=~/.config/fastfetch/config-bw.jsonc

ARGS=(--config "$CONFIG" --pipe false)

# Info only — no logo/graphic beside it.
ARGS+=(--logo none)

mapfile -t LINES < <(fastfetch "${ARGS[@]}")

for line in "${LINES[@]}"; do
	printf '%s\n' "$line"
	sleep 0.018
done
