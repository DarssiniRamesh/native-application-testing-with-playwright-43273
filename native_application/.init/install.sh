#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
PLAYWRIGHT_BROWSERS_PATH=${PLAYWRIGHT_BROWSERS_PATH:-"$WS/.cache/playwright-browsers"}

# Install npm dependencies as root (container runs as root)
cd "$WS"
if [ -f "package-lock.json" ]; then
  npm ci --no-audit --progress=false
else
  npm i --no-audit --progress=false
fi

# create cache path
mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"

# install chromium binary via Playwright with retries
RETRIES=3
for i in $(seq 1 $RETRIES); do
  if PLAYWRIGHT_BROWSERS_PATH="$PLAYWRIGHT_BROWSERS_PATH" npx --yes playwright install chromium; then
    break
  fi
  sleep $((i*2))
  if [ "$i" -eq "$RETRIES" ]; then
    echo "playwright browser install failed after $RETRIES attempts" >&2
    exit 20
  fi
done

# verify installation via presence of chromium in browsers path (best-effort)
if ! ls "$PLAYWRIGHT_BROWSERS_PATH" 2>/dev/null | grep -i chromium >/dev/null 2>&1; then
  echo "Chromium browser not found in PLAYWRIGHT_BROWSERS_PATH (non-fatal if using system deps)" >&2
fi

# report playwright version
npx --yes playwright --version || true
