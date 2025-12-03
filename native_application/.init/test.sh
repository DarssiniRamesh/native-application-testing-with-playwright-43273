#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WORKSPACE"
ART="$WORKSPACE/artifacts"
mkdir -p "$ART"
# ensure headless env for this run
export PLAYWRIGHT_HEADLESS=1
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$WORKSPACE/.local-browsers}"
# run tests with local playwright binary, capture log and return exit code
TEST_LOG="$ART/playwright_validation.log"
./node_modules/.bin/playwright test --workers=1 --timeout=30000 >"$TEST_LOG" 2>&1 || TEST_RC=$?
TEST_RC=${TEST_RC-0}
echo "$TEST_RC"
exit "$TEST_RC"
