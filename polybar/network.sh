#!/usr/bin/env bash
# nf-fa-plug / nf-fa-wifi — icon only in the bar (greyed out when offline).
# Click-left opens the rofi network panel (rofi/network-info.sh), which
# shows the connection details.
WIRED_ICON=$''
WIFI_ICON=$''

conn=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | grep -v ':loopback:' | head -1)
name=$(echo "$conn" | cut -d: -f1)
type=$(echo "$conn" | cut -d: -f2)

if [ -z "$name" ]; then
  echo "%{F#777777}${WIRED_ICON}%{F-}"
elif [ "$type" = "802-11-wireless" ]; then
  echo "$WIFI_ICON"
else
  echo "$WIRED_ICON"
fi
