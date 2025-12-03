#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WORKSPACE"
ART="$WORKSPACE/artifacts"
mkdir -p "$ART"
# orchestrate: start app, healthcheck, test, stop, summary
START_SCRIPT=".init/start.sh"
STOP_SCRIPT=".init/stop.sh"
TEST_SCRIPT=".init/test.sh"
# Run start and capture app log path
APP_LOG=$($START_SCRIPT)
# read PID
PIDFILE="$ART/native_app.pid"
if [ -f "$PIDFILE" ]; then APP_PID=$(cat "$PIDFILE"); else echo "no pidfile after start" >&2; exit 11; fi
# health check (up to 30s)
for i in {1..60}; do curl -sSf http://127.0.0.1:3000/ >/dev/null && break || sleep 0.5; done
if ! curl -sSf http://127.0.0.1:3000/ >/dev/null; then
echo "app failed health check" >&2
tail -n 200 "$APP_LOG" >&2
$STOP_SCRIPT || true
exit 10
fi
# export env explicitly for test run
export PLAYWRIGHT_HEADLESS=1
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$WORKSPACE/.local-browsers}"
# run tests
TEST_RC=0
$TEST_SCRIPT || TEST_RC=$?
# stop app
$STOP_SCRIPT || true
# ensure app log path variable populated
APP_LOG_PATH="$APP_LOG"
# write summary
cat >"$ART/summary.txt" <<EOF
artifacts:
- install log: $ART/install.log
- playwright install log: $ART/playwright_install.log
- playwright test log: $ART/playwright_validation.log
- app log: $APP_LOG_PATH
test_exit_code=$TEST_RC
EOF
cat "$ART/summary.txt"
exit "$TEST_RC"
