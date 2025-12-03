#!/usr/bin/env bash
# PUBLIC_INTERFACE
# Start http-server on port 8080 as root (container runs root-only). No sudo or pwuser references.
set -euo pipefail

cd /app
setsid npm run start > /tmp/http-server.log 2>&1 &

sleep 1
SERVER_PID="$(pgrep -f 'http-server -p 8080' | head -n1 || true)"
if [[ -z "${SERVER_PID:-}" ]]; then
  echo "ERROR: failed to find http-server process" >&2
  tail -n 200 /tmp/http-server.log || true
  exit 30
fi
if ! [[ "$SERVER_PID" =~ ^[0-9]+$ ]]; then
  echo "ERROR: invalid server pid: $SERVER_PID" >&2
  exit 31
fi
echo "$SERVER_PID" > /tmp/http-server.pid
echo "STARTED: pid=$SERVER_PID"
