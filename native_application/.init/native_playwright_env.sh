#!/usr/bin/env bash
# PUBLIC_INTERFACE
# native_playwright_env.sh
# This script exports environment variables needed by Playwright/Electron-style tests.
# It is safe to source even if variables are already set.

# Ensure cache and browser paths are in a writable location inside container
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/app/.local-browsers}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-runtime-pwuser}"

# Append local node_modules/.bin to PATH so npx/npm scripts resolve
if [[ -d "/app/node_modules/.bin" ]] && [[ ":$PATH:" != *":/app/node_modules/.bin:"* ]]; then
  export PATH="/app/node_modules/.bin:$PATH"
fi
