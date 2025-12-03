#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
cd "$WORKSPACE"
mkdir -p "$WORKSPACE"/tests "$WORKSPACE"/artifacts
# Create package.json only if absent; include 'playwright' to ensure CLI and browser tooling
if [ ! -f package.json ]; then
  cat > package.json <<'JSON'
{
  "name": "native-application-playwright",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "prepare": "npx playwright install chromium",
    "test": "./node_modules/.bin/playwright test --workers=1 --timeout=30000",
    "start": "node app.js"
  },
  "devDependencies": {
    "@playwright/test": "^1.30.0",
    "playwright": "^1.30.0"
  }
}
JSON
fi
# Minimal HTTP app for health-check (overwrite to ensure content)
cat > app.js <<'NODE'
const http = require('http');
const s = http.createServer((req,res)=>res.end('ok'));
s.listen(3000,()=>console.log('app:3000'))
NODE
# Simple Playwright test exercising the request fixture (overwrite to ensure content)
cat > tests/basic.spec.js <<'TEST'
const { test, expect } = require('@playwright/test');
test('basic http responds', async ({ request }) => {
  const r = await request.get('http://127.0.0.1:3000/');
  expect(r.status()).toBe(200);
  expect(await r.text()).toBe('ok');
});
TEST
# Generate package-lock deterministically if missing
if [ ! -f package-lock.json ]; then
  npm i --package-lock-only --no-audit --no-fund >"$WORKSPACE/artifacts/lockfile_gen.log" 2>&1 || true
fi
