#!/usr/bin/env bash
# CPU load as a scrolling sparkline of the last few samples plus the
# current percentage, colored green -> red as load climbs. History lives
# in $XDG_RUNTIME_DIR so it survives bar restarts but not reboots.

HIST="${XDG_RUNTIME_DIR:-/tmp}/polybar-cpu-history"
SAMPLES=8

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

{ read -r -a hist < "$HIST"; } 2>/dev/null || hist=()
hist+=("$pct")
[ "${#hist[@]}" -gt "$SAMPLES" ] && hist=("${hist[@]: -$SAMPLES}")
echo "${hist[*]}" > "$HIST"

if   [ "$pct" -ge 90 ]; then color="#E64553"
elif [ "$pct" -ge 75 ]; then color="#F5A25C"
elif [ "$pct" -ge 50 ]; then color="#F2C94C"
else color="#4CD97B"
fi

blocks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
spark=""
for ((i = ${#hist[@]}; i < SAMPLES; i++)); do spark+="${blocks[0]}"; done
for v in "${hist[@]}"; do i=$((v * 8 / 100)); spark+="${blocks[$((i > 7 ? 7 : i))]}"; done

printf '%%{F%s}%s%%{F-} %2d%%\n' "$color" "$spark" "$pct"
