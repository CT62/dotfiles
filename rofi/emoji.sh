#!/usr/bin/env bash
# rofi script-mode emoji picker: select an emoji, it's copied to the
# clipboard. Curated static list (no rofi-emoji plugin available).
set -uo pipefail

LIST=~/.config/rofi/emoji-list.txt

if [ -z "${ROFI_RETV:-}" ] || [ "$ROFI_RETV" = "0" ]; then
  printf '\0prompt\x1femoji\n'
  cat "$LIST"
  exit 0
fi

SELECTED="${1:-}"
EMOJI="${SELECTED%% *}"

if [ -n "$EMOJI" ]; then
  printf '%s' "$EMOJI" | xclip -selection clipboard
  notify-send -a "rice" "Emoji" "$EMOJI copied to clipboard" 2>/dev/null || true
fi
