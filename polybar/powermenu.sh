#!/usr/bin/env bash

options=" Lock\n Suspend\n Reboot\n Shutdown"

chosen=$(echo -e "$options" | rofi -dmenu -p "power" -theme ~/.config/rofi/current.rasi -no-custom)

case "$chosen" in
  *Lock)     loginctl lock-session ;;
  *Suspend)  systemctl suspend ;;
  *Reboot)   systemctl reboot ;;
  *Shutdown) systemctl poweroff ;;
esac
