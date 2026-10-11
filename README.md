# gods-eye-view-hermes

Deploy **[God's Eye View](https://github.com/bilawalsidhu/gods-eye-view)** (GEV) —
the open-source, browser-based "spy satellite" globe with live aircraft, ships,
satellites, earthquakes, fires, weather and public cameras — onto a system
controlled by a **Hermes agent**, with Hermes itself as the AI layer.

This repo is not the app. It is the deployment package:

| File | Purpose |
|---|---|
| `HERMES_INSTALL.md` | **The instructions.** Written for a Hermes agent to execute step by step: install, configure, verify, wire the MCP, operate. |
| `API_INFO.md` | **The transfer sheet.** Every provider key (name, purpose, cost, status), the local API surface, the full MCP tool list, the Tailscale setup, and the new-setup transfer checklist. No secret values exist or are stored. |
| `install.sh` | Idempotent helper that performs the mechanical steps (clone/update, deps, panel build, `.env` scaffold, doctor). |
| `env.template` | The approved `.env` shape — free providers only, per operator policy below. |
| `.gitignore` | Keeps `.env` and the upstream checkout out of git. |

## Operator policy baked into these instructions (Aaron, 2026-10-11)

1. **No Google Maps.** GEV runs on its free equivalents: Esri World Imagery
   (keyless default basemap), keyless terrain, OSM fallback, Photon/Nominatim
   search. Do not add `GOOGLE_MAPS_API_KEY` / `GOOGLE_MAPS_SERVER_API_KEY`.
2. **No OpenAI.** The in-app voice agent stays off. The controlling Hermes
   agent is the AI layer, through GEV's bundled MCP server (30 tools:
   flights, vessels, satellites, CCTV, fires, weather, situation briefs,
   `show_in_gods_eye_view` to drive the globe).
3. **Keys are never invented, bought, or scraped.** Optional free-provider
   keys (Cesium ion, NASA FIRMS, AISStream, OpenSky OAuth, TomTom, Mapillary)
   are added only when the operator supplies them through a secure channel.
   `.env` is owner-only (`chmod 600`) and never committed.
4. **No public exposure.** The dev server brokers provider keys through local
   proxy routes. Bind localhost; remote viewing goes over the operator's
   Tailscale tailnet (`tailscale serve`) or LAN only, with the hostname added
   to `GEV_ALLOWED_HOSTS`.

## Verified reference install

Performed 2026-10-11 on Ubuntu (Node 24.20.0, npm 10.9.4), upstream GEV
v0.2.1, commit `591f299`:

- `npm ci` clean (173 packages), `npm run doctor` all-OK in keyless mode
- `npm run build` and `npm run build:panel` pass
- Dev server serves on `http://localhost:4173`; first-run panel works
- MCP stdio server: handshake OK, 30 tools listed, live `get_earthquakes`
  call returned real USGS data plus a globe view URL

Known environment caveat (from that install): inside the Muse sandbox VM,
the egress proxy blocks Tailscale control-plane registration, Cloudflare
quick tunnels, and direct browser tile fetches. Install GEV on hosts with
normal egress (operator hardware, e.g. the RV command-center brain) for the
full experience; the MCP data path still works in restricted environments.
