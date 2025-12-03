#!/usr/bin/env bash
# PUBLIC_INTERFACE
# Minimal optional environment script for the native_application container.
# This file is intentionally light and MUST NOT use sudo.
# Add any environment exports needed by local builds here.

# Example environment toggles for Playwright:
export PLAYWRIGHT_HEADLESS="${PLAYWRIGHT_HEADLESS:-1}"
