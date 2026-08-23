#!/usr/bin/env bash
# rofi script-mode bluetooth picker: lists known devices with a
# connected/disconnected marker, plus power and scan actions up top.
# Selecting a device toggles it (connect if idle, disconnect if live);
# selecting an unpaired freshly-scanned device pairs+trusts+connects it.
set -uo pipefail

power_line() {
  if bluetoothctl show | grep -q "Powered: yes"; then
    echo "⏻ Power off Bluetooth"
  else
    echo "⏻ Power on Bluetooth"
  fi
}

if [ -z "${ROFI_RETV:-}" ] || [ "$ROFI_RETV" = "0" ]; then
  printf '\0prompt\x1fbluetooth\n'
  power_line
  echo "⟳ Scan for devices (10s)"

  if bluetoothctl show | grep -q "Powered: yes"; then
    while IFS= read -r line; do
      mac=$(echo "$line" | awk '{print $2}')
      name=$(echo "$line" | cut -d' ' -f3-)
      [ -z "$mac" ] && continue
      if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
        echo "● $name"
      else
        echo "○ $name"
      fi
    done < <(bluetoothctl devices)
  fi
  exit 0
fi

SELECTED="${1:-}"

case "$SELECTED" in
  "⏻ Power off Bluetooth")
    bluetoothctl power off >/dev/null
    ;;
  "⏻ Power on Bluetooth")
    bluetoothctl power on >/dev/null
    ;;
  "⟳ Scan for devices"*)
    notify-send -a "rice" "Bluetooth" "Scanning for 10s..." 2>/dev/null || true
    bluetoothctl --timeout 10 scan on >/dev/null 2>&1
    notify-send -a "rice" "Bluetooth" "Scan done, reopen the menu to see new devices" 2>/dev/null || true
    ;;
  "● "*|"○ "*)
    name="${SELECTED:2}"
    mac=$(bluetoothctl devices | awk -v n="$name" '{line=$0; sub(/^[^ ]+ [^ ]+ /, "", line); if (line == n) {print $2; exit}}')
    if [ -n "$mac" ]; then
      if [[ "$SELECTED" == "● "* ]]; then
        bluetoothctl disconnect "$mac" >/dev/null
        notify-send -a "rice" "Bluetooth" "Disconnected from $name" 2>/dev/null || true
      else
        bluetoothctl pair "$mac" >/dev/null 2>&1
        bluetoothctl trust "$mac" >/dev/null 2>&1
        if bluetoothctl connect "$mac" >/dev/null 2>&1; then
          notify-send -a "rice" "Bluetooth" "Connected to $name" 2>/dev/null || true
        else
          notify-send -a "rice" "Bluetooth" "Failed to connect to $name" 2>/dev/null || true
        fi
      fi
    fi
    ;;
esac
