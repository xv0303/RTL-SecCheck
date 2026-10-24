"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.CslRtlSeccheckPanelProvider = void 0;
/**
 * 对话式侧边栏的宿主端。
 *
 * 职责：
 *   - 把 media/panel.html 组装成 Webview（CSP + nonce + 资源 URI）
 *   - 接收 Webview 的 postMessage，转成对后端的 HTTP 调用（**Webview 内不许 fetch**）
 *   - 把结果按消息协议推回 Webview
 *   - 维护扫描轮询、取消、修复建议缓存
 *   - 把 findings 交给 DiagnosticsManager 画波浪线
 *
 * 硬约束：这里**不得**出现 showQuickPick / showInformationMessage /
 * showErrorMessage / withProgress / createWebviewPanel。所有异常一律转成
 * 消息流里的 status 卡片。
 */
const vscode = __importStar(require("vscode"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const crypto = __importStar(require("crypto"));
const backend = __importStar(require("./backend"));
const commandParser_1 = require("./commandParser");
const BACKEND_PROJECT_URL = "https://github.com/xv0303/RTL-SecCheck";
/** 读当前配置（每次现读，避免缓存与用户改动不同步） */
function readConfig() {
    const c = vscode.workspace.getConfiguration("cslRtlSeccheck");
    return {
        engine: (c.get("engine") ?? "both"),
        backendUrl: c.get("backendUrl") || "http://127.0.0.1:8321",
        veripvdPath: c.get("veripvdPath") || "",
    };
}
/** 引擎档位 → 后端 engines 标志。三档互斥，全 false 会被后端 400 拒绝，所以这里必有一真。 */
function engineFlags(mode) {
    return { lavd: mode !== "pvd", pvd: mode !== "lavd" };
}
class CslRtlSeccheckPanelProvider {
    context;
    diagnostics;
    static viewId = "cslRtlSeccheck.panel";
    view;
    disposed = false;
    viewVersion = 0;
    /* ---- 扫描状态 ---- */
    scanId = null;
    rtlDir = null;
    /** 面板打开那一刻定格的默认扫描目录（当前文件目录 → 工作区根 → 项目根）。
     *  之后切换活动文件不再改变默认值；面板重新可见（再次打开）时重新定格 */
    openDir = null;
    pollTimer;
    session = null;
    sessionVersion = 0;
    pendingScan = false;
    settingsVersion = 0;
    directoryVersion = 0;
    /** 最近一次「用户保存」时的 API Key 校验结果（依赖行显示用，带 HH:MM）。
     *  Neo4j 状态不走这里 —— GET /api/settings 每次现场握手，天然无 stale；
     *  API Key 联网校验只在保存时做（成本考虑），故由宿主记住最近结果 */
    lastApiKeyCheck = null;
    /* ---- L1 布局重排：标题栏齿轮 + 扫描目录独立静默保存 ---- */
    /** Webview 脚本是否已发过 ready（postMessage 在 ready 前可能丢失） */
    webviewReady = false;
    /** Webview 尚未 ready 时收到的齿轮点击：记下意图，ready 后补发 */
    pendingToggle = false;
    /** 最近一次完整设置快照，用于屏蔽目录保存之前发出的迟到 GET 结果。 */
    lastSettingsPayload = null;
    /** 目录静默保存串行化。resolve true=已保存，false=失败（runScan 据此中止） */
    pendingDirSave = null;
    /** 最近一次目录保存失败文案（runScan 中止时追加说明） */
    lastDirSaveError = null;
    /* ---- 修复建议缓存：`${scanId}:${findingId}` → 后端返回的 finding ---- */
    fixCache = new Map();
    fixRequests = new Map();
    constructor(context, diagnostics) {
        this.context = context;
        this.diagnostics = diagnostics;
    }
    /* ================================================================ *
     * Webview 装配
     * ================================================================ */
    resolveWebviewView(view) {
        this.disposed = false;
        this.viewVersion++;
        this.view = view;
        this.webviewReady = false;
        // 打开面板那一刻定格默认扫描目录：此后切换文件不影响默认值，
        // 面板重新可见时（onDidChangeVisibility）会重新定格
        this.openDir = this.defaultScanDir();
        view.webview.options = {
            enableScripts: true,
            localResourceRoots: [vscode.Uri.joinPath(this.context.extensionUri, "media")],
        };
        view.webview.html = this.buildHtml(view.webview);
        view.webview.onDidReceiveMessage((m) => {
            void this.onMessage(m);
        });
        view.onDidDispose(() => {
            this.dispose();
            this.view = undefined;
            this.webviewReady = false;
        });
        // 面板重新可见 = 再次「打开面板」：重新定格默认扫描目录，并刷新设置与依赖状态
        // （后端 / Neo4j 可能在外部被启动或停止）
        view.onDidChangeVisibility(() => {
            if (view.visible) {
                this.openDir = this.defaultScanDir();
                void this.pushSettings();
            }
        });
    }
    /** 配置变化时由 extension.ts 调用，刷新徽章与引擎下拉（引擎下拉只在用户没动过时跟随配置） */
    onConfigChanged() {
        if (this.session && this.session.base !== readConfig().backendUrl) {
            this.invalidateSession();
            this.post({ type: "data", kind: "progress", payload: { phase: "cancelled" } });
        }
        void this.pushSettings();
    }
    requestScan() {
        if (!this.isViewReady()) {
            this.pendingScan = true;
            return;
        }
        this.post({ type: "data", kind: "ui", action: "startScan" });
    }
    dispose() {
        this.disposed = true;
        this.viewVersion++;
        this.pendingScan = false;
        this.settingsVersion++;
        this.invalidateSession();
    }
    invalidateSession() {
        this.stopPolling();
        this.session?.abort.abort();
        this.session = null;
        this.scanId = null;
        this.rtlDir = null;
        this.fixCache.clear();
    }
    isCurrent(session) {
        return this.session === session && !session.abort.signal.aborted;
    }
    /** 视图与 Webview 脚本是否都已就绪（齿轮命令判断是否需要先 focus） */
    isViewReady() {
        return !!this.view && this.webviewReady;
    }
    /**
     * 标题栏齿轮：切换 Webview 内的「连接与扫描设置」卡。
     * 视图尚未解析 / Webview 脚本尚未 ready 时记下意图，等 ready 后补发
     * （ready 之前的 postMessage 可能丢失，避免点击无反应）。
     * H→W 消息：{type:"data", kind:"ui", action:"toggleSettings"}（L1 例外三）。
     */
    toggleSettings() {
        if (!this.view || !this.webviewReady) {
            // 记「点击奇偶」而不是只记「点过」：ready 前连点两下应相互抵消
            this.pendingToggle = !this.pendingToggle;
            return;
        }
        this.post({ type: "data", kind: "ui", action: "toggleSettings" });
    }
    buildHtml(webview) {
        const mediaDir = vscode.Uri.joinPath(this.context.extensionUri, "media");
        const cssUri = webview.asWebviewUri(vscode.Uri.joinPath(mediaDir, "panel.css"));
        const jsUri = webview.asWebviewUri(vscode.Uri.joinPath(mediaDir, "panel.js"));
        const nonce = crypto.randomBytes(16).toString("base64");
        const htmlPath = vscode.Uri.joinPath(mediaDir, "panel.html").fsPath;
        const template = fs.readFileSync(htmlPath, "utf8");
        return template
            .replace(/\{\{cspSource\}\}/g, webview.cspSource)
            .replace(/\{\{nonce\}\}/g, nonce)
            .replace(/\{\{cssUri\}\}/g, cssUri.toString())
            .replace(/\{\{jsUri\}\}/g, jsUri.toString());
    }
    /* ================================================================ *
     * 消息推送小工具
     * ================================================================ */
    post(msg) {
        void this.view?.webview.postMessage(msg);
    }
    /**
     * 消息流内的状态卡（红/黄/普通）—— 取代所有 vscode.window.show* 通知。
     * 带 tag 的是单例卡：前端会原地复用同类旧卡（如引擎切换提示），不再堆叠。
     */
    status(text, level = "info", tag, actions) {
        const payload = {
            text,
            level,
            ...(tag ? { tag } : {}),
            ...(actions?.length ? { actions } : {}),
        };
        this.post({ type: "data", kind: "status", payload });
    }
    backendMissingStatus(detail) {
        const suffix = detail ? `\n\n连接详情：${detail}` : "";
        this.status(`目前未检测到 RTL-SecCheck 后端。\n\n` +
            `请完成以下步骤：\n` +
            `1. 从项目主页下载完整项目\n` +
            `2. 安装 Python 依赖\n` +
            `3. 启动后端服务\n` +
            `4. 返回本面板重新连接\n\n` +
            `项目地址：\n${BACKEND_PROJECT_URL}${suffix}`, "error", "backend", [{ id: "reconnect", label: "重新连接" }]);
    }
    async reconnectBackend(base, viewVersion) {
        this.status("正在重新连接 RTL-SecCheck 后端…", "info", "backend");
        try {
            await backend.ensureBackend(base, (line) => this.status(line, "info", "backend"));
            if (viewVersion !== this.viewVersion || this.disposed)
                return;
            await this.pushSettings();
            if (viewVersion !== this.viewVersion || this.disposed)
                return;
            this.status("RTL-SecCheck 后端已连接，可以开始扫描。", "info", "backend");
        }
        catch (e) {
            if (viewVersion !== this.viewVersion || this.disposed)
                return;
            this.backendMissingStatus(String(e?.message ?? e));
        }
    }
    log(line) {
        this.post({ type: "data", kind: "log", payload: { line } });
    }
    /* ================================================================ *
     * 消息路由
     * ================================================================ */
    async onMessage(m) {
        if (this.disposed || !m || m.type !== "cmd")
            return;
        const base = readConfig().backendUrl;
        const viewVersion = this.viewVersion;
        try {
            switch (m.cmd) {
                case "ready":
                    this.webviewReady = true;
                    // 视图解析前就点过齿轮：Webview 现在能收消息了，先补发切换
                    // （不等 pushSettings —— 它可能因 Neo4j 握手等上数秒）
                    if (this.pendingToggle) {
                        this.pendingToggle = false;
                        this.post({ type: "data", kind: "ui", action: "toggleSettings" });
                    }
                    await this.pushSettings();
                    if (this.pendingScan) {
                        this.pendingScan = false;
                        this.requestScan();
                    }
                    break;
                case "reconnect":
                    await this.reconnectBackend(base, viewVersion);
                    break;
                case "startScan": {
                    // 「启动并扫描」按钮带来当前下拉档位；非法值回落到配置档
                    const req = m.payload?.engine;
                    const engine = ["both", "lavd", "pvd"].includes(req)
                        ? req
                        : readConfig().engine;
                    const requestedDir = typeof m.payload?.rtlDir === "string" ? m.payload.rtlDir.trim() : undefined;
                    await this.runScan(engine, requestedDir);
                    break;
                }
                case "cancel":
                    this.invalidateSession();
                    this.post({ type: "data", kind: "progress", payload: { phase: "cancelled" } });
                    this.status("已取消本次扫描的进度跟踪（后端任务未被强杀，可能仍在后台跑完）。", "warn");
                    break;
                case "graph":
                    await this.showGraph(base, m.payload);
                    break;
                case "evidence":
                    // 证据链 / 位置链接 / 图节点的「跳源码」都走这里
                    await this.openFile(m.payload);
                    break;
                case "fix":
                    await this.genFix(base, String(m.payload?.findingId ?? ""));
                    break;
                case "saveSettings": {
                    // 设置卡保存：只收已知的字符串字段，走现有 POST /api/settings。
                    // 前端只提交 dirty 字段，未动过的密码 / API Key 不会带掩码值上来。
                    const p = (m.payload ?? {});
                    // L1：扫描目标目录的静默保存（回车 / 失焦触发）。
                    // 只提交 rtl_dir，不渲染秒表卡与校验结果卡，成功不出卡；
                    // 串到上一条目录保存之后执行，避免快速编辑乱序落盘。
                    // runScan 会 await 这个 promise：保存失败则中止扫描，绝不用旧目录硬扫。
                    if (p.silent === true) {
                        const dir = typeof p.rtl_dir === "string" ? p.rtl_dir.trim() : "";
                        const requestId = typeof p.requestId === "number" ? p.requestId : 0;
                        const prev = this.pendingDirSave;
                        const task = (prev ?? Promise.resolve(true)).then(() => this.saveRtlDirQuiet(base, dir, requestId, viewVersion));
                        this.pendingDirSave = task;
                        await task;
                        if (this.pendingDirSave === task)
                            this.pendingDirSave = null;
                        break;
                    }
                    const patch = {};
                    for (const k of ["rtl_dir", "neo4j_uri", "neo4j_user", "neo4j_password", "api_key"]) {
                        if (typeof p[k] === "string")
                            patch[k] = p[k];
                    }
                    if (Object.keys(patch).length === 0) {
                        this.status("设置无变更（没有动过任何字段）。", "info", "savesettings");
                        break;
                    }
                    // 后端未运行时自动拉起（与扫描同一条 ensureBackend 路径；已在线时
                    // isAlive 探测直接通过，不会重复 spawn），否则 POST 会在网络层失败，
                    // 用户只能看到 undici 的天书 "fetch failed"
                    if (!(await backend.isAlive(base))) {
                        if (viewVersion !== this.viewVersion || this.disposed)
                            return;
                        this.status("后端未运行，正在自动启动后保存…", "info", "savesettings");
                        try {
                            // 启动日志打到 savesettings 单例卡上实时更新（不打到进度卡日志区，
                            // 否则会凭空多出一张与扫描无关的进度卡）
                            await backend.ensureBackend(base, (l) => this.status(l, "info", "savesettings"));
                        }
                        catch (e) {
                            this.status(`后端启动失败，设置未保存：${String(e?.message ?? e)}\n修改后可再次点保存重试。`, "error", "savesettings");
                            break;
                        }
                    }
                    // POST 阶段的秒表卡：校验最坏 ~15s（bolt 握手 5s + /models 10s），
                    // 期间界面不能静默 —— 每秒原地更新已等待秒数，结束后由结果卡接管
                    const t0 = Date.now();
                    const tick = setInterval(() => {
                        if (viewVersion !== this.viewVersion)
                            return;
                        this.status(`正在保存并校验设置…已 ${Math.round((Date.now() - t0) / 1000)}s` +
                            `（Neo4j 握手 + API Key 联网校验，最长约 15 秒）`, "info", "savesettings");
                    }, 1000);
                    this.status("正在保存并校验设置…（Neo4j 握手 + API Key 联网校验，最长约 15 秒）", "info", "savesettings");
                    try {
                        const r = await backend.api.saveSettings(base, patch);
                        if (viewVersion !== this.viewVersion) {
                            clearInterval(tick);
                            return;
                        }
                        // 记录本次（用刚保存的新配置现场算出的）API Key 校验结果，供依赖行显示
                        if (r.validation?.api_key) {
                            this.lastApiKeyCheck = {
                                ...r.validation.api_key,
                                time: new Date().toLocaleTimeString("zh-CN", {
                                    hour: "2-digit",
                                    minute: "2-digit",
                                    hour12: false,
                                }),
                            };
                        }
                        // 保存成功才回推 saved:true —— 前端据此清 dirty、灰显保存按钮；
                        // 失败的推送不带 saved，前端保留 dirty，可直接再点保存重试。
                        // 推送里的 Neo4j 状态由 GET 现场重新握手得出，不吃 POST 的旧结果
                        await this.pushSettings(true);
                        clearInterval(tick);
                        // 保存状态卡：校验结果分项渲染（保存本身已成功，失败只降级为黄卡，
                        // 红卡留给保存动作本身失败 —— 网络/后端拒绝，走 catch 分支）
                        const v = r.validation ?? {};
                        const neo = v.neo4j;
                        const key = v.api_key;
                        const failed = [];
                        if (neo && !neo.ok)
                            failed.push(`Neo4j：${neo.message}`);
                        if (key && !key.ok)
                            failed.push(`API Key：${key.message}`);
                        if (failed.length > 0) {
                            this.status(`设置已保存，但以下校验未通过：\n${failed.map((s) => "· " + s).join("\n")}` +
                                `\n修改后可再次点保存重试。`, "warn", "savesettings");
                        }
                        else {
                            // L1 起 validation 按 patch 字段返回（只含实际改动的项）：
                            // 只改了 Neo4j 就不谈 API Key，反之亦然，避免误报「未配置」。
                            const parts = [];
                            // neo.message 成功时带服务端版本：如「Neo4j 在线（5.3.0，握手+认证通过）」
                            if (neo?.ok)
                                parts.push(neo.message);
                            if (key) {
                                parts.push(key.kind === "offline"
                                    ? "API Key 已配置（未联网验证）"
                                    : `API Key 校验通过（${key.provider ?? "?"}）`);
                            }
                            this.status(`设置已保存${parts.length ? "，" + parts.join("；") : ""}。`, "info", "savesettings");
                        }
                    }
                    catch (e) {
                        clearInterval(tick);
                        if (viewVersion !== this.viewVersion)
                            return;
                        const raw = String(e?.message ?? e);
                        const msg = /fetch failed/i.test(raw)
                            ? `无法连接后端（${base}），设置未保存。请查看 backend/service.log。`
                            : `设置保存失败：${raw}`;
                        this.status(`${msg}\n修改后可再次点保存重试。`, "error", "savesettings");
                    }
                    break;
                }
                default:
                    // 未识别 cmd（乱码 / 过期消息）：在消息流内回指令说明，绝不弹窗。
                    // tag "help" 单例卡：连续多条未识别消息只更新一张，不堆叠。
                    this.status(commandParser_1.HELP_TEXT, "warn", "help");
                    break;
            }
        }
        catch (e) {
            this.status(String(e?.message ?? e), "error");
        }
    }
    /* ================================================================ *
     * 设置
     * ================================================================ */
    /**
     * markSaved=true：本次推送是对「保存成功」的确认，前端据此清 dirty 并灰显保存按钮；
     * 普通推送不带 saved 字段（缺省 = 不动前端的 dirty 状态）。
     */
    async pushSettings(markSaved = false) {
        const cfg = readConfig();
        const version = ++this.settingsVersion;
        const directoryVersion = this.directoryVersion;
        let online = false;
        let hasApiKey = false;
        let neo4jAlive = false;
        // Neo4j 分类文案（GET 现场握手得出）：失败 = 可行动原因，成功 = 「在线（版本）」
        // → 依赖行两种状态都显示（F10 起成功也带版本号）
        let neo4jHint = "";
        // 设置区回显值：api_key 用后端返回的脱敏串；neo4j 密码不下发前端，只发「是否已配置」
        let values = {
            rtlDir: "",
            neo4jUri: "",
            neo4jUser: "",
            apiKeyMasked: "",
            neo4jPwdSet: false,
        };
        try {
            const s = await backend.api.settings(cfg.backendUrl);
            online = true;
            hasApiKey = !!s.has_api_key;
            neo4jAlive = !!s.neo4j_alive;
            neo4jHint = s.neo4j_reason ?? "";
            values = {
                rtlDir: String(s.settings?.rtl_dir ?? ""),
                neo4jUri: String(s.settings?.neo4j_uri ?? ""),
                neo4jUser: String(s.settings?.neo4j_user ?? ""),
                apiKeyMasked: String(s.settings?.api_key ?? ""),
                neo4jPwdSet: !!s.settings?.neo4j_password,
            };
        }
        catch {
            online = false;
            this.backendMissingStatus();
            if (markSaved)
                throw new Error("设置已提交，但读取确认失败；请重试刷新或保存。");
        }
        if (version !== this.settingsVersion || cfg.backendUrl !== readConfig().backendUrl) {
            if (markSaved)
                this.post({ type: "data", kind: "settings", payload: { saved: true, acknowledgementOnly: true } });
            return;
        }
        if (directoryVersion !== this.directoryVersion && this.lastSettingsPayload?.values) {
            values.rtlDir = this.lastSettingsPayload.values.rtlDir;
        }
        const payload = {
            engine: cfg.engine,
            backendUrl: cfg.backendUrl,
            online,
            hasApiKey,
            neo4jAlive,
            // Neo4j 分类文案（依赖行显示用）：失败 = 原因，成功 = 「在线（版本）」
            neo4jHint,
            // 最近一次用户保存时的 API Key 校验结果（含 HH:MM），无则 null → 只显示「已配置」
            apiKeyCheck: this.lastApiKeyCheck,
            values,
            // 面板打开时定格的默认扫描目录（rtl_dir 留空时生效），给设置区的占位文本用
            defaultDir: this.openDir ?? "",
            // 仅保存成功确认时出现（见 saveSettings 分支），其余推送缺省
            ...(markSaved ? { saved: true } : {}),
        };
        // 缓存最近一次完整推送：目录静默保存成功后据此原地回推（不 GET、不握手）
        this.lastSettingsPayload = payload;
        this.post({ type: "data", kind: "settings", payload });
        // veripvdPath 非空时同步给后端（仅在后端在线且确实不一致时写，避免无谓覆盖）
        if (online && cfg.veripvdPath) {
            try {
                const s = await backend.api.settings(cfg.backendUrl);
                if (version !== this.settingsVersion || cfg.backendUrl !== readConfig().backendUrl)
                    return;
                const cur = s.settings?.veripvd_path || "";
                if (cur !== cfg.veripvdPath) {
                    // 后台同步不是用户保存：老后端用 skip_validation 跳过联网校验；
                    // L1 后端改为按 patch 字段决定范围（只含 veripvd_path → 不校验），
                    // 这里继续带上仅为兼容旧后端的语义。
                    await backend.api.saveSettings(cfg.backendUrl, {
                        veripvd_path: cfg.veripvdPath,
                        skip_validation: true,
                    });
                    this.log(`[OK] 已把 cslRtlSeccheck.veripvdPath 同步到后端 veripvd_path`);
                }
            }
            catch {
                /* 同步失败不影响主流程 */
            }
        }
    }
    /**
     * L1：扫描目标目录的静默保存。
     * 成功不出卡（只回推 settings 让前端清掉「保存中」标记）；失败才出错误卡。
     * POST 只带 rtl_dir，后端按 patch 字段决定校验范围 —— 不做 Neo4j 握手、
     * 不做 API Key 联网（宿主侧 isAlive 预检仍是既有链路，未改）。
     */
    async saveRtlDirQuiet(base, rtlDir, requestId, viewVersion) {
        this.lastDirSaveError = null;
        try {
            if (!(await backend.isAlive(base))) {
                if (viewVersion !== this.viewVersion || this.disposed)
                    return false;
                // 静默拉起：不把启动日志打到消息流（目录保存成功时不产生任何卡）
                await backend.ensureBackend(base, () => { });
            }
            await backend.api.saveSettings(base, { rtl_dir: rtlDir });
            if (viewVersion !== this.viewVersion)
                return false;
            if (base !== readConfig().backendUrl)
                throw new Error("后端地址已改变，请重新保存扫描目录");
            this.ackDirSaved(rtlDir, requestId);
            return true;
        }
        catch (e) {
            if (viewVersion !== this.viewVersion)
                return false;
            const raw = String(e?.message ?? e);
            const msg = /fetch failed/i.test(raw)
                ? `无法连接后端（${base}），扫描目标目录未保存。`
                : `扫描目标目录保存失败：${raw}`;
            this.lastDirSaveError = msg;
            this.post({ type: "data", kind: "settings", payload: { directoryAck: { requestId, value: rtlDir, ok: false } } });
            // 单例卡：连续失败只更新一张；前端据此解除防重、允许再次回车/失焦重试
            this.status(msg, "error", "rtlDir");
            return false;
        }
    }
    /**
     * 单独确认目录请求，避免回放其他设置的旧状态或清除新的编辑。
     * requestId 由 Webview 匹配；不重新 GET，不重复进行 Neo4j 握手。
     */
    ackDirSaved(rtlDir, requestId) {
        this.directoryVersion++;
        const last = this.lastSettingsPayload;
        if (last?.values) {
            this.lastSettingsPayload = { ...last, values: { ...last.values, rtlDir } };
            delete this.lastSettingsPayload.saved;
        }
        this.post({ type: "data", kind: "settings", payload: { directoryAck: { requestId, value: rtlDir, ok: true } } });
    }
    /**
     * 前置依赖体检（消息流内提示，绝不拦截、绝不弹窗）：
     *   - LAVD 依赖 Neo4j 在线（bolt 探测），探不到会走降级路径 → 很可能 0 条发现
     *   - PVD 的 LLM 步骤、以及所有修复建议依赖 API Key，缺了会静默降级
     *
     * 后端不在线时静默跳过（切档场景没必要催；扫描场景 ensureBackend 拉起后会再检一次）。
     */
    async checkPrereqs(mode, session) {
        let s;
        try {
            s = await backend.api.settings(session.base, session.abort.signal);
        }
        catch {
            return null;
        }
        if (!this.isCurrent(session))
            return null;
        if (mode !== "pvd" && !s.neo4j_alive) {
            const uri = String(s.settings?.neo4j_uri ?? "bolt://localhost:7687");
            // neo4j_reason 是后端现场握手的分类文案（端口被拒/认证失败/超时…），
            // 有则直接给可行动提示，无则退回通用指引
            const reason = s.neo4j_reason
                ? `原因：${s.neo4j_reason}。`
                : `请先在 Neo4j Desktop 里启动 DBMS，并确认其 bolt 端口与 ${uri} 一致。`;
            this.status(`Neo4j 未连接（探测 ${uri} 失败）：VerilogLAVD 建图检测需要数据库在线，` +
                `本次扫描将走降级路径，很可能产出 0 条发现。${reason}`, "warn", "neo4j");
        }
        if (mode !== "lavd" && !s.has_api_key) {
            this.status("未配置 LLM API Key：VeriPVD 的 LLM 分析步骤将被跳过（仅规则模式），" +
                "修复建议也会降级为本地模板。", "warn", "apikey");
        }
        // 顺带带回设置里的扫描目标目录（空 = 未配置），runScan 用它决定最终目录
        return { neo4jAlive: !!s.neo4j_alive, rtlDir: String(s.settings?.rtl_dir ?? "") };
    }
    /* ================================================================ *
     * 扫描
     * ================================================================ */
    async runScan(engine, requestedDir) {
        if (this.session && ["starting", "running", "finishing"].includes(this.session.state))
            return;
        const cfg = readConfig();
        const fallbackDir = this.openDir;
        this.invalidateSession();
        const session = {
            version: ++this.sessionVersion, base: cfg.backendUrl, id: null, dir: null,
            state: "starting", abort: new AbortController(), lavdNoNeo4j: false,
        };
        this.session = session;
        this.diagnostics.clear();
        this.post({ type: "data", kind: "progress", payload: {
                phase: "starting", text: `目标目录：${requestedDir || fallbackDir || "读取已保存目录…"}`, engine,
            } });
        try {
            // Wait for all directory saves already queued before this scan request.
            while (this.pendingDirSave) {
                const task = this.pendingDirSave;
                const saved = await task;
                if (!this.isCurrent(session))
                    return;
                if (!saved)
                    throw new Error(this.lastDirSaveError ?? "扫描目标目录未保存成功，本次扫描已中止。");
                if (this.pendingDirSave === task)
                    break;
            }
            if (!(await backend.isAlive(session.base))) {
                if (!this.isCurrent(session))
                    return;
                this.log("[WARN] 后端未运行，正在自动启动…");
                await backend.ensureBackend(session.base, (line) => {
                    if (this.isCurrent(session))
                        this.log(line);
                });
            }
            if (!this.isCurrent(session))
                return;
            const pre = await this.checkPrereqs(engine, session);
            if (!this.isCurrent(session))
                return;
            session.lavdNoNeo4j = engine !== "pvd" && pre !== null && !pre.neo4jAlive;
            // An explicit UI snapshot always wins over mutable shared settings.
            const dir = requestedDir !== undefined
                ? requestedDir || fallbackDir
                : pre?.rtlDir || fallbackDir;
            if (!dir)
                throw new Error("没有可扫描的目录，请填写扫描目标目录或打开一个 RTL 工程。");
            session.dir = dir;
            this.log(`[OK] 本次扫描目标目录：${dir}`);
            const result = await backend.api.startScan(session.base, dir, engineFlags(engine), session.abort.signal);
            if (!this.isCurrent(session))
                return;
            session.id = result.scan_id;
            session.state = "running";
            this.scanId = result.scan_id;
            this.rtlDir = dir;
            this.post({ type: "data", kind: "progress", payload: {
                    phase: "running", scanId: result.scan_id, text: `扫描已启动 ${result.scan_id}`,
                } });
            this.startPolling(session);
        }
        catch (e) {
            if (!this.isCurrent(session))
                return;
            session.state = "error";
            const msg = String(e?.message ?? e);
            this.post({ type: "data", kind: "progress", payload: { phase: "error", text: msg } });
            this.status(`扫描启动失败：${msg}`, "error");
        }
    }
    /**
     * 解析默认扫描目录：当前编辑器文件所在目录 → 工作区根 → 项目根。
     * 只在面板打开 / 重新可见时调用一次，结果定格在 openDir（不随后续切换
     * 活动文件变化）；后端设置里的 rtl_dir 非空时优先于此默认（见 runScan）。
     */
    defaultScanDir() {
        const active = vscode.window.activeTextEditor?.document;
        if (active && active.uri.scheme === "file") {
            return path.dirname(active.uri.fsPath);
        }
        const folders = vscode.workspace.workspaceFolders;
        if (folders && folders.length > 0)
            return folders[0].uri.fsPath;
        return backend.resolveProjectRoot();
    }
    startPolling(session) {
        if (!this.isCurrent(session))
            return;
        this.stopPolling();
        this.pollTimer = setTimeout(() => void this.pollOnce(session), 1000);
    }
    stopPolling() {
        if (this.pollTimer) {
            clearTimeout(this.pollTimer);
            this.pollTimer = undefined;
        }
    }
    async pollOnce(session) {
        if (!this.isCurrent(session) || !session.id || session.state !== "running")
            return;
        this.pollTimer = undefined;
        try {
            const st = await backend.api.status(session.base, session.id, session.abort.signal);
            if (!this.isCurrent(session))
                return;
            this.post({ type: "data", kind: "log", payload: { lines: st.logs ?? [], progress: st.progress ?? 0 } });
            if (st.state === "running")
                return;
            session.state = "finishing";
            if (st.state === "done") {
                await this.afterScanDone(session);
            }
            else {
                session.state = "error";
                this.post({ type: "data", kind: "progress", payload: { phase: "error", text: "扫描异常终止，详情见上方日志。" } });
                this.status("扫描异常终止。可展开进度卡查看日志，常见原因是 Neo4j 未启动或 RTL 目录不可读。", "error");
            }
        }
        catch (e) {
            if (!this.isCurrent(session))
                return;
            session.state = "error";
            const msg = String(e?.message ?? e);
            this.post({ type: "data", kind: "progress", payload: { phase: "error", text: msg } });
            this.status(`轮询失败：${msg}`, "error");
        }
        finally {
            if (this.isCurrent(session) && session.state === "running")
                this.startPolling(session);
        }
    }
    /** 扫描完成：拉报告 → 整包推给前端出「报告就绪」提示条 → 挂波浪线 → 进度卡收尾 */
    async afterScanDone(session) {
        const id = session.id;
        const rep = await backend.api.report(session.base, id, session.abort.signal);
        if (!this.isCurrent(session))
            return;
        session.state = "done";
        if (rep.rtl_dir)
            this.rtlDir = rep.rtl_dir;
        // 报告数据整包推一次；autoExpand=false → 前端只渲染「报告就绪」提示条，
        // 用户点「查看报告」后才铺开合并版报告卡（不再逐条弹 finding 卡）
        this.post({ type: "data", kind: "report", payload: { ...rep, autoExpand: false } });
        // 面板外联动：源码波浪线
        if (this.rtlDir) {
            try {
                this.diagnostics.setFindings(rep.findings, this.rtlDir);
            }
            catch (e) {
                this.log(`[WARN] 波浪线标注失败：${String(e?.message ?? e)}`);
            }
        }
        this.post({
            type: "data",
            kind: "progress",
            payload: { phase: "done", total: rep.findings.length, scanId: id },
        });
        // 复盘：LAVD 跑了但 Neo4j 不在线、结果为 0 —— 把「为什么是 0」说透，别让报告空着就完
        if (rep.findings.length === 0 && session.lavdNoNeo4j) {
            this.status("本次扫描 0 条发现，且扫描期间 Neo4j 未连接：VerilogLAVD 走了降级路径，" +
                "该结果不可作为「代码安全」的依据。启动 Neo4j 后重新扫描即可恢复完整检测。", "warn", "scanzero");
        }
        // 扫描收尾后刷新头部徽章，Neo4j / API Key 状态跟随后端最新探测结果
        await this.pushSettings();
    }
    /* ================================================================ *
     * 依赖图
     * ================================================================ */
    /**
     * 拉取本次扫描的模块依赖图推给前端。
     * focus（来自报告行内「查看依赖图」按钮）带上该 finding 的 module / file，
     * 前端据此在图里高亮对应模块节点 —— 后端协议不变，只是响应包上多个展示层字段。
     */
    async showGraph(base, focus) {
        if (!this.scanId) {
            this.status("还没有扫描结果。先点击「启动并扫描」跑一次检测。", "warn");
            return;
        }
        const session = this.session;
        if (!session?.id)
            return;
        try {
            const g = await backend.api.graph(session.base, session.id, session.abort.signal);
            if (!this.isCurrent(session))
                return;
            this.post({
                type: "data",
                kind: "graph",
                payload: { ...g, scanId: session.id, focus: focus ?? null },
            });
        }
        catch (e) {
            if (this.isCurrent(session))
                this.status(`依赖图不可用：${String(e?.message ?? e)}`, "warn");
        }
    }
    /* ================================================================ *
     * 修复建议
     * ================================================================ */
    /**
     * 生成修复建议。
     *
     * 命中缓存时直接回 cached:true，前端只做滚动定位，**不重复请求**（省 token）。
     * 失败时回 failed:true，前端降级成启发式模板建议。
     */
    async genFix(base, findingId) {
        if (!findingId) {
            this.status("请指定 finding 编号，例如「修复 F-001」。", "warn");
            return;
        }
        if (!this.scanId) {
            this.status("还没有扫描结果，无法生成修复建议。", "warn");
            return;
        }
        const session = this.session;
        if (!session?.id)
            return;
        const id = session.id;
        const key = `${session.base}:${id}:${findingId}`;
        if (this.fixRequests.has(key))
            return;
        const cached = this.fixCache.get(key);
        if (cached) {
            this.post({
                type: "data",
                kind: "fix",
                payload: { scanId: id, findingId, cached: true, finding: cached },
            });
            return;
        }
        try {
            const request = backend.api.fix(session.base, id, findingId, session.abort.signal);
            this.fixRequests.set(key, request);
            const r = await request;
            if (!this.isCurrent(session))
                return;
            this.fixCache.set(key, r.finding);
            this.post({
                type: "data",
                kind: "fix",
                payload: { scanId: id, findingId, cached: false, finding: r.finding },
            });
        }
        catch (e) {
            if (!this.isCurrent(session))
                return;
            // 降级：把失败原因交给前端，由前端用本地模板拼建议并标注「LLM 不可用」
            this.post({
                type: "data",
                kind: "fix",
                payload: { scanId: id, findingId, cached: false, failed: true, error: String(e?.message ?? e) },
            });
        }
        finally {
            this.fixRequests.delete(key);
        }
    }
    /* ================================================================ *
     * 原生联动：跳源码
     * ================================================================ */
    async openFile(p) {
        const file = p?.file;
        if (!file)
            return;
        const abs = path.isAbsolute(file)
            ? file
            : this.rtlDir
                ? path.join(this.rtlDir, file)
                : file;
        try {
            const doc = await vscode.workspace.openTextDocument(vscode.Uri.file(abs));
            const editor = await vscode.window.showTextDocument(doc, { preview: false });
            const line0 = Math.max(0, (p?.line ?? 1) - 1);
            const pos = new vscode.Position(line0, 0);
            editor.selection = new vscode.Selection(pos, pos);
            editor.revealRange(new vscode.Range(pos, pos), vscode.TextEditorRevealType.InCenter);
        }
        catch (e) {
            this.status(`无法打开 ${file}：${String(e?.message ?? e)}`, "warn");
        }
    }
}
exports.CslRtlSeccheckPanelProvider = CslRtlSeccheckPanelProvider;
//# sourceMappingURL=panelProvider.js.map