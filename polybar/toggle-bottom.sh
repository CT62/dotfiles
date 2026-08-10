#!/usr/bin/env bash
# Toggle the bottom polybar. The clock and battery normally live on the
# bottom bar; while it's hidden, the top bar (bar/main-alt) picks both up
# (date left of CPU, battery on the right) so nothing is lost.
set -uo pipefail

CONFIG=~/.config/polybar/config.ini

wait_for_exit() {
	while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.1; done
}

# volumeicon doesn't retry embedding after the systray host disappears -
# it falls back to a plain top-level (blank black) window and stays stuck
# there. Restart it once the new bar's systray module is up so it re-embeds.
restart_volumeicon() {
	pkill -x volumeicon 2>/dev/null
	sleep 0.3
	volumeicon &
	disown
}

if pgrep -f "polybar bottom --config" >/dev/null; then
	# Bottom bar is up -> hide it, switch top bar to the alt layout.
	pkill -f "polybar bottom --config"
	pkill -f "polybar main --config"
	wait_for_exit
	polybar main-alt --config="$CONFIG" >/tmp/polybar-main.log 2>&1 &
	disown
	restart_volumeicon
else
	# Bottom bar is hidden -> restore it, switch top bar back to normal.
	pkill -f "polybar main-alt --config"
	wait_for_exit
	polybar main --config="$CONFIG" >/tmp/polybar-main.log 2>&1 &
	polybar bottom --config="$CONFIG" >/tmp/polybar-bottom.log 2>&1 &
	disown -a
	restart_volumeicon
fi
