#!/usr/bin/env bash
set -euo pipefail

reason="${reason:-}"
TUNDEV="${TUNDEV:-${1:-tun0}}"

log() { logger -t vpnc-minimal "$*"; }

case "$reason" in
  pre-init)
    ip link set "$TUNDEV" up || true
    ;;
  connect)
    ip link set "$TUNDEV" up

    if [[ -n "${INTERNAL_IP4_ADDRESS:-}" ]]; then
      ip -4 addr flush dev "$TUNDEV" || true
      if [[ -n "${INTERNAL_IP4_NETMASK:-}" ]]; then
        ip -4 addr add "${INTERNAL_IP4_ADDRESS}/${INTERNAL_IP4_NETMASK}" dev "$TUNDEV"
      else
        ip -4 addr add "${INTERNAL_IP4_ADDRESS}/32" dev "$TUNDEV"
      fi
    fi

    if [[ -n "${INTERNAL_IP4_MTU:-}" ]]; then
      ip link set dev "$TUNDEV" mtu "$INTERNAL_IP4_MTU" || true
    fi

    # Intentionally DO NOT modify routes or resolv.conf.
    log "Configured ${TUNDEV} without changing host routes/DNS"
    ;;
  disconnect)
    ip -4 addr flush dev "$TUNDEV" || true
    ip link set "$TUNDEV" down || true
    ;;
esac

exit 0
