#!/usr/bin/env bash
# Stays empty unless the mic is actually muted.
if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q yes; then
  echo "✕ MIC"
fi
