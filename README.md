# ETFA

ETFA is a Cloudflare Worker project that provides an edge proxy gateway with an admin panel and subscription endpoints.

## What this repo contains

- `_worker.js` – main Worker logic.
- `wrangler.toml` – Cloudflare deployment configuration.
- `img.png` – screenshot asset.

## Quick start

1. Install Wrangler and log in:

   ```bash
   npm i -g wrangler
   wrangler login
   ```

2. Configure your admin password as an environment variable:

   ```bash
   wrangler secret put ADMIN
   ```

3. (Optional) Create and bind a KV namespace:

   ```bash
   wrangler kv namespace create KV
   ```

   Then add the KV binding in `wrangler.toml`.

4. Run locally:

   ```bash
   wrangler dev
   ```

5. Deploy:

   ```bash
   wrangler deploy
   ```

## Required variables

- `ADMIN` (required): password for `/admin` login.

## Optional variables

- `KEY`: custom token path key.
- `UUID`: fixed UUIDv4.
- `PROXYIP`: upstream proxy IP/host.
- `GO2SOCKS5`: domain list that must use SOCKS5.
- `DEBUG`: enable debug logs (`1` or `true`).
- `OFF_LOG`: disable request logging (`1` or `true`).
- `BEST_SUB`: enable best-subscription mode (`1` or `true`).

## Notes

- This project is intended for lawful testing and research in your jurisdiction.
- Review your local regulations before deployment and usage.

## License

MIT (see `LICENSE`).
