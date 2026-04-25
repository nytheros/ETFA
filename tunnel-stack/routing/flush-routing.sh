#!/usr/bin/env bash
set -euo pipefail
source /opt/tunnel-stack/routing/common.sh
require_root

uid="$(v2ray_uid)"

iptables -t mangle -D OUTPUT -m owner --uid-owner "$uid" -j TS_V2RAY_MARK 2>/dev/null || true
iptables -t mangle -F TS_V2RAY_MARK 2>/dev/null || true
iptables -t mangle -X TS_V2RAY_MARK 2>/dev/null || true

iptables -t filter -D OUTPUT -m owner --uid-owner "$uid" -j TS_V2RAY_KILL 2>/dev/null || true
iptables -t filter -F TS_V2RAY_KILL 2>/dev/null || true
iptables -t filter -X TS_V2RAY_KILL 2>/dev/null || true

iptables -t filter -D OUTPUT -p udp --dport 53 -j TS_DNS_GUARD 2>/dev/null || true
iptables -t filter -D OUTPUT -p tcp --dport 53 -j TS_DNS_GUARD 2>/dev/null || true
iptables -t filter -F TS_DNS_GUARD 2>/dev/null || true
iptables -t filter -X TS_DNS_GUARD 2>/dev/null || true

ip rule del fwmark "$MARK_DEC" lookup "$RT_TABLE_NAME" priority "$RULE_PRIORITY" 2>/dev/null || true
ip rule del uidrange "$uid-$uid" lookup "$RT_TABLE_NAME" priority "$((RULE_PRIORITY+1))" 2>/dev/null || true
ip route flush table "$RT_TABLE_NAME" 2>/dev/null || true
