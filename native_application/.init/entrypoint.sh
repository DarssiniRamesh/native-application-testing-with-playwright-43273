#!/bin/sh
# PUBLIC_INTERFACE
# Purpose: Root-only entrypoint for the native_application container.
# - Never calls sudo and never references any non-root user.
# - Resets environment to avoid vendor wrappers and external profiles.
# Parameters: Any command to exec; if none provided, runs validation or opens a shell.
# Returns: Executes provided command or validation; exits with command's status.

set -eu
cd /app

# Unset potential sudo envs
unset SUDO_USER 2>/dev/null || true
unset SUDO_COMMAND 2>/dev/null || true
unset SUDO_UID 2>/dev/null || true
unset SUDO_GID 2>/dev/null || true

# Clean PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Root-only runtime
export HOME="/root"

# Cache dirs
: "${PLAYWRIGHT_BROWSERS_PATH:=/app/.local-browsers}"
mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}" /app/artifacts || true

echo "[start-log] Entrypoint: uid=$(id -u) user=$(id -un) home=${HOME} shell=/bin/sh Marker=NO-SUDO-NO-PWUSER"

if [ "$#" -gt 0 ]; then
  exec "$@"
else
  if [ -x "/app/.init/validation.sh" ]; then
    exec /app/.init/validation.sh
  else
    echo "Container ready. Common commands:"
    echo "  npm start   # serve static files on :8080"
    echo "  npm test    # run Playwright tests"
    exec /bin/sh
  fi
fi
