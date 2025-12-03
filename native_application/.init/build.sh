#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WS"
# install deps idempotently as pwuser
if [ -f package-lock.json ]; then
  sudo -u pwuser bash -lc "cd '$WS' && npm ci --no-audit --progress=false"
else
  sudo -u pwuser bash -lc "cd '$WS' && npm i --no-audit --progress=false"
fi
