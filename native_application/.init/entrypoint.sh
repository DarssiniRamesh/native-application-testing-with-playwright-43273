#!/usr/bin/env bash
# PUBLIC_INTERFACE
# Safe entrypoint for native_application. Root-only; never uses sudo or non-root users.
# - Sources optional .init/native_playwright_env.sh
# - Ensures HOME=/root
# - If arguments are provided, exec them
# - Else runs .init/validation.sh if available, or starts an interactive shell
set -euo pipefail

cd /app

# Defense-in-depth: explicitly unset any SUDO_* variables injected by outer systems
unset SUDO_USER SUDO_COMMAND SUDO_UID SUDO_GID || true

# Defense-in-depth: if sudo exists in PATH, alias it to a function that errors out clearly.
if command -v sudo >/dev/null 2>&1; then
  sudo() {
    echo "ERROR: sudo must not be used in this container. The image runs as root-only." >&2
    return 99
  }
  export -f sudo || true
fi

# Optional environment script (never required)
if [[ -f ".init/native_playwright_env.sh" ]]; then
  # shellcheck disable=SC1091
  source ".init/native_playwright_env.sh" || true
fi

# Running as root only; set HOME accordingly
export HOME="/root"

echo "[start-log] Entrypoint: running as uid=$(id -u) user=$(id -un) home=${HOME} Marker=NO-SUDO-NO-PWUSER"

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
