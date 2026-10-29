#!/usr/bin/env bash
# Black lock screen (no i3lock-color needed): a pure black canvas with a
# faint dot grid fading out from the centre, HUD corner brackets, rings with
# an accent arc (i3lock's own typing indicator nests inside them), the date
# and who's locked. No clock — it'd be frozen at lock time.
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

THEME=$(cat ~/.config/rice/theme 2>/dev/null || echo bw)
case "$THEME" in
  catppuccin) FG='#cba6f7'; DIM='#6c7086'; LINE='#313244'; DOT='#6c7086' ;;
  *)          FG='#FFFFFF'; DIM='#6E6E6E'; LINE='#262626'; DOT='#5A5A5A' ;;
esac

# Whole X screen (all monitors) and the primary monitor the design sits on.
read -r RW RH < <(xrandr | sed -nE 's/.*current ([0-9]+) x ([0-9]+).*/\1 \2/p')
read -r W H X Y < <(xrandr --listactivemonitors |
  awk 'NR>1 && /\*/{split($3,g,/[\/x+]/); print g[1], g[3], g[5], g[6]; exit}')
: "${W:=$RW}" "${H:=$RH}" "${X:=0}" "${Y:=0}"
CX=$((W / 2)); CY=$((H / 2))

# Dot grid, faded by a radial mask so it glows around the centre.
magick -size 28x28 xc:black -fill "$DOT" -draw 'point 14,14' "$TMPDIR/tile.png"
magick -size "${W}x${H}" tile:"$TMPDIR/tile.png" \
  \( -size "${W}x${H}" radial-gradient:white-black -evaluate pow 1.6 \) \
  -compose multiply -composite "$TMPDIR/mon.png"

# HUD corner brackets.
M=48; L=36
BRACKETS=""
for c in "$M,$M,1,1" "$((W-M)),$M,-1,1" "$M,$((H-M)),1,-1" "$((W-M)),$((H-M)),-1,-1"; do
  IFS=, read -r bx by sx sy <<<"$c"
  BRACKETS+="line $bx,$by $((bx+sx*L)),$by line $bx,$by $bx,$((by+sy*L)) "
done

FONT=Cascadia-Mono-NF-Bold
THIN=Cascadia-Mono-NF-Light
DAY=$(date '+%A  %d  %B' | tr '[:lower:]' '[:upper:]')
R1=135; R2=150

magick "$TMPDIR/mon.png" -fill none \
  -stroke "$LINE" -strokewidth 1 \
    -draw "circle $CX,$CY $((CX+R1)),$CY" \
    -draw "circle $CX,$CY $((CX+R2)),$CY" \
    -draw "line $((CX-340)),$((CY+215)) $((CX-200)),$((CY+215))" \
    -draw "line $((CX+200)),$((CY+215)) $((CX+340)),$((CY+215))" \
  -stroke "$DIM" -draw "$BRACKETS" \
  -stroke "$FG" -strokewidth 3 \
    -draw "arc $((CX-R2)),$((CY-R2)) $((CX+R2)),$((CY+R2)) 200 290" \
    -draw "arc $((CX-R2)),$((CY-R2)) $((CX+R2)),$((CY+R2)) 20 110" \
  -stroke none -gravity center \
  -font "$FONT" -fill "$FG" -pointsize 64 -annotate +0+0 $'\U000f033e' \
  -kerning 6 -pointsize 26 -annotate +0+215 "$DAY" \
  -font "$THIN" -kerning 3 -fill "$DIM" -pointsize 16 \
    -annotate +0+262 "$(whoami)@$(hostname -s)  ·  type your password" \
  -gravity southwest -kerning 4 -pointsize 13 -annotate +$((M+12))+$((M+12)) "● LOCKED" \
  -gravity southeast -annotate +$((M+12))+$((M+12)) "$(uname -r | cut -d- -f1)" \
  "$TMPDIR/mon.png"

magick -size "${RW}x${RH}" xc:black "$TMPDIR/mon.png" -geometry "+$X+$Y" \
  -composite "$TMPDIR/lock.png"

[[ ${LOCK_PREVIEW:-} ]] && { cp "$TMPDIR/lock.png" "$LOCK_PREVIEW"; exit; }
i3lock -n -i "$TMPDIR/lock.png" -c 000000
