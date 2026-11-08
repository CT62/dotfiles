#!/usr/bin/env bash
# Shared artwork for the lock screen (rice/lock.sh) and the LightDM login
# screen (lightdm/install-greeter.sh), so the two always match.
#
#   lock-art.sh MODE WIDTH HEIGHT OUT.png [THEME]
#
# Deliberately minimal: a plain black canvas with a few lines of text.
# Lock mode: a small padlock in the centre (i3lock's typing ring draws around
# it), the date below and a dim hint. Greeter mode: just the hostname, sitting
# above the GTK login box, which is centred on the screen.
set -euo pipefail

MODE=$1 W=$2 H=$3 OUT=$4
THEME=${5:-$(cat ~/.config/rice/theme 2>/dev/null || echo bw)}

case "$THEME" in
  catppuccin) FG='#cdd6f4'; DIM='#6c7086' ;;
  *)          FG='#FFFFFF'; DIM='#5A5A5A' ;;
esac

REG=Cascadia-Mono-NF-Regular
THIN=Cascadia-Mono-NF-Light

if [[ $MODE == greeter ]]; then
  TITLE=$(hostname -s)
  magick -size "${W}x${H}" xc:black -gravity center \
    -font "$THIN" -kerning 6 -fill "$FG" -pointsize 22 -annotate +0-150 "$TITLE" \
    "$OUT"
else
  GLYPH=$'\U000f033e'                                   # nf-md-lock
  DATE=$(date '+%A %d %B' | tr '[:upper:]' '[:lower:]')
  magick -size "${W}x${H}" xc:black -gravity center \
    -font "$REG" -fill "$FG" -pointsize 34 -annotate +0+0 "$GLYPH" \
    -font "$THIN" -kerning 3 -fill "$FG" -pointsize 18 -annotate +0+150 "$DATE" \
    -fill "$DIM" -pointsize 13 -kerning 1 -annotate +0+180 "type your password" \
    "$OUT"
fi
