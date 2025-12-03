#!/usr/bin/env node
/**
 * PUBLIC_INTERFACE
 * A CI-friendly install helper:
 * - Uses npm ci when package-lock.json exists.
 * - Falls back to npm install when lock file is missing to avoid ENOENT.
 * - Runs playwright install (with deps) after node modules installation.
 * - Writes detailed logs to artifacts/install.log and prints proxy guidance on failure.
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const projectRoot = process.cwd();
const artifactsDir = path.join(projectRoot, 'artifacts');
const logPath = path.join(artifactsDir, 'install.log');

function ensureArtifactsDir() {
  try { fs.mkdirSync(artifactsDir, { recursive: true }); } catch (e) {}
}
ensureArtifactsDir();

function writeLog(line) {
  try { fs.appendFileSync(logPath, `${new Date().toISOString()} ${line}\n`); } catch (e) {}
}

function run(cmd, args, opts) {
  writeLog(`RUN: ${cmd} ${args.join(' ')}`);
  const res = spawnSync(cmd, args, { stdio: 'pipe', shell: false, ...opts });
  const out = (res.stdout || Buffer.from('')).toString();
  const err = (res.stderr || Buffer.from('')).toString();
  if (out) writeLog(`STDOUT:\n${out}`);
  if (err) writeLog(`STDERR:\n${err}`);
  writeLog(`EXIT: ${res.status}`);
  return res;
}

function printProxyGuidance() {
  const candidates = ['HTTP_PROXY','HTTPS_PROXY','NO_PROXY','http_proxy','https_proxy','no_proxy','NPM_CONFIG_PROXY','NPM_CONFIG_HTTPS_PROXY'];
  const present = candidates.filter(k => process.env[k]);
  writeLog(`ENV PROXY VARS PRESENT: ${present.join(', ') || '(none found)'}`);
  console.error('Note: If you are behind a corporate proxy, set environment variables before running installs:');
  console.error('  export HTTP_PROXY=http://user:pass@proxy:port');
  console.error('  export HTTPS_PROXY=http://user:pass@proxy:port');
  console.error('  npm config set proxy $HTTP_PROXY');
  console.error('  npm config set https-proxy $HTTPS_PROXY');
}

(function main() {
  writeLog('Starting CI install helper');

  const hasLock = fs.existsSync(path.join(projectRoot, 'package-lock.json'));
  const npmArgsCommon = ['--no-audit', '--no-fund'];

  let res;
  if (hasLock) {
    res = run('npm', ['ci', ...npmArgsCommon], { cwd: projectRoot });
    if (res.status !== 0) {
      console.error('npm ci failed. See artifacts/install.log for details.');
      printProxyGuidance();
      process.exit(res.status || 1);
    }
  } else {
    writeLog('package-lock.json not found; using npm install to avoid ENOENT.');
    res = run('npm', ['install', ...npmArgsCommon], { cwd: projectRoot });
    if (res.status !== 0) {
      console.error('npm install failed. See artifacts/install.log for details.');
      printProxyGuidance();
      process.exit(res.status || 1);
    }
  }

  // Ensure Playwright browsers are installed (with deps when possible)
  let pw = run('npx', ['--yes', 'playwright', 'install', '--with-deps'], { cwd: projectRoot });
  if (pw.status !== 0) {
    writeLog('playwright install with deps failed, retrying without --with-deps');
    pw = run('npx', ['--yes', 'playwright', 'install'], { cwd: projectRoot });
    if (pw.status !== 0) {
      console.error('playwright install failed. See artifacts/install.log for details.');
      printProxyGuidance();
      process.exit(pw.status || 1);
    }
  }

  writeLog('CI install helper completed successfully.');
  console.log('Install completed. Logs at artifacts/install.log');
})();
