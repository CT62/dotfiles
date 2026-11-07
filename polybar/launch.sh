#!/usr/bin/env bash

# Serialize overlapping calls (e.g. two quick theme switches): otherwise
# both kill the old bars, then both launch a set, leaving doubled bars.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/polybar-launch.lock"
flock 9
# (the bars themselves get fd 9 closed below, or they'd hold the lock forever)

killall -q polybar

while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.5; done

# Full "main" bar on the primary monitor (or the first one if none is
# marked primary), slim "side" bar on every other monitor.
monitors="$(polybar --list-monitors)"
primary="$(echo "$monitors" | grep primary | cut -d: -f1)"
[ -z "$primary" ] && primary="$(echo "$monitors" | head -1 | cut -d: -f1)"

for m in $(echo "$monitors" | cut -d: -f1); do
  bar=side
  [ "$m" = "$primary" ] && bar=main
  MONITOR="$m" polybar "$bar" --config=~/.config/polybar/config.ini \
    >"/tmp/polybar-$m.log" 2>&1 9>&- &
done

disown -a

for _ in $(seq 20); do
  [ "$(pgrep -u "$UID" -x polybar | wc -l)" -ge "$(echo "$monitors" | wc -l)" ] && break
  sleep 0.1
done
