#!/usr/bin/env bash

# nf-fa-bluetooth_b
ICON=$''

if [ "$1" = "toggle" ]; then
  if bluetoothctl show | grep -q "Powered: yes"; then
    bluetoothctl power off >/dev/null
  else
    bluetoothctl power on >/dev/null
  fi
  exit 0
fi

if ! bluetoothctl show | grep -q "Powered: yes"; then
  echo "%{F#777777}${ICON}%{F-}"
  exit 0
fi

device=$(bluetoothctl devices Connected | head -1 | cut -d' ' -f3-)

if [ -n "$device" ]; then
  echo "${ICON} ${device}"
else
  echo "${ICON}"
fi
