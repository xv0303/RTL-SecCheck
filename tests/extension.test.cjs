const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { EventEmitter } = require('node:events');
const root = path.join(__dirname, '..', 'vscode-extension');
const deferred = () => { let resolve, reject; const promise = new Promise((r, j) => { resolve = r; reject = j; }); return { promise, resolve, reject }; };
const tick = () => new Promise(r => setImmediate(r));

function load(name, mocks = {}, globals = {}) {
  const module = { exports: {} };
  const code = fs.readFileSync(path.join(root, 'out', name + '.js'), 'utf8');
  vm.runInNewContext(code, { module, exports: module.exports, require: n => n in mocks ? mocks[n] : require(n.startsWith('.') ? path.join(root, 'out', n) : n),
    __dirname: path.join(root, 'out'), URL, AbortController, setTimeout, clearTimeout, setInterval, clearInterval,
    console, ...globals }, { filename: name + '.js' });
  return module.exports;
}

class Element {
  constructor(id = '') {
    this.id = id; this.value = ''; this.style = {}; this.dataset = {}; this.listeners = {};
    this.childNodes = []; this.className = ''; this.isConnected = true; this.disabled = false;
    const classes = new Set();
    this.classList = { add: x => classes.add(x), remove: x => classes.delete(x), contains: x => classes.has(x),
      toggle: (x, on = !classes.has(x)) => { on ? classes.add(x) : classes.delete(x); return on; } };
  }
  addEventListener(k, f) { this.listeners[k] = f; }
  appendChild(c) { this.childNodes.push(c); c.isConnected = true; return c; }
  insertBefore(c) { return this.appendChild(c); }
  removeChild(c) { this.childNodes.splice(this.childNodes.indexOf(c), 1); }
  remove() { this.isConnected = false; }
  scrollIntoView() {}
  querySelector(selector) {
    return this.childNodes.find(c => selector === '.fix-panel' ? c.className?.includes('fix-panel') :
      selector.includes('fix-toggle') && c.dataset?.fixToggle === '1') || null;
  }
}

function panel() {
  const elements = new Map(), sent = [];
  const document = { activeElement: null, getElementById(id) { if (!elements.has(id)) elements.set(id, new Element(id)); return elements.get(id); },
    createElement: () => new Element(), createTextNode: text => ({ textContent: text }) };
  const window = { addEventListener() {} };
  const code = fs.readFileSync(path.join(root, 'media', 'panel.js'), 'utf8').replace('  post("ready");',
    'window.hooks = {renderSettings,saveDirIfChanged,renderProgress,renderLog,ensureProgressCard,extractLoc,renderFix,requestFix,findingRows,startScanFromPanel,renderUi};');
  vm.runInNewContext(code, { document, window, acquireVsCodeApi: () => ({ postMessage: m => sent.push(m) }) });
  const h = window.hooks, input = document.getElementById('sRtlDir');
  return { ...h, sent, document, elements, input,
    edit(value, focus = true) { input.value = value; document.activeElement = focus ? input : null; input.listeners.input(); },
    settings(value = 'A') { h.renderSettings({ values: { rtlDir: value }, defaultDir: 'DEFAULT', engine: 'both' }); },
    ack(requestId, value, ok = true) { h.renderSettings({ directoryAck: { requestId, value, ok } }); } };
}

test('directory acknowledgements preserve newer input and drain only the latest edit', () => {
  const p = panel(); p.settings(); p.edit('B'); p.saveDirIfChanged(); p.edit('C', false);
  p.ack(1, 'B'); assert.equal(p.input.value, 'C');
  p.ack(2, 'C'); assert.equal(p.input.value, 'C');
  assert.deepEqual(p.sent.filter(m => m.cmd === 'saveSettings').map(m => m.payload.rtl_dir), ['B', 'C']);
  p.settings('A'); assert.equal(p.input.value, 'A'); // ordinary refresh can update a clean field
});

test('ordinary settings and stale directory acknowledgements cannot overwrite unsaved edits', () => {
  const p = panel(); p.settings(); p.edit('B', false); p.saveDirIfChanged(); p.edit('C', false);
  p.settings('A'); p.ack(0, 'WRONG'); assert.equal(p.input.value, 'C');
  assert.equal(p.sent.length, 1);
});

test('scan waits for the directory snapshot clicked by the user, including a preceding save', () => {
  const p = panel(); p.settings(); p.edit('B'); p.saveDirIfChanged(); p.edit('C', false);
  p.startScanFromPanel(); assert.equal(p.sent.some(m => m.cmd === 'startScan'), false);
  p.ack(1, 'B'); p.edit('D', false); p.ack(2, 'C');
  const scan = p.sent.find(m => m.cmd === 'startScan'); assert.equal(scan.payload.rtlDir, 'C');
  assert.equal(p.input.value, 'D');
});

test('directory save failure aborts a queued scan and preserves input for retry', () => {
  const p = panel(); p.settings(); p.edit('B', false); p.startScanFromPanel(); p.ack(1, 'B', false);
  assert.equal(p.sent.some(m => m.cmd === 'startScan'), false);
  assert.equal(p.elements.get('scanBtn').disabled, false); assert.equal(p.input.value, 'B');
  p.startScanFromPanel(); p.ack(2, 'B'); assert.equal(p.sent.filter(m => m.cmd === 'startScan').length, 1);
});

test('early scan command waits for initial settings instead of clearing the saved directory', () => {
  const p = panel(); p.startScanFromPanel(); p.settings('SAVED');
  assert.equal(p.sent.find(m => m.cmd === 'startScan').payload.rtlDir, 'SAVED');
  assert.equal(p.sent.filter(m => m.cmd === 'saveSettings').length, 0);
});

test('directory failure during an active scan does not enable another scan', () => {
  const p = panel(); p.settings(); p.renderProgress({ phase: 'starting' });
  p.edit('B', false); p.saveDirIfChanged(); p.ack(1, 'B', false);
  assert.equal(p.elements.get('scanBtn').disabled, true);
});

test('progress uses the backend 0..100 scale and is clamped', () => {
  const p = panel(); p.renderProgress({ phase: 'starting' }); p.renderLog({ lines: [], progress: 60 });
  assert.equal(p.ensureProgressCard().fill.style.width, '60%');
  p.renderProgress({ progress: 200 }); assert.equal(p.ensureProgressCard().fill.style.width, '100%');
});

test('Windows evidence paths retain drive letters, spaces and Unicode', () => {
  const p = panel();
  for (const file of ['C:\\RTL\\top.v', 'C:\\my project\\工程\\top.sv', 'rtl/模块/top.v']) {
    const loc = p.extractLoc('Evidence ' + file + ':12 matched'); assert.equal(loc.file, file); assert.equal(loc.line, 12);
  }
  assert.equal(p.extractLoc('"rtl/my project/top.v":4').file, 'rtl/my project/top.v');
});

test('failed fix suggestions can be retried while successful results remain cached', () => {
  const p = panel(), f = { id: 'F-1', location: [] }, btn = new Element();
  p.findingRows.set(f.id, { row: new Element(), detailTr: new Element(), detail: new Element(), btnFix: btn, data: f });
  p.requestFix(f, btn); p.renderFix({ findingId: f.id, failed: true, error: 'offline' }); p.requestFix(f, btn);
  assert.equal(p.sent.filter(m => m.cmd === 'fix').length, 2);
  p.renderFix({ findingId: f.id, finding: { fix_suggestion: 'Success' } }); p.requestFix(f, btn);
  assert.equal(p.sent.filter(m => m.cmd === 'fix').length, 2);
  const pair = p.findingRows.get(f.id), suggestion = pair.detail.querySelector('.fix-panel');
  suggestion.classList.remove('open'); p.requestFix(f, btn);
  assert.equal(suggestion.classList.contains('open'), true);
});

function host() {
  const messages = [], timers = [], cancelled = [];
  const cfg = { engine: 'both', backendUrl: 'http://mock:8321' };
  const backend = { api: { settings: async () => ({ settings: {}, has_api_key: true, neo4j_alive: true }) }, isAlive: async () => true, resolveProjectRoot: () => null };
  const vscode = { workspace: { getConfiguration: () => ({ get: key => cfg[key] }), workspaceFolders: [] }, window: {} };
  const { CslRtlSeccheckPanelProvider: P } = load('panelProvider', { vscode, './backend': backend }, {
    setTimeout: fn => { const token = { fn }; timers.push(token); return token; }, clearTimeout: token => cancelled.push(token) });
  const provider = new P({}, { clear() {}, setFindings() {} }); provider.view = { webview: { postMessage: m => messages.push(m) } }; provider.openDir = 'DEFAULT';
  const session = { version: 1, base: cfg.backendUrl, id: 'S-OLD', dir: 'OLD', state: 'running', abort: new AbortController(), lavdNoNeo4j: false };
  provider.session = session; provider.scanId = session.id; provider.rtlDir = session.dir;
  return { provider, session, backend, messages, timers, cancelled, cfg };
}

test('cancelled in-flight status cannot publish logs, report or completion', async () => {
  const h = host(), d = deferred(); h.backend.api.status = () => d.promise;
  const work = h.provider.pollOnce(h.session); await h.provider.onMessage({ type: 'cmd', cmd: 'cancel' });
  d.resolve({ state: 'done', logs: ['old'], progress: 100 }); await work;
  assert.equal(h.messages.filter(m => m.kind === 'progress').map(m => m.payload.phase).join(','), 'cancelled');
  assert.equal(h.messages.some(m => m.kind === 'report' || m.kind === 'log'), false);
  assert.equal(h.session.abort.signal.aborted, true);
});

test('old status response cannot stop a new timer or replace its directory', async () => {
  const h = host(), d = deferred(); h.backend.api.status = () => d.promise;
  const work = h.provider.pollOnce(h.session); h.provider.invalidateSession();
  const currentTimer = {}; h.provider.pollTimer = currentTimer; h.provider.rtlDir = 'NEW';
  d.resolve({ state: 'done', logs: [], progress: 100 }); await work;
  assert.equal(h.cancelled.includes(currentTimer), false); assert.equal(h.provider.rtlDir, 'NEW'); assert.equal(h.messages.length, 0);
});

test('polling schedules the next request only after the current one completes', async () => {
  const h = host(), d = deferred(); h.backend.api.status = () => d.promise;
  h.provider.startPolling(h.session); const work = h.timers[0].fn(); await tick();
  assert.equal(h.timers.length, 1); d.resolve({ state: 'running', logs: [], progress: 60 }); await tick();
  assert.equal(h.timers.length, 2);
});

test('in-flight report, graph and fix responses are discarded after changing scan', async () => {
  for (const kind of ['report', 'graph', 'fix']) {
    const h = host(), d = deferred(); h.backend.api[kind] = () => d.promise;
    const work = kind === 'report' ? h.provider.afterScanDone(h.session) : kind === 'graph' ? h.provider.showGraph('mock') : h.provider.genFix('mock', 'F-1');
    h.provider.invalidateSession(); h.provider.rtlDir = 'NEW';
    d.resolve(kind === 'report' ? { rtl_dir: 'OLD', findings: [] } : kind === 'fix' ? { finding: { id: 'F-1' } } : { nodes: [] }); await work;
    assert.equal(h.messages.length, 0); assert.equal(h.provider.rtlDir, 'NEW');
  }
});

test('host scan uses the explicit directory snapshot and rejects duplicate starts', async () => {
  const h = host(), d = deferred(); h.provider.invalidateSession(); const dirs = [];
  h.backend.api.settings = async () => ({ settings: { rtl_dir: 'WRONG' }, neo4j_alive: true, has_api_key: true });
  h.backend.api.startScan = (base, dir) => { dirs.push(dir); return d.promise; };
  const work = h.provider.runScan('both', 'EXPLICIT'); await tick(); await h.provider.runScan('both', 'DUPLICATE');
  assert.deepEqual(dirs, ['EXPLICIT']); d.resolve({ scan_id: 'S-NEW' }); await work;
  assert.equal(h.provider.rtlDir, 'EXPLICIT');
});

test('host merges duplicate fix requests, retries failure and caches success', async () => {
  const h = host(), first = deferred(); let calls = 0;
  h.backend.api.fix = () => { calls++; return first.promise; };
  const work = h.provider.genFix('mock', 'F-1'); await h.provider.genFix('mock', 'F-1');
  assert.equal(calls, 1); first.reject(new Error('offline')); await work;
  h.backend.api.fix = async () => { calls++; return { ok: true, finding: { id: 'F-1', fix_suggestion: 'ok' } }; };
  await h.provider.genFix('mock', 'F-1'); await h.provider.genFix('mock', 'F-1'); assert.equal(calls, 2);
});

test('host serializes directory saves and confirms their request IDs without replaying settings', async () => {
  const h = host(), first = deferred(), values = [];
  h.backend.api.saveSettings = async (base, patch) => { values.push(patch.rtl_dir); if (patch.rtl_dir === 'B') await first.promise; return { ok: true }; };
  const b = h.provider.onMessage({ type: 'cmd', cmd: 'saveSettings', payload: { silent: true, rtl_dir: 'B', requestId: 1 } });
  const c = h.provider.onMessage({ type: 'cmd', cmd: 'saveSettings', payload: { silent: true, rtl_dir: 'C', requestId: 2 } });
  await tick(); assert.deepEqual(values, ['B']); first.resolve(); await Promise.all([b, c]);
  assert.deepEqual(values, ['B', 'C']);
  assert.deepEqual(h.messages.map(m => m.payload.directoryAck.requestId), [1, 2]);
  assert.equal(h.provider.pendingDirSave, null);
});

test('disposing a view prevents a delayed settings probe from restarting the backend', async () => {
  const h = host(), d = deferred(); let starts = 0;
  h.backend.isAlive = () => d.promise; h.backend.ensureBackend = async () => { starts++; };
  const work = h.provider.onMessage({ type: 'cmd', cmd: 'saveSettings', payload: { silent: true, rtl_dir: 'B', requestId: 1 } });
  await tick(); h.provider.dispose(); d.resolve(false); await work;
  assert.equal(starts, 0); assert.equal(h.messages.length, 0);
});

test('HTTP timeout includes a stalled response body', async () => {
  const d = deferred(); let signal;
  const b = load('backend', { vscode: {} }, { fetch: async (_, init) => { signal = init.signal; return { ok: true, text: () => d.promise }; } });
  await assert.rejects(b.get('http://mock', '/test', 15), /超时/); assert.equal(signal.aborted, true); d.resolve('{}');
});

test('HTTP cancellation covers a stalled body and releases listeners', async () => {
  const d = deferred(), ac = new AbortController();
  const b = load('backend', { vscode: {} }, { fetch: async () => ({ ok: true, text: () => d.promise }) });
  const work = b.get('http://mock', '/test', 1000, ac.signal); ac.abort(new Error('cancelled'));
  await assert.rejects(work, /cancelled/); d.resolve('{}');
});

test('concurrent backend starts spawn once, release dead children and never kill an exited PID', async () => {
  let alive = false; const spawns = [];
  class Socket extends EventEmitter { setTimeout() {} destroy() {} connect() { queueMicrotask(() => this.emit('error', Error('offline'))); } }
  const log = Object.assign(new EventEmitter(), { write() {}, end() {} });
  const b = load('backend', { vscode: { workspace: { getConfiguration: () => ({ get: () => 'C:/ROOT' }), workspaceFolders: [] } },
    fs: { existsSync: () => true, createWriteStream: () => log }, net: { Socket }, child_process: { spawn(cmd, args) {
      const child = Object.assign(new EventEmitter(), { pid: 100, exitCode: null, signalCode: null, stdout: new EventEmitter(), stderr: new EventEmitter(), kill() {} });
      spawns.push({ cmd, args, child }); alive = true; return child;
    } } }, { fetch: async () => ({ ok: alive }), setTimeout: (fn, ms) => setTimeout(fn, ms === 1000 ? 1 : ms) });
  await Promise.all([b.ensureBackend('http://localhost:8321', () => {}), b.ensureBackend('http://localhost:8321', () => {})]);
  assert.equal(spawns.length, 1); assert.equal(b.hasSpawnedBackend(), true);
  log.emit('error', Error('log permission denied')); // must not crash startup/host
  spawns[0].child.exitCode = 1; spawns[0].child.emit('exit', 1); assert.equal(b.hasSpawnedBackend(), false);
  await b.stopBackend(); assert.equal(spawns.length, 1);
});

test('scan command focuses the view and requests a real scan', async () => {
  const commands = new Map(); let scans = 0;
  class P { requestScan() { scans++; } } P.viewId = 'panel';
  const vscode = { window: { registerWebviewViewProvider() {} }, commands: { registerCommand: (name, fn) => commands.set(name, fn), executeCommand: async () => {} },
    workspace: { onDidChangeConfiguration() {} } };
  load('extension', { vscode, './panelProvider': { CslRtlSeccheckPanelProvider: P }, './diagnostics': { DiagnosticsManager: class {} }, './backend': {} }).activate({ subscriptions: [] });
  await commands.get('cslRtlSeccheck.scan')(); assert.equal(scans, 1);
});
