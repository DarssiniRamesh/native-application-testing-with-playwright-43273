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

# Use POSIX sh for all subsequent RUN lines to avoid inheriting any vendor bash profiles
SHELL ["/bin/sh", "-c"]

# Copy manifests regardless of build context (repo root or container dir)
COPY native-application-testing-with-playwright-43273/native_application/package.json native-application-testing-with-playwright-43273/native_application/package-lock.json* /tmp/appmanifests/ 2>/dev/null || true
COPY package.json package-lock.json* /tmp/appmanifests/ 2>/dev/null || true

# Move whichever set exists into /app and validate presence
RUN set -eu; \
    if [ -f /tmp/appmanifests/package.json ]; then \
      mv /tmp/appmanifests/package.json /app/; \
      if [ -f /tmp/appmanifests/package-lock.json ]; then mv /tmp/appmanifests/package-lock.json /app/; fi; \
    fi; \
    rm -rf /tmp/appmanifests || true; \
    if [ ! -f /app/package.json ]; then \
      echo "ERROR: package.json was not found in build context. Build from native_application folder or repository root."; \
      exit 1; \
    fi

# Diagnostic: search the filesystem for any 'pwuser' or 'sudo' references from base layers; print matches to aid CI logs
# Note: this is a diagnostic only; no sudo will be invoked.
RUN set -eu; \
    echo "[diag] Scanning filesystem for patterns: pwuser|sudo"; \
    (grep -RIl --exclude-dir=/proc --exclude-dir=/sys --exclude-dir=/dev --exclude-dir=/var/lib/apt/lists --exclude-dir=/app node / etc /usr /bin /sbin 2>/dev/null | xargs -r grep -nE "pwuser|sudo" || true) | tee /app/artifacts/diag-grep.txt || true; \
    echo "[diag] Scan complete; results saved to /app/artifacts/diag-grep.txt"

# Install dependencies (build stage runs as root; no sudo required)
# Build-time logging: verify effective user and sudo presence to ensure no pwuser/sudo is expected
RUN set -eu; \
    echo "[build-log] START: effective user check (should be root). Marker=NO-SUDO-NO-PWUSER"; \
    echo "[build-log] Effective user: $(id -un) (uid: $(id -u)) HOME=${HOME:-}"; \
    echo "[build-log] PATH=${PATH}"; \
    if command -v sudo >/dev/null 2>&1; then echo "[build-log] sudo present in base image at $(command -v sudo)"; else echo "[build-log] sudo not present (expected)"; fi; \
    if [ -f package-lock.json ]; then \
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

# Ensure .init scripts exist and are executable; verify none contain sudo/pwuser
RUN set -eu; \
    mkdir -p /app/.init /app/artifacts; \
    if [ -f /app/.init/validation.sh ]; then chmod +x /app/.init/validation.sh; fi; \
    if [ -f /app/.init/native_playwright_env.sh ]; then chmod +x /app/.init/native_playwright_env.sh || true; fi; \
    if grep -RInE "sudo|pwuser" /app/.init 2>/dev/null; then \
      echo "[warn] Found 'sudo' or 'pwuser' in /app/.init scripts. Please remove. Failing build."; \
      exit 2; \
    else \
      echo "[ok] .init scripts contain no sudo/pwuser."; \
    fi

# Add a safe entrypoint that never invokes sudo and runs as root
COPY .init/entrypoint.sh /app/.init/entrypoint.sh 2>/dev/null || true
# If it wasn't present in build context, write a minimal one
RUN if [ ! -f /app/.init/entrypoint.sh ]; then \
      cat > /app/.init/entrypoint.sh <<'EOSH'; \
#!/bin/sh
set -eu
cd /app

# Defense-in-depth: explicitly unset any SUDO_* variables injected by outer systems
unset SUDO_USER 2>/dev/null || true
unset SUDO_COMMAND 2>/dev/null || true
unset SUDO_UID 2>/dev/null || true
unset SUDO_GID 2>/dev/null || true

# Mask potential vendor wrappers: ensure PATH is clean and avoid sourcing any external profiles
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Root-only runtime; set HOME accordingly
export HOME="/root"

# Ensure playwright/browser cache dirs exist and are writable
: "${PLAYWRIGHT_BROWSERS_PATH:=/app/.local-browsers}"
mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}" /app/artifacts || true

# Print effective user info (debug aid)
echo "[start-log] Entrypoint: uid=$(id -u) user=$(id -un) home=${HOME} shell=/bin/sh Marker=NO-SUDO-NO-PWUSER"

# Default behavior: if a command is provided, exec it; else show help or run validation
if [ "$#" -gt 0 ]; then
  exec "$@"
else
  if [ -x "/app/.init/validation.sh" ]; then
    exec /app/.init/validation.sh
  else
    echo "Container ready. Common commands:"
    echo "  npm start   # serve static files on :8080"
    echo "  npm test    # run Playwright tests"
    exec /bin/sh
  fi
fi
EOSH \
    ; fi && chmod +x /app/.init/entrypoint.sh

# Also provide a minimal override entrypoint to short-circuit any external wrapper from base image layers
RUN cat > /app/.init/entrypoint-override.sh <<'EOSH' && chmod +x /app/.init/entrypoint-override.sh
#!/bin/sh
set -eu
export HOME="/root"
# Use a pristine PATH to avoid any inherited vendor shim
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
echo "[start-log] Override Entrypoint: uid=$(id -u) user=$(id -un) (root-only). Marker=NO-SUDO-NO-PWUSER"
exec /app/.init/entrypoint.sh "$@"
EOSH

# Force container to run as root
USER root

# Ensure working directory remains /app
WORKDIR /app

# Expose the tiny app port used by http-server
EXPOSE 8080

# Reset entrypoint/cmd explicitly to our root-only scripts
ENTRYPOINT ["/app/.init/entrypoint-override.sh"]
CMD []
