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

# Always show a random Pokemon (raw ANSI via pokemon-colorscripts, colors
# and all) instead of the plain diamond; keys/values stay themed.
if command -v pokemon-colorscripts >/dev/null 2>&1; then
	ARGS+=(--logo-type command-raw --logo "pokemon-colorscripts --no-title -r")
fi

mapfile -t LINES < <(fastfetch "${ARGS[@]}")

for line in "${LINES[@]}"; do
	printf '%s\n' "$line"
	sleep 0.018
done
