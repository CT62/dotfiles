#!/usr/bin/env bash
secs=$(cut -d. -f1 /proc/uptime)
d=$((secs / 86400)) h=$(((secs % 86400) / 3600)) m=$(((secs % 3600) / 60))
if [ "$d" -gt 0 ]; then
  printf 'up %dd %dh\n' "$d" "$h"
else
  printf 'up %dh %02dm\n' "$h" "$m"
fi
