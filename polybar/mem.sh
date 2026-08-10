#!/usr/bin/env bash
# Proportional memory usage bar, colored green -> red as usage climbs (no
# percentage shown, styled like storage.sh's disk-usage bar).

total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
used=$((total - avail))
pct=$((100 * used / total))

width=10
filled=$((pct * width / 100))
empty=$((width - filled))

if   [ "$pct" -ge 90 ]; then color="#E64553"
elif [ "$pct" -ge 75 ]; then color="#F5A25C"
elif [ "$pct" -ge 50 ]; then color="#F2C94C"
else color="#4CD97B"
fi

bar=""
[ "$filled" -gt 0 ] && bar+=$(printf '█%.0s' $(seq 1 "$filled"))
[ "$empty" -gt 0 ] && bar+=$(printf '░%.0s' $(seq 1 "$empty"))

printf '%%{F%s}[%s]%%{F-}\n' "$color" "$bar"
