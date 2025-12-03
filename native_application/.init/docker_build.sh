#!/usr/bin/env bash
set -euo pipefail
# Build the Docker image for native_application with safe defaults
WORKSPACE="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WORKSPACE"

IMAGE_NAME="native-application-playwright:latest"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or not available in PATH." >&2
  exit 2
fi

# Build with no cache control by default; allow passing extra args
BUILD_ARGS=()
if [[ -n "${DOCKER_BUILD_EXTRA_ARGS-}" ]]; then
  # shellcheck disable=SC2206
  BUILD_ARGS+=(${DOCKER_BUILD_EXTRA_ARGS})
fi

echo "Building Docker image: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" "${BUILD_ARGS[@]}" .
echo "Built image: ${IMAGE_NAME}"
