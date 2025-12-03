#!/bin/sh
# PUBLIC_INTERFACE
# Purpose: Optional validation script run by entrypoint when no command is provided.
# - Confirms Playwright and http-server are installed.
# - Ensures no 'sudo' or 'pwuser' references exist in this repository's .init scripts.
# Returns: exits 0 on success; non-zero on any validation failure.

set -eu

echo "[validation] Starting validation checks (root-only, no-sudo)."

# Check node/npm presence
if ! command -v node >/dev/null 2>&1; then
  echo "[validation] ERROR: node not found in PATH." >&2
  exit 10
fi
if ! command -v npm >/dev/null 2>&1; then
  echo "[validation] ERROR: npm not found in PATH." >&2
  exit 11
fi

# Check Playwright and http-server
if ! node -e "require('@playwright/test');" >/dev/null 2>&1; then
  echo "[validation] ERROR: @playwright/test not installed." >&2
  exit 12
fi
if ! command -v http-server >/dev/null 2>&1; then
  echo "[validation] ERROR: http-server not installed." >&2
  exit 13
fi

# Verify .init scripts are clean
if grep -RInE "sudo|pwuser" /app/.init 2>/dev/null; then
  echo "[validation] ERROR: Found 'sudo' or 'pwuser' in .init scripts." >&2
  exit 14
fi

echo "[validation] All checks passed."
exit 0
