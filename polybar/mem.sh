#!/usr/bin/env bash
# Memory usage as a short segmented gauge plus GiB used, colored
# green -> red as usage climbs.

total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
used=$((total - avail))
pct=$((100 * used / total))

width=6
filled=$(((pct * width + 50) / 100))
empty=$((width - filled))

if   [ "$pct" -ge 90 ]; then color="#E64553"
elif [ "$pct" -ge 75 ]; then color="#F5A25C"
elif [ "$pct" -ge 50 ]; then color="#F2C94C"
else color="#4CD97B"
fi

bar=""
[ "$filled" -gt 0 ] && bar+=$(printf '▰%.0s' $(seq 1 "$filled"))
[ "$empty" -gt 0 ] && bar+=$(printf '▱%.0s' $(seq 1 "$empty"))

printf '%%{F%s}%s%%{F-} %s\n' "$color" "$bar" "$(awk -v k="$used" 'BEGIN { printf "%.1fG", k / 1048576 }')"
