#!/usr/bin/env bash
set -euo pipefail
source /opt/tunnel-stack/routing/common.sh

strict="${1:-}"
uid="$(v2ray_uid)"

ip rule show | grep -q "fwmark 0x1 lookup ${RT_TABLE_NAME}" || { echo "Missing fwmark rule" >&2; exit 1; }
ip route show table "$RT_TABLE_NAME" | grep -Eq 'default|unreachable default' || { echo "Missing ${RT_TABLE_NAME} default route" >&2; exit 1; }
iptables -t mangle -C OUTPUT -m owner --uid-owner "$uid" -j TS_V2RAY_MARK >/dev/null
iptables -t mangle -C TS_V2RAY_MARK -j MARK --set-mark "$MARK_DEC" >/dev/null
iptables -t filter -C OUTPUT -m owner --uid-owner "$uid" -j TS_V2RAY_KILL >/dev/null
iptables -t filter -C TS_V2RAY_KILL -o "$VPN_IFACE" -j ACCEPT >/dev/null
iptables -t filter -C TS_V2RAY_KILL -j DROP >/dev/null

if [[ "$strict" == "--strict" ]]; then
  ip link show "$VPN_IFACE" >/dev/null 2>&1 || { echo "VPN interface ${VPN_IFACE} down" >&2; exit 1; }
fi

echo "routing-ok"
