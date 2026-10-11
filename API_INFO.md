# API_INFO — God's Eye View provider & API transfer sheet

Everything a new setup needs to reproduce this configuration. **There are no
secret values in this file and none were ever issued for this deployment** —
every provider slot below is currently EMPTY. Keys are obtained by the
operator from each provider and written into the target machine's `.env`
only (never into git, never into chat logs).

## 1. Provider keys (`.env` on the target machine, `chmod 600`)

| Env var | Provider | Unlocks | Cost | Status in this deployment |
|---|---|---|---|---|
| `CESIUM_ION_TOKEN` | Cesium ion (cesium.com/ion) | Photoreal-style 3D + Bing aerial stacks, world terrain | Free tier (personal/non-commercial terms) | Slot open — awaiting operator key |
| `FIRMS_MAP_KEY` | NASA FIRMS (firms.modaps.eosdis.nasa.gov) | Live wildfire layer | Free | Slot open |
| `AISSTREAM_API_KEY` | AISStream (aisstream.io) | Live ship/vessel tracking | Free | Slot open |
| `OPENSKY_CLIENT_ID` + `OPENSKY_CLIENT_SECRET` | OpenSky Network (opensky-network.org) | Removes anonymous rate limits on live flights | Free account | Slot open (keyless anonymous flights work without it) |
| `TOMTOM_API_KEY` | TomTom (developer.tomtom.com) | Real traffic flow instead of built-in simulation | Free tier | Slot open |
| `MAPILLARY_CLIENT_TOKEN` | Mapillary (mapillary.com/dashboard/developers) | Street-level imagery layer | Free | Slot open |
| `LAUNCH_LIBRARY_2` (in-app provider) | The Space Devs | Launch/mission data | Public access works keyless | Keyless |

### Excluded by operator policy — do NOT configure on the new setup

| Env var | Why excluded |
|---|---|
| `GOOGLE_MAPS_API_KEY`, `GOOGLE_MAPS_SERVER_API_KEY` | Operator directive 2026-10-11: replaced by free equivalents — Esri World Imagery (keyless default), OSM fallback, keyless terrain, Photon/Nominatim search. Also avoids a billing-enabled Google Cloud account. |
| `OPENAI_API_KEY` | Operator directive 2026-10-11: no OpenAI. The controlling Hermes agent is the AI layer via the MCP server (section 3). The in-app voice button stays off. |

### Works with zero keys (no transfer needed)

Esri World Imagery basemap, keyless terrain, OSM, OpenSky anonymous flights,
USGS earthquakes, Launch Library 2 public missions, built-in traffic
simulation, CCTV public feeds, weather (GFS/ECMWF + radar), ALPR camera
locations from OSM.

## 2. App server API surface (local)

- Base: `http://localhost:4173` (Vite dev server; `npm run preview` for the
  production build). Bind localhost by default.
- The server brokers provider keys through local proxy routes — **never
  expose it publicly**. For remote viewing use Tailscale Serve (section 4)
  or LAN with `HOST` set deliberately.
- Host allowlist: default `localhost, 127.0.0.1`. Extra hostnames (e.g. a
  `*.ts.net` name) must be added via `GEV_ALLOWED_HOSTS` in `.env`, then the
  server restarted.
- In-app key management: the POWER UP panel (bottom-right of the UI, or
  `?setup=1`) writes the checkout's `.env` itself when the operator pastes
  keys there — that is the operator's alternative to editing `.env`.

## 3. MCP API (how Hermes talks to GEV)

- Server: `server/mcp/stdio.js` in the upstream checkout, stdio JSON-RPC.
- Launch: `node /abs/path/gods-eye-view/server/mcp/stdio.js --api-base http://localhost:4173`
- Requires: the app server running (dev or preview) AND `npm run build:panel`
  done once (rebuild after app changes).
- Verified handshake: protocol `2025-11-25`, server `gods-eye-view 0.2.1`,
  **30 tools**:

  `get_earthquakes`, `get_active_fires`, `get_recent_launches`,
  `aircraft_in_area`, `find_aircraft`, `get_aircraft_track`,
  `get_aircraft_info`, `vessels_in_area`, `find_vessel`, `get_vessel_track`,
  `next_satellite_pass`, `satellites_overhead`, `find_cctv_cameras`,
  `get_cctv_snapshot`, `find_alpr_cameras`, `get_traffic_flow`,
  `get_weather_map`, `get_recent_imagery`, `find_submarine_cables`,
  `find_infrastructure`, `get_bhote_koshi_flood`, `get_cyclones`,
  `get_fire_perimeters`, `get_terrain_height`,
  `find_military_installations`, `get_map_features`, `situation_brief`,
  `military_awareness`, `show_in_gods_eye_view`, `panel_request`

- Tool results include a `view` object with a share URL
  (`http://localhost:4173/#v=2&lat=…&lon=…&alt=…&l=…`) that frames the globe
  for what was asked — Hermes can hand that view to the operator or render
  it in-panel.
- Smoke test after any new install (must return real data, not an error):
  `tools/call get_earthquakes {"min_magnitude": 4.5, "limit": 3}`.

## 4. Tailscale (operator's remote-viewing path)

- Operator tailnet created 2026-10-11 under `techsquaredllc42071@gmail.com`;
  operator phone node: `moto-g-power-xt2515v` (100.119.59.117).
- On a target host with normal network egress: install Tailscale
  (`curl -fsSL https://tailscale.com/install.sh | sh`), `tailscale up`
  (operator approves the machine into the tailnet), then
  `tailscale serve --bg 4173` and add the resulting `*.ts.net` hostname to
  `GEV_ALLOWED_HOSTS`. The operator then opens `https://<host>.ts.net` on
  any tailnet device — tiles/feeds load over that device's own connection.
- Known dead end: the Muse sandbox VM cannot join a tailnet — its egress
  proxy rejects the control-plane registration (HTTP 400 on
  `/machine/register`). Do not burn attempts retrying from that VM.

## 5. Transfer checklist for a new setup

1. Clone this repo; read `HERMES_INSTALL.md` end to end.
2. Run `install.sh` (clones upstream GEV, installs deps, builds panel,
   scaffolds `.env` from `env.template`).
3. Operator supplies any free-provider keys → write into `.env` only,
   `chmod 600`, restart server, re-run `npm run doctor` and confirm each
   provider flips to configured.
4. Do NOT add Google or OpenAI keys (policy, section 1).
5. Wire the MCP into the controlling Hermes agent (section 3) and run the
   smoke test.
6. Optional: Tailscale serve for operator phone viewing (section 4).
