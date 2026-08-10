#!/usr/bin/env bash
# duf-style usage bar for /
read -r used total pct < <(df -k --output=used,size,pcent / | tail -1 | tr -d '%')

used_h=$(numfmt --to=iec $((used * 1024)))
total_h=$(numfmt --to=iec $((total * 1024)))

width=20
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

printf '%%{F%s}[%s]%%{F-} %s%% %s/%s\n' "$color" "$bar" "$pct" "$used_h" "$total_h"
