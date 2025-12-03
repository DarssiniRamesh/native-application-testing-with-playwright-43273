#!/usr/bin/env bash
# PUBLIC_INTERFACE
# Safe entrypoint that never uses sudo. Runs as root.
set -euo pipefail

cd /app

# Optional environment script
if [[ -f ".init/native_playwright_env.sh" ]]; then
  # shellcheck disable=SC1091
  source ".init/native_playwright_env.sh" || true
fi

# Running as root only; set HOME accordingly
export HOME="/root"

echo "Entrypoint: running as user: $(id -u) (uid) / $(id -un) (name) home=${HOME}"

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
