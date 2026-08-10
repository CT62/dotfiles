#!/usr/bin/env bash
# Launches Chrome with native dark mode when the rice is on a dark theme
# (bw), and without it on invert (light). Only takes effect at launch —
# an already-running Chrome needs to be restarted to pick up a change.
THEME=$(cat ~/.config/rice/theme 2>/dev/null || echo bw)

if [ "$THEME" = "invert" ]; then
  exec /usr/bin/google-chrome-stable --password-store=basic "$@"
else
  exec /usr/bin/google-chrome-stable --password-store=basic \
    --force-dark-mode --enable-features=WebUIDarkMode "$@"
fi
