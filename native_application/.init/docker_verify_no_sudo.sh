#!/usr/bin/env bash
# PUBLIC_INTERFACE
# Verify build does not invoke sudo/pwuser by building the image and capturing logs.
# This helper is for CI environments with Docker available.
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-native_application}"
CONTEXT_MODE="${CONTEXT_MODE:-auto}" # auto, repo, container

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTAINER_DIR="${ROOT_DIR}/native-application-testing-with-playwright-43273/native_application"

build_from_repo() {
  echo "[verify] Building from repository root..."
  (cd "${ROOT_DIR}" && docker build -f "${CONTAINER_DIR}/Dockerfile" -t "${IMAGE_NAME}" .)
}

build_from_container() {
  echo "[verify] Building from container directory..."
  (cd "${CONTAINER_DIR}" && docker build -t "${IMAGE_NAME}" .)
}

case "${CONTEXT_MODE}" in
  auto)
    set +e
    build_from_repo 2>&1 | tee /tmp/native_app_build_repo.log
    status=$?
    set -e
    if [[ $status -ne 0 ]]; then
      echo "[verify] Repo-root build failed; retrying from container directory..."
      build_from_container 2>&1 | tee /tmp/native_app_build_container.log
    fi
    ;;
  repo) build_from_repo 2>&1 | tee /tmp/native_app_build_repo.log ;;
  container) build_from_container 2>&1 | tee /tmp/native_app_build_container.log ;;
  *) echo "Invalid CONTEXT_MODE: ${CONTEXT_MODE}" >&2; exit 2;;
esac

echo "[verify] Build complete. Checking logs for forbidden patterns..."
if grep -RInE "pwuser|sudo: unknown user|useradd|groupadd|chown .*pwuser" /tmp/native_app_build_*.log; then
  echo "[verify] ERROR: forbidden sudo/pwuser references found in build logs" >&2
  exit 10
else
  echo "[verify] OK: no sudo/pwuser references detected in build logs."
fi

echo "[verify] Running container to print entrypoint effective user..."
docker run --rm "${IMAGE_NAME}" /app/.init/entrypoint-override.sh true
echo "[verify] SUCCESS"
