#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WS"
# install deps idempotently as root
if [ -f package-lock.json ]; then
  npm ci --no-audit --progress=false
else
  npm i --no-audit --progress=false
fi
