# Vendored copy of God's Eye View

This directory is a full vendored copy of the upstream project, included so a
Hermes-controlled system can be stood up from this repo alone.

- **Upstream:** https://github.com/bilawalsidhu/gods-eye-view
- **Version:** 0.2.1
- **Upstream commit:** `591f299` (Merge PR #986, checked out 2026-10-11)
- **License:** MIT, Copyright (c) 2026 Bilawal Sidhu — see `LICENSE` in this
  directory. The upstream license and notices are preserved verbatim.

## What is NOT in this copy (deliberately)

- `node_modules/` — reproducible with `npm ci` (locked by `package-lock.json`).
- `dist/` — build output, reproducible with `npm run build` / `build:panel`.
- `.env` — never committed, by operator policy. The approved configuration
  lives in `../env.template`; copy it to `.env` here and `chmod 600`.

## "Our changes" = configuration, not code

The upstream code is byte-identical to the reference commit. The deployment
customization is entirely in this repo's root files:

- `../HERMES_INSTALL.md` — agent-executable install/operations instructions
- `../API_INFO.md` — provider/API transfer sheet (no Google Maps, no OpenAI;
  Hermes is the AI layer via `server/mcp/stdio.js`)
- `../env.template` — the approved `.env` shape (free providers only)
- `../install.sh` — uses this vendored copy when present instead of cloning

To refresh the vendored copy later: re-clone upstream, replace this
directory's contents (keeping this file's commit line updated), and push.
