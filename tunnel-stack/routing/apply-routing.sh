#!/usr/bin/env bash
set -euo pipefail
source /opt/tunnel-stack/routing/common.sh
require_root

trap 'insert_rule_first filter OUTPUT -m owner --uid-owner "$(v2ray_uid)" -j DROP' ERR

ensure_rt_table
ensure_ip_rule

if ip link show "$VPN_IFACE" >/dev/null 2>&1; then
  ip route replace default dev "$VPN_IFACE" table "$RT_TABLE_NAME"
else
  ip route replace unreachable default table "$RT_TABLE_NAME"
fi

uid="$(v2ray_uid)"

ensure_chain mangle TS_V2RAY_MARK
ensure_rule mangle OUTPUT -m owner --uid-owner "$uid" -j TS_V2RAY_MARK
ensure_rule mangle TS_V2RAY_MARK -j MARK --set-mark "$MARK_DEC"

ensure_chain filter TS_V2RAY_KILL
ensure_rule filter OUTPUT -m owner --uid-owner "$uid" -j TS_V2RAY_KILL
ensure_rule filter TS_V2RAY_KILL -o lo -j ACCEPT
ensure_rule filter TS_V2RAY_KILL -o "$VPN_IFACE" -j ACCEPT
ensure_rule filter TS_V2RAY_KILL -j DROP

# DNS leak prevention: block DNS egress outside VPN for all users (except loopback).
ensure_chain filter TS_DNS_GUARD
ensure_rule filter OUTPUT -p udp --dport 53 -j TS_DNS_GUARD
ensure_rule filter OUTPUT -p tcp --dport 53 -j TS_DNS_GUARD
ensure_rule filter TS_DNS_GUARD -o lo -j ACCEPT
ensure_rule filter TS_DNS_GUARD -o "$VPN_IFACE" -j ACCEPT
ensure_rule filter TS_DNS_GUARD -j DROP

exit 0
