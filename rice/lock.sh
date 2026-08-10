#!/usr/bin/env bash
# Blurred/desaturated screenshot lock screen (no i3lock-color needed).
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

SHOT="$TMPDIR/lock.png"
maim "$SHOT"
convert "$SHOT" -colorspace Gray -blur 0x8 -modulate 35 "$SHOT"

i3lock -n -i "$SHOT"
