#!/usr/bin/env bash
# Fired by the gammastep-prompt systemd --user timer at dusk (matches
# dusk-time in ~/.config/gammastep/config.ini). Asks before switching to
# warm colors rather than gammastep just kicking in unasked.

pgrep -x gammastep >/dev/null && exit 0

action=$(dunstify --appname="gammastep" --urgency=normal \
    --action="enable,Enable" --action="skip,Not tonight" \
    "Getting dark out" "Turn on warmer colors for the evening?")

[ "$action" = "enable" ] && setsid gammastep >/dev/null 2>&1 &
