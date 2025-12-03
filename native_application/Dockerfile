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

# Create app directory
WORKDIR /app

# Use bash for all subsequent RUN lines
SHELL ["/bin/bash", "-c"]

# Try to copy manifests whether build context is repository root or the container folder
# 1) If context is repo root, manifests live under native_application/
# 2) If context is native_application, manifests live at ./
# The first COPY that matches will work; missing paths are ignored by Docker only if using wildcard.
# We handle both explicitly with two COPY commands gated by existence checks.
# Copy from subdir if present in build context
COPY native-application-testing-with-playwright-43273/native_application/package.json native-application-testing-with-playwright-43273/native_application/package-lock.json* /tmp/appmanifests/ 2>/dev/null || true
COPY package.json package-lock.json* /tmp/appmanifests/ 2>/dev/null || true

# Move whichever set exists into /app
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

# Install dependencies deterministically when lockfile present, else fallback
RUN set -euo pipefail; \
    if [[ -f package-lock.json ]]; then \
      npm ci --no-audit --no-fund; \
    else \
      npm install --no-audit --no-fund; \
    fi

# Ensure playwright is available and install chromium to a writable path
ENV PLAYWRIGHT_BROWSERS_PATH=/app/.local-browsers
RUN mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}" && \
    npx --yes playwright install chromium --with-deps || npx --yes playwright install chromium

# Provide a safe env script location system-wide (optional) to avoid sed errors in setups that edit /etc/profile.d
RUN mkdir -p /etc/profile.d && \
    touch /etc/profile.d/native_playwright_env.sh && \
    chmod 0644 /etc/profile.d/native_playwright_env.sh

# Copy source code (support both contexts)
# If building from repo root, copy only container folder. If building from container folder, copy current directory.
# Try repo-relative path first, then fallback to .
COPY native-application-testing-with-playwright-43273/native_application/ /app/ 2>/dev/null || true
COPY . /app/ 2>/dev/null || true

# Source local env script at build-time where possible (no-op if missing)
RUN if [[ -f ".init/native_playwright_env.sh" ]]; then echo "Sourcing local env script for verification"; bash -lc "source .init/native_playwright_env.sh >/dev/null 2>&1 || true"; fi

# Expose the tiny app port used by http-server
EXPOSE 8080

# Default command runs the validation script if present; else print help
CMD if [[ -x ".init/validation.sh" ]]; then \
      ./.init/validation.sh; \
    else \
      echo "Container ready. To run tests: npm test"; \
      bash; \
    fi
