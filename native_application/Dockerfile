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

# Optionally create a non-root user 'pwuser' deterministically; avoid hard runtime requirement.
# Fixed UID/GID for reproducibility; do not fail if already exists.
RUN set -eux; \
    if ! getent group pwuser >/dev/null; then groupadd -g 1001 pwuser || true; fi; \
    if ! id -u pwuser >/dev/null 2>&1; then useradd -m -u 1001 -g 1001 -s /bin/bash pwuser || true; fi

# Create app directory
WORKDIR /app

# Prepare paths for playwright and npm cache; ensure ownership to pwuser
ENV PLAYWRIGHT_BROWSERS_PATH=/app/.local-browsers \
    NPM_CONFIG_CACHE=/home/pwuser/.npm

RUN mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}" /home/pwuser/.npm /home/pwuser/.cache && \
    chown -R pwuser:pwuser /app "${PLAYWRIGHT_BROWSERS_PATH}" /home/pwuser

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
    fi; \
    chown -R pwuser:pwuser /app/node_modules || true

# Ensure playwright is available and install chromium to a writable path
RUN mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}" && \
    npx --yes playwright install chromium --with-deps || npx --yes playwright install chromium; \
    chown -R pwuser:pwuser "${PLAYWRIGHT_BROWSERS_PATH}" || true

# Provide a safe env script location system-wide (optional)
RUN mkdir -p /etc/profile.d && \
    touch /etc/profile.d/native_playwright_env.sh && \
    chmod 0644 /etc/profile.d/native_playwright_env.sh

# Copy source code (support both contexts)
COPY native-application-testing-with-playwright-43273/native_application/ /app/ 2>/dev/null || true
COPY . /app/ 2>/dev/null || true

# Fix ownership for pwuser after sources are copied
RUN chown -R pwuser:pwuser /app || true

# Add a safe entrypoint that never invokes sudo and works for both root and pwuser
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

# If running as root and pwuser exists, ensure /app ownership is relaxed for both users
if [[ "$(id -u)" -eq 0 ]]; then
  if id -u pwuser >/dev/null 2>&1; then
    chown -R pwuser:pwuser /app || true
    export HOME="/home/pwuser"
  else
    export HOME="/root"
  fi
else
  # Non-root: set HOME to current user's home if available
  export HOME="${HOME:-/tmp}"
fi

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

# Default to root at runtime to avoid failures when external tools inject 'sudo' or assume root.
# You can run with a non-root user by adding: docker run --user 1001:1001 ...
USER root

# Ensure working directory remains /app for pwuser
WORKDIR /app

# Expose the tiny app port used by http-server
EXPOSE 8080

# Use safe entrypoint and default to no-op help; never call sudo
ENTRYPOINT ["/app/.init/entrypoint.sh"]
CMD []
