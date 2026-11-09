#!/usr/bin/env bash
# Types the GitHub token into the focused window ($mod+g).
# The token is read from a file outside this repo at keypress time and piped
# straight into xdotool, so it never lands in the repo, argv or the clipboard.
TOKEN_FILE="${GITHUB_TOKEN_FILE:-$HOME/github_token.txt}"

if [ ! -r "$TOKEN_FILE" ]; then
  notify-send -u critical "GitHub token" "Can't read $TOKEN_FILE"
  exit 1
fi
if ! command -v xdotool >/dev/null; then
  notify-send -u critical "GitHub token" "xdotool isn't installed"
  exit 1
fi

# strip the trailing newline so it doesn't also press Enter
tr -d '\r\n' < "$TOKEN_FILE" | xdotool type --clearmodifiers --delay 0 --file -
