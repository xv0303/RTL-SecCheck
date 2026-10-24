/*
 * 侧边栏的 Webview 端。
 *
 * 职责：
 *   - 渲染消息流：状态卡 / 进度卡 / 「报告就绪」提示条 / 合并版报告卡 / 依赖图卡
 *   - 底部固定操作条：引擎下拉（切换即生效）+ 依赖提示 + 启动并扫描
 *   - 报告卡内每行可展开：完整描述 / 证据链 / 修复建议（loading、降级、缓存都在展开区内）
 *   - 修复建议的会话级展示缓存（命中即展开定位，不发第二次请求）
 *   - LLM 不可用时的本地启发式模板降级
 *
 * 硬约束：全程**不出现 fetch**，所有数据一律经宿主 postMessage 中转
 * （消息协议：W→H {type:"cmd",...}，H→W {type:"data",...}）。
 * 所有文本用 textContent 写入，不拼 innerHTML，finding 描述里的任何字符都进不了 DOM。
 */
(function () {
  "use strict";

  const vscode = acquireVsCodeApi();

  /* ================================================================ *
   * DOM 引用 & 全局状态
   * ================================================================ */

  const $ = (id) => document.getElementById(id);
  const el = {
    flow: $("flow"),
    engineSel: $("engineSel"),
    depHint: $("depHint"),
    scanBtn: $("scanBtn"),
    setBody: $("setBody"),
    setSave: $("setSave"),
    sNeoUriHint: $("sNeoUriHint"),
    sRtlDir: $("sRtlDir"),
    sNeoUri: $("sNeoUri"),
    sNeoUser: $("sNeoUser"),
    sNeoPwd: $("sNeoPwd"),
    sApiKey: $("sApiKey"),
  };

  /** 当前进度卡（同一时刻消息流里只有一张活跃进度卡） */
  let progressCard = null;

  /** 当前依赖图卡（单例：重复查看时移除旧卡重画，不堆叠） */
  let graphCard = null;

  /** 当前报告卡（单例：再次查看时移除旧卡重画） */
  let reportCard = null;

  /** 「报告就绪」提示条（单例；点「查看报告」后让位给完整报告卡） */
  let readyBar = null;

  /** 最近一次报告数据（扫描完成时宿主整包推一次，供「查看报告」就地渲染） */
  let lastReport = null;

  /** 上一次轮询收到的日志行，用于增量追加（后端只回最后 40 行，超出会滑动） */
  let lastLogs = [];

  /** 最近一次 settings 推送（引擎下拉切换时刷新依赖提示用） */
  let lastSettings = {};

  /** 用户是否动过引擎下拉。动过之后配置推送不再覆盖本地选择（切换不回写配置） */
  let engineTouched = false;

  /**
   * 设置区 dirty 标记：input 事件打上、保存提交后清除。
   * 保存时只提交动过的字段 —— 未动过的密码 / API Key 不会被掩码回显值覆盖；
   * 回填时也只覆盖未动过的输入框，不打断正在编辑的用户。
   */
  const setDirty = {};
  // 设置卡只含 Neo4j / API Key 四项；扫描目标目录已独立到固定头部，
  // 走自己的静默保存逻辑（saveDirIfChanged），不参与设置卡的 dirty 门控
  const SET_FIELD_IDS = ["sNeoUri", "sNeoUser", "sNeoPwd", "sApiKey"];

  /**
   * 扫描目标目录：最近一次后端已保存值（settings 推送更新）+ 静默保存状态。
   * 回车 / 失焦时值有变更才 POST {rtl_dir, silent:true}；保存成功由宿主回推
   * settings（不 GET、不握手）来清状态，失败由 tag:"rtlDir" 的 error 卡解除防重。
   */
  let savedRtlDir = "";
  let dirSaving = false;
  let pendingDirValue = null;
  let dirDirty = false;
  let dirRequestId = 0;
  let pendingScan = null;
  let settingsLoaded = false;
  let scanBusy = false;

  /** 保存进行中：按钮禁用 + 文案「保存并校验中…」，防重复提交。
   *  恢复路径：成功 = settings 推送 saved===true；失败 = error 级 savesettings 卡 */
  let saving = false;

  /**
   * 编辑版本号：每次输入 +1；点保存时定格快照。回推清 dirty 前比对 revision ——
   * 在途期间又有新编辑（revision > 快照）的字段不清 dirty，值保留在输入框里，
   * 可直接再点保存补交。修复：成功推送不再误清「保存在途期间」的新编辑。
   */
  let editRev = 0;
  const fieldRev = {};
  let saveRevSnapshot = 0;

  /** 保存按钮门控：保存进行中禁改文案；平时只在有改动（dirty）时可点 */
  function updateSaveBtn() {
    el.setSave.disabled = saving || Object.keys(setDirty).length === 0;
    el.setSave.textContent = saving ? "保存并校验中…" : "保存设置";
  }

  /**
   * Neo4j URI 轻量提醒（仅提醒、不拦截保存）：
   *   - 不以 bolt:// 开头 → 提示 URI 格式
   *   - 端口为 7687 → 提示与 Neo4j Desktop 实际显示的 bolt 端口核对（本机常用非默认端口）
   */
  function checkNeoUriHint() {
    const v = el.sNeoUri.value.trim();
    const hints = [];
    if (v && !/^bolt:\/\//i.test(v)) hints.push("Neo4j URI 通常以 bolt:// 开头");
    if (v && /:7687\/?$/i.test(v)) hints.push("默认端口为 7687，请确认与 Neo4j Desktop 显示一致");
    el.sNeoUri.classList.toggle("uri-warn", hints.length > 0);
    el.sNeoUriHint.textContent = hints.join("；");
    el.sNeoUriHint.style.display = hints.length > 0 ? "" : "none";
  }

  /** findingId → { row, detail, data, btnFix }，行展开与修复建议定位都靠它 */
  const findingRows = new Map();

  /** 已经渲染过修复建议面板的 findingId 集合（配合宿主的会话级缓存） */
  const fixRendered = new Set();

  /* ================================================================ *
   * 小工具
   * ================================================================ */

  /** 建元素。text 一律走 textContent，杜绝注入。 */
  function h(tag, cls, text) {
    const n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text !== undefined && text !== null && text !== "") n.textContent = String(text);
    return n;
  }

  function post(cmd, payload) {
    vscode.postMessage({ type: "cmd", cmd, payload: payload || {} });
  }

  /** 引擎显示名：后端 source 字段是 "veriloglavd"/"veripvd" */
  function engineLabel(source) {
    if (source === "veriloglavd") return "VerilogLAVD";
    if (source === "veripvd") return "VeriPVD";
    return source || "未知引擎";
  }

  /** 过滤 chips 上的引擎短名（规格：全部 17 / LAVD 9 / PVD 8） */
  function chipLabel(source) {
    if (source === "veriloglavd") return "LAVD";
    if (source === "veripvd") return "PVD";
    return source || "其他";
  }

  function sevLabel(s) {
    return { high: "高危", medium: "中危", low: "低危" }[String(s || "").toLowerCase()] || s || "未知";
  }

  /** 严重度排序权重：高危最上 */
  function sevRank(s) {
    const k = String(s || "").toLowerCase();
    return k === "high" ? 0 : k === "medium" ? 1 : 2;
  }

  /** 从一行文字里提取「文件:行号」（.v / .sv / .vh 等），供证据链与图节点跳转 */
  const LOC_RE = /(?:"([^"\r\n]+\.(?:svh|sv|vh|v))"|'([^'\r\n]+\.(?:svh|sv|vh|v))'|([A-Za-z]:[\\/][^<>"|?*\r\n:]+\.(?:svh|sv|vh|v))|((?:[\p{L}\p{N}_./\\-]+[\\/])*[\p{L}\p{N}_.-]+\.(?:svh|sv|vh|v))):(\d+)/u;
  function extractLoc(text) {
    const m = String(text || "").match(LOC_RE);
    if (!m) return null;
    return { file: m[1] || m[2] || m[3] || m[4], line: parseInt(m[5], 10) || 1 };
  }

  /** 消息流滚动：只有当用户本来就贴着底部时才跟随滚动，翻看历史不被打断 */
  function scrollFlow() {
    const f = el.flow;
    if (f.scrollHeight - f.scrollTop - f.clientHeight < 120) {
      f.scrollTop = f.scrollHeight;
    }
  }

  /* ================================================================ *
   * 消息入口（宿主 → Webview）
   * ================================================================ */

  window.addEventListener("message", (ev) => {
    const m = ev.data;
    if (!m || m.type !== "data") return;

    switch (m.kind) {
      case "settings": renderSettings(m.payload || {}); break;
      case "ui":       renderUi(m); break;
      case "status":   renderStatus(m.payload || {}); break;
      case "log":      renderLog(m.payload || {}); break;
      case "progress": renderProgress(m.payload || {}); break;
      case "report":   renderReport(m.payload || {}); break;
      case "graph":    renderGraph(m.payload || {}); break;
      case "fix":      renderFix(m.payload || {}); break;
      default: break; // 未知 kind 静默忽略（协议容错）
    }
    scrollFlow();
  });

  /* ================================================================ *
   * 固定头部：扫描目录 / 引擎下拉 / 依赖提示 / 启动并扫描
   * ================================================================ */

  /**
   * 宿主 UI 指令（L1 例外三：{type:"data",kind:"ui",action:...}）。
   * 目前只有标题栏齿轮的 toggleSettings：开合「连接与扫描设置」卡。
   * 未知 action 静默忽略（协议容错）。
   */
  function renderUi(m) {
    if (m && m.action === "toggleSettings") {
      el.setBody.style.display = el.setBody.style.display === "none" ? "" : "none";
    }
    if (m && m.action === "startScan") startScanFromPanel();
  }

  function renderSettings(p) {
    if (p.directoryAck) {
      const ack = p.directoryAck;
      if (!dirSaving || ack.requestId !== dirRequestId) return;
      dirSaving = false;
      pendingDirValue = null;
      if (!ack.ok) {
        pendingScan = null;
        el.scanBtn.disabled = scanBusy;
        return;
      }
      savedRtlDir = ack.value;
      dirDirty = el.sRtlDir.value.trim() !== savedRtlDir;
      // Acknowledge the submitted snapshot, never overwrite newer text in the input.
      if (pendingScan || document.activeElement !== el.sRtlDir) saveDirIfChanged();
      return;
    }
    if (p.acknowledgementOnly) {
      acknowledgeSettingsSave(p);
      return;
    }
    lastSettings = p;
    settingsLoaded = true;

    // 保存成功的确认推送（saved===true）才清 dirty 并灰显保存按钮；
    // 失败 / 普通推送（缺省）保留 dirty —— 改过的值还在输入框里，可直接再点保存重试。
    // 清 dirty 带 revision 比对：只清「保存时已提交且在途期间未被再次编辑」的字段
    acknowledgeSettingsSave(p);

    // 宿主配置 → 下拉：用户选过的以本地为准。
    if (!engineTouched && p.engine && ["both", "lavd", "pvd"].includes(p.engine)) {
      el.engineSel.value = p.engine;
    }
    renderSettingsFields(p.values || {});
    renderDepHint();
    if (pendingScan && pendingScan.rtlDir === null) pendingScan.rtlDir = el.sRtlDir.value.trim();
    if (pendingScan) saveDirIfChanged();
  }

  function acknowledgeSettingsSave(p) {
    if (p.saved === true) {
      for (const id of Object.keys(setDirty)) {
        if ((fieldRev[id] || 0) <= saveRevSnapshot) delete setDirty[id];
      }
      saving = false;
      updateSaveBtn();
    }

  }

  /** 设置区回填：只覆盖没动过、也没正在聚焦的输入框 */
  function fillInput(input, value) {
    if (setDirty[input.id] || document.activeElement === input) return;
    input.value = value;
  }

  /**
   * 设置区回显。values 由宿主从 GET /api/settings 整理而来：
   * api_key 是后端脱敏串（如 sk-6f****c1c），neo4j 密码不下发、只用
   * placeholder 表达「已配置 / 未配置」（连长度都不透露）。
   */
  function renderSettingsFields(v) {
    // 目录字段的「已保存值」与回填分开处理：即使输入框正被聚焦（fillInput 跳过），
    // 也要更新 savedRtlDir，否则失焦时会误判为未变更
    if (!dirSaving && !dirDirty) {
      savedRtlDir = v.rtlDir || "";
      el.sRtlDir.value = savedRtlDir;
    }
    fillInput(el.sNeoUri, v.neo4jUri || "");
    fillInput(el.sNeoUser, v.neo4jUser || "");
    fillInput(el.sApiKey, v.apiKeyMasked || "");

    if (!setDirty.sNeoPwd && document.activeElement !== el.sNeoPwd) {
      el.sNeoPwd.value = "";
      el.sNeoPwd.placeholder = v.neo4jPwdSet ? "已配置（输入新值可覆盖）" : "未配置";
    }

    const d = lastSettings.defaultDir;
    el.sRtlDir.placeholder = d
      ? `留空 = ${d}`
      : "留空 = 打开面板时的目录";

    checkNeoUriHint();
  }

  /**
   * API Key 依赖行：优先显示「最近一次保存时」的联网校验结果（带 HH:MM，
   * 让人知道这个 ✓ 是何时验的，不是实时）；没验过则只显示配置状态。
   * 注意：读的是 lastSettings（已保存配置的状态），用户正在编辑未保存的
   * 输入不影响这里 —— 保存之后由宿主推送刷新，这是 F9 的验收标准。
   */
  function apiKeyHintSpan(p, unconfiguredText) {
    const ok = !!p.hasApiKey;
    const c = p.apiKeyCheck;
    let text;
    if (ok && c) {
      if (c.ok && c.kind === "offline") {
        text = `✓ API Key 已配置（未联网验证，${c.time}）`;
      } else if (c.ok) {
        text = `✓ API Key 校验通过（${c.provider || "?"}，${c.time}）`;
      } else {
        text = `✗ API Key 校验失败：${c.message}（${c.time}）`;
      }
    } else if (ok) {
      text = "✓ API Key 已配置";
    } else {
      text = "✗ API Key 未配置 —— " + unconfiguredText;
    }
    const cls = ok && (!c || c.ok) ? "dep-ok" : "dep-warn";
    const span = h("span", cls);
    span.textContent = text;
    return span;
  }

  /**
   * 依赖提示：Neo4j / API Key 状态各占一行，缺什么标什么。
   * Neo4j 行只在含 LAVD 的档位出现（仅 PVD 不建图，无此依赖）；
   * API Key 行所有档位都出现 —— 仅 PVD 的 LLM 分析与修复建议依赖它，
   * 其余档位的修复建议同样依赖。
   * Neo4j 两种状态都显示后端分类文案（neo4jHint）：失败 = 可行动原因
   * （端口被拒/认证失败/超时…），成功 = 「在线（5.3.0，握手+认证通过）」；
   * 旧后端成功时不带文案 → 回退通用 ✓ 文案。
   */
  function renderDepHint() {
    const eng = el.engineSel.value;
    const p = lastSettings;
    el.depHint.textContent = "";
    el.depHint.style.display = "";

    const key = apiKeyHintSpan(
      p,
      eng === "pvd"
        ? "VeriPVD 的 LLM 分析将跳过（仅规则模式），修复建议降级为本地模板"
        : "修复建议将降级为本地模板"
    );

    if (eng === "pvd") {
      el.depHint.appendChild(key);
      return;
    }

    const neoOk = !!p.neo4jAlive;
    const neo = h("span", neoOk ? "dep-ok" : "dep-warn");
    neo.textContent = neoOk
      ? (p.neo4jHint ? "✓ " + p.neo4jHint : "✓ Neo4j 运行中（握手+认证通过）")
      : `✗ ${p.neo4jHint || "Neo4j 未启动"} —— LAVD 建图将降级，很可能产出 0 findings`;
    el.depHint.appendChild(neo);

    el.depHint.appendChild(h("br"));
    el.depHint.appendChild(key);
  }

  el.engineSel.addEventListener("change", () => {
    // 切换纯本地生效：立即刷新依赖提示；档位由 startScan 的 engine 参数带上，
    // 不回写配置、没有「应用」按钮
    engineTouched = true;
    renderDepHint();
  });

  function startScanFromPanel() {
    if (el.scanBtn.disabled) return;
    pendingScan = { engine: el.engineSel.value, rtlDir: settingsLoaded || dirDirty ? el.sRtlDir.value.trim() : null };
    el.scanBtn.disabled = true;
    if (settingsLoaded) saveDirIfChanged();
  }
  el.scanBtn.addEventListener("click", startScanFromPanel);

  /* ---- 扫描目标目录：回车 / 失焦静默保存（成功不出卡，失败才出错误卡） ---- */

  function saveDirIfChanged() {
    if (dirSaving || !settingsLoaded) return;
    const v = pendingScan ? pendingScan.rtlDir : el.sRtlDir.value.trim();
    if (v === savedRtlDir) {
      if (pendingScan) {
        const scan = pendingScan;
        pendingScan = null;
        post("startScan", { ...scan, rtlDir: scan.rtlDir || lastSettings.defaultDir || "" });
        if (document.activeElement !== el.sRtlDir && el.sRtlDir.value.trim() !== savedRtlDir) saveDirIfChanged();
      }
      return;
    }
    dirSaving = true;
    pendingDirValue = v;
    dirRequestId++;
    post("saveSettings", { rtl_dir: v, silent: true, requestId: dirRequestId });
  }

  el.sRtlDir.addEventListener("input", () => { dirDirty = true; });

  el.sRtlDir.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      saveDirIfChanged();
    }
  });
  el.sRtlDir.addEventListener("blur", saveDirIfChanged);

  /* ---- 设置卡：dirty 标记 / 保存（只提交动过的字段；开合由标题栏齿轮控制） ---- */

  SET_FIELD_IDS.forEach((id) => {
    el[id].addEventListener("input", () => {
      setDirty[id] = true;
      editRev += 1;
      fieldRev[id] = editRev;
      updateSaveBtn();
      if (id === "sNeoUri") checkNeoUriHint();
    });
  });

  el.setSave.addEventListener("click", () => {
    const patch = {};
    if (setDirty.sNeoUri) patch.neo4j_uri = el.sNeoUri.value.trim();
    if (setDirty.sNeoUser) patch.neo4j_user = el.sNeoUser.value.trim();
    if (setDirty.sNeoPwd) patch.neo4j_password = el.sNeoPwd.value;   // 密码保留原样，不去空格
    if (setDirty.sApiKey) patch.api_key = el.sApiKey.value.trim();
    // 定格编辑版本号：此后发生的编辑不算进本次保存（成功回推时 revision 比对用）
    saveRevSnapshot = editRev;
    saving = true;
    updateSaveBtn();
    post("saveSettings", patch);
    // dirty 不在这里清：等宿主确认保存成功（settings 推送 saved===true）才清，
    // 失败时改动仍标记为 dirty，再次打开设置卡可直接再点保存重试。这里只收起设置卡
    el.setBody.style.display = "none";
  });

  /* ================================================================ *
   * 状态卡
   * ================================================================ */

  /**
   * 状态卡。带 tag 的是「单例」状态卡（如 Neo4j 缺失提示）：同类新卡到达时
   * 原地更新旧卡内容并挪到流底部，而不是再堆一张，避免消息流被重复提示刷屏。
   */
  function renderStatus(p) {
    const level = p.level === "warn" ? "warn" : p.level === "error" ? "error" : "";
    // 保存动作失败（红卡）→ 恢复保存按钮（dirty 保留，改动还在输入框里可直接重试）。
    // 成功路径不走这里（由 settings 推送 saved===true 恢复）；info / warn 不恢复 ——
    // 「校验未通过」黄卡伴随 saved:true 推送到达，按钮已由推送恢复
    if (p.tag === "savesettings" && p.level === "error") {
      saving = false;
      updateSaveBtn();
    }
    // 目录静默保存失败（红卡）→ 解除防重，允许再次回车 / 失焦重试
    let card = p.tag ? el.flow.querySelector('[data-status-tag="' + p.tag + '"]') : null;
    if (!card) {
      card = h("div", "card status-card" + (level ? " " + level : ""));
      if (p.tag) card.dataset.statusTag = p.tag;
      el.flow.appendChild(card);
    } else {
      card.className = "card status-card" + (level ? " " + level : "");
    }
    let pre = card.querySelector("pre");
    if (!pre) {
      pre = h("pre");
      card.insertBefore(pre, card.firstChild);
    }
    pre.textContent = p.text || "";
    const oldActions = card.querySelector(".status-actions");
    if (oldActions) oldActions.remove();
    if (Array.isArray(p.actions) && p.actions.length) {
      const actions = h("div", "status-actions");
      p.actions.forEach((action) => {
        if (!action || !action.id || !action.label) return;
        const btn = h("button", "toggle status-action", action.label);
        btn.type = "button";
        btn.addEventListener("click", () => {
          btn.disabled = true;
          post(action.id);
        });
        actions.appendChild(btn);
      });
      if (actions.childNodes.length) card.appendChild(actions);
    }
  }

  /* ================================================================ *
   * 进度卡
   * ================================================================ */

  /**
   * 保证消息流里有一张进度卡，返回其各部位引用。
   * 后端启动日志（kind:"log" 单行）在进度卡出现之前也会到达，此时先占位建卡。
   */
  function ensureProgressCard() {
    if (progressCard) return progressCard;

    const card = h("div", "card progress-card");
    const titleRow = h("div", "card-title");
    const spinner = h("span", "spinner");
    spinner.style.display = "none";
    const title = h("span", "", "准备中…");
    const cancel = h("button", "toggle", "取消");
    cancel.style.display = "none";
    cancel.addEventListener("click", () => post("cancel"));
    titleRow.appendChild(spinner);
    titleRow.appendChild(title);
    titleRow.appendChild(cancel);

    const bar = h("div", "progress-bar");
    const fill = h("div", "progress-fill");
    bar.appendChild(fill);

    const logBox = h("div", "progress-log");
    logBox.style.display = "none";

    card.appendChild(titleRow);
    card.appendChild(bar);
    card.appendChild(logBox);
    el.flow.appendChild(card);

    progressCard = { card, spinner, title, cancel, fill, logBox };
    return progressCard;
  }

  /** 新一轮扫描：旧进度卡（含日志）整体让位，报告/提示条一并清空 */
  function resetForNewScan() {
    if (progressCard && progressCard.card.isConnected) progressCard.card.remove();
    progressCard = null;
    lastLogs = [];
    clearReportUI();
    if (graphCard && graphCard.isConnected) graphCard.remove();
    graphCard = null;
    el.scanBtn.disabled = false;
  }

  function renderProgress(p) {
    if (p.phase === "starting" || p.phase === "running") scanBusy = true;
    else if (["done", "error", "cancelled"].includes(p.phase)) scanBusy = false;
    if (p.phase === "starting") {
      resetForNewScan();
      el.scanBtn.disabled = true;
    }

    const pc = ensureProgressCard();
    const phase = p.phase;

    if (phase === "starting" || phase === "running") {
      pc.card.className = "card progress-card";
      pc.spinner.style.display = "";
      pc.title.textContent = p.text || (phase === "starting" ? "正在启动扫描…" : "扫描进行中…");
      if (phase === "running") pc.cancel.style.display = "";
    } else if (phase === "done") {
      pc.card.className = "card progress-card done";
      pc.spinner.style.display = "none";
      pc.cancel.style.display = "none";
      pc.title.textContent = `扫描完成（${p.scanId || ""}）`;
      pc.fill.style.width = "100%";
      el.scanBtn.disabled = false;
    } else if (phase === "error") {
      pc.card.className = "card progress-card error";
      pc.spinner.style.display = "none";
      pc.cancel.style.display = "none";
      pc.title.textContent = p.text || "扫描失败";
      el.scanBtn.disabled = false;
    } else if (phase === "cancelled") {
      pc.card.className = "card progress-card cancelled";
      pc.spinner.style.display = "none";
      pc.cancel.style.display = "none";
      pc.title.textContent = "已取消进度跟踪";
      el.scanBtn.disabled = false;
    }

    if (typeof p.progress === "number") pc.fill.style.width = progressWidth(p.progress);
  }

  function progressWidth(value) {
    return `${Math.max(0, Math.min(100, Math.round(value)))}%`;
  }

  /* ================================================================ *
   * 日志（两种形态：单行 line / 轮询批量 lines+progress）
   * ================================================================ */

  function renderLog(p) {
    if (Array.isArray(p.lines)) {
      appendLogLines(p.lines);
      if (typeof p.progress === "number" && progressCard) {
        progressCard.fill.style.width = progressWidth(p.progress);
      }
    } else if (p.line !== undefined) {
      appendLogLines([p.line]);
    }
  }

  /**
   * 增量追加：后端只保留最后 40 行，超出后窗口滑动。
   * 用「上批最后一行在新批中的位置」判断衔接点，衔接不上就整批追加（宁可偶有
   * 重复，不可漏行）。DOM 里最多保留 200 行，防止长扫描把消息流撑爆。
   */
  function appendLogLines(lines) {
    const pc = ensureProgressCard();
    pc.logBox.style.display = "";

    let fresh = lines;
    if (lastLogs.length > 0) {
      const last = lastLogs[lastLogs.length - 1];
      const idx = lines.indexOf(last);
      if (idx >= 0) fresh = lines.slice(idx + 1);
    }
    lastLogs = lines.slice();

    for (const raw of fresh) {
      if (raw === undefined || raw === null) continue;
      pc.logBox.appendChild(formatLogLine(String(raw)));
    }
    while (pc.logBox.childNodes.length > 200) pc.logBox.removeChild(pc.logBox.firstChild);
    pc.logBox.scrollTop = pc.logBox.scrollHeight;
  }

  /** [OK]/[DONE] 绿前缀、[WARN] 橙前缀、[FAIL]/[ERR] 红前缀，其余原色 */
  function formatLogLine(line) {
    const div = h("div");
    const m = line.match(/^\s*\[(OK|DONE|WARN|FAIL|ERR)\]/);
    if (m) {
      const cls = m[1] === "OK" || m[1] === "DONE" ? "ok" : m[1] === "WARN" ? "warn" : "fail";
      const prefix = h("span", cls, m[0]);
      div.appendChild(prefix);
      div.appendChild(document.createTextNode(line.slice(m[0].length)));
    } else {
      div.textContent = line;
    }
    return div;
  }

  /* ================================================================ *
   * 「报告就绪」提示条（扫描完成 → 不自动铺报告，点了才渲染）
   * ================================================================ */

  function removeReadyBar() {
    if (readyBar && readyBar.isConnected) readyBar.remove();
    readyBar = null;
  }

  function renderReadyBar(rep) {
    removeReadyBar();
    const findings = Array.isArray(rep.findings) ? rep.findings : [];
    const total = rep.summary ? rep.summary.total : findings.length;
    const high = rep.summary ? rep.summary.high : findings.filter((f) => f.severity === "high").length;

    const bar = h("div", "card ready-bar");
    bar.appendChild(h("span", "ready-text", `✓ 扫描完成，共 ${total} findings（高危 ${high}）`));
    const btn = h("button", "toggle", "查看报告");
    btn.addEventListener("click", () => {
      removeReadyBar();
      renderReport({ ...(lastReport || rep), autoExpand: true });
    });
    bar.appendChild(btn);

    el.flow.appendChild(bar);
    readyBar = bar;
  }

  /** 再次扫描时清空旧报告 UI（提示条 / 报告卡 / 行索引 / 修复缓存索引） */
  function clearReportUI() {
    removeReadyBar();
    if (reportCard && reportCard.isConnected) reportCard.remove();
    reportCard = null;
    lastReport = null;
    findingRows.clear();
    fixRendered.clear();
  }

  /* ================================================================ *
   * 报告卡（合并版：汇总行 + 高危摘要条 + 过滤 chips + 可展开表格）
   * ================================================================ */

  function renderReport(rep) {
    const findings = Array.isArray(rep.findings) ? rep.findings : [];

    // autoExpand=false：扫描完自动推的那份 → 只出「报告就绪」提示条，数据先存着
    if (!rep.autoExpand) {
      lastReport = rep;
      renderReadyBar(rep);
      return;
    }

    // 单例：重复查看时移除旧卡重画
    if (reportCard && reportCard.isConnected) reportCard.remove();
    removeReadyBar();
    findingRows.clear();
    fixRendered.clear();

    const card = h("div", "card report-card");
    reportCard = card;

    /* --- 汇总行 + 卡头按钮（依赖图 / 收起）--- */
    const total = rep.summary ? rep.summary.total : findings.length;
    const high = rep.summary ? rep.summary.high : findings.filter((f) => f.severity === "high").length;

    const head = h("div", "report-head");
    head.appendChild(h("div", "report-summary",
      `扫描 ${rep.scan_id || ""} · 共 ${total} 条发现（高危 ${high}）`));

    const headBtns = h("div", "report-head-btns");
    // 依赖图是扫描级数据（GET /api/scan/{id}/graph，与单条 finding 无关），
    // 所以卡头保留一个入口（覆盖 0 findings 场景），行内另有带模块聚焦的入口
    const btnGraph = h("button", "toggle", "查看模块依赖图");
    btnGraph.addEventListener("click", () => post("graph", {}));
    headBtns.appendChild(btnGraph);

    const body = h("div", "collapsible open");
    const btnCollapse = h("button", "toggle", "收起报告");
    btnCollapse.addEventListener("click", () => {
      const open = body.classList.toggle("open");
      btnCollapse.textContent = open ? "收起报告" : "展开报告";
    });
    headBtns.appendChild(btnCollapse);
    head.appendChild(headBtns);
    card.appendChild(head);

    /* --- 高危摘要条（红色；每个高危编号独立可点 → 展开并定位对应表格行）--- */
    const highFindings = findings
      .filter((f) => String(f.severity || "").toLowerCase() === "high")
      .sort((a, b) => String(a.id).localeCompare(String(b.id)));
    if (highFindings.length > 0) {
      const bar = h("div", "high-bar");
      bar.appendChild(h("span", "high-bar-text",
        `⚠ 高危 ${highFindings.length} 条（点编号定位）：`));
      for (const f of highFindings) {
        const chip = h("span", "high-bar-id", `${f.id} ↗`);
        const loc = f.location && f.location[0];
        chip.title = `${f.description || ""} ${loc && loc.file ? `（${loc.file}:${loc.line || "?"}）` : ""}`.trim();
        chip.addEventListener("click", () => revealFinding(f.id));
        bar.appendChild(chip);
      }
      card.appendChild(bar);
    }

    /* --- 过滤 chips（来源计数并入 chip 文字，只有这一组）--- */
    const byEngine = (rep.summary && rep.summary.by_engine) || {};
    const tabs = h("div", "pill-tabs");
    const pills = [];

    function makePill(label, filter) {
      const p = h("button", "pill clickable", label);
      p.addEventListener("click", () => {
        pills.forEach((x) => x.classList.remove("on"));
        p.classList.add("on");
        applyFilter(filter);
      });
      pills.push(p);
      tabs.appendChild(p);
      return p;
    }

    makePill(`全部 ${total}`, null).classList.add("on");
    for (const [src, n] of Object.entries(byEngine)) {
      makePill(`${chipLabel(src)} ${n}`, src);
    }
    body.appendChild(tabs);

    /* --- 可展开表格（ID/类型/严重度/描述/位置/来源，高危排最上）--- */
    const table = h("table");
    const thead = h("thead");
    const hr = h("tr");
    ["ID", "类型", "严重度", "描述", "位置", "来源"].forEach((t) => hr.appendChild(h("th", "", t)));
    thead.appendChild(hr);
    table.appendChild(thead);

    const tbody = h("tbody");
    const sorted = findings.slice().sort((a, b) =>
      sevRank(a.severity) - sevRank(b.severity) || String(a.id).localeCompare(String(b.id)));

    for (const f of sorted) {
      buildRowPair(f, tbody);
    }
    table.appendChild(tbody);
    body.appendChild(table);

    if (findings.length === 0) {
      body.appendChild(h("div", "empty-note", "本次扫描未发现问题，或报告为空。"));
    }

    card.appendChild(body);
    el.flow.appendChild(card);

    /* --- 筛选：主行和展开行成对显隐 --- */
    function applyFilter(filter) {
      for (const [, pair] of findingRows) {
        const show = !filter ||
          String((pair.data && pair.data.source) || "").toLowerCase() === String(filter).toLowerCase();
        pair.row.style.display = show ? "" : "none";
        setDetailOpen(pair, show && pair.detailTr.classList.contains("expanded"));
      }
    }
  }

  /**
   * 一个 finding = 主行（摘要）+ 展开行（完整描述 / 证据链 / 修复建议）。
   * 点主行切换展开；展开行初始隐藏。
   */
  function buildRowPair(f, tbody) {
    const sev = String(f.severity || "low").toLowerCase();
    const tr = h("tr", `row ${sev}`);
    tr.appendChild(h("td", "fid", f.id || "?"));
    tr.appendChild(h("td", "", f.type || "—"));
    const tdSev = h("td");
    tdSev.appendChild(h("span", `tag ${sev}`, sevLabel(sev)));
    tr.appendChild(tdSev);
    const tdDesc = h("td", "", f.description || "");
    tdDesc.style.maxWidth = "90px";
    tr.appendChild(tdDesc);
    const loc = f.location && f.location[0];
    const tdLoc = h("td");
    if (loc && loc.file) tdLoc.appendChild(makeLocLink(loc.file, loc.line));
    else tdLoc.textContent = "—";
    tr.appendChild(tdLoc);
    tr.appendChild(h("td", "", engineLabel(f.source)));

    const detailTr = h("tr", "detail-row");
    detailTr.style.display = "none";
    const tdWrap = h("td");
    tdWrap.colSpan = 6;
    const detail = h("div", "row-detail");
    tdWrap.appendChild(detail);
    detailTr.appendChild(tdWrap);

    /* --- 展开区内容 --- */
    detail.appendChild(h("div", "row-desc", f.description || "(无描述)"));
    if (f.description_en) detail.appendChild(h("div", "row-desc", f.description_en));

    if (Array.isArray(f.evidence) && f.evidence.length > 0) {
      const btnEv = h("button", "toggle", "查看证据链");
      const box = h("div", "collapsible");
      f.evidence.forEach((e, i) => box.appendChild(renderChainStep(e, i)));
      btnEv.addEventListener("click", () => {
        const open = box.classList.toggle("open");
        btnEv.textContent = open ? "收起证据链" : "查看证据链";
      });
      detail.appendChild(btnEv);
      detail.appendChild(box);
    }

    const btnFix = h("button", "toggle", "生成修复建议");
    btnFix.dataset.fixState = "idle";
    btnFix.addEventListener("click", () => requestFix(f, btnFix));
    detail.appendChild(btnFix);

    // 依赖图入口也收进行展开区：带上该 finding 的 module/file，
    // 渲染时高亮对应模块节点（后端 graph 是扫描级的，focus 只是前端展示层字段）
    const btnGraph = h("button", "toggle", "查看依赖图");
    btnGraph.addEventListener("click", () => {
      const loc = f.location && f.location[0];
      post("graph", { module: (loc && loc.module) || "", file: (loc && loc.file) || "" });
    });
    detail.appendChild(btnGraph);

    tr.addEventListener("click", () => {
      const pair = findingRows.get(f.id);
      if (pair) setDetailOpen(pair, !pair.detailTr.classList.contains("expanded"));
    });

    tbody.appendChild(tr);
    tbody.appendChild(detailTr);
    findingRows.set(f.id, { row: tr, detailTr, detail, data: f, btnFix });
  }

  /** 展开/收起某行的详情（显隐状态记在 detailTr 的 expanded 类上） */
  function setDetailOpen(pair, open) {
    pair.detailTr.classList.toggle("expanded", open);
    pair.detailTr.style.display = open ? "" : "none";
  }

  /** 展开某行并滚动定位（高危摘要条 / 修复建议定位共用） */
  function revealFinding(id) {
    const pair = findingRows.get(id);
    if (!pair) return;
    setDetailOpen(pair, true);
    pair.row.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  /* ================================================================ *
   * 证据链 / 位置链接
   * ================================================================ */

  /** 证据链单条：编号圆点 + 文字；文字里含「文件:行号」则做成可点链接 */
  function renderChainStep(text, i) {
    const step = h("div", "chain-step");
    step.appendChild(h("span", "n", String(i + 1)));
    const txt = h("div", "txt");
    const s = String(text);
    const loc = extractLoc(s);
    if (loc) {
      const m = s.match(LOC_RE);
      txt.appendChild(document.createTextNode(s.slice(0, m.index)));
      txt.appendChild(makeLocLink(loc.file, loc.line));
      txt.appendChild(document.createTextNode(s.slice(m.index + m[0].length)));
    } else {
      txt.textContent = s;
    }
    step.appendChild(txt);
    return step;
  }

  /** 可点的「文件:行号」，点击 → 宿主 openTextDocument 跳行 */
  function makeLocLink(file, line) {
    const a = h("span", "loclink", `${file}:${line || "?"}`);
    a.title = "点击跳转到源码";
    a.addEventListener("click", () => post("evidence", { file, line: line || 1 }));
    return a;
  }

  /* ================================================================ *
   * 修复建议（平移到行展开区，逻辑不变）
   * ================================================================ */

  function requestFix(f, btn) {
    // 已渲染过 → 直接展开定位，不重复请求（宿主侧另有会话级缓存双保险）
    if (fixRendered.has(f.id)) {
      const pair = findingRows.get(f.id);
      if (pair) {
        const panel = pair.detail.querySelector(".fix-panel");
        if (panel) {
          openFixPanel(pair, panel);
          revealFinding(f.id);
          panel.scrollIntoView({ behavior: "smooth", block: "nearest" });
          return;
        }
      }
    }

    // loading 态：文案 + 防重复点击
    btn.disabled = true;
    btn.textContent = "LLM 分析中（约 10~40 秒）…";
    post("fix", { findingId: f.id });
  }

  function openFixPanel(pair, panel) {
    panel.classList.add("open");
    const toggle = pair.detail.querySelector('[data-fix-toggle="1"]');
    if (toggle) toggle.textContent = "收起修复建议";
  }

  function renderFix(p) {
    if (p.scanId && p.scanId !== (lastReport && lastReport.scan_id)) return;
    const id = p.findingId;
    const pair = findingRows.get(id);
    if (!pair) return;

    // 恢复按钮
    if (pair.btnFix) {
      pair.btnFix.disabled = false;
      pair.btnFix.textContent = p.failed ? "重试生成修复建议" : "查看修复建议";
    }

    // 宿主缓存命中、且本地已渲染过 → 只展开定位
    if (p.cached && fixRendered.has(id)) {
      const panel = pair.detail.querySelector(".fix-panel");
      if (panel) {
        openFixPanel(pair, panel);
        revealFinding(id);
        panel.scrollIntoView({ behavior: "smooth", block: "nearest" });
      }
      return;
    }

    // 已有面板就换内容，没有就新建（「生成修复建议」按钮保留，折叠开关另立）
    let panel = pair.detail.querySelector(".fix-panel");
    if (!panel) {
      panel = h("div", "fix-panel open");
      const toggle = h("button", "toggle", "收起修复建议");
      toggle.dataset.fixToggle = "1";
      toggle.addEventListener("click", () => {
        const open = panel.classList.toggle("open");
        toggle.textContent = open ? "收起修复建议" : "展开修复建议";
      });
      if (pair.btnFix && pair.btnFix.isConnected) {
        pair.detail.insertBefore(toggle, pair.btnFix.nextSibling);
      } else {
        pair.detail.appendChild(toggle);
      }
      pair.detail.appendChild(panel);
    }
    panel.textContent = "";
    openFixPanel(pair, panel);

    if (p.failed) {
      // 降级：本地启发式模板，顶部标注 LLM 不可用
      panel.classList.add("fallback");
      panel.appendChild(h("h4", "", "⚠ LLM 不可用，以下为启发式建议"));
      const body = h("div", "fix-body");
      body.textContent = buildFallbackSuggestion(pair.data, p.error);
      panel.appendChild(body);
      panel.appendChild(h("div", "fix-note", `失败原因：${p.error || "未知"}`));
    } else {
      panel.classList.remove("fallback");
      panel.appendChild(h("h4", "", "修复建议（仅供参考，不生成补丁）"));
      const body = h("div", "fix-body");
      body.textContent = stripCodeFences(p.finding ? p.finding.fix_suggestion : "");
      panel.appendChild(body);
      panel.appendChild(h("div", "fix-note", p.cached ? "（来自本次会话缓存，未重复请求）" : ""));
    }

    if (p.failed) fixRendered.delete(id);
    else fixRendered.add(id);
    revealFinding(id);
    panel.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }

  /**
   * 剥掉所有 ``` 围栏只保留文字 —— 问题说明 / 推荐写法思路 / 修改方向。
   * 这里不显示任何代码块与补丁。
   */
  function stripCodeFences(md) {
    return String(md || "")
      .replace(/```[^\n]*\n?/g, "")   // 开闭围栏整行剥掉，围栏内文字保留
      .replace(/``/g, "")
      .replace(/`([^`\n]+)`/g, "$1")  // 行内代码标记只留内容
      .trim();
  }

  /** LLM 不可用时的三段式启发式模板 */
  function buildFallbackSuggestion(f, err) {
    const sev = sevLabel(f && f.severity);
    const type = (f && (f.type || f.id)) || "未知类型";
    const desc = (f && f.description) || "";
    const loc = f && f.location && f.location[0];
    const where = loc && loc.file ? `${loc.file}${loc.line ? ":" + loc.line : ""}` : "见证据链";

    return [
      `【问题说明】`,
      `本条为${sev}级别的 ${type} 风险。${desc}`,
      ``,
      `【建议方向】`,
      `• 优先检查 ${where} 处的赋值/判断逻辑，确认敏感信号是否可能被意外路径改写或旁路。`,
      `• 若涉及复位/置位端（如 scan chain、TAP 相关逻辑），确认其是否仅由可信状态机驱动。`,
      `• 若为权限流问题，检查跨模块边界的数据流是否经过充分的访问控制。`,
      ``,
      `【涉及位置】`,
      `${where}。具体触发路径见该 finding 的证据链逐条说明。`,
    ].join("\n");
  }

  /* ================================================================ *
   * 依赖图卡（力导向布局 + SVG）
   * ================================================================ *
   * 布局：圆形初始化，之后迭代
   * 「斥力（所有点两两互斥）+ 弹簧力（边把两端拉近）+ 向心力（往画布中心收）」，
   * 每步位移限幅，防止爆炸。侧栏宽度窄，画布按卡片实际宽度缩放。
   */

  function renderGraph(g) {
    const nodes = Array.isArray(g.nodes) ? g.nodes.slice() : [];
    const edges = Array.isArray(g.edges) ? g.edges : [];
    if (nodes.length === 0) {
      renderStatus({ text: "依赖图不可用：本次扫描没有模块依赖数据。", level: "warn" });
      return;
    }

    const card = h("div", "card graph-card");
    const title = h("div", "card-title", `模块依赖图（${nodes.length} 个模块）`);
    card.appendChild(title);

    // 行内「查看依赖图」带来的聚焦目标：先按 module 名匹配，再退回文件名匹配
    const focus = g.focus || null;
    const focusModule = focus ? String(focus.module || "") : "";
    const focusFile = focus && focus.file
      ? String(focus.file).replace(/\\/g, "/").split("/").pop().toLowerCase()
      : "";
    const isFocus = (n) =>
      (!!focusModule && String(n.id) === focusModule) ||
      (!!focusFile && String(n.file || "").replace(/\\/g, "/").split("/").pop().toLowerCase() === focusFile);

    // 单例：重复「查看依赖图」时移除旧卡重画（图可能随新扫描变化），消息流里只有一张
    if (graphCard && graphCard.isConnected) graphCard.remove();
    graphCard = card;

    /* --- 画布 + 图例整体放进折叠区，默认展开，可收起 --- */
    const body = h("div", "collapsible open");
    const btn = h("button", "toggle", "收起依赖图");
    btn.addEventListener("click", () => {
      const open = body.classList.toggle("open");
      btn.textContent = open ? "收起依赖图" : "展开依赖图";
    });

    const wrap = h("div", "graph-wrap");
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    wrap.appendChild(svg);
    body.appendChild(wrap);

    const legend = h("div", "graph-legend");
    legend.appendChild(h("span", "", "● 高危模块"));
    legend.appendChild(h("span", "", "○ 带发现的模块"));
    legend.appendChild(h("span", "", "· 无发现模块"));
    if (g.meta && g.meta.truncated) {
      legend.appendChild(h("span", "", `（已截断，共 ${g.meta.total_modules} 个模块）`));
    }
    body.appendChild(legend);

    // 先把 body 挂进 card，再把折叠按钮插到它前面 —— insertBefore 的参照节点
    // 必须已是子节点，反过来调会抛 NotFoundError，图卡就永远进不了消息流
    card.appendChild(body);
    card.insertBefore(btn, body);

    el.flow.appendChild(card);

    /* --- 画布尺寸：跟着卡片实际宽度走 --- */
    const W = Math.max(220, Math.min(340, card.clientWidth - 22));
    const H = Math.max(180, Math.min(260, Math.round(W * 0.75)));
    svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
    svg.setAttribute("width", W);
    svg.setAttribute("height", H);

    /* --- 力导向迭代 --- */
    const R = Math.min(W, H) * 0.38;
    nodes.forEach((n, i) => {
      const a = (2 * Math.PI * i) / nodes.length;
      n.x = W / 2 + R * Math.cos(a);
      n.y = H / 2 + R * Math.sin(a);
    });

    const idx = new Map(nodes.map((n, i) => [n.id, i]));
    const MAX_STEP = 4;
    for (let iter = 0; iter < 260; iter++) {
      const fx = new Array(nodes.length).fill(0);
      const fy = new Array(nodes.length).fill(0);

      // 斥力：两两互斥，距离越近推得越狠
      const REP = 1400;
      for (let i = 0; i < nodes.length; i++) {
        for (let j = i + 1; j < nodes.length; j++) {
          let dx = nodes[i].x - nodes[j].x;
          let dy = nodes[i].y - nodes[j].y;
          let d2 = dx * dx + dy * dy;
          if (d2 < 1) d2 = 1;
          const f = REP / d2;
          const d = Math.sqrt(d2);
          fx[i] += (dx / d) * f; fy[i] += (dy / d) * f;
          fx[j] -= (dx / d) * f; fy[j] -= (dy / d) * f;
        }
      }
      // 弹簧力：边把两端拉近
      const K = 0.02, IDEAL = Math.min(W, H) / 3;
      for (const e of edges) {
        const a = idx.get(e.source), b = idx.get(e.target);
        if (a === undefined || b === undefined) continue;
        const dx = nodes[b].x - nodes[a].x;
        const dy = nodes[b].y - nodes[a].y;
        const d = Math.max(1, Math.sqrt(dx * dx + dy * dy));
        const f = K * (d - IDEAL);
        fx[a] += (dx / d) * f; fy[a] += (dy / d) * f;
        fx[b] -= (dx / d) * f; fy[b] -= (dy / d) * f;
      }
      // 向心力 + 位移限幅 + 应用
      const GX = 0.008, GY = 0.008;
      nodes.forEach((n, i) => {
        let dx = fx[i] + (W / 2 - n.x) * GX;
        let dy = fy[i] + (H / 2 - n.y) * GY;
        dx = Math.max(-MAX_STEP, Math.min(MAX_STEP, dx));
        dy = Math.max(-MAX_STEP, Math.min(MAX_STEP, dy));
        n.x += dx; n.y += dy;
      });
    }

    /* --- 绘制 --- */
    const NS = "http://www.w3.org/2000/svg";
    const sevColor = (n) =>
      n.max_sev === "high" ? "var(--red)" : n.findings ? "var(--orange)" : "rgba(127,127,127,.55)";

    for (const e of edges) {
      const a = idx.get(e.source), b = idx.get(e.target);
      if (a === undefined || b === undefined) continue;
      const line = document.createElementNS(NS, "line");
      line.setAttribute("x1", nodes[a].x); line.setAttribute("y1", nodes[a].y);
      line.setAttribute("x2", nodes[b].x); line.setAttribute("y2", nodes[b].y);
      line.setAttribute("stroke", "rgba(127,127,127,.35)");
      line.setAttribute("stroke-width", "1");
      svg.appendChild(line);
    }

    for (const n of nodes) {
      const r = 4 + Math.min(6, n.findings || 0);
      const g1 = document.createElementNS(NS, "g");
      g1.setAttribute("class", "gnode");

      const c = document.createElementNS(NS, "circle");
      c.setAttribute("cx", Math.max(r, Math.min(W - r, n.x)));
      c.setAttribute("cy", Math.max(r, Math.min(H - r, n.y)));
      c.setAttribute("r", r);
      // 高危实心红；带发现的实心橙；无发现的灰描边空心
      if (n.max_sev === "high") {
        c.setAttribute("fill", sevColor(n));
      } else if (n.findings) {
        c.setAttribute("fill", sevColor(n));
      } else {
        c.setAttribute("fill", "none");
        c.setAttribute("stroke", sevColor(n));
        c.setAttribute("stroke-width", "1");
      }
      g1.appendChild(c);

      // 聚焦节点：红色虚线外圈，行内「查看依赖图」定位到该 finding 所在模块
      if (focus && isFocus(n)) {
        const ring = document.createElementNS(NS, "circle");
        ring.setAttribute("cx", c.getAttribute("cx"));
        ring.setAttribute("cy", c.getAttribute("cy"));
        ring.setAttribute("r", r + 3.5);
        ring.setAttribute("fill", "none");
        ring.setAttribute("stroke", "var(--red)");
        ring.setAttribute("stroke-width", "1.5");
        ring.setAttribute("stroke-dasharray", "3 2");
        g1.appendChild(ring);
      }

      const t = document.createElementNS(NS, "text");
      t.setAttribute("x", Math.max(r, Math.min(W - r, n.x)) + r + 2);
      t.setAttribute("y", Math.max(r, Math.min(H - r, n.y)) + 3);
      t.setAttribute("font-size", "8.5");
      t.setAttribute("fill", "var(--muted)");
      t.textContent = n.id;
      g1.appendChild(t);

      // 点模块 → 跳源码
      if (n.file) g1.addEventListener("click", () => post("evidence", { file: n.file, line: 1 }));
      svg.appendChild(g1);
    }
  }

  /* ================================================================ *
   * 启动
   * ================================================================ */

  post("ready");
})();
