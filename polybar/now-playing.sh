#!/usr/bin/env bash
# Center bar module: when a player has a track loaded, show clickable
# prev / play-pause / next buttons plus the track; otherwise show nothing.
set -uo pipefail

truncate() {
  local s="$1" max="$2"
  if [ "${#s}" -gt "$max" ]; then
    printf '%s…' "${s:0:$max}"
  else
    printf '%s' "$s"
  fi
}

# nf-md-skip_previous / play / pause / skip_next / music
PREV=$'\U000f04ae' PLAY=$'\U000f040a' PAUSE=$'\U000f03e4' NEXT=$'\U000f04ad'
NOTE=$'\U000f075a'

STATUS=$(playerctl status 2>/dev/null)
if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
  ARTIST=$(playerctl metadata artist 2>/dev/null)
  TITLE=$(playerctl metadata title 2>/dev/null)
  if [ -n "$TITLE" ]; then
    TOGGLE=$PLAY
    [ "$STATUS" = "Playing" ] && TOGGLE=$PAUSE
    TRACK="$TITLE"
    [ -n "$ARTIST" ] && TRACK="$ARTIST — $TITLE"
    printf '%%{A1:playerctl previous:}%s%%{A}  %%{A1:playerctl play-pause:}%s%%{A}  %%{A1:playerctl next:}%s%%{A}   %s %s\n' \
      "$PREV" "$TOGGLE" "$NEXT" "$NOTE" "$(truncate "$TRACK" 40)"
    exit 0
  fi
fi
