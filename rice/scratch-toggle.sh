#!/usr/bin/env bash
# Show/hide the scratchpad dropdown terminal, spawning it on first use
# or after it's been closed.
set -euo pipefail

RESULT=$(i3-msg '[instance="scratch_term"] scratchpad show' 2>/dev/null || true)
if [[ "$RESULT" != *'"success":true'* ]]; then
  kitty --class scratch_term &
fi
