#!/usr/bin/env bash

# Serialize overlapping calls (e.g. two quick theme switches): otherwise
# both kill the old bars, then both launch a set, leaving doubled bars.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/polybar-launch.lock"
flock 9
# (the bars themselves get fd 9 closed below, or they'd hold the lock forever)

killall -q polybar

while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.5; done

# The bar goes on the primary monitor (falls back to polybar's default
# monitor when none is marked primary).
export MONITOR="$(polybar --list-monitors | grep primary | cut -d: -f1)"
polybar main --config=~/.config/polybar/config.ini >/tmp/polybar.log 2>&1 9>&- &

disown -a

for _ in $(seq 20); do
  [ "$(pgrep -u "$UID" -x polybar | wc -l)" -ge 1 ] && break
  sleep 0.1
done
