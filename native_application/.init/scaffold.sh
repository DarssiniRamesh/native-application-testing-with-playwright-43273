#!/usr/bin/env bash
set -euo pipefail

# workspace from container context
WS="/home/kavia/workspace/code-generation/native-application-testing-with-playwright-43273/native_application"
PLAYWRIGHT_VERSION="^1.41.1"
HTTP_SERVER_VERSION="^14.1.1"

# ensure workspace exists and init package.json if missing
mkdir -p "$WS"
cd "$WS"
[ -f package.json ] || npm init -y

# merge/add devDependencies and scripts using a small node helper to avoid quoting brittleness
PW_V="$PLAYWRIGHT_VERSION" HS_V="$HTTP_SERVER_VERSION" node -e '
const fs=require("fs"), pfile=process.cwd()+"/package.json";
let p=fs.existsSync(pfile)?JSON.parse(fs.readFileSync(pfile)):{};
p.devDependencies=p.devDependencies||{};
if (!p.devDependencies.playwright) p.devDependencies.playwright=process.env.PW_V;
if (!p.devDependencies["http-server"]) p.devDependencies["http-server"]=process.env.HS_V;
p.scripts=p.scripts||{};
if (!p.scripts.start) p.scripts.start="http-server -p 8080";
if (!p.scripts.test) p.scripts.test="playwright test";
fs.writeFileSync(pfile,JSON.stringify(p,null,2));
'

# create tests directory and a basic Playwright test
mkdir -p "$WS/tests"
cat > "$WS/tests/basic.spec.mjs" <<'EOT'
import { test, expect } from '@playwright/test';

test('local server page title', async ({ page }) => {
  await page.goto('http://127.0.0.1:8080');
  const title = await page.title();
  expect(title).toBeDefined();
});
EOT

# create playwright.config.mjs that respects PW_DISABLE_SANDBOX
cat > "$WS/playwright.config.mjs" <<'EOM'
import { defineConfig } from '@playwright/test';
const disableSandbox = !!process.env.PW_DISABLE_SANDBOX;
const args = ['--disable-dev-shm-usage'];
if (disableSandbox) args.push('--no-sandbox','--disable-setuid-sandbox');
export default defineConfig({ use: { browserName: 'chromium', headless: process.env.CI?true:false, launchOptions: { args } } });
EOM

# quick validation: show resulting package.json minimal fields (non-fatal)
if [ -f "$WS/package.json" ]; then
  jq '{name,version,scripts,devDependencies}' "$WS/package.json" 2>/dev/null || true
fi
