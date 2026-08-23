#!/usr/bin/env bash

killall -q polybar

while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.5; done

MONITOR="$(polybar --list-monitors | grep primary | cut -d: -f1)" polybar main --config=~/.config/polybar/config.ini >/tmp/polybar.log 2>&1 &
polybar bottom --config=~/.config/polybar/config.ini >/tmp/polybar-bottom.log 2>&1 &

disown -a
