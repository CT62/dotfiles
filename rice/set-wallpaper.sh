#!/usr/bin/env bash
THEME=$(cat ~/.config/rice/theme 2>/dev/null || echo bw)
WALLPAPERS=~/.config/i3/wallpapers

# Catppuccin wallpapers come in <name>-landscape.png / <name>-portrait.png pairs
# (made by gen-catppuccin-wallpapers.py); each monitor gets the one matching its
# orientation, so the vertical monitor isn't just a crop of the landscape image.
if [ "$THEME" = catppuccin ]; then
  name=$(find -L "$WALLPAPERS/wallpaper" -maxdepth 1 -name '*-landscape.png' | shuf -n 1)
  name=${name%-landscape.png}
  [ -n "$name" ] || exit 0
  args=()
  # feh assigns images to monitors in this same order
  while read -r w h; do
    if [ "$h" -gt "$w" ] && [ -f "$name-portrait.png" ]; then
      args+=("$name-portrait.png")
    else
      args+=("$name-landscape.png")
    fi
  done < <(xrandr --listmonitors | sed -nE 's/^ *[0-9]+: \S+ ([0-9]+)\/[0-9]+x([0-9]+)\/.*/\1 \2/p')
  [ ${#args[@]} -gt 0 ] || args=("$name-landscape.png")
  feh --bg-fill "${args[@]}" || true
  exit 0
fi

# dithered/ is shared by the black and white themes only, never catppuccin.
case "$THEME" in
  invert)      dirs=("$WALLPAPERS/wallpaper-invert" "$WALLPAPERS/dithered") ;;
  *)           dirs=("$WALLPAPERS/wallpaper-bw" "$WALLPAPERS/dithered") ;;
esac
wp=$(find -L "${dirs[@]}" -maxdepth 1 -type f | shuf -n 1)
[ -n "$wp" ] || exit 0
feh --bg-fill "$wp" "$wp" || true
