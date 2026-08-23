#!/usr/bin/env bash
THEME=$(cat ~/.config/rice/theme 2>/dev/null || echo bw)

case "$THEME" in
  catppuccin)  wp=$(find -L ~/Downloads/wallpaper -maxdepth 1 -type f | shuf -n 1) ;;
  *)           wp=$(find -L ~/Downloads/wallpaper-bw -maxdepth 1 -type f | shuf -n 1) ;;
esac
[ -n "$wp" ] && feh --bg-fill "$wp" "$wp" || true
