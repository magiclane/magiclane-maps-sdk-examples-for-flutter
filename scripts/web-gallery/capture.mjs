// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.
//
// Capture a screenshot of a URL after a real (wall-clock) render delay, driving
// the system Chrome via the DevTools Protocol. Unlike `chrome --screenshot`
// with --virtual-time-budget, this waits real seconds so the map's async tile /
// POI loads actually finish before the frame is grabbed. No extra downloads.
//
// Usage: node capture.mjs <chromeBin> <url> <outPath> <width> <height> <delayMs>
// Requires Node with a global WebSocket (Node 21+). The build script falls back
// to `chrome --screenshot` when this script fails.

import { spawn } from 'node:child_process';
import { mkdtempSync, rmSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const [, , chromeBin, url, outPath, wStr, hStr, delayStr] = process.argv;
const width = parseInt(wStr, 10) || 1200;
const height = parseInt(hStr, 10) || 1000;
const delayMs = parseInt(delayStr, 10) || 8000;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const profile = mkdtempSync(join(tmpdir(), 'ml-cap-'));

const chrome = spawn(chromeBin, [
  '--headless=new', '--disable-gpu', '--no-sandbox',
  `--user-data-dir=${profile}`, '--disable-web-security', '--enable-unsafe-swiftshader',
  '--hide-scrollbars', '--force-device-scale-factor=1', `--window-size=${width},${height}`,
  '--remote-debugging-port=0', '--remote-allow-origins=*', 'about:blank',
], { stdio: ['ignore', 'ignore', 'ignore'] });

async function readDevToolsPort() {
  const f = join(profile, 'DevToolsActivePort');
  for (let i = 0; i < 150; i++) {
    if (existsSync(f)) {
      const line = readFileSync(f, 'utf8').split('\n')[0].trim();
      if (line) return line;
    }
    await sleep(100);
  }
  throw new Error('Chrome did not expose a DevTools port');
}

let ws;
let failed = false;
try {
  if (typeof WebSocket === 'undefined') throw new Error('global WebSocket unavailable (need Node 21+)');

  const port = await readDevToolsPort();

  // Open a tab already navigated to the target URL, then talk to that page's
  // own DevTools endpoint (no Target/session juggling).
  const created = await (await fetch(`http://127.0.0.1:${port}/json/new?${url}`, { method: 'PUT' })).json();
  if (!created || !created.webSocketDebuggerUrl) {
    throw new Error(`could not open page tab: ${JSON.stringify(created)}`);
  }

  ws = new WebSocket(created.webSocketDebuggerUrl);
  await new Promise((res, rej) => {
    ws.addEventListener('open', res);
    ws.addEventListener('error', () => rej(new Error('DevTools WebSocket error')));
  });

  let msgId = 1;
  const pending = new Map();
  ws.addEventListener('message', (ev) => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  });
  const call = (method, params) => new Promise((res) => {
    const id = msgId++;
    pending.set(id, res);
    ws.send(JSON.stringify({ id, method, params: params || {} }));
  });

  // Give the map real time to fetch tiles / POIs and render before capturing.
  await sleep(delayMs);

  const resp = await call('Page.captureScreenshot',
    { format: 'png', clip: { x: 0, y: 0, width, height, scale: 1 }, captureBeyondViewport: false });
  if (!resp.result || !resp.result.data) {
    throw new Error(`captureScreenshot failed: ${JSON.stringify(resp.error || resp)}`);
  }
  writeFileSync(outPath, Buffer.from(resp.result.data, 'base64'));
} catch (e) {
  failed = true;
  process.stderr.write(`capture.mjs: ${e.message}\n`);
} finally {
  try { ws && ws.close(); } catch { /* ignore */ }
  chrome.kill('SIGTERM');
  await sleep(200);
  try { chrome.kill('SIGKILL'); } catch { /* ignore */ }
  try { rmSync(profile, { recursive: true, force: true }); } catch { /* ignore */ }
}

process.exit(failed ? 1 : 0);
