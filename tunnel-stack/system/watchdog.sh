#!/usr/bin/env bash
set -euo pipefail

VPN_INTERFACE="${VPN_INTERFACE:-tun0}"

while true; do
  if ! ip link show "$VPN_INTERFACE" >/dev/null 2>&1; then
    logger -t tunnel-watchdog "${VPN_INTERFACE} missing; restarting openconnect"
    systemctl restart openconnect.service || true
  fi

  /opt/tunnel-stack/routing/apply-routing.sh || logger -t tunnel-watchdog "routing reapply failed"

  if ! /opt/tunnel-stack/routing/check-routing.sh >/dev/null 2>&1; then
    logger -t tunnel-watchdog "routing check failed; forcing v2ray restart"
    systemctl restart v2ray.service || true
  fi

  sleep 5
done
