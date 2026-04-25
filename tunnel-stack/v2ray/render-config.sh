#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${V2RAY_ENV_FILE:-/etc/tunnel-stack/v2ray.env}"
OUT_FILE="${V2RAY_CONFIG_FILE:-/etc/v2ray/config.json}"

[[ -f "$ENV_FILE" ]] || { echo "Missing $ENV_FILE" >&2; exit 1; }
# shellcheck disable=SC1090
source "$ENV_FILE"

: "${V2RAY_CLIENT_UUID:?V2RAY_CLIENT_UUID required}"
: "${REALITY_PRIVATE_KEY:?REALITY_PRIVATE_KEY required}"
: "${REALITY_SHORT_ID:?REALITY_SHORT_ID required}"

V2RAY_LISTEN_PORT="${V2RAY_LISTEN_PORT:-10808}"
REALITY_DEST="${REALITY_DEST:-www.cloudflare.com:443}"
REALITY_SERVER_NAME="${REALITY_SERVER_NAME:-www.cloudflare.com}"
OUTBOUND_MODE="${OUTBOUND_MODE:-tun_direct}"

make_direct_outbound() {
  cat <<JSON
    {
      "tag": "proxy",
      "protocol": "freedom"
    }
JSON
}

make_upstream_outbound() {
  : "${UPSTREAM_ADDRESS:?UPSTREAM_ADDRESS required when OUTBOUND_MODE=upstream_vless_ws}"
  : "${UPSTREAM_PORT:?UPSTREAM_PORT required when OUTBOUND_MODE=upstream_vless_ws}"
  : "${UPSTREAM_UUID:?UPSTREAM_UUID required when OUTBOUND_MODE=upstream_vless_ws}"

  local security="${UPSTREAM_SECURITY:-tls}"
  local network="${UPSTREAM_NETWORK:-ws}"
  local ws_path="${UPSTREAM_WS_PATH:-/}"
  local host_header="${UPSTREAM_HOST_HEADER:-${UPSTREAM_SERVER_NAME:-$UPSTREAM_ADDRESS}}"
  local server_name="${UPSTREAM_SERVER_NAME:-$UPSTREAM_ADDRESS}"
  local fingerprint="${UPSTREAM_FP:-chrome}"

  cat <<JSON
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "${UPSTREAM_ADDRESS}",
            "port": ${UPSTREAM_PORT},
            "users": [
              {
                "id": "${UPSTREAM_UUID}",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "${network}",
        "security": "${security}",
        "tlsSettings": {
          "serverName": "${server_name}",
          "fingerprint": "${fingerprint}"
        },
        "wsSettings": {
          "path": "${ws_path}",
          "headers": {
            "Host": "${host_header}"
          }
        }
      }
    }
JSON
}

case "$OUTBOUND_MODE" in
  tun_direct)
    outbound_json="$(make_direct_outbound)"
    ;;
  upstream_vless_ws)
    outbound_json="$(make_upstream_outbound)"
    ;;
  *)
    echo "Unsupported OUTBOUND_MODE=$OUTBOUND_MODE (supported: tun_direct, upstream_vless_ws)" >&2
    exit 1
    ;;
esac

install -d -m 0755 "$(dirname "$OUT_FILE")"
cat > "$OUT_FILE" <<JSON
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": ${V2RAY_LISTEN_PORT},
      "listen": "0.0.0.0",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${V2RAY_CLIENT_UUID}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "${REALITY_DEST}",
          "xver": 0,
          "serverNames": ["${REALITY_SERVER_NAME}"],
          "privateKey": "${REALITY_PRIVATE_KEY}",
          "shortIds": ["${REALITY_SHORT_ID}"]
        }
      }
    }
  ],
  "outbounds": [
${outbound_json}
  ]
}
JSON
