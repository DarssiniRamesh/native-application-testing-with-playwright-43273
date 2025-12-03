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

# Copy package manifests first for better caching when available
# These files may not exist on initial scaffold; use a safe pattern
COPY package.json package-lock.json* ./

# Install dependencies deterministically when lockfile present, else fallback
# Use bash explicitly and set -o pipefail to avoid syntax errors in RUN
SHELL ["/bin/bash", "-c"]
RUN set -euo pipefail; \
    if [[ -f package-lock.json ]]; then \
      npm ci --no-audit --no-fund; \
    elif [[ -f package.json ]]; then \
      npm install --no-audit --no-fund; \
    else \
      echo "No package.json found at build-time; continuing. You can mount sources at runtime."; \
    fi

# Ensure playwright is available and install chromium to a writable path
ENV PLAYWRIGHT_BROWSERS_PATH=/app/.local-browsers
RUN mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}" && \
    if [[ -f package.json ]]; then \
      npx --yes playwright install chromium --with-deps || npx --yes playwright install chromium; \
    fi

# Copy source code (if present)
COPY . .

# Expose the tiny app port
EXPOSE 3000

# Default command runs the validation script if present; else print help
CMD if [[ -x ".init/validation.sh" ]]; then \
      ./.init/validation.sh; \
    elif [[ -f "app.js" ]]; then \
      node app.js; \
    else \
      echo "No validation.sh or app.js found. Mount sources or run an interactive shell."; \
      bash; \
    fi
