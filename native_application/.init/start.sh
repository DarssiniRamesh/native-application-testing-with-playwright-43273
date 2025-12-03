#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WS"

# Source local env if present to ensure PATH augmentation
if [[ -f ".init/native_playwright_env.sh" ]]; then
  # shellcheck disable=SC1091
  source ".init/native_playwright_env.sh"
fi

# start http-server as root in a new session, capture logs
if ! grep -q '"start"' package.json 2>/dev/null; then
  echo "ERROR: package.json missing start script" >&2
  exit 25
fi
mkdir -p /tmp
setsid npm run start > /tmp/http-server.log 2>&1 &

# small delay to let process appear
sleep 1

# robustly find PID for http-server -p 8080
SERVER_PID="$(pgrep -f "http-server -p 8080" | head -n1 || true)"
if [ -z "${SERVER_PID:-}" ]; then
  echo "ERROR: failed to find http-server process" >&2
  tail -n 200 /tmp/http-server.log || true
  exit 30
fi
if ! echo "$SERVER_PID" | grep -E '^[0-9]+$' >/dev/null; then
  echo "ERROR: invalid server pid: $SERVER_PID" >&2
  exit 31
fi

# export PID for callers
echo "$SERVER_PID" > /tmp/http-server.pid
echo "STARTED: pid=$SERVER_PID (user=$(id -un))"
