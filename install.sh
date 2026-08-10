#!/usr/bin/env bash
# One-command installer for Fedora: installs the required packages,
# then symlinks polybar/ into ~/.config/polybar.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.config/polybar"

PACKAGES=(
  polybar
  i3
  playerctl
  pulseaudio-utils
  bluez
  jq
  rofi
  kitty
  cascadia-mono-nf-fonts
)

if command -v dnf >/dev/null 2>&1; then
  echo "Installing dependencies via dnf..."
  sudo dnf install -y "${PACKAGES[@]}"
else
  echo "dnf not found — this installer targets Fedora."
  echo "Install these manually for your distro: ${PACKAGES[*]}"
fi

if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
  BACKUP="${TARGET}.bak.$(date +%s)"
  echo "Backing up existing $TARGET to $BACKUP"
  mv "$TARGET" "$BACKUP"
fi

ln -sfn "$REPO_DIR/polybar" "$TARGET"
echo "Linked $TARGET -> $REPO_DIR/polybar"

echo
echo "Done. Run ~/.config/polybar/launch.sh (or restart i3) to start the bars."
echo "Note: powermenu.sh calls rofi with a theme at ~/.config/rofi/current.rasi —"
echo "point it at your own rofi theme, or edit/remove that line if you don't have one."
