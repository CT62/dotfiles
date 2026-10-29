#!/usr/bin/env bash
# Power menu ($mod+Shift+p): a single row of big icon buttons, with the
# uptime as the header. Uses the shared rofi theme, reshaped via -theme-str.

# nf-md-lock / power_sleep / logout / restart / power
LOCK=$'\U000f033e' SLEEP=$'\U000f04b2' LOGOUT=$'\U000f0343' REBOOT=$'\U000f0709' OFF=$'\U000f0425'

UP=$(uptime -p | sed 's/^up //')

chosen=$(printf '%s\n' "$LOCK" "$SLEEP" "$LOGOUT" "$REBOOT" "$OFF" | rofi -dmenu -no-custom \
  -p "" -mesg "up $UP" -selected-row 0 \
  -theme ~/.config/rofi/current.rasi \
  -theme-str '
    window { width: 560px; }
    inputbar { enabled: false; }
    message { margin: 16px 16px 0 16px; }
    listview { columns: 5; lines: 1; layout: vertical; flow: horizontal; scrollbar: false; spacing: 10px; padding: 16px; }
    element { padding: 22px 0; border-radius: 14px; children: [ element-text ]; }
    element normal.normal, element alternate.normal { background-color: @bg-alt; }
    element-text { font: "Cascadia Mono NF 24"; horizontal-align: 0.5; }
  ')

case "$chosen" in
  "$LOCK")   loginctl lock-session ;;
  "$SLEEP")  systemctl suspend ;;
  "$LOGOUT") i3-msg exit ;;
  "$REBOOT") systemctl reboot ;;
  "$OFF")    systemctl poweroff ;;
esac
