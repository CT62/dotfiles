#!/usr/bin/env bash
# Install the themed LightDM login screen. Renders the backgrounds with the
# lock screen's artwork (rice/lock-art.sh) for each connected monitor shape,
# installs the Rice-Greeter GTK theme and the greeter config.
#
# Run as your normal user; it asks for sudo only for the system files.
# Takes effect at the next logout/reboot.
set -euo pipefail

REPO=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
CONF=/etc/lightdm/lightdm-gtk-greeter.conf
BGDIR=/usr/share/backgrounds
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cp "$REPO/lightdm/lightdm-gtk-greeter.conf" "$TMP/greeter.conf"

# Landscape background is the default; each portrait/odd-sized monitor gets
# its own render so the dial stays centred instead of being cropped.
"$REPO/rice/lock-art.sh" greeter 1920 1080 "$TMP/lockscreen-greeter-bw.png" bw
if command -v xrandr >/dev/null && [[ ${DISPLAY:-} ]]; then
  while read -r NAME W H; do
    if ((W * 9 != H * 16)); then
      F="lockscreen-greeter-bw-${W}x${H}.png"
      [[ -f $TMP/$F ]] || "$REPO/rice/lock-art.sh" greeter "$W" "$H" "$TMP/$F" bw
      printf '\n[monitor: %s]\nbackground=%s/%s\n' "$NAME" "$BGDIR" "$F" >>"$TMP/greeter.conf"
    fi
  done < <(xrandr --listactivemonitors |
    awk 'NR>1 {split($3,g,/[\/x+]/); print $4, g[1], g[3]}')
fi

echo "Installing greeter theme, backgrounds and config (needs sudo)..."
[[ -f $CONF && ! -L $CONF ]] && sudo cp "$CONF" "$CONF.bak.$(date +%s)"
sudo install -m 644 "$TMP"/lockscreen-greeter-bw*.png "$BGDIR/"
sudo install -Dm 644 "$REPO/lightdm/Rice-Greeter/gtk-3.0/gtk.css" \
  /usr/share/themes/Rice-Greeter/gtk-3.0/gtk.css
sudo install -m 644 "$TMP/greeter.conf" "$CONF"
echo "Login screen themed. You'll see it at your next logout or reboot."
