# HERMES_INSTALL — Install God's Eye View on a Hermes-controlled system

**Audience: a Hermes agent executing this install end to end.** Follow the
steps in order; each has a verification. Where a step needs the operator
(a credential, an account approval), stop and ask — never substitute your
own credentials, never create accounts, never buy anything.

Upstream project: https://github.com/bilawalsidhu/gods-eye-view
Reference deployment: v0.2.1, commit `591f299`, verified 2026-10-11.
Companion files in this repo: `install.sh` (mechanical steps), `API_INFO.md`
(every provider key, the MCP tool list, the transfer checklist).

---

## 0. Ground rules (operator policy — do not deviate)

1. **No Google Maps keys.** The app runs on free equivalents: Esri World
   Imagery keyless basemap, keyless terrain, OSM fallback, Photon/Nominatim
   search. Never add `GOOGLE_MAPS_API_KEY` or `GOOGLE_MAPS_SERVER_API_KEY`.
2. **No OpenAI key.** The in-app voice stays off. **You** (the controlling
   Hermes agent) are the AI layer, via the bundled MCP server (step 6).
3. **No invented or self-procured keys.** Optional free-provider keys
   (Cesium ion, FIRMS, AISStream, OpenSky, TomTom, Mapillary) are written
   only when the operator supplies them through a secure channel. Full list
   and status: `API_INFO.md` §1.
4. **No public exposure.** The app brokers keys through local proxy routes.
   Bind localhost. Remote access only via the operator's Tailscale tailnet
   or a deliberate LAN bind the operator approved (step 7).
5. `.env` is `chmod 600`, never committed, never echoed into logs or chat.

## 1. Prerequisites

- Node.js **24.x (≥ 24.14)** or **26.x** (Node 25 is EOL — the setup doctor
  warns). Verify: `node --version`.
- npm, git, ~1 GB free disk (checkout ≈ 200 MB, `node_modules` ≈ 400 MB,
  plus a Puppeteer Chromium in `~/.cache` if you run the visual check).
- Normal network egress. (Restricted-egress sandboxes can still run the
  app and the MCP data path, but tiles/tailnet-join may fail — see §8.)

## 2. Get the code

```bash
git clone https://github.com/bilawalsidhu/gods-eye-view.git
cd gods-eye-view
```

Or run `./install.sh` from this repo, which does steps 2–5 mechanically.

## 3. Install dependencies

```bash
npm ci
```

Verify: exits 0 (reference: "added 173 packages"). A deprecated-package
warning for `sourcemap-codec` is expected and harmless.

## 4. Configure `.env`

Copy `env.template` from this repo to `gods-eye-view/.env`, then
`chmod 600 .env`. The template's slots are all **empty** — that is the
correct initial state; the app runs keyless. When the operator later
supplies a free-provider key, write it into the matching line, restart the
server (step 5), and re-run the doctor (step 5) to confirm it registered.
Never add the excluded Google/OpenAI variables (rule 0.1–0.2).

## 5. Doctor, build, run

```bash
npm run doctor        # expect: [OK] Node, [OK] npm, [OK] dependencies,
                      # Map: Esri World Imagery (keyless) — then "Ready."
npm run build         # production bundle must complete
npm run build:panel   # required once for the MCP panel; rerun after app changes
npm run dev           # serves http://localhost:4173 (keep running)
```

Verify: `curl -s -o /dev/null -w "%{http_code}" http://localhost:4173` → `200`.

## 6. Wire the MCP (you are the AI layer)

The MCP server lets you query every feed and drive the operator's globe.

- Command: `node <abs path>/gods-eye-view/server/mcp/stdio.js --api-base http://localhost:4173`
- It reads from the running app of step 5. If the app is down, tools fail —
  check the app first when a call errors.
- Register it with your MCP client config using the **absolute** path
  (clients don't load your shell profile). Per-client snippets are in the
  upstream `docs/MCP_SETUP.md`.
- Full tool list (30) and semantics: `API_INFO.md` §3.

**Smoke test (required):** JSON-RPC `initialize` → expect server
`gods-eye-view`, protocol `2025-11-25`; `tools/list` → 30 tools; then
`tools/call get_earthquakes {"min_magnitude": 4.5, "limit": 3}` → must
return real USGS rows and a `view` URL. If the data call errors, the
install is not verified — diagnose before reporting success.

## 7. Operator phone viewing via Tailscale (optional, operator-gated)

Only on a host with normal egress, and only after the operator has a
Tailscale account and approves the machine:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up            # operator approves this machine in their tailnet
tailscale serve --bg 4173
```

Then add the machine's `*.ts.net` hostname to `GEV_ALLOWED_HOSTS` in
`.env` and restart the app. The operator opens `https://<host>.ts.net` on
their phone (Tailscale app signed in). Details and the operator's existing
tailnet: `API_INFO.md` §4.

## 8. Known failure modes (from the reference install)

- **Tiles don't load in a local headless/sandbox browser, app otherwise
  fine:** the sandbox's egress proxy blocks the tile hosts. Verify through
  the MCP smoke test instead; on operator hardware the tiles load.
- **Tailscale registration returns HTTP 400** (`/machine/register`):
  the host's egress proxy is mangling the control-plane handshake. This
  is an environment wall, not a config error — stop retrying (you'll hit
  rate limits) and report it.
- **Cloudflare quick tunnels / localhost in a remote browser:** also
  blocked in sandbox environments. Don't present them as options.
- **Puppeteer `networkidle2` hangs** during screenshot checks: the app
  holds long-lived connections. Wait on `domcontentloaded` + fixed delays.

## 9. Operations

- Restart app: stop the `vite` process bound to port 4173, rerun
  `npm run dev`. After `.env` changes, a restart is mandatory.
- Update: `git pull` in the checkout, `npm ci`, `npm run build:panel`,
  restart. Re-run the doctor + MCP smoke test after every update.
- Health checks an operator may ask for: doctor output (provider states),
  `curl` 200 on port 4173, one MCP data call.
- Report to the operator: what is running, which providers are configured
  (names only — never key values), the smoke-test result, and any
  environment limitation hit. Do not claim a layer works if you only saw
  it in a list; a data call is the proof.
