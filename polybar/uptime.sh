#!/usr/bin/env bash
secs=$(cut -d. -f1 /proc/uptime)
printf '▶ UP %dh%02dm\n' $((secs/3600)) $(((secs%3600)/60))
