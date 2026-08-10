#!/usr/bin/env bash
THEME=$(cat ~/.config/rice/theme 2>/dev/null || echo bw)

case "$THEME" in
  catppuccin)  wp=$(find ~/Downloads/wallpaper -maxdepth 1 -type f | shuf -n 1) ;;
  *)           wp=$(find ~/Downloads/wallpaper-bw -maxdepth 1 -type f | shuf -n 1) ;;
esac
[ -n "$wp" ] && hsetroot -fill "$wp" || true
