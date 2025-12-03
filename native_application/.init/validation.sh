#!/usr/bin/env bash
# PUBLIC_INTERFACE
# This script validates that node dependencies and Playwright are installed.
# It runs inside the container at runtime by default CMD.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "[validation] Node version: $(node -v)"
echo "[validation] NPM version: $(npm -v)"

if [[ -f package-lock.json ]]; then
  echo "[validation] Installing dependencies via npm ci"
  npm ci --no-audit --no-fund
elif [[ -f package.json ]]; then
  echo "[validation] Installing dependencies via npm install"
  npm install --no-audit --no-fund
else
  echo "[validation] ERROR: package.json not found in /app"
  exit 1
fi

echo "[validation] Ensuring Playwright Chromium is installed"
npx --yes playwright install chromium --with-deps || npx --yes playwright install chromium

echo "[validation] Success. You can now run: npm test"
exit 0
