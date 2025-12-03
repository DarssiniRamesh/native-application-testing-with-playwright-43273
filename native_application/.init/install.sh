#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WORKSPACE"
ART="$WORKSPACE/artifacts"
mkdir -p "$ART"
LOG="$ART/install.log"
# Ensure PLAYWRIGHT_BROWSERS_PATH persisted and owned
PLAYWRIGHT_BROWSERS_PATH="${WORKSPACE}/.local-browsers"
export PLAYWRIGHT_BROWSERS_PATH
mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
# Ensure ownership for current user (sudo allowed in container)
sudo chown -R "$(id -u):$(id -g)" "$PLAYWRIGHT_BROWSERS_PATH" || true
# Persist env in /etc/profile.d idempotently
sudo sed -i '/PLAYWRIGHT_BROWSERS_PATH/d' /etc/profile.d/native_playwright_env.sh || true
sudo tee -a /etc/profile.d/native_playwright_env.sh > /dev/null <<EOF
export PLAYWRIGHT_BROWSERS_PATH="$PLAYWRIGHT_BROWSERS_PATH"
EOF
sudo chmod 644 /etc/profile.d/native_playwright_env.sh
# Deterministic npm install: prefer npm ci when lockfile exists
if [ -f package-lock.json ]; then
  # If node_modules exists from prior non-lockfile install, remove to avoid conflicts
  if [ -d node_modules ] && [ ! -f .npm_ci_succeeded ]; then rm -rf node_modules || true; fi
  npm ci --no-audit --no-fund >"$LOG" 2>&1 || { echo "npm ci failed, see $LOG. If behind proxy set HTTP_PROXY/HTTPS_PROXY or HTTP_PROXY/HTTPS_PROXY_AUTH. Consider running: npm cache clean --force" >&2; tail -n 200 "$LOG" >&2; exit 5; }
  touch .npm_ci_succeeded || true
else
  npm i --no-audit --no-fund >"$LOG" 2>&1 || { echo "npm install failed, see $LOG" >&2; tail -n 200 "$LOG" >&2; exit 6; }
fi
# Ensure playwright CLI exists locally
if [ ! -x ./node_modules/.bin/playwright ]; then
  echo "playwright CLI missing locally; ensure package.json includes 'playwright' or 'playwright-core' and run npm install" >"$ART/playwright_cli_missing.txt"
  exit 7
fi
# Install Chromium explicitly and capture logs
PLAYWRIGHT_BROWSERS_PATH="$PLAYWRIGHT_BROWSERS_PATH" ./node_modules/.bin/playwright install chromium >"$ART/playwright_install.log" 2>&1 || { echo "playwright install failed, see $ART/playwright_install.log" >&2; tail -n 200 "$ART/playwright_install.log" >&2; exit 8; }
# Validate Chromium via Playwright Node API
node -e "(async()=>{try{const pw=require('playwright');const exe=pw.chromium.executablePath();console.log(exe||'');process.exit(exe?0:11);}catch(e){console.error(e);process.exit(12);}})()" >"$ART/chrome_check.txt" 2>&1 || { echo "Chromium validation failed, see $ART/chrome_check.txt" >&2; tail -n 200 "$ART/chrome_check.txt" >&2; exit 9; }
# Record playwright version
./node_modules/.bin/playwright --version >"$ART/playwright_version.txt" 2>&1 || true
