#!/usr/bin/env bash
# rofi script-mode network info panel: shows live stats for the active
# wired connection (this machine has no wifi radio) and lets you switch
# the DNS provider. Type a raw IPv4 address as the search text and hit
# enter to use it as a custom DNS server.
set -uo pipefail

PING_TARGET="1.1.1.1"

active_conn() {
  nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null \
    | grep -v ':loopback:' | head -1
}

iface() { active_conn | cut -d: -f3; }
conn_name() { active_conn | cut -d: -f1; }

dns_label() {
  case "$1" in
    "1.1.1.1"|"1.0.0.1") echo "Cloudflare" ;;
    "8.8.8.8"|"8.8.4.4") echo "Google" ;;
    "") echo "DHCP (router)" ;;
    *) echo "Custom ($1)" ;;
  esac
}

if [ -z "${ROFI_RETV:-}" ] || [ "$ROFI_RETV" = "0" ]; then
  IF="$(iface)"
  CONN="$(conn_name)"

  if [ -z "$IF" ]; then
    printf '\0prompt\x1fnetwork\n'
    printf '\0message\x1fNo active connection.\n'
    exit 0
  fi

  IP=$(nmcli -g IP4.ADDRESS device show "$IF" 2>/dev/null | head -1 | cut -d/ -f1)
  GATEWAY=$(nmcli -g IP4.GATEWAY device show "$IF" 2>/dev/null)
  RESOLVED_DNS=$(nmcli -g IP4.DNS device show "$IF" 2>/dev/null | head -1)

  IGNORE_AUTO=$(nmcli -g ipv4.ignore-auto-dns connection show "$CONN" 2>/dev/null)
  if [ "$IGNORE_AUTO" = "yes" ]; then
    DNS=$(nmcli -g ipv4.dns connection show "$CONN" 2>/dev/null | cut -d, -f1)
  else
    DNS=""
  fi

  PING_OUT=$(ping -c 2 -W 1 "$PING_TARGET" 2>/dev/null)
  LOSS=$(echo "$PING_OUT" | grep -oP '\d+(?=% packet loss)')
  AVG=$(echo "$PING_OUT" | grep -oP 'rtt.*= [\d.]+/\K[\d.]+' )
  [ -z "$LOSS" ] && LOSS="?"
  [ -z "$AVG" ] && AVG="?"

  RX1=$(cat "/sys/class/net/$IF/statistics/rx_bytes" 2>/dev/null || echo 0)
  TX1=$(cat "/sys/class/net/$IF/statistics/tx_bytes" 2>/dev/null || echo 0)
  sleep 0.3
  RX2=$(cat "/sys/class/net/$IF/statistics/rx_bytes" 2>/dev/null || echo 0)
  TX2=$(cat "/sys/class/net/$IF/statistics/tx_bytes" 2>/dev/null || echo 0)
  RXRATE=$(awk -v a="$RX1" -v b="$RX2" 'BEGIN{printf "%.1f", (b-a)/0.3/1024}')
  TXRATE=$(awk -v a="$TX1" -v b="$TX2" 'BEGIN{printf "%.1f", (b-a)/0.3/1024}')

  printf '\0prompt\x1fnetwork\n'
  printf '\0message\x1f%s (wired)  |  IP %s  |  Gateway %s  |  DNS %s  |  Ping %sms  |  Loss %s%%  |  ↓ %s KB/s  |  ↑ %s KB/s\n' \
    "$IF" "${IP:-?}" "${GATEWAY:-?}" "${RESOLVED_DNS:-?}" "$AVG" "$LOSS" "$RXRATE" "$TXRATE"

  for preset in "" "1.1.1.1" "8.8.8.8"; do
    label=$(dns_label "$preset")
    if [ "$preset" = "$DNS" ] || { [ -z "$preset" ] && [ -z "$DNS" ]; }; then
      echo "● DNS: $label"
    else
      echo "○ DNS: $label"
    fi
  done
  if [ -n "$DNS" ] && [ "$DNS" != "1.1.1.1" ] && [ "$DNS" != "8.8.8.8" ]; then
    echo "● DNS: $(dns_label "$DNS")"
  fi

  echo "⧉ Copy IP address"
  exit 0
fi

SELECTED="${1:-}"
CONN="$(conn_name)"

set_dns() {
  local server="$1"
  if [ -z "$server" ]; then
    nmcli connection modify "$CONN" ipv4.ignore-auto-dns no ipv4.dns "" >/dev/null 2>&1
  else
    nmcli connection modify "$CONN" ipv4.ignore-auto-dns yes ipv4.dns "$server" >/dev/null 2>&1
  fi
  nmcli connection up "$CONN" >/dev/null 2>&1
}

case "$SELECTED" in
  *"DNS: DHCP"*)
    set_dns ""
    notify-send -a "rice" "Network" "DNS set to DHCP (router)" 2>/dev/null || true
    ;;
  *"DNS: Cloudflare"*)
    set_dns "1.1.1.1 1.0.0.1"
    notify-send -a "rice" "Network" "DNS set to Cloudflare" 2>/dev/null || true
    ;;
  *"DNS: Google"*)
    set_dns "8.8.8.8 8.8.4.4"
    notify-send -a "rice" "Network" "DNS set to Google" 2>/dev/null || true
    ;;
  "⧉ Copy IP address")
    IF="$(iface)"
    IP=$(nmcli -g IP4.ADDRESS device show "$IF" 2>/dev/null | head -1 | cut -d/ -f1)
    if [ -n "$IP" ]; then
      printf '%s' "$IP" | xsel -b 2>/dev/null
      notify-send -a "rice" "Network" "Copied $IP" 2>/dev/null || true
    fi
    ;;
  *[0-9].*[0-9].*[0-9].*[0-9]*)
    if [[ "$SELECTED" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      set_dns "$SELECTED"
      notify-send -a "rice" "Network" "DNS set to custom ($SELECTED)" 2>/dev/null || true
    fi
    ;;
esac
