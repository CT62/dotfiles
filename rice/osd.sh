#!/usr/bin/env bash
# On-screen display for volume/brightness, riding on dunst's progress_bar
# (no xob package on Fedora, and this stays themed for free).
set -euo pipefail

KIND="$1"

case "$KIND" in
  volume)
    VALUE=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
    MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -q "yes" && echo 1 || echo 0)
    if [ "$MUTED" = "1" ]; then
      notify-send -a "rice" -t 1500 -h string:x-dunst-stack-tag:osd-volume "♪ muted" ""
    else
      notify-send -a "rice" -t 1500 -h int:value:"$VALUE" -h string:x-dunst-stack-tag:osd-volume "♪ VOLUME" "${VALUE}%"
    fi
    ;;
  brightness)
    VALUE=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
    notify-send -a "rice" -t 1500 -h int:value:"$VALUE" -h string:x-dunst-stack-tag:osd-brightness "☀ BRIGHTNESS" "${VALUE}%"
    ;;
esac
