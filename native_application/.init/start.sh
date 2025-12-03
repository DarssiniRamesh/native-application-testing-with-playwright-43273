#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WORKSPACE"
ART="$WORKSPACE/artifacts"
mkdir -p "$ART"
APP_LOG="$ART/native_app.validation.$(date +%s).log"
# start the app in background and write PID file
node app.js >"$APP_LOG" 2>&1 &
echo $! > "$ART/native_app.pid"
# give caller the log path and pid
echo "$APP_LOG"
