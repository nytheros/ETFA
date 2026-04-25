#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-/etc/tunnel-stack/openconnect.env}"
[[ -f "$ENV_FILE" ]] || { echo "Missing $ENV_FILE" >&2; exit 1; }
# shellcheck disable=SC1090
source "$ENV_FILE"

: "${VPN_SERVER:?VPN_SERVER required}"
: "${VPN_USER:?VPN_USER required}"
: "${VPN_PASSWORD_FILE:?VPN_PASSWORD_FILE required}"

VPN_INTERFACE="${VPN_INTERFACE:-tun0}"
VPN_PROTOCOL="${VPN_PROTOCOL:-anyconnect}"
VPN_GROUP="${VPN_GROUP:-}"
VPN_EXTRA_ARGS="${VPN_EXTRA_ARGS:-}"

[[ -r "$VPN_PASSWORD_FILE" ]] || { echo "Cannot read VPN_PASSWORD_FILE=$VPN_PASSWORD_FILE" >&2; exit 1; }

args=(
  --background=0
  --protocol="$VPN_PROTOCOL"
  --user="$VPN_USER"
  --interface="$VPN_INTERFACE"
  --passwd-on-stdin
  --script=/opt/tunnel-stack/vpn/vpnc-minimal.sh
)

if [[ -n "$VPN_GROUP" ]]; then
  args+=(--authgroup="$VPN_GROUP")
fi

if [[ -n "$VPN_EXTRA_ARGS" ]]; then
  # shellcheck disable=SC2206
  extra=( $VPN_EXTRA_ARGS )
  args+=("${extra[@]}")
fi

exec openconnect "${args[@]}" "$VPN_SERVER" < "$VPN_PASSWORD_FILE"
