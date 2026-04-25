# ETFA (Edge Tunnel Flow Assistant)

A user-friendly toolkit for running an **edge gateway on Cloudflare Workers** and (optionally) a **Linux tunnel stack** for VPN + routing + V2Ray.

This README is written as an A-to-Z guide so you can go from zero to running quickly.

---

## Table of Contents

1. [What ETFA includes](#what-etfa-includes)
2. [Who this is for](#who-this-is-for)
3. [Architecture at a glance](#architecture-at-a-glance)
4. [Repository layout](#repository-layout)
5. [Prerequisites](#prerequisites)
6. [Quick start (Cloudflare Worker)](#quick-start-cloudflare-worker)
7. [Worker configuration](#worker-configuration)
8. [Cloudflare KV setup (recommended)](#cloudflare-kv-setup-recommended)
9. [Run locally](#run-locally)
10. [Deploy to Cloudflare](#deploy-to-cloudflare)
11. [Common endpoints](#common-endpoints)
12. [Tunnel stack (optional, Linux)](#tunnel-stack-optional-linux)
13. [Troubleshooting](#troubleshooting)
14. [Security checklist](#security-checklist)
15. [Upgrade and maintenance](#upgrade-and-maintenance)
16. [FAQ](#faq)
17. [License](#license)

---

## What ETFA includes

ETFA has **two parts** in one repo:

1. **Cloudflare Worker app**
   - Main runtime in `_worker.js`.
   - Deploy config in `wrangler.toml`.
   - Supports password-protected admin/login flow and subscription-style endpoints.

2. **Optional Linux tunnel stack** (`tunnel-stack/`)
   - OpenConnect service wrapper.
   - Routing scripts and watchdog.
   - V2Ray service template.
   - `tunnelctl` command helper.

> You can use only the Worker part if you don’t need the Linux tunnel stack.

---

## Who this is for

- You want a Worker-based edge gateway with admin/auth features.
- You may also want a host-level tunnel/routing setup on Linux.
- You prefer a practical setup with copy/paste commands.

---

## Architecture at a glance

- **Cloudflare Edge** handles incoming HTTP(S)/WebSocket requests via `_worker.js`.
- **Environment variables / secrets** control authentication and behavior.
- **KV (optional but recommended)** stores runtime/admin config and logs.
- **Linux tunnel stack (optional)** runs OpenConnect + routing + V2Ray on a server.

---

## Repository layout

```text
.
├── _worker.js                         # Main Cloudflare Worker logic
├── wrangler.toml                      # Wrangler deploy/dev config
├── bootstrap/install.sh               # Installer for Linux tunnel stack
├── tunnel-stack/
│   ├── cli/tunnelctl                  # Start/stop/status/diag helper
│   ├── routing/*.sh                   # Policy routing + kill-switch scripts
│   ├── system/*.service               # systemd units
│   ├── vpn/openconnect.env.example    # OpenConnect env template
│   └── v2ray/config.json.example      # V2Ray baseline config template
├── LICENSE
└── README.md
```

---

## Prerequisites

### For Worker deployment

- A Cloudflare account.
- Node.js + npm (recent LTS recommended).
- Wrangler CLI.

Install Wrangler globally:

```bash
npm i -g wrangler
```

Login:

```bash
wrangler login
```

### For optional tunnel stack

- Linux host with `systemd`.
- Root/sudo access.
- Installed binaries expected by your services (for example OpenConnect, V2Ray, networking tools).

---

## Quick start (Cloudflare Worker)

From repo root:

1. Set the admin password secret (required):

   ```bash
   wrangler secret put ADMIN
   ```

2. (Optional) create KV namespace and bind it (see next sections).

3. Run local dev:

   ```bash
   wrangler dev
   ```

4. Deploy:

   ```bash
   wrangler deploy
   ```

---

## Worker configuration

The Worker reads many environment variables. Most important first:

### Required

- `ADMIN` (or equivalent password variable)
  Password for login/admin protection.

### Common optional variables

- `KEY`
  Custom path key support.

- `UUID`
  Fixed UUIDv4. If omitted, UUID can be derived internally.

- `PROXYIP`
  Upstream proxy IP/host list.

- `GO2SOCKS5`
  Domain list forced over SOCKS5 path.

- `DEBUG`
  Enable debug logs with `1` or `true`.

- `OFF_LOG`
  Disable logging with `1` or `true`.

- `BEST_SUB`
  Toggle best-subscription behavior with `1` or `true`.

> Tip: use Wrangler secrets for sensitive values.

---

## Cloudflare KV setup (recommended)

`wrangler.toml` already includes a commented KV binding block:

```toml
#[[kv_namespaces]]
#binding = "KV"            # default KV binding name (do not change)
#id = ""                # KV namespace id
```

### Steps

1. Create KV namespace:

   ```bash
   wrangler kv namespace create KV
   ```

2. Copy the returned namespace `id`.
3. Uncomment and fill the KV block in `wrangler.toml`.
4. Re-deploy.

Without KV, some admin/config storage features won’t be available.

---

## Run locally

```bash
wrangler dev
```

Then open the local URL shown by Wrangler.

Recommended local checks:

- `GET /login`
- `GET /admin` (should redirect to login until authenticated)
- Any route you expect to use in your workflow

---

## Deploy to Cloudflare

```bash
wrangler deploy
```

After deploy:

1. Open your Worker URL.
2. Verify login/admin flow.
3. Validate critical endpoints.
4. Confirm secrets and KV binding are present in the deployed environment.

---

## Common endpoints

Exact behavior depends on your env/KV state, but typical paths include:

- `/login` – authentication page/flow.
- `/admin` – authenticated admin panel.
- `/admin/config.json` – config read/write in admin flow.
- `/admin/log.json` – logs from KV (if enabled).
- `/sub` – subscription-related output (token-gated).
- `/version?uuid=<uuid>` – version response under expected conditions.

> If an endpoint is unavailable, check `ADMIN`, `KEY`, cookies/auth state, and KV binding first.

---

## Tunnel stack (optional, Linux)

If you only need Worker features, skip this section.

### Install files to system paths

The bootstrap script installs assets under `/opt/tunnel-stack`, systemd unit files, default env/config templates, and `tunnelctl`.

Run as root:

```bash
bash bootstrap/install.sh
```

What it sets up:

- `/etc/tunnel-stack/openconnect.env` (from template)
- `/etc/v2ray/config.json` (from template)
- systemd units for routing, VPN, V2Ray, watchdog
- `/usr/local/bin/tunnelctl`

### Edit required config

1. `/etc/tunnel-stack/openconnect.env`
2. `/etc/v2ray/config.json`
3. Ensure secret file referenced by `VPN_PASSWORD_FILE` exists and has strict permissions.

### Start services

```bash
tunnelctl start
```

### Operational commands

```bash
tunnelctl status
tunnelctl restart
tunnelctl stop
tunnelctl logs vpn
tunnelctl logs v2ray
tunnelctl diag
```

---

## Troubleshooting

### Worker issues

- **403/redirect loops on admin**
  - Verify `ADMIN` secret exists.
  - Clear browser cookies and re-login.
  - Check path/key assumptions.

- **Missing config/log behavior**
  - Confirm KV namespace is bound as `KV`.

- **Unexpected route behavior**
  - Validate env variables and request headers.
  - Turn on `DEBUG` temporarily.

### Tunnel stack issues

- **Services fail to start**
  - `systemctl status <service>` for details.
  - Ensure OpenConnect/V2Ray binaries are installed.

- **No tunnel traffic**
  - Run `tunnelctl diag`.
  - Check interface name (`VPN_INTERFACE`, default `tun0`).
  - Confirm routing table/rules exist.

- **V2Ray not listening**
  - Verify `/etc/v2ray/config.json` correctness.
  - Check journal logs via `tunnelctl logs v2ray`.

---

## Security checklist

- Use strong admin password.
- Store secrets with Wrangler secrets (not plaintext in repo).
- Enable least privilege for API tokens.
- Protect Linux secrets (mode `0600` where applicable).
- Restrict admin access using additional controls if possible.
- Regularly rotate credentials.

---

## Upgrade and maintenance

- Pull latest code.
- Re-check `wrangler.toml` compatibility date and bindings.
- Re-deploy Worker.
- For Linux stack, review changed service/routing scripts before reinstall/restart.

---

## FAQ

### Do I need KV?
Not strictly for all routes, but it is recommended for admin/config/log features.

### Can I run only the Worker part?
Yes. The tunnel stack is optional.

### Where do I configure OpenConnect credentials?
In `/etc/tunnel-stack/openconnect.env` and the password file path it points to.

### Is this production-ready out of the box?
Treat it as a base. Review security, routing, monitoring, and legal/policy compliance before production use.

---

## License

MIT. See `LICENSE`.

---

## Legal and responsible use

Use this project only in environments and jurisdictions where you are authorized to operate it. You are responsible for compliance with local laws, provider terms, and organizational policy.
