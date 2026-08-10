#!/usr/bin/env bash
# rofi script-mode calculator: type an expression, press Enter — the
# result is shown and copied to the clipboard. Uses bc (no arbitrary
# code execution) so it's safe to eval directly.
set -uo pipefail

if [ -z "${ROFI_RETV:-}" ] || [ "$ROFI_RETV" = "0" ]; then
  printf '\0prompt\x1fcalc\n'
  printf '\0message\x1fType an expression and press Enter\n'
  exit 0
fi

INPUT="${1:-}"

# Selecting the previously-shown result line: already copied, just exit.
if [[ "$INPUT" == "= "* ]]; then
  exit 0
fi

RESULT=$(echo "$INPUT" | bc -l 2>/dev/null)

if [ -z "$RESULT" ]; then
  printf '\0message\x1finvalid expression\n'
  echo "= error"
  exit 0
fi

printf '%s' "$RESULT" | xclip -selection clipboard
printf '\0message\x1fcopied to clipboard\n'
echo "= $RESULT"
