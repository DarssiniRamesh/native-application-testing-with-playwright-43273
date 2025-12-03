#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
ART="$WORKSPACE/artifacts"
PIDFILE="$ART/native_app.pid"

if [[ -f "$PIDFILE" ]]; then
  APP_PID="$(cat "$PIDFILE" || true)"
  if [[ -n "${APP_PID:-}" ]]; then
    kill "$APP_PID" >/dev/null 2>&1 || true
    for i in {1..10}; do
      if ! kill -0 "$APP_PID" >/dev/null 2>&1; then break; fi
      sleep 0.5
    done
    if kill -0 "$APP_PID" >/dev/null 2>&1; then
      kill -9 "$APP_PID" >/dev/null 2>&1 || true
    fi
  fi
  rm -f "$PIDFILE"
fi
