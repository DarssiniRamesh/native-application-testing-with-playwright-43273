#!/usr/bin/env bash
# PUBLIC_INTERFACE
# Simple validation script to confirm environment is sane. Root-only; no sudo or pwuser.
set -euo pipefail

cd /app

# Ensure entrypoint is executable (defense-in-depth when bind-mounting)
if [[ -f "/app/.init/entrypoint.sh" ]]; then
  chmod +x /app/.init/entrypoint.sh || true
fi

echo "[validation] User: $(id -un) (uid: $(id -u))"
echo "[validation] Node: $(node -v), npm: $(npm -v)"
# Try to print Playwright version if installed
node -e "try{console.log('[validation] Playwright version:', require('@playwright/test/package.json').version)}catch(e){console.log('[validation] Playwright not installed')}" || true

# Ensure package.json is present and npm can read it
if [[ ! -f /app/package.json ]]; then
  echo "[validation] ERROR: /app/package.json not found" >&2
  exit 2
fi

# Verify playwright CLI is available (best-effort)
if command -v npx >/dev/null 2>&1; then
  npx --yes playwright --version || true
fi

echo "[validation] OK"
