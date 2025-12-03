#!/usr/bin/env bash
# PUBLIC_INTERFACE
# Minimal optional environment script for the native_application container.
# Root-only runtime; this script MUST NOT use sudo and MUST NOT reference non-root users.
# Add any environment exports needed by local builds here.

# Example environment toggles for Playwright:
export PLAYWRIGHT_HEADLESS="${PLAYWRIGHT_HEADLESS:-1}"
