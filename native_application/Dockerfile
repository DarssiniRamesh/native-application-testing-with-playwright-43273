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
RUN set -euo pipefail; \
    if [[ -f package-lock.json ]]; then \
      npm ci --no-audit --no-fund; \
    else \
      npm install --no-audit --no-fund; \
    fi

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

# Add a safe entrypoint that never invokes sudo and runs as root
RUN mkdir -p /app/.init
COPY .init/entrypoint.sh /app/.init/entrypoint.sh 2>/dev/null || true
# If it wasn't present in build context, write a minimal one
RUN if [[ ! -f /app/.init/entrypoint.sh ]]; then \
      cat > /app/.init/entrypoint.sh <<'EOSH'; \
#!/usr/bin/env bash
set -euo pipefail
cd /app

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
echo "Entrypoint: running as uid=$(id -u) user=$(id -un) home=${HOME}"

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
      chmod +x /app/.init/entrypoint.sh; \
    fi

# Ensure working directory remains /app
WORKDIR /app

# Expose the tiny app port used by http-server
EXPOSE 8080

# Use safe entrypoint and default to no-op help; never call sudo
ENTRYPOINT ["/app/.init/entrypoint.sh"]
CMD []
