#!/usr/bin/env bash
THEME=$(cat ~/.config/rice/theme 2>/dev/null || echo bw)
WALLPAPERS=~/.config/i3/wallpapers

# dithered/ is shared by the black and white themes only, never catppuccin.
case "$THEME" in
  catppuccin)  dirs=("$WALLPAPERS/wallpaper") ;;
  invert)      dirs=("$WALLPAPERS/wallpaper-invert" "$WALLPAPERS/dithered") ;;
  *)           dirs=("$WALLPAPERS/wallpaper-bw" "$WALLPAPERS/dithered") ;;
esac
wp=$(find -L "${dirs[@]}" -maxdepth 1 -type f | shuf -n 1)
[ -n "$wp" ] || exit 0
feh --bg-fill "$wp" "$wp" || true
