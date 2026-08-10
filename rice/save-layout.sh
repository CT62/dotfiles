#!/usr/bin/env bash
# Save the current (or given) workspace layout via i3's built-in
# i3-save-tree, auto-keeping class/instance match criteria so
# append_layout can swallow windows back into place on restore.
set -euo pipefail

LAYOUTS=~/.config/rice/layouts
mkdir -p "$LAYOUTS"

WS="${1:-$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')}"

i3-save-tree --workspace="$WS" \
  | sed -E 's#^(\s*)// ("(class|instance)":.*)#\1\2#' \
  > "$LAYOUTS/$WS.json"

notify-send -a "rice" "i3 layout" "Saved workspace $WS" 2>/dev/null || true
