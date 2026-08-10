#!/usr/bin/env bash
# Restore a workspace layout saved by save-layout.sh. This recreates the
# split/tabbed/stacked container structure as placeholders; it does not
# relaunch programs (i3-save-tree is layout-only, unlike i3-resurrect) —
# open the same apps afterwards and i3 will swallow them into place.
set -euo pipefail

LAYOUTS=~/.config/rice/layouts

WS="${1:-$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')}"
FILE="$LAYOUTS/$WS.json"

if [ ! -f "$FILE" ]; then
  notify-send -a "rice" "i3 layout" "No saved layout for workspace $WS" 2>/dev/null || true
  exit 1
fi

i3-msg "workspace $WS; append_layout $FILE" >/dev/null
notify-send -a "rice" "i3 layout" "Restored workspace $WS layout — reopen your apps" 2>/dev/null || true
