#!/usr/bin/env bash
# Lock screen (no i3lock-color needed). The minimal artwork comes from
# lock-art.sh, which the LightDM login screen shares, and is drawn on every
# monitor, with i3lock's own typing ring appearing around the centre padlock.
#
# LOCK_PREVIEW=/path/out.png lock.sh   renders the image without locking.
set -euo pipefail

HERE=$(dirname "$(readlink -f "$0")")
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

read -r RW RH < <(xrandr | sed -nE 's/.*current ([0-9]+) x ([0-9]+).*/\1 \2/p')

ARGS=(-size "${RW}x${RH}" xc:black)
i=0
while read -r W H X Y; do
  "$HERE/lock-art.sh" lock "$W" "$H" "$TMPDIR/mon$i.png"
  ARGS+=("$TMPDIR/mon$i.png" -geometry "+$X+$Y" -composite)
  i=$((i + 1))
done < <(xrandr --listactivemonitors |
  awk 'NR>1 {split($3,g,/[\/x+]/); print g[1], g[3], g[5], g[6]}')

if ((i == 0)); then
  "$HERE/lock-art.sh" lock "$RW" "$RH" "$TMPDIR/lock.png"
else
  magick "${ARGS[@]}" "$TMPDIR/lock.png"
fi

[[ ${LOCK_PREVIEW:-} ]] && { cp "$TMPDIR/lock.png" "$LOCK_PREVIEW"; exit; }
i3lock -n -i "$TMPDIR/lock.png" -c 000000
