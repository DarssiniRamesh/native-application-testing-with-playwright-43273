# syntax=docker/dockerfile:1
# Minimal Node + Playwright environment for native app testing
FROM node:20-bullseye

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    PLAYWRIGHT_HEADLESS=1 \
    NODE_ENV=development

# Install minimal OS libraries needed for Chromium/Electron headless
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libgtk-3-0 libgbm1 libnss3 libx11-6 libxcomposite1 libxrandr2 libxss1 libasound2 curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Run exclusively as root; do not create any extra users
USER root

# Create app directory
WORKDIR /app

# Prepare paths for playwright and npm cache; keep them under /root or /app for root ownership
ENV PLAYWRIGHT_BROWSERS_PATH=/app/.local-browsers \
    NPM_CONFIG_CACHE=/root/.npm

# Ensure necessary directories exist and are writable by root
RUN mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}" /root/.npm /root/.cache

# Use bash for all subsequent RUN lines
SHELL ["/bin/bash", "-c"]

# Copy manifests regardless of build context (repo root or container dir)
COPY native-application-testing-with-playwright-43273/native_application/package.json native-application-testing-with-playwright-43273/native_application/package-lock.json* /tmp/appmanifests/ 2>/dev/null || true
COPY package.json package-lock.json* /tmp/appmanifests/ 2>/dev/null || true

# Move whichever set exists into /app and validate presence
RUN set -euo pipefail; \
    if [[ -f /tmp/appmanifests/package.json ]]; then \
      mv /tmp/appmanifests/package.json /app/; \
      if [[ -f /tmp/appmanifests/package-lock.json ]]; then mv /tmp/appmanifests/package-lock.json /app/; fi; \
    fi; \
    rm -rf /tmp/appmanifests || true; \
    if [[ ! -f /app/package.json ]]; then \
      echo "ERROR: package.json was not found in build context. Build from native_application folder or repository root."; \
      exit 1; \
    fi

# Install dependencies (build stage runs as root; no sudo required)
# Build-time logging: verify effective user and sudo presence to ensure no pwuser/sudo is expected
RUN set -euo pipefail; \
    echo "[build-log] START: effective user check (should be root). Marker=NO-SUDO-NO-PWUSER"; \
    echo "[build-log] Effective user: $(id -un) (uid: $(id -u)) HOME=${HOME:-}"; \
    echo "[build-log] PATH=${PATH}"; \
    if command -v sudo >/dev/null 2>&1; then echo "[build-log] sudo present in base image at $(command -v sudo)"; else echo "[build-log] sudo not present (expected)"; fi; \
    if [[ -f package-lock.json ]]; then \
      npm ci --no-audit --no-fund; \
    else \
      npm install --no-audit --no-fund; \
    fi; \
    echo "[build-log] COMPLETE: dependency install finished. Marker=NO-SUDO-NO-PWUSER"

# Ensure playwright is available and install chromium to a writable path
RUN mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}" && \
    npx --yes playwright install chromium --with-deps || npx --yes playwright install chromium

# Provide a safe env script location system-wide (optional)
RUN mkdir -p /etc/profile.d && \
    touch /etc/profile.d/native_playwright_env.sh && \
    chmod 0644 /etc/profile.d/native_playwright_env.sh

# Copy source code (support both contexts)
COPY native-application-testing-with-playwright-43273/native_application/ /app/ 2>/dev/null || true
COPY . /app/ 2>/dev/null || true
# Ensure validation script is executable if present
RUN if [[ -f /app/.init/validation.sh ]]; then chmod +x /app/.init/validation.sh; fi

# Add a safe entrypoint that never invokes sudo and runs as root
RUN mkdir -p /app/.init
COPY .init/entrypoint.sh /app/.init/entrypoint.sh 2>/dev/null || true
# If it wasn't present in build context, write a minimal one
RUN if [[ ! -f /app/.init/entrypoint.sh ]]; then \
      cat > /app/.init/entrypoint.sh <<'EOSH'; \
#!/usr/bin/env bash
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

# Source optional local env script
if [[ -f ".init/native_playwright_env.sh" ]]; then
  # shellcheck disable=SC1091
  source ".init/native_playwright_env.sh" || true
fi

# Running as root only; set HOME accordingly
export HOME="/root"

# Ensure playwright/browser cache dirs exist and are writable
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/app/.local-browsers}"
mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}" /app/artifacts || true

# Print effective user info (debug aid)
echo "[start-log] Entrypoint: running as uid=$(id -u) user=$(id -un) home=${HOME} Marker=NO-SUDO-NO-PWUSER"

# Default behavior: if a command is provided, exec it; else show help
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
EOSH
    fi
# Ensure entrypoint is executable if present
RUN if [[ -f /app/.init/entrypoint.sh ]]; then chmod +x /app/.init/entrypoint.sh; fi

# Also provide a minimal override entrypoint to short-circuit any external wrapper from base image layers
RUN cat > /app/.init/entrypoint-override.sh <<'EOSH' && chmod +x /app/.init/entrypoint-override.sh
#!/usr/bin/env bash
set -euo pipefail
export HOME="/root"
echo "[start-log] Override Entrypoint: uid=$(id -u) user=$(id -un) (root-only). Marker=NO-SUDO-NO-PWUSER"
exec /app/.init/entrypoint.sh "$@"
EOSH

# Force container to run as root
USER root

# Ensure working directory remains /app
WORKDIR /app

# Expose the tiny app port used by http-server
EXPOSE 8080

# Use override entrypoint that guarantees root-only execution and never calls sudo
ENTRYPOINT ["/app/.init/entrypoint-override.sh"]
# Default to showing validation/help; explicit commands can be provided at docker run
CMD []
