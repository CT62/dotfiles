#!/usr/bin/env bash
# rofi picker for the rice theme ($mod+t) — jump straight to any theme
# instead of cycling through them with $mod+Shift+t. Each row shows the
# theme's palette as colored swatches; the active one is marked.
set -euo pipefail

CURRENT=$(cat ~/.config/rice/theme 2>/dev/null || echo bw)

row() {
  local name="$1" desc="$2"; shift 2
  local swatches="" c
  for c in "$@"; do swatches+="<span foreground='$c'>██</span>"; done
  local mark="  "
  [ "$name" = "$CURRENT" ] && mark="▸ "
  printf '%s%s  <b>%s</b>  <i>%s</i>\n' "$mark" "$swatches" "$name" "$desc"
}

CHOSEN=$(
  {
    row bw         "black &amp; white, solid"      "#000000" "#6E6E6E" "#FFFFFF"
    row invert     "white &amp; black, light"      "#FFFFFF" "#6E6E6E" "#000000"
    row catppuccin "mocha pastels"                 "#1e1e2e" "#cba6f7" "#f5c2e7" "#89b4fa"
  } | rofi -dmenu -markup-rows -i -no-custom -p "theme" \
      -theme ~/.config/rofi/current.rasi -theme-str 'listview { lines: 3; } element-icon { enabled: false; }'
) || exit 0

NAME=$(sed -E 's/<[^>]+>//g' <<<"$CHOSEN" | grep -oE '\b(bw|invert|catppuccin)\b' | head -1)
[ -n "$NAME" ] && [ "$NAME" != "$CURRENT" ] && exec ~/.config/rice/toggle-theme.sh "$NAME"
