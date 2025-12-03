#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WS"
# start http-server as pwuser in a new session, capture logs
sudo -u pwuser bash -lc "cd '$WS' && mkdir -p /tmp && setsid npm run start > /tmp/http-server.log 2>&1 &"
# small delay to let process appear
sleep 1
# robustly find PID for http-server -p 8080 owned by pwuser
SERVER_PID="$(pgrep -u pwuser -f "http-server -p 8080" | head -n1 || true)"
if [ -z "${SERVER_PID:-}" ]; then
  echo "ERROR: failed to find http-server process" >&2
  tail -n 200 /tmp/http-server.log || true
  exit 30
fi
if ! echo "$SERVER_PID" | grep -E '^[0-9]+$' >/dev/null; then
  echo "ERROR: invalid server pid: $SERVER_PID" >&2
  exit 31
fi
OWNER="$(ps -o user= -p "$SERVER_PID" | tr -d ' ')"
if [ "$OWNER" != "pwuser" ]; then
  echo "ERROR: server pid $SERVER_PID not owned by pwuser (owner=$OWNER)" >&2
  exit 32
fi
# export PID for callers
echo "$SERVER_PID" > /tmp/http-server.pid
echo "STARTED: pid=$SERVER_PID"
