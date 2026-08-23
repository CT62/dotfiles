#!/usr/bin/env bash
# CPU temperature via k10temp (Tctl), styled like the internal/temperature
# module it replaces: colored diamond ramp green -> red as temp climbs from
# base to warn.

base=40
warn=80

raw=$(cat /sys/class/hwmon/hwmon1/temp1_input 2>/dev/null) || raw=0
temp=$((raw / 1000))

ramp=(
  "#4CD97B" "#8BD46E" "#C4D96C" "#F2C94C"
  "#F5A25C" "#F2735C" "#E64553"
)

idx=$(( (temp - base) * 6 / (warn - base) ))
[ "$idx" -lt 0 ] && idx=0
[ "$idx" -gt 6 ] && idx=6
color="${ramp[$idx]}"

if [ "$temp" -ge "$warn" ]; then
  color="#E64553"
fi

printf '%%{F%s}◈%%{F-} TEMP %s°C\n' "$color" "$temp"
