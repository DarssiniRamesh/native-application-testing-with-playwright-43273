#!/usr/bin/env bash
# PUBLIC_INTERFACE
# Stop http-server started by .init/start.sh. Root-only; no sudo or pwuser.
set -euo pipefail

PID_FILE="/tmp/http-server.pid"
if [[ ! -f "$PID_FILE" ]]; then
  echo "NOOP: no pid file ($PID_FILE)"
  exit 0
fi
SERVER_PID="$(cat "$PID_FILE")"
if [[ -z "${SERVER_PID:-}" ]]; then
  echo "NOOP: pid file empty"
  exit 0
fi
if ! [[ "$SERVER_PID" =~ ^[0-9]+$ ]]; then
  echo "WARN: invalid pid in $PID_FILE: $SERVER_PID" >&2
  rm -f "$PID_FILE" || true
  exit 1
fi
if ! ps -p "$SERVER_PID" >/dev/null 2>&1; then
  echo "NOOP: process $SERVER_PID not running"
  rm -f "$PID_FILE" || true
  exit 0
fi
kill "$SERVER_PID" >/dev/null 2>&1 || true
rm -f "$PID_FILE" || true
echo "STOPPED: pid=$SERVER_PID"
