#!/usr/bin/env bash
# Keep DVI-D-1 primary/landscape (monitor 1) and HDMI-1 portrait,
# positioned to its right (monitor 2).
xrandr --output DVI-D-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
  --output HDMI-1 --mode 1920x1080 --rotate left --pos 1920x0
