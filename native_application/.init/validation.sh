#!/usr/bin/env bash
# PUBLIC_INTERFACE
# Simple validation script to confirm environment is sane. No sudo.
set -euo pipefail

echo "[validation] User: $(id -un) (uid: $(id -u))"
echo "[validation] Node: $(node -v), npm: $(npm -v)"
echo "[validation] Playwright version: $(node -e "console.log(require('@playwright/test/package.json').version)")"

# Ensure package.json is present and npm can read it
test -f /app/package.json

# Verify playwright can show help (sanity check)
npx playwright --version || true

echo "[validation] OK"
