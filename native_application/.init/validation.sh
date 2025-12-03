#!/usr/bin/env bash
# PUBLIC_INTERFACE
# /** Validation entrypoint for the native_application container.
#  * Purpose: Ensure the container environment is ready without relying on sudo.
#  * Behavior:
#  *  - Prints basic environment info
#  *  - Verifies current user is 'pwuser'
#  *  - Verifies Playwright CLI is available
#  *  - Starts a simple HTTP server to serve index.html on port 8080
#  * Returns: exits non-zero if prechecks fail; otherwise starts server in foreground.
#  */
set -euo pipefail

echo "[validation] Starting container validation without sudo..."
echo "[validation] whoami: $(whoami)"
echo "[validation] uid:gid = $(id -u):$(id -g)"
echo "[validation] node version: $(node -v || echo 'node not found')"
echo "[validation] npm version: $(npm -v || echo 'npm not found')"

# Ensure we are the expected user; not strictly required, but helps catch misconfigurations.
if [[ "$(whoami)" != "pwuser" ]]; then
  echo "[validation][warn] Expected user 'pwuser' but got '$(whoami)'. Proceeding anyway."
fi

# Ensure Playwright is available (installed during image build)
if ! npx --yes playwright --version >/dev/null 2>&1; then
  echo "[validation][error] Playwright CLI is not available. Please rebuild the image."
  exit 1
fi

# Serve the app directory
echo "[validation] Launching http-server on :8080"
exec npx --yes http-server -p 8080 -c-1 .
