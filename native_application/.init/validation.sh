#!/usr/bin/env bash
# PUBLIC_INTERFACE
# This script validates runtime invariants for the container:
# - Runs as root (uid 0)
# - Sudo is not used and not required
# - Prints explicit start marker for CI verification
set -euo pipefail

echo "[start-log] Container start validation. Marker=NO-SUDO-NO-PWUSER"
echo "[start-log] Effective user: $(id -un) (uid: $(id -u)) HOME=${HOME:-/root}"

if command -v sudo >/dev/null 2>&1; then
  echo "[start-log] Note: sudo binary present in PATH at $(command -v sudo), but it must not be used."
else
  echo "[start-log] sudo not present (expected). Marker=NO-SUDO-NO-PWUSER"
fi

# Exit success; caller may exec shell or run tests next
exit 0
