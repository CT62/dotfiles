#!/usr/bin/env bash
# Center bar module: show the currently playing track when something is
# actually playing, otherwise fall back to the focused window's title
# (what the old internal/xwindow module showed).
set -uo pipefail

truncate() {
  local s="$1" max="$2"
  if [ "${#s}" -gt "$max" ]; then
    printf '%s...' "${s:0:$max}"
  else
    printf '%s' "$s"
  fi
}

STATUS=$(playerctl status 2>/dev/null)
if [ "$STATUS" = "Playing" ]; then
  ARTIST=$(playerctl metadata artist 2>/dev/null)
  TITLE=$(playerctl metadata title 2>/dev/null)
  if [ -n "$TITLE" ]; then
    if [ -n "$ARTIST" ]; then
      truncate "♫ $ARTIST — $TITLE" 60
    else
      truncate "♫ $TITLE" 60
    fi
    exit 0
  fi
fi

WINDOW=$(i3-msg -t get_tree 2>/dev/null | jq -r '.. | objects | select(.focused == true) | .name // empty' | head -1)
if [ -n "$WINDOW" ]; then
  truncate "▸ $WINDOW" 60
fi
