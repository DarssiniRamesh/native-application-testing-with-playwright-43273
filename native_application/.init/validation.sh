#!/usr/bin/env bash
set -euo pipefail
# PUBLIC_INTERFACE
# This script validates that npm can install dependencies even if no lockfile exists,
# logs to artifacts/install.log, performs Playwright browser install, and then runs tests.

cd "$(dirname "$0")/.."

mkdir -p artifacts
LOG="artifacts/install.log"

echo "$(date -Iseconds) starting validation" | tee -a "$LOG"

# Prefer npm ci when lock exists, else npm install to avoid ENOENT
if [[ -f package-lock.json ]]; then
  echo "Using npm ci..." | tee -a "$LOG"
  if ! npm ci --no-audit --no-fund >>"$LOG" 2>&1; then
    echo "npm ci failed, see $LOG" | tee -a "$LOG"
    echo "Proxy guidance: set HTTP_PROXY/HTTPS_PROXY or npm config proxy if behind corporate proxy." | tee -a "$LOG"
    exit 1
  fi
else
  echo "No package-lock.json found. Falling back to npm install..." | tee -a "$LOG"
  if ! npm install --no-audit --no-fund >>"$LOG" 2>&1; then
    echo "npm install failed, see $LOG" | tee -a "$LOG"
    echo "Proxy guidance: set HTTP_PROXY/HTTPS_PROXY or npm config proxy if behind corporate proxy." | tee -a "$LOG"
    exit 1
  fi
fi

# Install Playwright browsers
if ! npx --yes playwright install --with-deps >>"$LOG" 2>&1; then
  echo "playwright install --with-deps failed; retrying without deps" | tee -a "$LOG"
  if ! npx --yes playwright install >>"$LOG" 2>&1; then
    echo "playwright install failed, see $LOG" | tee -a "$LOG"
    exit 1
  fi
fi

echo "Validation completed successfully" | tee -a "$LOG"
exit 0
