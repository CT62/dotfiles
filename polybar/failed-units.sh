#!/usr/bin/env bash
# Stays empty (and takes no bar space) unless something's actually broken.
n=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
if [ "$n" -gt 0 ]; then
  printf '⚠ %d FAILED\n' "$n"
fi
