#!/usr/bin/env bash
# Searchable cheatsheet of every i3 keybinding ($mod+slash), read live
# from i3/config: each binding is labeled with the comment block directly
# above it (or its command, if it has none). Picking a row runs it.
set -euo pipefail

CONFIG=~/.config/i3/config

CHOSEN=$(
  awk '
    /^[[:space:]]*#/ {
      sub(/^[[:space:]]*#[[:space:]]*/, "")
      comment = (comment != "" ? comment " " : "") $0; next
    }
    /^[[:space:]]*$/ { comment = ""; next }
    /^[[:space:]]*mode / { mode = $2; gsub(/"/, "", mode); next }
    /^[[:space:]]*}/ { mode = ""; next }
    /^[[:space:]]*bindsym / {
      i = 2; while ($i ~ /^--/) i++
      key = $i; cmd = $0
      sub(/^[[:space:]]*bindsym[[:space:]]+(--[a-z-]+[[:space:]]+)*[^[:space:]]+[[:space:]]+/, "", cmd)
      gsub(/\$mod/, "Super", key)
      label = (comment != "" ? comment : cmd)
      if (length(label) > 78) { label = substr(label, 1, 78); sub(/ [^ ]*$/, "", label); label = label "…" }
      if (mode != "") label = "[" mode "] " label
      printf "%-22s  %s\t%s\n", key, label, cmd
    }
  ' "$CONFIG" \
  | rofi -dmenu -i -p "keys" -display-columns 1 -display-column-separator '\t' \
      -theme ~/.config/rofi/current.rasi -theme-str 'window { width: 52%; } listview { lines: 14; }'
) || exit 0

CMD=$(cut -f2 <<<"$CHOSEN")
[ -n "$CMD" ] && [[ "$CMD" != mode* ]] && i3-msg "$CMD" >/dev/null
