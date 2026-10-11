#!/bin/sh
# Mechanical install steps for God's Eye View on a Hermes-controlled system.
# Policy and verification live in HERMES_INSTALL.md — read it first.
# Idempotent: safe to re-run (updates the checkout, refreshes deps).
set -eu

DIR="${GEV_DIR:-$HOME/gods-eye-view}"
REPO="https://github.com/bilawalsidhu/gods-eye-view.git"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Node gate: need 24.x (>=24.14) or 26.x
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
if [ "$NODE_MAJOR" != "24" ] && [ "$NODE_MAJOR" != "26" ]; then
  echo "ERROR: Node 24.x (>=24.14) or 26.x required; found $(node --version 2>/dev/null || echo none)" >&2
  exit 1
fi

if [ -d "$DIR/.git" ]; then
  echo "Updating existing checkout in $DIR"
  git -C "$DIR" pull --ff-only
else
  git clone "$REPO" "$DIR"
fi

cd "$DIR"
npm ci

# .env scaffold — never overwrite an existing one (it may hold operator keys)
if [ ! -f .env ]; then
  cp "$SCRIPT_DIR/env.template" .env
  chmod 600 .env
  echo "Created .env from env.template (all slots empty — keyless mode)"
else
  echo ".env already exists — left untouched"
fi

npm run build:panel
npm run doctor

echo
echo "Done. Start the app with:  cd \"$DIR\" && npm run dev   (http://localhost:4173)"
echo "Then wire the MCP per HERMES_INSTALL.md step 6 and run the smoke test."
