/**
 * 后端生命周期 + HTTP 访问层。
 *
 * 拉起策略照搬 tcl/seccheck.tcl 里已经跑通的做法：
 *   1. 先探测 127.0.0.1:8321（优先 HTTP /api/settings，失败退回 TCP 端口探测）
 *   2. 没起来就直接 spawn uvicorn —— **不用 start.bat**，因为它会弹出一个必须
 *      保持开启的控制台窗口、自动打开浏览器、并在末尾 pause 阻塞，对扩展是灾难
 *   3. 起来后轮询等待就绪，超时则回收刚刚拉起的那个进程
 *
 * 关键约束：**只有本扩展自己 spawn 出来的进程才会被 stopBackend() 回收**。
 * 如果后端本来就在跑（用户手动起的、或者 Vivado Tcl 起的），扩展只是 attach 上去，
 * 退出时绝不插手别人的进程。
 */
import * as vscode from "vscode";
import * as fs from "fs";
import * as path from "path";
import * as net from "net";
import { spawn, ChildProcess } from "child_process";

/* ------------------------------------------------------------------ *
 * 类型：与后端真实返回结构对齐（backend/main.py + unify.py）
 * ------------------------------------------------------------------ */

/** finding 的位置。后端是数组，通常只取第 0 项；file 一般是相对 rtl_dir 的路径。 */
export interface FindingLocation {
  file: string;
  line?: number;
  module?: string;
}

export interface Finding {
  id: string;
  /** "veriloglavd" | "veripvd"（后端的字段名是 source，不是 engine） */
  source?: string;
  /** CWE 编号或漏洞类型，如 "CWE-1243" / "permission_related_vulnerability" */
  type?: string;
  severity: string;
  description?: string;
  /** 仅 VerilogLAVD 的 finding 带这个字段 */
  description_en?: string;
  location?: FindingLocation[];
  /** 实测是字符串数组，形如 "access_ctrl.v:11 Always block matched…" */
  evidence?: unknown[];
  fix_suggestion?: string;
  verification?: { tool?: string; status?: string; detail?: string };
}

export interface EngineFlags {
  lavd: boolean;
  pvd: boolean;
}

export interface Report {
  scan_id: string;
  rtl_dir: string;
  findings: Finding[];
  warnings?: string[];
  engines?: EngineFlags | null;
  summary?: { total: number; high: number; by_engine: Record<string, number> };
}

export interface ScanStatus {
  /** 后端除了 running/done 还会返回 error */
  state: "running" | "done" | "error";
  logs: string[];
  warnings?: string[];
  engines?: EngineFlags | null;
  progress?: number;
}

export interface GraphData {
  nodes: Array<{ id: string; file?: string; findings?: number; max_sev?: string }>;
  edges: Array<{ source: string; target: string }>;
  meta?: { truncated?: boolean; total_modules?: number };
}

export interface BackendSettings {
  has_api_key: boolean;
  neo4j_alive: boolean;
  /** 纯增量字段：Neo4j 失败时的分类文案（成功为空串）—— 依赖行的可行动提示 */
  neo4j_reason?: string;
  settings?: Record<string, unknown>;
}

/** 后端即时校验的单项结果（POST /api/settings 的 validation.* ） */
export interface CheckResult {
  ok: boolean;
  /** ok | auth | refused | timeout | version | format | missing | offline | http | unknown */
  kind: string;
  message: string;
  /** 仅 api_key 校验带：deepseek/qwen/gpt/claude/gemini */
  provider?: string;
}

/* ------------------------------------------------------------------ *
 * 项目根目录定位
 * ------------------------------------------------------------------ */

/**
 * 定位 RTL-SecCheck 项目根目录（含 backend/main.py 的那层）。
 *
 * 探测顺序：
 *   1. 用户显式配置的 cslRtlSeccheck.projectRoot
 *   2. 扩展安装位置的上两级 —— 开发态（<root>/vscode-extension/out）能直接命中
 *   3. 当前工作区里含 backend/main.py 的目录
 *   4. 当前工作区根目录（兜底）
 *
 * 之所以要这一串：扩展一旦以 .vsix 装进别的 VSCode，__dirname 会指向
 * ~/.vscode/extensions/csl-rtl-seccheck-x.y.z/out，第 2 步就落空了。
 */
export function resolveProjectRoot(): string | null {
  const configured = vscode.workspace
    .getConfiguration("cslRtlSeccheck")
    .get<string>("projectRoot");
  if (configured && hasBackend(configured)) {
    return configured;
  }

  // __dirname === <扩展目录>/out
  const fromExtension = path.resolve(__dirname, "..", "..");
  if (hasBackend(fromExtension)) {
    return fromExtension;
  }

  const folders = vscode.workspace.workspaceFolders ?? [];
  for (const f of folders) {
    if (hasBackend(f.uri.fsPath)) {
      return f.uri.fsPath;
    }
  }
  return folders.length > 0 ? folders[0].uri.fsPath : null;
}

/** 判断一个目录像不像项目根：必须有 backend/main.py */
function hasBackend(dir: string): boolean {
  try {
    return fs.existsSync(path.join(dir, "backend", "main.py"));
  } catch {
    return false;
  }
}

export function backendDir(): string | null {
  const root = resolveProjectRoot();
  return root ? path.join(root, "backend") : null;
}

/* ------------------------------------------------------------------ *
 * 进程状态
 * ------------------------------------------------------------------ */

/** 扩展自己拉起且尚未退出的进程；复用已有服务时不登记所有权 */
const ownedChildren = new Set<ChildProcess>();
const starts = new Map<string, { promise: Promise<void>; listeners: Set<(line: string) => void> }>();
let lifecycleVersion = 0;

/** 供测试/诊断用：当前是否持有一个由本扩展拉起的后端进程 */
export function hasSpawnedBackend(): boolean {
  return ownedChildren.size > 0;
}

const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

/* ------------------------------------------------------------------ *
 * 探测
 * ------------------------------------------------------------------ */

/** TCP 端口探测。对应 Tcl 的 sec_port_listening（那边是解析 netstat，这边直接连） */
export function probePort(port: number, host = "127.0.0.1", timeout = 1500): Promise<boolean> {
  return new Promise((resolve) => {
    const sock = new net.Socket();
    let settled = false;
    const finish = (ok: boolean) => {
      if (settled) return;
      settled = true;
      sock.destroy();
      resolve(ok);
    };
    sock.setTimeout(timeout);
    sock.once("connect", () => finish(true));
    sock.once("timeout", () => finish(false));
    sock.once("error", () => finish(false));
    try {
      sock.connect(port, host);
    } catch {
      finish(false);
    }
  });
}

/**
 * 后端是否活着。先走 HTTP（能同时确认 FastAPI 真的在应答），
 * 失败再退回端口探测 —— 对应 Tcl 的 sec_backend_alive 双保险：
 * HTTP 探测可能因为机器繁忙而超时，但端口其实是通的。
 */
export async function isAlive(baseUrl: string): Promise<boolean> {
  try {
    const ok = await fetchWithTimeout(`${baseUrl}/api/settings`, { method: "GET" }, 2000,
      async (r) => { await r.body?.cancel(); return r.ok; });
    if (ok) return true;
  } catch {
    /* 落到端口探测 */
  }
  try {
    const u = new URL(baseUrl);
    return await probePort(Number(u.port || (u.protocol === "https:" ? "443" : "80")), u.hostname || "127.0.0.1");
  } catch {
    return false;
  }
}

/* ------------------------------------------------------------------ *
 * 启动 / 回收
 * ------------------------------------------------------------------ */

/**
 * 确保后端可用。已运行则直接复用；否则 spawn uvicorn 并等待就绪。
 *
 * @param onLog 逐行回调，宿主把它转成面板里的日志行
 * @throws 启动失败或超时（调用方负责渲染成消息流内的状态卡）
 */
export async function ensureBackend(
  baseUrl: string,
  onLog: (line: string) => void
): Promise<void> {
  const key = baseUrl.replace(/\/+$/, "");
  let task = starts.get(key);
  if (!task) {
    const listeners = new Set<(line: string) => void>([onLog]);
    const version = lifecycleVersion;
    const promise = Promise.resolve().then(() => ensureBackendOnce(key, (line) => {
      for (const listener of listeners) listener(line);
    }, version));
    task = { promise, listeners };
    starts.set(key, task);
  }
  task.listeners.add(onLog);
  try {
    await task.promise;
  } finally {
    task.listeners.delete(onLog);
    if (starts.get(key) === task) starts.delete(key);
  }
}

async function ensureBackendOnce(baseUrl: string, onLog: (line: string) => void, version: number): Promise<void> {
  if (await isAlive(baseUrl)) {
    onLog("[OK] 后端已在运行，直接复用（不会接管它的生命周期）");
    return;
  }

  if (version !== lifecycleVersion) throw new Error("后端启动已取消");

  const bdir = backendDir();
  if (!bdir || !fs.existsSync(path.join(bdir, "main.py"))) {
    throw new Error(
      "找不到 backend/main.py。请在设置里指定 cslRtlSeccheck.projectRoot，或直接在 VSCode 中打开 RTL-SecCheck 项目目录。"
    );
  }

  const u = new URL(baseUrl);
  const host = u.hostname || "127.0.0.1";
  const port = u.port || (u.protocol === "https:" ? "443" : "80");
  if (u.protocol !== "http:" || !["127.0.0.1", "localhost", "[::1]"].includes(host)) {
    throw new Error("配置的后端不可达；仅支持自动启动本机 HTTP 后端，请先启动远程服务或检查 backendUrl。");
  }

  // 解释器：优先项目自带的 venv，找不到就退回 PATH 里的 python
  const venvPy = path.join(bdir, ".venv", "Scripts", "python.exe");
  const py = fs.existsSync(venvPy) ? venvPy : "python";

  const logPath = path.join(bdir, "service.log");
  let logStream: fs.WriteStream | null = null;
  try {
    logStream = fs.createWriteStream(logPath, { flags: "a" });
    logStream.on("error", () => { logStream = null; });
    logStream.write(
      `\n${new Date().toISOString()}  [EXT] VSCode 扩展正在拉起 uvicorn\n`
    );
  } catch {
    logStream = null;
  }

  onLog(`[RUN] 启动后端：${py} -m uvicorn --app-dir ${bdir} --port ${port}`);

  const child = spawn(
    py,
    [
      "-E",
      "-s",
      "-u",
      "-m",
      "uvicorn",
      "--app-dir",
      bdir,
      "main:app",
      "--host",
      host,
      "--port",
      port,
    ],
    {
      cwd: bdir,
      // detached 保持 false 且不调 unref()：不让后端脱离 VSCode 的生命周期，
      // 这样 deactivate() 里回收它才是符合预期的行为。
      detached: false,
      windowsHide: true,
      stdio: ["ignore", "pipe", "pipe"],
    }
  );

  if (child.pid) ownedChildren.add(child);
  const release = () => { ownedChildren.delete(child); };
  child.once("exit", release);
  child.once("error", release);
  let startupError: Error | undefined;

  // uvicorn 的输出同时进 service.log（和 start.bat 写同一个文件，便于排查）
  if (logStream) {
    child.stdout?.on("data", (b: Buffer) => logStream?.write(b));
    child.stderr?.on("data", (b: Buffer) => logStream?.write(b));
    child.on("close", () => logStream?.end());
  }
  child.on("error", (err) => {
    startupError = err;
    onLog(`[FAIL] 无法启动 python 进程：${err.message}`);
  });

  onLog(`[RUN] 等待后端就绪（最多 15 秒，pid ${child.pid ?? "?"}）…`);

  try {
    for (let i = 1; i <= 15; i++) {
      await sleep(1000);
      if (version !== lifecycleVersion) throw new Error("后端启动已取消");
      if (startupError) throw startupError;
      if (child.exitCode !== null || child.signalCode !== null) throw new Error("后端进程提前退出，请检查 service.log");
      if (await isAlive(baseUrl)) {
        if (version !== lifecycleVersion) throw new Error("后端启动已取消");
        onLog(`[OK] 后端已就绪：${baseUrl}（pid ${child.pid ?? "?"}）`);
        return;
      }
      onLog(`[RUN] 等待中 ${i}/15 …`);
    }

    // 超时：把刚拉起来的进程收掉，别留个半死不活的占着端口
    throw new Error(`后端在约 15 秒内没有就绪。请查看日志：${logPath}`);
  } catch (e) {
    await stopChild(child);
    throw e;
  }
}

/**
 * 回收后端进程。由 extension.ts 的 deactivate() 调用。
 *
 * 只回收 ownedChildren 中仍在运行的进程，并取消尚未完成的启动任务。
 */
export async function stopBackend(): Promise<void> {
  lifecycleVersion++;
  await Promise.all([...ownedChildren].map(stopChild));
  await Promise.allSettled([...starts.values()].map((task) => task.promise));
}

async function stopChild(child: ChildProcess): Promise<void> {
  if (!ownedChildren.delete(child) || !child.pid || child.exitCode !== null || child.signalCode !== null) return;
  const pid = child.pid;

  await new Promise<void>((resolve) => {
    let done = false;
    const finish = () => {
      if (done) return;
      done = true;
      resolve();
    };
    // 兜底：taskkill 万一卡住也不能让 deactivate 挂死
    const guard = setTimeout(finish, 5000);
    try {
      // /T 连子进程树一起终止，/F 强制
      const killer = spawn("taskkill", ["/PID", String(pid), "/T", "/F"], {
        windowsHide: true,
      });
      killer.on("exit", () => {
        clearTimeout(guard);
        finish();
      });
      killer.on("error", () => {
        clearTimeout(guard);
        finish();
      });
    } catch {
      // 进程可能早就自己退了，taskkill 报「找不到进程」属正常，不往上抛
      clearTimeout(guard);
      finish();
    }
  });

  // 保险：如果 taskkill 没能收掉（比如权限问题），至少断开引用
  try {
    if (!child.killed && child.exitCode === null && child.signalCode === null) child.kill();
  } catch {
    /* ignore */
  }
}

/* ------------------------------------------------------------------ *
 * HTTP 封装（全局 fetch + AbortController 超时）
 * ------------------------------------------------------------------ */

async function fetchWithTimeout<T>(
  url: string,
  init: RequestInit,
  timeoutMs: number,
  consume: (response: Response) => Promise<T>,
  signal?: AbortSignal
): Promise<T> {
  const ac = new AbortController();
  const abort = () => ac.abort(signal?.reason);
  signal?.addEventListener("abort", abort, { once: true });
  if (signal?.aborted) abort();
  const timer = setTimeout(() => ac.abort(new Error(`请求超时（${timeoutMs}ms）`)), timeoutMs);
  let rejectAbort: () => void = () => {};
  const aborted = new Promise<never>((_, reject) => {
    rejectAbort = () => reject(ac.signal.reason ?? new Error("请求已取消"));
    ac.signal.addEventListener("abort", rejectAbort, { once: true });
    if (ac.signal.aborted) rejectAbort();
  });
  try {
    return await Promise.race([fetch(url, { ...init, signal: ac.signal }).then(consume), aborted]);
  } finally {
    clearTimeout(timer);
    signal?.removeEventListener("abort", abort);
    ac.signal.removeEventListener("abort", rejectAbort);
  }
}

/** 统一解包：非 2xx 时把后端 {"detail": "..."} 里的信息提出来当错误消息 */
async function unwrap<T>(r: Response): Promise<T> {
  const text = await r.text();
  let data: any;
  try {
    data = text ? JSON.parse(text) : undefined;
  } catch {
    data = undefined;
  }
  if (!r.ok) {
    const detail = data?.detail ?? text ?? `HTTP ${r.status}`;
    throw new Error(typeof detail === "string" ? detail : JSON.stringify(detail));
  }
  return data as T;
}

export async function get<T>(baseUrl: string, p: string, timeoutMs = 15000, signal?: AbortSignal): Promise<T> {
  return fetchWithTimeout(baseUrl.replace(/\/+$/, "") + p, { method: "GET" }, timeoutMs, unwrap<T>, signal);
}

export async function post<T>(
  baseUrl: string,
  p: string,
  body?: unknown,
  timeoutMs = 120000,
  signal?: AbortSignal
): Promise<T> {
  return fetchWithTimeout(
    baseUrl.replace(/\/+$/, "") + p,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body ?? {}),
    },
    timeoutMs,
    unwrap<T>,
    signal
  );
}

/* ------------------------------------------------------------------ *
 * 端点封装
 * ------------------------------------------------------------------ */

export const api = {
  // GET 会现场做一次 Neo4j bolt 握手（最坏 5s 超时），给足余量避免误报离线
  settings: (base: string, signal?: AbortSignal) => get<BackendSettings>(base, "/api/settings", 15000, signal),
  startScan: (base: string, rtlDir: string, engines: EngineFlags, signal?: AbortSignal) =>
    post<{ scan_id: string }>(base, "/api/scan", { rtl_dir: rtlDir, engines }, 30000, signal),
  status: (base: string, id: string, signal?: AbortSignal) => get<ScanStatus>(base, `/api/scan/${id}/status`, 15000, signal),
  report: (base: string, id: string, signal?: AbortSignal) => get<Report>(base, `/api/scan/${id}/report`, 30000, signal),
  graph: (base: string, id: string, signal?: AbortSignal) => get<GraphData>(base, `/api/scan/${id}/graph`, 30000, signal),
  /** LLM 生成修复建议，实测 10~40 秒，超时给足 */
  fix: (base: string, id: string, findingId: string, signal?: AbortSignal) =>
    post<{ ok: boolean; finding: Finding }>(
      base,
      `/api/scan/${id}/fix/${encodeURIComponent(findingId)}`,
      {},
      330000,
      signal
    ),
  /**
   * 后端返回体：{ok, has_api_key, neo4j_alive?, neo4j_reason?, validation?}。
   * L1 起校验范围由 patch 字段决定：含 neo4j_* → 返回 neo4j_* +
   * validation.neo4j；含 api_key → validation.api_key；只含 rtl_dir →
   * 两者都不返回（不握手、不联网）。Neo4j 握手最坏 5s、API Key 联网
   * 校验最坏 10s，POST 超时仍给足 30s。
   */
  saveSettings: (base: string, patch: Record<string, unknown>) =>
    post<{
      ok: boolean;
      has_api_key: boolean;
      /** 仅当 patch 含 neo4j_* 字段时出现 */
      neo4j_alive?: boolean;
      /** 仅当 patch 含 neo4j_* 字段时出现（成功=在线文案，失败=分类原因） */
      neo4j_reason?: string;
      /** 只含实际校验过的分项（L1 字段范围校验） */
      validation?: { neo4j?: CheckResult; api_key?: CheckResult };
    }>(base, "/api/settings", patch, 30000),
};
