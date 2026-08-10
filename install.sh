#!/usr/bin/env bash
# One-command installer for Fedora: installs every package this rice needs,
# then symlinks each config folder into place under ~/.config (and the
# wallpapers into ~/Downloads).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGES=(
  # window manager / bar / launcher / notifications
  i3 polybar rofi dunst
  # terminal / browser
  kitty qutebrowser
  # compositor / color temp / wallpaper
  picom gammastep hsetroot
  # screenshots / lock screen
  maim flameshot ImageMagick i3lock
  # media / audio / bluetooth / clipboard / brightness
  playerctl pulseaudio-utils bluez copyq brightnessctl
  # session glue used by i3's exec lines
  dex-autostart xss-lock network-manager-applet libnotify
  # scripting deps
  jq python3-i3ipc
  # font used across every module (bars, i3, kitty, qutebrowser)
  cascadia-mono-nf-fonts
  # system info on terminal open (see fastfetch/)
  fastfetch git
)

if command -v dnf >/dev/null 2>&1; then
  echo "Installing dependencies via dnf..."
  sudo dnf install -y "${PACKAGES[@]}"
else
  echo "dnf not found — this installer targets Fedora."
  echo "Install these manually for your distro: ${PACKAGES[*]}"
fi

link() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    local backup="${dest}.bak.$(date +%s)"
    echo "Backing up existing $dest to $backup"
    mv "$dest" "$backup"
  fi
  ln -sfn "$src" "$dest"
  echo "Linked $dest -> $src"
}

link "$REPO_DIR/i3"          "$HOME/.config/i3"
link "$REPO_DIR/polybar"     "$HOME/.config/polybar"
link "$REPO_DIR/kitty"       "$HOME/.config/kitty"
link "$REPO_DIR/dunst"       "$HOME/.config/dunst"
link "$REPO_DIR/rofi"        "$HOME/.config/rofi"
mkdir -p "$HOME/.config/qutebrowser"
link "$REPO_DIR/qutebrowser/config.py" "$HOME/.config/qutebrowser/config.py"
link "$REPO_DIR/rice"        "$HOME/.config/rice"
link "$REPO_DIR/picom"       "$HOME/.config/picom"
link "$REPO_DIR/gammastep"   "$HOME/.config/gammastep"
link "$REPO_DIR/flameshot"   "$HOME/.config/flameshot"
link "$REPO_DIR/fastfetch"   "$HOME/.config/fastfetch"

# pokemon-colorscripts isn't packaged for Fedora — clone it straight from
# its repo and symlink the entrypoint into ~/.local/bin. fastfetch/run.sh
# shows a random Pokemon as the logo on every terminal open; it degrades
# to the plain themed logo if this ever isn't on PATH.
POKEMON_DIR="$HOME/.local/share/pokemon-colorscripts"
if [ ! -d "$POKEMON_DIR" ]; then
  echo "Cloning pokemon-colorscripts..."
  git clone --depth 1 https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$POKEMON_DIR"
fi
chmod +x "$POKEMON_DIR/pokemon-colorscripts.py"
mkdir -p "$HOME/.local/bin"
link "$POKEMON_DIR/pokemon-colorscripts.py" "$HOME/.local/bin/pokemon-colorscripts"

# Append the fastfetch-on-shell-open snippet to .bashrc if it's not there yet
# (appended, not symlinked, so Fedora's default .bashrc content is kept).
BASHRC_MARKER="# Animated, theme-matched fastfetch on new interactive shells"
if ! grep -qF "$BASHRC_MARKER" "$HOME/.bashrc" 2>/dev/null; then
  echo "Adding fastfetch startup snippet to ~/.bashrc"
  { echo; cat "$REPO_DIR/fastfetch/bashrc-snippet.sh"; } >> "$HOME/.bashrc"
fi

mkdir -p "$HOME/Downloads"
link "$REPO_DIR/wallpapers/wallpaper"    "$HOME/Downloads/wallpaper"
link "$REPO_DIR/wallpapers/wallpaper-bw" "$HOME/Downloads/wallpaper-bw"

mkdir -p "$HOME/.config/systemd/user"
link "$REPO_DIR/systemd/user/gammastep-prompt.service" "$HOME/.config/systemd/user/gammastep-prompt.service"
link "$REPO_DIR/systemd/user/gammastep-prompt.timer"   "$HOME/.config/systemd/user/gammastep-prompt.timer"
systemctl --user daemon-reload
systemctl --user enable --now gammastep-prompt.timer

echo
echo "Done. Log out and back into i3 (or run: ~/.config/rice/toggle-theme.sh"
echo "twice to force everything to reload) to pick everything up."
echo
echo "Not installed by this script (install/configure separately if you use them):"
echo "  - google-chrome-stable (not in Fedora repos; used by rice/chrome-launch.sh)"
echo "  - spicetify, for Spotify theming (used by rice/toggle-theme.sh if present)"
echo "  - Obsidian, if you want the rice/obsidian/*.css theme"
echo
echo "Note: rice/toggle-theme.sh hardcodes an Obsidian vault path"
echo "(/home/clive/code/course/comp sci) — edit that line to your own vault, or"
echo "leave it; it's just skipped if the folder doesn't exist."
