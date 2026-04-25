#!/usr/bin/env bash
set -euo pipefail

STACK_ROOT="/opt/tunnel-stack"
SRC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/tunnel-stack"

install -d -m 0755 "$STACK_ROOT"
cp -a "$SRC_ROOT"/. "$STACK_ROOT"/

install -d -m 0750 /etc/tunnel-stack/secret
install -d -m 0755 /etc/v2ray
install -d -m 0755 /var/log/v2ray

if ! id -u v2ray >/dev/null 2>&1; then
  useradd --system --home /nonexistent --shell /usr/sbin/nologin v2ray
fi

install -m 0600 "$STACK_ROOT/vpn/openconnect.env.example" /etc/tunnel-stack/openconnect.env
install -m 0640 "$STACK_ROOT/v2ray/config.json.example" /etc/v2ray/config.json
chown -R v2ray:v2ray /var/log/v2ray
chown v2ray:v2ray /etc/v2ray/config.json

install -m 0644 "$STACK_ROOT/system/openconnect.service" /etc/systemd/system/openconnect.service
install -m 0644 "$STACK_ROOT/system/tunnel-routing.service" /etc/systemd/system/tunnel-routing.service
install -m 0644 "$STACK_ROOT/system/v2ray.service" /etc/systemd/system/v2ray.service
install -m 0644 "$STACK_ROOT/system/tunnel-watchdog.service" /etc/systemd/system/tunnel-watchdog.service
install -m 0644 "$STACK_ROOT/system/sysctl-apply.service" /etc/systemd/system/sysctl-apply.service
install -m 0644 "$STACK_ROOT/system/99-tunnel-stack.conf" /etc/sysctl.d/99-tunnel-stack.conf
install -m 0755 "$STACK_ROOT/cli/tunnelctl" /usr/local/bin/tunnelctl

chmod 0755 "$STACK_ROOT"/vpn/*.sh "$STACK_ROOT"/routing/*.sh "$STACK_ROOT/system/watchdog.sh"

systemctl daemon-reload

echo "Bootstrap complete. Edit /etc/tunnel-stack/openconnect.env and /etc/v2ray/config.json, then run: tunnelctl start"
