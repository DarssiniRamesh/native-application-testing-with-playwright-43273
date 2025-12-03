#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WS"
# ensure XDG runtime dir exists and is owned by pwuser
XDG_DIR="/tmp/xdg-runtime-pwuser"
mkdir -p "$XDG_DIR"
chown pwuser:pwuser "$XDG_DIR" || true
# Ensure PLAYWRIGHT_BROWSERS_PATH default
PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$WS/.cache/playwright-browsers}"
mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
chown -R pwuser:pwuser "$PLAYWRIGHT_BROWSERS_PATH" || true
# run tests as pwuser, preserve PATH to local node_modules
set +e
sudo -u pwuser bash -lc "cd '$WS' && PATH='$WS/node_modules/.bin:$HOME/.npm-global/bin:$PATH' PLAYWRIGHT_BROWSERS_PATH='$PLAYWRIGHT_BROWSERS_PATH' XDG_RUNTIME_DIR='$XDG_DIR' npx --yes playwright test --reporter=list"
RC=$?
set -e
echo "$RC" > /tmp/playwright.test.rc
if [ "$RC" -eq 0 ]; then
  echo "TESTS: SUCCESS"
else
  echo "TESTS: FAILURE rc=$RC" >&2
fi
exit $RC
