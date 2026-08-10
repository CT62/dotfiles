#!/usr/bin/env bash
# Proportional CPU usage bar, colored green -> red as load climbs (no
# percentage shown, styled like storage.sh's disk-usage bar).

read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat
sleep 0.2
read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat

idle1=$((i1 + w1))
idle2=$((i2 + w2))
total1=$((u1 + n1 + s1 + i1 + w1 + q1 + sq1 + st1))
total2=$((u2 + n2 + s2 + i2 + w2 + q2 + sq2 + st2))

totald=$((total2 - total1))
idled=$((idle2 - idle1))
pct=$(((100 * (totald - idled)) / totald))

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
