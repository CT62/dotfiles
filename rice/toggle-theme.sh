#!/usr/bin/env bash
# Cycles the whole rice through bw -> invert -> catppuccin -> bw,
# swapping i3, polybar, kitty, dunst, rofi, qutebrowser and the
# wallpaper together. Pass a theme name to jump straight to it instead
# (that's what rice/theme-picker.sh does).
set -euo pipefail

# One switch at a time — mashing the key would otherwise interleave two
# runs reading/writing the theme file and restarting picom/polybar.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/rice-theme.lock"
flock 9
# Long-lived children below (polybar, qutebrowser, spicetify) get fd 9
# closed so they don't inherit the lock and block the next switch.

RICE=~/.config/rice
STATE_FILE="$RICE/theme"
CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo bw)
THEMES=(bw invert catppuccin)

if [ $# -gt 0 ]; then
  NEW="$1"
  if [[ ! " ${THEMES[*]} " == *" $NEW "* ]]; then
    echo "unknown theme: $NEW (have: ${THEMES[*]})" >&2
    exit 1
  fi
else
  NEW=${THEMES[0]}
  for i in "${!THEMES[@]}"; do
    if [ "${THEMES[$i]}" = "$CURRENT" ]; then
      NEW=${THEMES[$(( (i + 1) % ${#THEMES[@]} ))]}
    fi
  done
fi
echo "$NEW" > "$STATE_FILE"

cp ~/.config/i3/theme-$NEW.conf ~/.config/i3/theme.conf
cp ~/.config/polybar/colors-$NEW.ini ~/.config/polybar/colors.ini
cp ~/.config/kitty/theme-$NEW.conf ~/.config/kitty/theme.conf
cp ~/.config/dunst/dunstrc-$NEW.conf ~/.config/dunst/dunstrc
cp ~/.config/rofi/theme-$NEW.rasi ~/.config/rofi/current.rasi
dunstctl reload >/dev/null 2>&1 || true

# Obsidian: the "Rice" theme's theme.css gets overwritten and Obsidian
# hot-reloads it from disk (no restart needed, unlike Chrome/Spotify below).
OBSIDIAN_VAULT="/home/clive/code/course/comp sci"
if [ -d "$OBSIDIAN_VAULT/.obsidian/themes/rice" ]; then
  cp ~/.config/rice/obsidian/theme-$NEW.css "$OBSIDIAN_VAULT/.obsidian/themes/rice/theme.css"
fi

~/.config/rice/set-wallpaper.sh

i3-msg reload >/dev/null
~/.config/polybar/launch.sh 9>&-

# kitty's listen_on auto-suffixes the socket with each process's own pid
# (e.g. @mykitty-12345), so there's no single @mykitty socket to talk to —
# hit every running instance's real socket instead.
for pid in $(pgrep -x kitty); do
  kitty @ --to "unix:@mykitty-$pid" set-colors -a ~/.config/kitty/theme.conf 2>/dev/null || true
done

# Only nudge qutebrowser if it's already running — invoking the :command
# form with no running instance just launches a brand new window instead
# of reaching an existing one over IPC.
if pgrep -x qutebrowser >/dev/null 2>&1; then
  qutebrowser ":config-source" >/dev/null 2>&1 9>&- &
  disown 2>/dev/null || true
fi

# Spotify (via spicetify) and Chrome don't hot-reload — patch/queue the
# change now and tell the user to restart them if they're currently open.
(
  ~/.spicetify/spicetify config color_scheme "$NEW" >/dev/null 2>&1
  ~/.spicetify/spicetify apply >/dev/null 2>&1
  if flatpak ps 2>/dev/null | grep -q com.spotify.Client; then
    notify-send -a "rice" "Spotify theme" "Updated — restart Spotify to see it" 2>/dev/null || true
  fi
) 9>&- &
disown 2>/dev/null || true

if pgrep -x chrome >/dev/null 2>&1 || pgrep -f "google-chrome-stable" >/dev/null 2>&1; then
  notify-send -a "rice" "Chrome theme" "Restart Chrome to see it" 2>/dev/null || true
fi

notify-send -a "rice" "Theme" "Switched to $NEW" 2>/dev/null || true
