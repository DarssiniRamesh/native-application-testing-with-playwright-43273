#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WS"

# Source safe local env script if present to avoid sed file-not-found in system paths
if [[ -f ".init/native_playwright_env.sh" ]]; then
  # shellcheck disable=SC1091
  source ".init/native_playwright_env.sh"
fi

# build (install deps) - ensure dependencies are present first
if [ -f package-lock.json ] && [ -s package-lock.json ]; then
  sudo -u pwuser bash -lc "cd '$WS' && npm ci --no-audit --progress=false"
elif [ -f package.json ]; then
  sudo -u pwuser bash -lc "cd '$WS' && npm i --no-audit --progress=false"
else
  echo 'No package.json found; initializing minimal project...' >&2
  exit 20
fi

# Guarantee Playwright browser is installed in writable path (best-effort)
sudo -u pwuser bash -lc "cd '$WS' && npx --yes playwright install chromium >/dev/null 2>&1 || true"

# start server
bash .init/start.sh
SERVER_PID="$(cat /tmp/http-server.pid || true)"
if [ -z "$SERVER_PID" ]; then
  echo "VALIDATION: failed to start server" >&2
  exit 30
fi

# readiness check: retry up to 30s
READY=1
for i in $(seq 1 30); do
  if sudo -u pwuser bash -lc "curl -sfS --max-time 2 http://127.0.0.1:8080 >/dev/null"; then
    READY=0 && break
  fi
  sleep 1
done
if [ "$READY" -ne 0 ]; then
  echo "VALIDATION: http-server not ready after timeout" >&2
  tail -n 200 /tmp/http-server.log || true
  bash .init/stop.sh || true
  exit 33
fi

# run tests
bash .init/test.sh
TEST_RC=$?

# stop server
bash .init/stop.sh || true

# evidence
echo "VALIDATION: test exit code=$TEST_RC"
if [ "$TEST_RC" -eq 0 ]; then
  echo "VALIDATION: SUCCESS"
  exit 0
else
  echo "VALIDATION: FAILURE - see /tmp/http-server.log and /tmp/playwright.test.rc and Playwright output" >&2
  tail -n 200 /tmp/http-server.log || true
  exit 40
fi
