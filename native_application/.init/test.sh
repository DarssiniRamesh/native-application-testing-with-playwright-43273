#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WS"

# Source env to ensure PATH and vars are consistent
if [[ -f ".init/native_playwright_env.sh" ]]; then
  # shellcheck disable=SC1091
  source ".init/native_playwright_env.sh"
fi

# ensure XDG runtime dir exists
XDG_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-runtime-root}"
mkdir -p "$XDG_DIR"

# Ensure PLAYWRIGHT_BROWSERS_PATH default
PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$WS/.cache/playwright-browsers}"
mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"

# run tests as root, preserve PATH to local node_modules
set +e
PATH="$WS/node_modules/.bin:$HOME/.npm-global/bin:$PATH" PLAYWRIGHT_BROWSERS_PATH="$PLAYWRIGHT_BROWSERS_PATH" XDG_RUNTIME_DIR="$XDG_DIR" npx --yes playwright test --reporter=list
RC=$?
set -e

echo "$RC" > /tmp/playwright.test.rc
if [ "$RC" -eq 0 ]; then
  echo "TESTS: SUCCESS"
else
  echo "TESTS: FAILURE rc=$RC" >&2
fi
exit $RC
