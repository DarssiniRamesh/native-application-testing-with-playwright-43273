#!/usr/bin/env bash
set -euo pipefail
# Run the built image and execute validation
WORKSPACE="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WORKSPACE"

IMAGE_NAME="native-application-playwright:latest"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or not available in PATH." >&2
  exit 2
fi

# Ensure artifacts dir exists and is writable on host
mkdir -p "$WORKSPACE/artifacts"

# Run container, mapping workspace to /app for visibility of scripts and collecting artifacts
docker run --rm \
  -e PLAYWRIGHT_HEADLESS=1 \
  -v "$WORKSPACE":/app \
  -w /app \
  -p 3000:3000 \
  "${IMAGE_NAME}"
