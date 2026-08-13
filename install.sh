#!/usr/bin/env bash
# One-command installer for Fedora: installs every package this rice needs,
# then symlinks each config folder into place under ~/.config (and the
# wallpapers into ~/Downloads).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGES=(
  # window manager / bar / launcher / notifications
  i3 polybar rofi dunst
  # terminal / browser / editor
  kitty qutebrowser neovim
  # compositor / color temp / wallpaper
  picom gammastep hsetroot
  # screenshots / lock screen
  maim flameshot ImageMagick i3lock
  # media / audio / bluetooth / clipboard / brightness / volume tray icon
  playerctl pulseaudio-utils bluez copyq brightnessctl volumeicon
  # session glue used by i3's exec lines
  dex-autostart xss-lock network-manager-applet libnotify
  # login screen (see lightdm/ below)
  lightdm lightdm-gtk-greeter
  # GTK/Qt app theming consistency (see gtk-3.0/, gtk-4.0/, qt5ct/, qt6ct/)
  qt5ct qt6ct
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

# Fedora spins can default to gdm/sddm instead — this rice expects lightdm
# (see lightdm/ below for its themed greeter).
if command -v systemctl >/dev/null 2>&1 && [ -f /usr/lib/systemd/system/lightdm.service ]; then
  echo "Setting lightdm as the display manager..."
  sudo systemctl disable gdm.service sddm.service 2>/dev/null || true
  sudo systemctl enable lightdm.service
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

# GTK3/GTK4 app theming (dark Adwaita + Cascadia Mono NF), Qt app theming
# (qt5ct/qt6ct, Fusion style + bw color scheme) and the QT_QPA_PLATFORMTHEME
# env var that makes Qt apps actually pick qt5ct up.
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/environment.d"
link "$REPO_DIR/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
link "$REPO_DIR/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
link "$REPO_DIR/qt5ct"       "$HOME/.config/qt5ct"
link "$REPO_DIR/qt6ct"       "$HOME/.config/qt6ct"
link "$REPO_DIR/x11/xprofile" "$HOME/.xprofile"
link "$REPO_DIR/x11/environment.d-qt-theme.conf" "$HOME/.config/environment.d/qt-theme.conf"

# vim and nvim share the same rice-reactive colorscheme (see vim/vimrc);
# nvim/init.vim just sources ~/.vimrc so both look identical.
mkdir -p "$HOME/.vim" "$HOME/.config/nvim"
link "$REPO_DIR/vim/vimrc"   "$HOME/.vimrc"
link "$REPO_DIR/vim/colors"  "$HOME/.vim/colors"
link "$REPO_DIR/nvim/init.vim" "$HOME/.config/nvim/init.vim"

# Shell aliases (vim -> nvim) and the git-branch-in-kitty-tab-title hook.
# Appended via symlinked files, not the whole ~/.bashrc.d dir, so anything
# else Fedora or another tool drops in there later is left alone.
mkdir -p "$HOME/.bashrc.d"
link "$REPO_DIR/bash/bashrc.d/aliases.sh"   "$HOME/.bashrc.d/aliases.sh"
link "$REPO_DIR/bash/bashrc.d/git-title.sh" "$HOME/.bashrc.d/git-title.sh"

# Login screen: themed to match rice/lock.sh's blurred/desaturated look.
# Needs sudo since it writes under /etc and /usr/share — done here instead
# of via link() so a non-Fedora/non-lightdm system can skip it cleanly.
if command -v convert >/dev/null 2>&1 && [ -d /etc/lightdm ]; then
  echo "Setting up themed lightdm greeter..."
  GREETER_CONF=/etc/lightdm/lightdm-gtk-greeter.conf
  GREETER_BG=/usr/share/backgrounds/lockscreen-greeter-bw.png
  if [ -f "$GREETER_CONF" ] && [ ! -L "$GREETER_CONF" ]; then
    sudo cp "$GREETER_CONF" "$GREETER_CONF.bak.$(date +%s)"
  fi
  SRC_WALLPAPER="$REPO_DIR/wallpapers/wallpaper-bw/night-field-walker.jpg"
  TMP_BG=$(mktemp --suffix=.png)
  convert "$SRC_WALLPAPER" -colorspace Gray -blur 0x8 -modulate 35 "$TMP_BG"
  sudo install -m 644 "$TMP_BG" "$GREETER_BG"
  rm -f "$TMP_BG"
  sudo install -m 644 "$REPO_DIR/lightdm/lightdm-gtk-greeter.conf" "$GREETER_CONF"
  echo "Greeter themed. Takes effect next login/reboot."
fi

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
echo "Note: volumeicon is installed and i3/config has a for_window rule for it,"
echo "but nothing here autostarts it — start it manually, or add an exec line"
echo "to i3/config if you want it launched on login."
echo
echo "Note: rice/toggle-theme.sh hardcodes an Obsidian vault path"
echo "(/home/clive/code/course/comp sci) — edit that line to your own vault, or"
echo "leave it; it's just skipped if the folder doesn't exist."
