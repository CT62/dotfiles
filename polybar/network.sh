#!/usr/bin/env bash
# nf-fa-plug / nf-fa-wifi — icon only in the bar; the connection name is
# dropped from the label, so click-left (see config.ini) surfaces it via
# notify-send instead.
WIRED_ICON=$''
WIFI_ICON=$''

conn=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | grep -v ':loopback:' | head -1)
name=$(echo "$conn" | cut -d: -f1)
type=$(echo "$conn" | cut -d: -f2)

if [ "$1" = "info" ]; then
  notify-send -a "rice" "Network" "${name:-Offline}" 2>/dev/null || true
  exit 0
fi

if [ -z "$name" ]; then
  echo "%{F#777777}${WIRED_ICON}%{F-}"
elif [ "$type" = "802-11-wireless" ]; then
  echo "$WIFI_ICON"
else
  echo "$WIRED_ICON"
fi
