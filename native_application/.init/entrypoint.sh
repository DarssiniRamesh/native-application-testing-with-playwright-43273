#!/usr/bin/env bash
# PUBLIC_INTERFACE
# Safe entrypoint for native_application. Root-only; never uses sudo or non-root users.
# - Sources optional .init/native_playwright_env.sh
# - Ensures HOME=/root
# - If arguments are provided, exec them
# - Else runs .init/validation.sh if available, or starts an interactive shell
set -euo pipefail

cd /app

# Optional environment script (never required)
if [[ -f ".init/native_playwright_env.sh" ]]; then
  # shellcheck disable=SC1091
  source ".init/native_playwright_env.sh" || true
fi

# Running as root only; set HOME accordingly
export HOME="/root"

echo "Entrypoint: running as uid=$(id -u) user=$(id -un) home=${HOME}"

# Ensure this script is executable (defensive when bind-mounted)
chmod +x "/app/.init/entrypoint.sh" || true

# If command given, exec it; else run validation or provide help
if [[ $# -gt 0 ]]; then
  exec "$@"
else
  if [[ -x ".init/validation.sh" ]]; then
    exec ./.init/validation.sh
  else
    echo "Container ready. Common commands:"
    echo "  npm start   # serve static files on :8080"
    echo "  npm test    # run Playwright tests"
    exec bash
  fi
fi
