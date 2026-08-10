#!/usr/bin/env bash
# rofi script-mode clipboard history, backed by a headless copyq server.
# Selection copies the displayed text straight to the clipboard via xclip
# instead of asking copyq to re-select by row index — copyq's internal
# order isn't stable between the two separate script invocations rofi
# makes (list, then select), so an index captured during listing can
# point at a different item by the time it's used.
set -uo pipefail

if [ -z "${ROFI_RETV:-}" ] || [ "$ROFI_RETV" = "0" ]; then
  printf '\0prompt\x1fclipboard\n'
  N=$(copyq count 2>/dev/null || echo 0)
  for i in $(seq 0 $((N - 1))); do
    item=$(copyq read "$i" 2>/dev/null | tr '\n' ' ' | cut -c1-200)
    [ -n "$item" ] && printf '%s\n' "$item"
  done
  exit 0
fi

SELECTED="${1:-}"
if [ -n "$SELECTED" ]; then
  printf '%s' "$SELECTED" | xclip -selection clipboard
fi
