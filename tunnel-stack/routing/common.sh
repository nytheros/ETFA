#!/usr/bin/env bash
set -euo pipefail

VPN_IFACE="${VPN_INTERFACE:-tun0}"
RT_TABLE_ID="${RT_TABLE_ID:-200}"
RT_TABLE_NAME="${RT_TABLE_NAME:-vpnroute}"
V2RAY_USER="${V2RAY_USER:-v2ray}"
MARK_HEX="${MARK_HEX:-0x1}"
MARK_DEC=1
RULE_PRIORITY="${RULE_PRIORITY:-100}"

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    echo "Must run as root" >&2
    exit 1
  fi
}

v2ray_uid() {
  id -u "$V2RAY_USER"
}

ensure_rt_table() {
  local line="${RT_TABLE_ID} ${RT_TABLE_NAME}"
  if ! grep -Eq "^${RT_TABLE_ID}[[:space:]]+${RT_TABLE_NAME}$" /etc/iproute2/rt_tables; then
    echo "$line" >> /etc/iproute2/rt_tables
  fi
}

ensure_ip_rule() {
  local uid
  uid="$(v2ray_uid)"
  ip rule add fwmark "$MARK_DEC" lookup "$RT_TABLE_NAME" priority "$RULE_PRIORITY" 2>/dev/null || true
  ip rule add uidrange "${uid}-${uid}" lookup "$RT_TABLE_NAME" priority "$((RULE_PRIORITY+1))" 2>/dev/null || true
}

ensure_chain() {
  local table="$1" chain="$2"
  iptables -t "$table" -N "$chain" 2>/dev/null || true
}

ensure_rule() {
  local table="$1"; shift
  if ! iptables -t "$table" -C "$@" 2>/dev/null; then
    iptables -t "$table" -A "$@"
  fi
}

insert_rule_first() {
  local table="$1"; shift
  if ! iptables -t "$table" -C "$@" 2>/dev/null; then
    iptables -t "$table" -I "$@"
  fi
}
