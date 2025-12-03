#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
PLAYWRIGHT_BROWSERS_PATH=${PLAYWRIGHT_BROWSERS_PATH:-"$WS/.cache/playwright-browsers"}
# prefer npm ci if lockfile present, run as pwuser
if [ -f "$WS/package-lock.json" ]; then
  sudo -u pwuser bash -lc "cd '$WS' && npm ci --no-audit --progress=false"
else
  sudo -u pwuser bash -lc "cd '$WS' && npm i --no-audit --progress=false"
fi
# ensure playwright declared in devDependencies
sudo -u pwuser bash -lc "cd '$WS' && node -e 'const p=require(\"./package.json\"); if(!(p.devDependencies&&p.devDependencies.playwright)||(typeof p.devDependencies.playwright!==\"string\")) { console.error(\"playwright not declared in devDependencies\"); process.exit(2)}'"
# create cache path and ensure ownership
sudo -u pwuser bash -lc "mkdir -p '$PLAYWRIGHT_BROWSERS_PATH'"
sudo chown -R pwuser:pwuser "$PLAYWRIGHT_BROWSERS_PATH"
# install chromium binary via Playwright with retries
RETRIES=3
for i in $(seq 1 $RETRIES); do
  if sudo -u pwuser bash -lc "cd '$WS' && PLAYWRIGHT_BROWSERS_PATH='$PLAYWRIGHT_BROWSERS_PATH' npx --yes playwright install chromium"; then
    break
  fi
  sleep $((i*2))
  if [ "$i" -eq "$RETRIES" ]; then
    echo "playwright browser install failed after $RETRIES attempts" >&2
    exit 20
  fi
done
# verify installation via playwright show-brief or presence of chromium directory
if ! sudo -u pwuser bash -lc "cd '$WS' && PLAYWRIGHT_BROWSERS_PATH='$PLAYWRIGHT_BROWSERS_PATH' npx --yes playwright show-brief | grep -i chromium >/dev/null 2>&1"; then
  if ! sudo -u pwuser bash -lc "ls '$PLAYWRIGHT_BROWSERS_PATH' 2>/dev/null | grep -i chromium >/dev/null 2>&1"; then
    echo "Chromium browser not found in PLAYWRIGHT_BROWSERS_PATH" >&2
    exit 21
  fi
fi
# ensure workspace ownership and report playwright version
sudo chown -R pwuser:pwuser "$WS"
sudo -u pwuser bash -lc "cd '$WS' && npx --yes playwright --version"
