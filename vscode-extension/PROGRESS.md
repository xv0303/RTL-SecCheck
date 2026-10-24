> 2026-10-22：v0.1.1 已修复目录保存竞态、扫描会话隔离、轮询重叠、后端重复启动、HTTP 响应体超时、修复失败重试、并发报告覆盖、Windows 证据路径和模型服务商路由。
> 外观保持原样（panel.html / panel.css 未变）。目录确认在既有 kind:"settings" 内增加 directoryAck:{requestId,value,ok}；命令扫描经 kind:"ui",action:"startScan" 复用当前面板入口。后端 HTTP 路由及响应结构不变。
> 回归测试在仓库 tests/，详见 TESTING.md；以下为此前交接记录，相关旧实现说明以当前源码为准。

# PROGRESS — csl-rtl-seccheck 交接记录

> 更新时间：2026-10-17（**L1 布局重排已完成，待人工验收**：视图标题栏齿轮
> （view/title, group:navigation）控制「连接与扫描设置」卡开合；扫描目录独立到
> 固定头部、回车/失焦静默保存；原底部操作条整体上移到固定头部，消息流/报告成为
> 唯一滚动区。后端 `POST /api/settings` 的校验范围改为**按 patch 实际字段决定**
> （只含 rtl_dir 时不握手、不联网），`skip_validation` 保留兼容接收但不再决定范围。
> 此前 F5–F10 均已完成，F6/F7/F8/F9/F10 待人工验收；F10 已修复 Neo4j 假在线根因
> （Bolt 范围编码 + SUCCESS/FAILURE 偏移）、保存秒表进度卡 + revision 边界，
> 新增 tools/check_bolt.py 回归工具）

---

## 1. 已完成的工作

### 1.1 侧边栏 UI 重构（前一会话，9/9 自检通过）

- 自由文本输入框已删除（`commandParser.ts` 的自然语言 `parse()` 随之退役，文件现只保留
  `EngineMode` 类型与 `HELP_TEXT` 容错说明）。
- 操作条改为「引擎下拉 + 按钮直选」：切换引擎即时生效，无需确认。
- 报告合并卡 / 行展开详情（证据链、修复建议、依赖图）/ 进度卡取消按钮 / 依赖提示区
  等结构均已落地，9 项自检全部通过。

### 1.2 设置区方案确认结论

- 方案已获用户批准，附一条修改意见（原话）：
  **「可以按照这个方案，但我对设置那块，我认为可以进入时默认当前文件的目录」**
  → 已实现为 `defaultScanDir()`：**当前编辑器文件所在目录 → 工作区根 → 项目根**
  的三级回落；设置区目录输入框的 placeholder 实时显示当前计算出的默认值。
- UI 形态：操作条顶部「连接与扫描设置」**可折叠区**（默认收起），不弹任何窗口。
- 字段：扫描目标目录 / Neo4j URI / 用户名 / 密码 / API Key 共 5 项 + 保存按钮。

### 1.3 rtl_dir 走后端 settings.json 的决策

- 后端 `save_settings` 是 pydantic `SettingsIn` 白名单 + `DEFAULT_SETTINGS ∪ 现有文件`
  的 merge 过滤，因此新增字段只需 **backend/main.py 两行**：
  `DEFAULT_SETTINGS["rtl_dir"] = ""` 与 `SettingsIn.rtl_dir: str | None = None`。
- **路由 / URL / 返回信封 `{settings, has_api_key, neo4j_alive}` 均未改动**，
  读写复用现有 `GET/POST /api/settings`（此项偏离已向用户说明并获确认）。
- 优先级：后端设置 `rtl_dir` 非空 → 优先于扩展端 `defaultScanDir()`；
  为空 → 回落「当前文件目录 / 工作区根」。

### 1.4 四个 F5 验收问题的修复要点

| # | 问题 | 根因 | 修复 |
|---|------|------|------|
| 1 | 「仅PVD」档依赖提示区空白 | renderDepHint 整体隐藏的早退分支 | 去掉早退，改为按行控制：Neo4j 行只在含 LAVD 档显示；API Key 行所有档显示（PVD 档专属文案：LLM 分析跳过、修复建议降级） |
| 2 | 无处配置 Neo4j / API Key / 扫描目录 | 功能缺失 | 新增设置区（见 1.2/1.3），dirty 字段跟踪，只提交动过的字段 |
| 3 | 「查看模块依赖图」点击无效果 | `panel.js` renderGraph 中 `card.insertBefore(btn, body)` 在 body 尚非 card 子节点时调用，抛 DOMException `NotFoundError`（DOM 规范行为），被消息监听器吞掉，图卡永远进不了消息流。按钮 post → 宿主 GET → H→W push 各环节均正常，断点在最后一环渲染 | 调整顺序：先 `card.appendChild(body)` 再 `card.insertBefore(btn, body)`，加注释说明顺序约束。卡头与行内两个入口一并恢复 |
| 4 | 扫描目录来源不明 | 此前无任何 settings 字段控制；链路为 runScan → defaultScanDir()=开发宿主首个工作区文件夹 → POST /api/scan → lavd_bridge 递归 glob `**/*.v`；扫到 demo_soc 是因为工作区=项目根时 glob 命中 `examples/demo_soc` | 与问题 2 合并解决：`rtl_dir` 走后端设置 + 扩展端默认改为当前文件目录（见 1.2/1.3） |

---

## 2. 关键文件清单及当前状态

| 文件 | 状态 | 说明 |
|------|------|------|
| `vscode-extension/media/panel.js` | **已改** | ① renderGraph insertBefore 顺序修复（问题 3）；② renderDepHint 重写（问题 1）；③ 设置区逻辑：el 引用、`setDirty` 脏标记、`renderSettingsFields`/`fillInput` 回填（不覆盖正在编辑/已脏字段）、保存只提交脏字段；④ F6：dirty 清空改为宿主确认（settings 推送 `saved===true` 才清 + 灰显按钮）、`updateSaveBtn` 按钮门控、`checkNeoUriHint` URI 轻量提醒、折叠态改记在 `.settings-sec.open`（齿轮旋转）；⑤ F7：删 `bNeo4j`/`bKey` el 引用与 renderSettings 中的徽章 toggle（状态显示只剩 renderDepHint，读 lastSettings）。`node --check` 通过；⑥ F8：defaultDir 缺省兜底 placeholder 改「留空 = 打开面板时的目录」；⑦ F9：renderDepHint 失败态显示后端分类文案（neo4jHint），API Key 行显示最近一次校验结果（provider/原因 + HH:MM），未保存编辑不影响依赖行；⑧ F10：renderDepHint 成功行显示 `✓ neo4jHint`（带服务端版本，旧后端无文案时回退通用文案）；保存按钮状态机（`saving` 防重 + 文案「保存并校验中…」，error 级 savesettings 卡恢复）；`editRev`/`fieldRev`/`saveRevSnapshot` revision 比对——成功推送只清「保存时已提交且在途未被再编辑」的 dirty；⑨ L1：删 `setToggle`/面板内齿轮，新增 `kind:"ui"` 的 `toggleSettings` 开合设置卡、扫描目录独立状态（`savedRtlDir`/`dirSaving`/`pendingDirValue`）、回车/失焦/点击扫描三处触发静默保存、`rtlDir` 错误卡解除防重、设置卡 dirty 字段去掉 `sRtlDir` |
| `vscode-extension/media/panel.html` | **已改** | 操作条顶部 `settings-sec` 折叠区（setToggle/setBody + 5 输入框 + setSave）；F6：折叠头箭头换 `set-gear` 齿轮 span、Neo4j URI 下新增 `sNeoUriHint` 提示行、保存按钮改 `set-save` 类且默认 `disabled`；F7：**整个 `<header class="phead">` 徽章区删除**、API Key 输入框下新增 `set-note` 常显提示（五家提供商 + Key 须与 llm_model 同家）；⑥ F8：set-note 删「或网页设置页」与「默认 deepseek-chat」、目录输入框 placeholder 改「留空 = 打开面板时的目录」；⑨ L1：结构改为 `header.topbar` + `div#setBody` + `main#flow`，扫描目录独立为头部 `.dir-field`，设置卡移出头部、只剩 Neo4j/API Key 四项，删除面板内 setToggle/齿轮 |
| `vscode-extension/media/panel.css` | **已改** | 设置区样式段；F6 新增：`.set-gear` 齿轮（CSS mask + data-URI SVG，随 currentColor 适配主题，`.settings-sec.open` 时旋转 90°）、`.set-save` 主按钮样式（`--vscode-button-*`，disabled 灰显）、`.uri-warn` 橙框与 `.set-hint` 提示文字；F7：删 `.phead/.ptitle/.badges/.badge` 面板头样式段、新增 `.set-note`（中性灰常显说明，区别于橙色 `.set-hint` 警告）；⑨ L1：`.actionbar` → 固定头部 `.topbar`（border-bottom）、`.flow` 加 `min-height:0` 成为唯一滚动区、`.settings-body` 改为头部下方独立固定卡（`max-height:50vh` 兜底）、删 `.settings-sec/.settings-toggle/.set-gear`、输入框样式泛化为 `.panel input[type=text|password]`、新增 `.dir-field/.set-title` |
| `vscode-extension/src/panelProvider.ts` | **已改** | pushSettings 增加 `values`（api_key 用后端脱敏串；**neo4j_password 不下发前端**，转成布尔 `neo4jPwdSet`）与 `defaultDir`；新增 `saveSettings` cmd 分支；`checkPrereqs` 返回 `rtlDir`；`runScan` 中后端 rtl_dir 优先并写日志「来自后端设置」；`defaultScanDir()` 改为当前文件目录优先；F6：saveSettings 分支 POST 前探测后端、离线则复用 `ensureBackend` 自动拉起（启动日志打到 savesettings 单例卡）、`fetch failed` 翻译成人话、`pushSettings(markSaved)` 保存成功回推 `saved:true`；⑥ F8：新增 `openDir` 字段（resolveWebviewView + 面板重新可见时 `defaultScanDir()` 定格快照），`pushSettings` 的 `defaultDir` 与 `runScan` 目录解析改用快照，不再实时跟随活动文件；⑦ F9：新增 `lastApiKeyCheck` 字段（保存时校验结果 + HH:MM），保存分支按 `validation` 渲染分项校验卡（失败黄卡逐项列表），pushSettings payload 加 `neo4jHint`/`apiKeyCheck`，veripvdPath 同步带 `skip_validation:true`，checkPrereqs Neo4j 警告卡带分类原因；⑧ F10：saveSettings 分支 POST 阶段加秒表单例卡（每秒「已 Ns」原地更新，结束/异常 clearInterval）、绿卡 neoPart 改用 `neo.message`（带版本）、黄/红卡末尾加「修改后可再次点保存重试」、后端启动失败红卡同样加重试提示；⑨ L1：新增 `isViewReady()/toggleSettings()`（视图未就绪记 `pendingToggle`，ready 后补发）、`pendingDirSave` 目录保存串行化 + `runScan` 等待/失败中止、`saveRtlDirQuiet`（成功不出卡，失败红卡 tag:rtlDir）、`ackDirSaved`（复用最近一次 settings payload 回推，不 GET/不握手）、保存结果卡按 `validation` 实际分项渲染（不再误报未校验项） |
| `vscode-extension/src/backend.ts` | **已改** | `api.saveSettings` 返回类型补 `has_api_key` / `neo4j_alive`；F9：加 `CheckResult` 类型、返回体补 `neo4j_reason`/`validation`、GET 超时 5s→15s、POST 超时 10s→30s；F10：CheckResult kind 注释补 `version`（Bolt 版本不兼容）；⑨ L1：`saveSettings` 返回类型改为 `neo4j_alive?`/`neo4j_reason?` 可选（只含 rtl_dir 的 patch 不返回），注释写明 validation 分项按 patch 字段决定 |
| `vscode-extension/src/commandParser.ts` | **已改** | HELP_TEXT 增加设置区一行说明 |
| `vscode-extension/src/extension.ts` | **已改** | L1：注册 `cslRtlSeccheck.toggleSettings`（视图未就绪先 `focus`，再调用 provider；全程不弹窗）；deactivate 进程回收逻辑维持原样 |
| `vscode-extension/package.json` | **已改** | L1：`contributes.commands` 新增 `cslRtlSeccheck.toggleSettings`（title「连接与扫描设置」）；`contributes.menus.view/title` 注册齿轮按钮（`when: view == cslRtlSeccheck.panel`、`group: navigation`）；视图名/容器未动。**2026-10-17 修复**：`icon: "$(gear)"` 从菜单项移到 `contributes.commands`（VS Code 的 view/title 工具栏图标取自 `command.icon`，菜单项 schema 不含 icon 字段，放在菜单里不生效 → 齿轮不显示） |
| `backend/main.py` | **已改** | F5：`DEFAULT_SETTINGS` 与 `SettingsIn` 各加 `rtl_dir`。F9：删 `_neo4j_alive()` 换 `_neo4j_check()`（stdlib Bolt 握手+认证，分类 refused/auth/format/timeout/unknown）、加 `_api_key_check()`（五家 GET /models 零 token 校验）、GET/POST 加 `neo4j_reason`/`validation`、`SettingsIn` 加 `skip_validation`（协议例外二）。F10：**`_bolt_handshake` 版本协商换官方驱动同款范围编码**（旧式定版被 Neo4j 5.x 断连，根因见 4.1.4/历史坑清单）；SUCCESS/FAILURE 判定剥离 struct 标记（b1 70/b1 7f，兼容裸 0x70/0x7f）；`_bolt_server_version()` 从 SUCCESS metadata 提取版本入 ok 文案；noagree 独立分类 `version`（「Bolt 版本不兼容」）；协商版本号 / 失败原始响应前 16 字节经 `_diag()` 打 stdout（进 service.log）；GET/POST 的 `neo4j_reason` 成功也带文案（见约束 7 例外二 F10 修订）。**L1**：`set_settings` 改为按 patch 实际字段决定校验范围（仅含 `rtl_dir`/`veripvd_path` 等 → 不校验、不握手不联网；含 `neo4j_*` → 只校验 Neo4j；含 `api_key` → 只校验 API Key），`validation`/`neo4j_alive`/`neo4j_reason` 按实际校验项返回；`skip_validation` 保留兼容接收但不再决定范围（核实结论见 4.1.5）。`py_compile` 通过 |
| `backend/tools/check_bolt.py` | **新增** | Bolt 握手回归工具（需真实 Neo4j）：`backend` 模式直接调 `main._neo4j_check`（用 backend venv 跑）、`raw` 模式纯 stdlib 重放官方驱动同款握手+HELLO、`oldstyle` 模式复现旧式 offers 被 5.x 断连的根因。2026-10-16 实测三模式全符合预期 |
| `backend/settings.json` | 未改 | 现存真实 api_key（sk-6f…c1c）、neo4j_password、neo4j_uri=bolt://localhost:8848；load 时自动并入 `rtl_dir:""` 默认值 |

**编译/校验结果**：`npm run compile` EXIT=0（期间出现一次 TS2588 `const dir` 不可重赋值，已改 `let` 并复编译通过）；`node --check panel.js` OK；panel.html 标签配对全匹配；`python -m py_compile main.py` OK。
**L1 校验**：`npm run compile` EXIT=0；`node --check media/panel.js` OK；`package.json` JSON 解析 OK；`panel.html` 标签配对 OK；`python -m py_compile backend/main.py` OK；后端字段范围校验用 mock 实测：`rtl_dir`-only → 0 次握手/联网、`neo4j_*`-only → 仅 Neo4j、`api_key`-only → 仅 API Key、`veripvd_path+skip_validation` → 0 次校验、掩码 key → 0 次校验。

---

## 3. 硬性约束全文（后续开发必须继续遵守）

1. **禁弹窗 API**：禁用 `showQuickPick` / `showInformationMessage` / `showErrorMessage` /
   `withProgress` / `createWebviewPanel`。一切交互反馈走面板消息流内的状态卡。
2. **fix 双缓存 + 降级**：宿主持有 `fixCache`（Map，键 `${scanId}:${findingId}`），
   命中缓存回 `cached:true` 只做滚动定位、**不重复请求后端**（省 token）；
   生成失败回 `failed:true`，由前端降级为启发式本地模板建议并标注「LLM 不可用」；
   无 api_key 时后端 fixgen 也不调 LLM，直接走降级路径。**修复只给建议，不生成补丁**。
3. **spawn 参数**：`python -E -s -u -m uvicorn --app-dir <backendDir> main:app
   --host 127.0.0.1 --port 8321`，`cwd=backendDir`，`detached:false`（不 unref），
   `windowsHide:true`，`stdio:["ignore","pipe","pipe"]`；**不用 start.bat**
   （它会弹控制台窗口、开浏览器、末尾 pause）。stdout/stderr 追加写 `backend/service.log`。
4. **deactivate 进程回收**：只杀本扩展自己 spawn 的进程（`spawnedPid` 非空才动手），
   `taskkill /PID <pid> /T /F` + 5 秒兜底 guard；attach 到已运行后端时绝不插手。
5. **消息协议**：W→H `{type:"cmd", cmd, payload}`；H→W `{type:"data", kind, payload}`
   （kind ∈ settings/status/log/progress/report/graph/fix）。新增设置类 cmd 也走现有信封格式。
   **例外（L1）**：H→W 新增 `kind:"ui"`，消息体用**顶层 `action`**（不套 payload）：
   `{type:"data", kind:"ui", action:"toggleSettings"}`，仅用于视图标题栏齿轮开合设置卡
   （见约束 7 例外三）。
6. **Webview 无 fetch 无 innerHTML**：Webview 内不做任何 HTTP 请求（HTTP 全在宿主，
   经全局 fetch + AbortController 超时封装）；DOM 渲染只用 `textContent` / `createElement`。
7. **后端 API 协议不改**：路由、URL、返回结构不动；设置读写用现有
   `GET/POST /api/settings`。已确认例外（均纯增量，旧字段全部保留，旧消费者
   忽略未知字段不受影响）：
   - 例外一（F5）：main.py 为 `rtl_dir` 加的两行字段定义；
   - 例外二（F9，2026-10-16 用户放行；F10 修订语义）：`GET /api/settings`
     返回体加 `neo4j_reason`（分类文案）；`POST /api/settings` 返回体加
     `neo4j_reason` + `validation: {neo4j, api_key}`（保存后用新配置现场试连的
     分类结果）；`SettingsIn` 加可选入参 `skip_validation`（扩展端 veripvdPath
     后台同步传 true 跳过联网校验，避免每次面板打开都打一次 LLM 网关；
     用户保存缺省 = 校验）。
     **F10 修订**：`neo4j_reason` 成功时不再返回空串，而是带成功文案
     「Neo4j 在线（<版本>，握手+认证通过）」—— 依赖行据此显示服务端版本；
     旧消费者只在失败时读该字段，不受影响。
   - 例外三（L1，2026-10-17 用户放行）：① H→W 消息新增
     `{type:"data", kind:"ui", action:"toggleSettings"}`（kind 为 `ui`，`action` 在
     顶层、不套 payload），仅用于视图标题栏齿轮开合设置卡；属 **Webview 消息协议
     扩展**，后端路由/URL/返回结构零改动。② **`POST /api/settings` 的 validation
     范围由 patch 实际字段决定**：含 `neo4j_uri/user/password` → 只校验 Neo4j；含
     `api_key` → 只校验 API Key；只含 `rtl_dir` / `veripvd_path` 等 → 不校验（不握手、
     不联网）。响应中 `neo4j_alive` / `neo4j_reason` 仅在执行 Neo4j 校验时出现，
     `validation` 只含实际校验过的分项；`skip_validation` 保留兼容接收但**不再决定
     范围**。**这是 L1 的刻意规则，不是后续无意引入的协议变更**，验收/排查时不要
     按 F9 的「总是两项校验」理解。
8. **脱敏哨兵**：GET /api/settings 返回的 api_key 为 `前4位 + "****" + 后4位`；
   POST 时 api_key 值**包含 "****" 子串**即视为未修改、不覆盖真实 key（backend/main.py
   L113/L123 的实际实现；用户口述的 "********" 即指此哨兵）。neo4j_password 虽被后端
   明文返回，但**宿主不下发 Webview**，只转成布尔 `neo4jPwdSet`，前端密码框仅显示
   placeholder「已配置（输入新值可覆盖）/ 未配置」。

---

## 4. 待办与已知问题

### 4.1 实施进度

- 4 个问题的修复代码**全部改完**（8 处编辑，见第 2 节），编译与语法校验全绿。
- **F6 设置区三项改进已改完**（本轮，用户验收反馈）：
  1. **保存时 "fetch failed"**：根因是后端未运行（扩展此前只在扫描时拉起后端）。
     saveSettings 分支 POST 前先 `isAlive` 探测，离线则复用 `ensureBackend` 自动
     拉起（已在线直接 POST，不重复 spawn）；启动日志打到 savesettings 单例状态卡
     （避免凭空多出一张进度卡）；仍失败时把 "fetch failed" 翻译为
     「无法连接后端（URL），请查看 backend/service.log」。
  2. **dirty 清空时机**：前端点击保存不再立即清 dirty；宿主保存成功后
     `pushSettings(true)` 回推 `saved:true`，前端收到才清 dirty + 灰显按钮；
     失败/普通推送（saved 缺省）保留 dirty，可直接再点保存重试。
     （settings 消息 payload 新增可选字段 `saved`，不新增 kind，不违反约束 5）
  3. **保存按钮 dirty 门控**：默认 disabled，任一字段改动才启用；保存成功回到
     灰显。「设置无变更」提示仅作兜底。
  4. **齿轮图标**：折叠头改为「⚙ 齿轮 + 连接与扫描设置」，齿轮用 CSS mask +
     data-URI 内联 SVG（随主题变色、无图片文件、无 innerHTML），展开时旋转 90°。
  5. **保存按钮主按钮样式**：`--vscode-button-*` 蓝底白字加粗撑满设置区，
     disabled 灰显。
  6. **Neo4j URI 轻量提醒（仅提醒不拦截）**：非 `bolt://` 开头提示格式；端口为
     7687 时额外提示「默认端口为 7687，请确认与 Neo4j Desktop 显示一致」（本机
     实际 bolt 端口为 7787）。输入框橙框 + 字段下方橙色小字，input 时与回填后
     均会刷新。
- 编译校验：`npm run compile` EXIT=0；`node --check media/panel.js` OK。
- 已知注意事项：**若 8321 端口仍有旧后端进程在跑，验收前必须先停掉** —— main.py
  改过，旧进程不认识 `rtl_dir` 字段，POST 会被 pydantic 白名单丢弃；F5 后由扩展
  自动拉起新后端即可。

### 4.1.1 F7（顶部徽章删除 + API Key 提示）改动记录

- 用户需求（原意）：① 设置区 API Key 提示用户该输入哪些 AI 的 Key —— **只列
  VeriPVD 支持的五家**（DeepSeek / 通义Qwen / OpenAI GPT / Claude / Gemini，
  与 `engines.py _provider_of` 一致），不新增其他提供商、不加模型/Base URL 字段；
  ② 顶部 Neo4j / API Key 徽章删除（底部依赖提示区已有同样的状态信息）。
- 实现：panel.html 删 `<header class="phead">` 整块、API Key 框下加 `.set-note`
  常显提示（含「Key 须与后端 llm_model 同一家（默认 deepseek-chat）」的说明，
  因为后端按模型名选网关，Key 与模型不同家会静默失败）；panel.js 删 bNeo4j/bKey
  引用与 toggle；panel.css 删面板头样式段、加 `.set-note`（中性灰）。
- **settings 推送里的 `neo4jAlive` / `hasApiKey` 字段保留未动** —— renderDepHint
  经 lastSettings 消费它们，是删徽章后唯一的状态显示。
- 校验：`node --check media/panel.js` OK；panel.html 标签配对全匹配；
  无 TS 改动，无需重编译。

### 4.1.2 F8（提示文案 + 默认目录定格）改动记录

- 用户需求（原意）：① 设置区 API Key 提示里「可在 backend/settings.json 或网页
  设置页修改」删掉「或网页设置页」，只保留 backend/settings.json；② 扫描目标
  目录默认值改为**打开面板那一刻的目录**（不再实时跟随活动文件变化）。
- 实现：
  - `panel.html`：set-note 文案删「或网页设置页」与「默认 deepseek-chat」；目录
    输入框 placeholder 改为「留空 = 打开面板时的目录」。
  - `panel.js`：defaultDir 缺省时的兜底 placeholder 同步改为同一文案。
  - `panelProvider.ts`：新增 `openDir` 字段；`resolveWebviewView` 与
    `onDidChangeVisibility(visible)` 两处调用 `defaultScanDir()` **定格**快照
    （面板重新可见 = 再次打开 → 重新定格）；`pushSettings` 的 `defaultDir`
    与 `runScan` 的目录解析改用 `openDir`。`defaultScanDir()` 本身（当前文件
    目录 → 工作区根 → 项目根的三级回落）未动，只是调用时机从"每次现算"改为
    "打开时定格一次"。顺带修正了 onDidChangeVisibility 处过期的「刷新徽章」
    注释（徽章 F7 已删）。
- 优先级链不变：后端设置 `rtl_dir` 非空 → 优先于 `openDir` 快照；快照为空
  （打开时无文件无工作区）→ runScan 报「没有可扫描的目录」错误卡。
- 校验：`npm run compile` EXIT=0；`node --check media/panel.js` OK。

#### F8 需人工验收场景

27. 展开设置区 → API Key 提示末尾只提 backend/settings.json，不再出现
    「或网页设置页」；
28. 打开某 .v 文件 → 打开面板 → 目录留空直接扫描 → 目标 = 该文件所在目录
    （与 F5 行为一致）；
29. **保持面板开着**，切换到另一个目录的 .v 文件 → placeholder 与扫描目标
    **不变**（仍为打开面板时定格的目录）；
30. 关闭面板再重新打开（或切走再切回该视图）→ 默认目录重新定格为当前
    活动文件所在目录；
31. 后端 rtl_dir 配置了固定路径时 → 仍优先于面板快照（回归，同场景 11）。

### 4.1.3 F9（保存设置即时校验）改动记录

- 用户需求（原意）：保存设置时用**刚提交的新配置**立即试连并报明确错误——
  ① Neo4j 做 bolt 连接 + 认证，失败按原因分类（10061 被拒 / 认证失败 /
  超时与无法解析给原始摘要截断 200 字）；② API Key 做零 token 的 GET /models
  轻量联网校验，网络不通则降级为格式校验并注明「未联网验证」；③ 校验失败
  配置照常持久化、不回滚、不阻塞保存，黄卡（红卡留给保存动作本身失败）；
  ④ 每次保存都用新配置现场重算，不得复用旧探测结果；⑤ 依赖行失败态给
  可行动提示，不要只显示 ✗。
- **stale 假在线问题（同源修复）**：旧 `_neo4j_alive()` 只做 TCP 端口探测，
  密码错也报「在线」；API Key 只看「是否配置」，存了坏 Key 仍一路 ✓。
  两者即用户遇到的「改错密码/端口后仍显示两个依赖可用」的根因。
- 后端 `main.py`：
  - `_neo4j_alive()` 整体删除，所有调用点（GET/POST /api/settings、
    _scan_worker 预检）统一换 `_neo4j_check(uri, user, password)`，不留两套；
  - 纯 stdlib 手写最小 Bolt 握手（`_bolt_handshake`：magic 0x6060B017 +
    版本协商 offer 5.0/4.4/4.3/3.0 → HELLO basic 认证 → SUCCESS/FAILURE），
    分类 kind ∈ ok/refused/auth/format/timeout/unknown，文案按用户指定；
    整体 try/except、socket 超时 5s、未预期解析异常归 unknown + 原始摘要；
    版本协商带 3.0（0x00030000 无歧义编码）兜底，4.x/5.x 编码不认也能回落；
  - `_api_key_check(api_key, llm_model)`：按 `_provider_of` 定五家 provider，
    GET 各家 /models（Bearer / x-api-key+anthropic-version / x-goog-api-key），
    10s 超时；401/403 → 认证被拒文案（提示 Key 与 llm_model 同家）；网络不通
    → 格式校验 + 「未联网验证：<原因>」；
  - GET 加 `neo4j_reason`；POST 加 `neo4j_reason` + `validation`；`SettingsIn`
    加 `skip_validation`（协议例外二，见第 3 节约束 7）。
- 扩展端：`backend.ts` 加 `CheckResult` 类型、GET 超时 5s→15s（握手余量）、
  POST 超时 10s→30s（联网校验最坏 ~15s）；`panelProvider.ts` 新增
  `lastApiKeyCheck`（最近一次保存的 API Key 校验 + HH:MM），保存成功后按
  `validation` 渲染 savesettings 单例卡（全过 → info「设置已保存，Neo4j 在线；
  API Key 校验通过（deepseek）」；有失败 → **黄卡**「设置已保存，但以下校验
  未通过：」逐项列表）；`pushSettings` payload 加 `neo4jHint`（GET 现场握手，
  无 stale）与 `apiKeyCheck`（保存时算，依赖行显示「最近一次校验结果（HH:MM）」）；
  veripvdPath 后台同步带 `skip_validation: true`；`checkPrereqs` 的 Neo4j 警告卡
  有分类原因时优先显示原因。
- 前端 `panel.js`：`renderDepHint` 重写 —— Neo4j 失败行显示 `neo4jHint` 分类
  文案（端口被拒 → 检查端口与 Neo4j Desktop 一致；认证失败 → 检查用户名/密码）；
  API Key 行按最近校验结果显示「✓ 校验通过（provider，HH:MM）」/
  「✓ 已配置（未联网验证，HH:MM）」/「✗ 校验失败：<原因>（HH:MM）」。
  **未保存的编辑不影响依赖行**（读 lastSettings，保存推送后才刷新）——按用户
  指定的边界行为。
- 实测记录（2026-10-16）：mock Bolt 服务器三场景（SUCCESS/FAILURE 认证带原始
  code/垃圾响应归 unknown）全过；真实 DeepSeek key GET /models → 校验通过；
  假 key → 401 认证被拒；断网模拟 → 格式校验 + 未联网验证。真机 Neo4j 当时
  未启动（8848 被拒分类正确），**SUCCESS/认证失败两路径待用户开 Neo4j 后
  按场景 33/34 验收**。
- 校验：`py_compile` OK；`npm run compile` EXIT=0；`node --check panel.js` OK。
  8321 上的旧后端进程（PID 38676）已按约定杀掉，验收时由扩展自动拉起新版。

#### F9 需人工验收场景

32. 后端离线 → 改设置点保存 → 自动拉起后端（savesettings 卡，同场景 13）→
    保存后黄/绿卡给出**分类**校验结果（不再只有「在线/未连接」二值）；
33. Neo4j Desktop 已启动、URI/密码正确 → 保存 → 绿卡「Neo4j 在线（握手+认证
    通过）」，依赖行「✓ Neo4j 运行中（握手+认证通过）」；
34. **密码故意改错** → 保存 → 黄卡「设置已保存，但以下校验未通过：· Neo4j：
    Neo4j 认证失败：请检查用户名/密码…」；依赖行同步显示分类文案（非裸 ✗）；
    `backend/settings.json` 中错误密码**已持久化**（不回滚）；改回正确密码再保存
    → 恢复绿卡（**stale 修复核心场景**：保存后立即按新配置重算）；
35. 端口故意改成未监听端口（如 9999）→ 保存 → 分类为「连接被拒：请检查端口
    （当前 bolt://localhost:9999）与 Neo4j Desktop 显示是否一致」；
36. API Key 填一个错误 Key → 保存 → 黄卡「API Key：校验失败：认证被拒
    （deepseek），请确认 Key 与 llm_model 同家」；依赖行「✗ API Key 校验失败：
    …（HH:MM）」；改回正确 Key → 保存 → 绿卡 + 依赖行「✓ 校验通过
    （deepseek，HH:MM）」；
37. 断网（或网关不可达）保存 → 黄/绿卡 API Key 部分显示「已配置（格式检查
    通过，未联网验证：<原因>）」，不算校验失败；
38. 只改扫描目录保存（不动 Neo4j/Key）→ 卡上仍给出两项校验结果（按已存配置
    现算）；打开面板不产生任何联网校验动作（只有保存才打网关）；
39. 正在编辑设置输入框（未保存）→ 依赖行不随输入实时变化（维持已保存配置的
    状态，用户指定的边界行为）；
40. 扫描时 Neo4j 离线 → 进度日志的 WARN 带分类原因（同 4.1 问题 1 链路回归）。

### 4.1.4 F10（Neo4j 假在线根因修复 + 保存进度/边界改进）改动记录

- **用户报告**：Neo4j 端口改成正确的 7787（`server.bolt.listen_address=:7787`）
  后保存，依赖行仍检测不到；用户怀疑「设置没写入文件、只是个启动按钮」。
- **排查结论**（2026-10-16 实测链）：
  1. 设置**确实写入了文件**（settings.json 中 neo4j_uri=bolt://localhost:7787），
     「不写文件」的怀疑排除；
  2. 7787 确实在监听、neo4j.conf 确认 bolt 绑定 7787、DBMS 日志
     「Bolt enabled on localhost:7787」启动正常（Neo4j 5.3.0 enterprise，
     http=7475，routing=7689，集群口 5001/6001/7001）；
  3. **真 neo4j 驱动连 7787 成功**（连接+认证全过），我们的握手被断连 ——
     问题在手写握手的版本协商编码；
  4. 决定性对比：同一条件下重放官方驱动的协商字节 → 立即得版本响应
     `00 00 00 05` + HELLO SUCCESS；发我们的旧式定版 offers → 0 字节断连。
- **根因**：Neo4j 5.x 服务端只认「范围编码」新式版本协商；旧实现发的
  `0x00050000/0x00040400/…` 定版 offers 被直接挂断。**连带 bug**：真实服务端
  SUCCESS/FAILURE 消息带 struct 标记（`b1 70 <map>` / `b1 7f <map>`），旧实现
  在偏移 0 找裸 `0x70/0x7F`，即便协商过了认证结果也会误判 unknown。
  （此前 F9 的 mock 三场景全过没暴露：mock 也按裸 0x70 写的。）
- **修复**（main.py `_bolt_handshake`）：
  - 版本协商 16 字节换成官方 neo4j Python 驱动 5.x `get_handshake()` 同款：
    `00 00 01 FF | 00 08 08 05 | 00 02 04 04 | 00 00 00 03`
    （v2 协商清单标记 / Bolt 5.x 范围 / 4.2–4.4 / 3.0），与官方驱动兼容面一致；
  - SUCCESS/FAILURE 判定先剥 struct 标记（保留裸 0x70/0x7f 兼容分支），
    `_parse_bolt_failure` 相应从 `resp[2:]` 读 map；
  - `_bolt_server_version()` 从 SUCCESS metadata 的 server 字段取版本
    （如 `Neo4j/5.3.0` → `5.3.0`）；
  - 协商成功版本号打日志；noagree（服务端回 00000000）独立分类 `version`
    「Bolt 版本不兼容」，不与 unknown 混用；
  - 握手失败的原始响应前 16 字节 hex / 0 字节断连（"0 bytes, connection
    closed"）经 `_diag()` 打 stdout → 扩展拉起时进 backend/service.log；
  - `_neo4j_check` ok 文案带版本：「Neo4j 在线（5.3.0，握手+认证通过）」；
    GET/POST 的 `neo4j_reason` 成功也带文案（约束 7 例外二 F10 修订）。
- **保存进度 + 边界改进**（用户 8 点补充之 6/7/8）：
  - panelProvider saveSettings：POST 阶段秒表单例卡（「正在保存并校验设置…
    已 Ns（Neo4j 握手 + API Key 联网校验，最长约 15 秒）」每秒原地更新，
    成功/异常 clearInterval；后端离线时的启动日志卡不受影响——秒表只在
    ensureBackend 之后启动）；绿卡 neoPart 改用 `neo.message`（带版本）；
    黄卡（校验未通过）与红卡（保存失败/后端启动失败）末尾加
    「修改后可再次点保存重试。」；
  - panel.js 保存按钮状态机：点击即 disabled + 文案「保存并校验中…」防重；
    恢复路径 = settings 推送 `saved===true`（成功）或 error 级 savesettings
    卡到达（失败，dirty 保留可重试）；info/warn 卡不恢复（秒表卡/黄卡伴随
    saved:true 推送）；
  - revision 边界修复：`editRev`（每次输入 +1）/`fieldRev[id]`（字段最后编辑
    时的 revision）/`saveRevSnapshot`（点保存时定格）。成功推送清 dirty 前比对：
    只清 `fieldRev[id] <= saveRevSnapshot` 的字段 —— **保存在途期间的新编辑
    不被误清**，dirty 保留、值在输入框里，可直接再点保存补交。
- **回归工具**：`backend/tools/check_bolt.py`（见第 2 节表）。
- 实测记录（2026-10-16）：`backend` 模式 `_neo4j_check(bolt://localhost:7787)`
  → ok=True，message「Neo4j 在线（5.3.0，握手+认证通过）」；`raw` 模式重放
  → 协商 00000005 + HELLO SUCCESS（server=Neo4j/5.3.0）；`oldstyle` 模式 →
  「connection closed after 0/4 bytes」根因复现。`py_compile` OK；
  `npm run compile` EXIT=0；`node --check panel.js` OK。
- ⚠️ **8321 旧后端（PID 32320）未杀**（权限拦截，需用户手动处理）：旧进程
  不含握手修复，验收前先 `taskkill /PID 32320 /T /F` 或重启 VSCode，
  由扩展自动拉起新版。

#### F10 需人工验收场景

41. （四连测·正确配置）杀掉旧后端 → 打开面板 → 保存设置 → 绿卡
    「设置已保存，Neo4j 在线（5.3.0，握手+认证通过）；…」；依赖行
    「✓ Neo4j 在线（5.3.0，握手+认证通过）」—— **F9 场景 33 的真修复**；
42. （四连测·密码错）密码改错保存 → 黄卡「Neo4j：Neo4j 认证失败：请检查
    用户名/密码…」+ 末行「修改后可再次点保存重试。」；错误密码已持久化
    不回滚；service.log 有 `[BOLT] auth failure, raw head: …`；
43. （四连测·端口错）端口改 9999 保存 → 黄卡分类「连接被拒：请检查端口…」；
44. （四连测·Neo4j 停用）Neo4j Desktop 停止 DBMS 后保存/打开面板 →
    连接被拒（或超时）分类；重新启动 DBMS → 恢复 ✓；
45. （扫描回归）配置正确时启动扫描 → 预检不再出 Neo4j 假失败警告卡，
    LAVD 正常出 findings（不再走降级 0 条路径）；
46. （stale 终验）打开面板依赖行实时反映 Neo4j 真实状态：外部启停 DBMS
    后切走再切回面板（触发 onDidChangeVisibility 重推）→ 状态随真实变化；
47. （保存进度）后端在线时点保存 → 消息流出现「正在保存并校验设置…已 Ns…」
    秒表卡每秒原地更新，结果出来后原地变绿/黄卡，不堆叠；保存按钮全程
    灰显「保存并校验中…」，结束后恢复「保存设置」；
48. （防重）保存进行中重复展开设置区 → 按钮不可点；
49. （revision 边界）点保存后 15 秒内再改一个字段（如扫描目录）→ 保存成功
    后该字段仍为 dirty（按钮可点），再点保存只提交该字段；
50. （失败重试）断网/后端不可达时保存 → 红卡带「修改后可再次点保存重试。」
    → 按钮恢复可点、改动保留，环境恢复后直接再点保存成功。

### 4.1.5 L1（布局重排 + 目录独立保存 + 字段范围校验）改动记录

- **用户需求（原意）**：顶部固定头部（扫描目录 / 引擎 / 依赖提示 / 启动扫描），
  消息流与报告成为其下唯一滚动区；视图标题栏最右侧齿轮（view/title +
  ThemeIcon gear）开合「连接与扫描设置」卡；设置卡不再含扫描目录；目录独立
  输入框，回车/失焦静默保存（成功不出卡，失败才出错误卡）；扫描仍读后端已保存
  的 rtl_dir，不新增参数。
- **协议**：H→W 新增 `kind:"ui"` + 顶层 `action:"toggleSettings"`（例外三）；
  W→H 不新增 cmd；`saveSettings` 现有 cmd 增加可选 payload `silent:true`
  （目录静默保存用，不新增消息类型）。
- **布局实现**：`panel.html` 改为 `header.topbar`（目录字段 + 引擎 + depHint +
  scanBtn）+ `div#setBody`（头部下方固定设置卡，默认 hidden）+ `main#flow`
  （`flex:1; min-height:0; overflow-y:auto`）。`panel.css` 删除 `.actionbar` /
  `.settings-sec` / `.settings-toggle` / `.set-gear`，新增 `.topbar` /
  `.dir-field` / `.set-title`，输入框样式泛化到 `.panel input[type=text|password]`。
  设置卡 `max-height:50vh; overflow-y:auto` 兜底。展开状态只存 Webview 内存，
  不持久化；`retainContextWhenHidden` 下切走再切回仍保持（仍属本会话）。
- **齿轮**：`package.json` 注册命令 + `view/title` 菜单（navigation、`$(gear)`）；
  `extension.ts` 命令处理器在视图未就绪时先 `focus`；`panelProvider.toggleSettings()`
  在视图未解析或 `webviewReady===false` 时记 `pendingToggle`，收到 Webview `ready`
  后先于 `pushSettings` 补发（ready 前的 postMessage 可能丢失），避免点击无反应。
- **目录静默保存**：前端 `saveDirIfChanged()`（Enter / blur / 点击扫描三处触发；
  `dirSaving` 防重、`savedRtlDir` 比对避免无变更请求），post
  `saveSettings {rtl_dir, silent:true}`。宿主 `saveRtlDirQuiet()`：
  `isAlive` → 必要时静默 `ensureBackend` → `POST {rtl_dir}`；成功用
  `ackDirSaved()` 复用最近一次 settings payload 回推确认（**不 GET、不握手**），
  失败才发 `status(..., "error", "rtlDir")`。前端收到确认推送清 `dirSaving`，
  收到 `rtlDir` 红卡也清（允许重试）。保存成功不产生任何状态卡。
- **扫描竞态**：宿主 `pendingDirSave: Promise<boolean>` 串行化；`runScan` 开头
  await 它，**失败则中止扫描**并更新 `rtlDir` 红卡（「本次扫描已中止：未使用旧
  目录继续」）；前端点击扫描前也先调 `saveDirIfChanged()`，覆盖「Enter 保存中
  立刻点扫描」与「此前保存失败后直接点扫描」两种路径。扫描请求体不变。
- **后端字段范围校验（核实结论）**：`skip_validation` **确实存在**（F9 引入，
  `SettingsIn` 字段；PROGRESS 例外二有记录），但其原语义只是 `validate=False`
  跳过整个 `validation` 块，**Neo4j 握手仍无条件执行**（旧实现 L396
  `neo = _neo4j_check_of(s)`），与「目录保存不握手」的要求不一致，故未采用它
  决定范围。现 `set_settings` 改为：
  - `touched_neo = any(neo4j_uri/user/password in payload)` → 跑 `_neo4j_check_of`，
    返回 `neo4j_alive`/`neo4j_reason` + `validation.neo4j`；
  - `touched_key = "api_key" in payload`（掩码值先被剔除）→ `validation.api_key`；
  - 两者都没有（只含 `rtl_dir` / `veripvd_path` 等）→ 无任何校验/握手/联网，
    响应只有 `{ok, has_api_key}`；`validation` 与 `neo4j_*` 按实际校验项出现。
  - `skip_validation` 仍被接收并从 payload 剔除（兼容旧客户端 / 不落盘），但
    **不再影响校验范围**；扩展端 veripvdPath 同步继续带它仅为兼容旧后端。
  - 扩展端保存结果卡同步按实际分项渲染：只改 Neo4j 时不再误报「API Key 未配置」，
    反之亦然。
- **2026-10-17 齿轮不显示修复**：用户反馈视图标题栏没有齿轮。根因是 `icon: "$(gear)"`
  写在 `contributes.menus["view/title"]` 的菜单项上 —— VS Code 的工具栏图标实际取自
  `contributes.commands[].icon`，菜单项 schema 不支持 icon 字段，因此图标被忽略。
  已把 `"icon": "$(gear)"` 移到 `cslRtlSeccheck.toggleSettings` 命令定义，菜单项只保留
  `command/when/group`。命令处理器、H→W `toggleSettings` 消息链路均未改动。
- **静态校验**：`npm run compile` EXIT=0；`node --check media/panel.js` OK；
  `package.json` JSON 解析 OK；`panel.html` 标签配对 OK；`py_compile main.py` OK。
  后端字段范围用 mock 实测（2026-10-17）：`rtl_dir`-only → 0 次 neo/key 校验；
  `neo4j_*`-only → 仅 neo；`api_key`-only → 仅 key；`veripvd_path+skip_validation`
  → 0 次；掩码 key → 0 次。
- ⚠️ **验收前必须重启 8321 上的旧后端**（main.py 已改；旧进程仍按 F9/F10 语义
  无条件握手）。杀掉旧进程或重启 VSCode，由扩展自动拉起新版。

#### L1 需人工验收场景

51. 视图标题栏最右侧出现齿轮（tooltip「连接与扫描设置」）；点击展开 / 再点收起
    「连接与扫描设置」卡，全程不弹窗；首次打开视图、Webview 尚未 ready 时点击也
    能生效（pendingToggle 补发）。
52. 设置卡只在固定头部下方展开：内容下推、头部四件套位置不变；切走视图再切回
    保持展开（本会话）；重载 VSCode 后默认收起。
53. 设置卡内只有 Neo4j URI / 用户名 / 密码 / LLM API Key / 保存设置，**没有扫描
    目标目录**；API Key 脱敏回显、密码 placeholder 行为不变。
54. 目录静默保存：修改扫描目录 → 回车 → 消息流无成功卡；`backend/settings.json`
    的 `rtl_dir` 已更新；失焦同样生效；未改动直接失焦不产生请求。
55. 目录保存失败：后端不可达且启动失败（如指向错误 backendUrl）→ 出现红色
    「无法连接后端（…），扫描目标目录未保存」卡（不是裸 fetch failed）；输入值
    保留；恢复后再次失焦/回车可重试。
56. 目录输入后**不按回车直接点扫描**：blur 先触发保存，扫描等待保存完成后读取
    新目录（日志「扫描目标目录（来自后端设置）」）。
57. 保存失败中止：在保存失败（或保存中会失败）的情况下点扫描 → 扫描中止，
    红卡注明「本次扫描已中止：未使用旧目录继续」，不进入 running、不用旧目录。
58. 清空目录 → 回车保存 → 扫描回落到打开面板时的默认目录；placeholder 不变。
59. 滚动布局：消息多时只有消息流滚动，顶部目录/引擎/依赖提示/扫描按钮固定；
    报告卡、报告就绪条、行展开区都在消息流内滚动；设置卡超长时自身滚动。
60. 报告流程回归：扫描 → 报告就绪条 → 查看报告 → 高危 chip 定位 → 行展开 →
    证据链 → 依赖图（卡头/行内聚焦）→ 修复建议（缓存命中不重复请求、失败降级）。
61. 字段范围校验（设置卡）：只改 Neo4j URI/用户名/密码 → 保存后绿/黄卡只提
    Neo4j，不再出现「API Key 未配置」；只改 API Key → 只提 API Key；两项都改 →
    两项都提；错误密码/坏 Key 的黄卡与持久化不回滚行为不变。
62. 字段范围校验（接口）：直接 `POST /api/settings {"rtl_dir": "..."}` →
    响应无 `validation`/`neo4j_alive`，`service.log` 无新的 Bolt 诊断；只带
    `neo4j_uri` → 仅 `validation.neo4j`；只带 `api_key` → 仅 `validation.api_key`。
63. veripvdPath 后台同步回归：面板打开/重新可见不产生校验卡、不额外打 LLM 网关
    （patch 只含 `veripvd_path`）。
64. 引擎切档依赖提示、扫描取消按钮、fix 双缓存与降级、脱敏哨兵全部回归不变。

### 4.2 需重新人工验收的场景清单

**问题 3（依赖图）**
1. 扫描完成 → 查看报告 → 报告卡头「查看模块依赖图」→ 消息流渲染图卡（节点+边+图例）；
2. 展开某 finding 行 → 行内「查看依赖图」→ 图卡渲染且对应模块有红色虚线聚焦圈；
3. 两个入口重复点击 → 图卡单例重画不堆叠；「收起依赖图」可折叠；点节点跳源码。

**问题 1（依赖提示）**
4. 引擎切「仅PVD」→ 只显示一行 API Key 状态（已配置 ✓ / 未配置 ✗ 且文案提及
   VeriPVD LLM 分析跳过）；Neo4j 行不出现；
5. 「双引擎」「仅LAVD」→ 两行提示与改动前一致（回归）。

**问题 2/4（设置区与扫描目录）**
6. 打开面板 → 展开设置区 → Neo4j URI/用户名、API Key（形如 `sk-6f****c1c`）回显正确，
   密码框 placeholder 显示「已配置（输入新值可覆盖）」；
7. 改 Neo4j URI 为错误端口 → 保存 → status 卡显示「Neo4j 未连接」、徽章变灰；
   改回 → 保存 → 徽章转绿（验证保存真实生效）；
8. 只改 URI 不动密码/API Key → 保存后 `backend/settings.json` 中 `neo4j_password`、
   `api_key` 保持原值未被清掉；
9. 输入新 API Key → 保存 → 重开面板回显新脱敏串；清空 API Key → 保存 → 徽章 API Key
   变灰，重新输入可恢复；
10. 打开自己测试集里的某个 .v 文件 → 目录留空直接扫描 → 进度卡目标目录 =
    该文件所在目录（placeholder 随当前文件变化）；
11. 设置区填固定测试集路径（如 `C:\Users\99754\Desktop\RTL_Test`）→ 保存 → 无论当前
    打开什么文件/工作区，扫描目标都是该路径，进度卡日志出现
    「扫描目标目录（来自后端设置）」；
12. 清空目录字段 → 保存 → 回到「当前文件目录」默认行为；后端离线时点保存 →
    消息流出现错误状态卡（不弹窗）。

### 4.3 F6（设置区三项改进）需重验场景

**保存自动拉起后端（fetch failed 修复）**
13. 确保后端未运行（重启 VSCode 或先杀掉 8321 进程）→ 展开设置区 → 填入
    Neo4j URI/密码等信息 → 点保存 → savesettings 状态卡先显示「正在自动启动
    后保存…」及启动日志（等待中 x/15），就绪后显示「设置已保存：…」；
    **不应再出现 "fetch failed"**；启动过程不应多出进度卡；
14. 后端已在运行时点保存 → 直接保存成功，不出现「正在自动启动」过程；
15. 人为制造后端不可达（如改 `cslRtlSeccheck.backendUrl` 为错误端口后重启面板）
    → 点保存 → 状态卡显示「无法连接后端（URL）…service.log」或「后端启动
    失败…」（错误卡，不弹窗、不是裸 "fetch failed"）。

**dirty 时机 / 按钮门控**
16. 打开设置区未动任何字段 → 保存按钮灰显不可点；
17. 改任一字段（如只改用户名）→ 按钮变蓝可点 → 保存成功后回到灰显，
    且字段回填为保存后的值；
18. 后端离线时点保存且启动失败 → 重新展开设置区 → 已填的值仍在、按钮仍可点
    （dirty 保留）→ 直接再点保存可重试（后端恢复后应成功）；
19. 只改 URI 不动密码/API Key → 保存后 `backend/settings.json` 中
    `neo4j_password`、`api_key` 保持原值（回归，与场景 8 同）。

**齿轮图标 / 主按钮 / URI 提醒**
20. 折叠头显示「⚙ 连接与扫描设置」，齿轮随主题前景色变色；点击展开时齿轮
    旋转 90°、收起时转回；
21. 保存按钮为蓝底白字加粗、撑满设置区宽度，hover 有高亮；
22. URI 输入 `http://localhost:7687` → 输入框橙框 + 提示「Neo4j URI 通常以
    bolt:// 开头；默认端口为 7687，请确认与 Neo4j Desktop 显示一致」；
    输入 `bolt://localhost:7787` → 提醒消失；提醒出现时仍可正常保存（不拦截）；
23. 后端已保存 `bolt://localhost:7687` 的场景：打开设置区回填后即显示 7687
    提醒（回填路径也会刷新提醒）。

### 4.4 F7 需人工验收场景

24. 打开面板 → **顶部不再有 Neo4j / API Key 徽章**（原 phead 区域整个消失，
    消息流直接从面板顶部开始）；
25. 底部依赖提示区正常显示 Neo4j / API Key 状态（切「仅PVD」只显示 API Key 行，
    切「双引擎」「仅LAVD」显示两行）—— 删徽章后它是唯一状态显示，回归确认；
26. 展开设置区 → API Key 输入框下方常显灰色小字提示（五家提供商 + Key 须与
    llm_model 同家），不随输入变化、不影响保存按钮门控。

---

## 5. 效果图基准文件路径

- `seccheck_settings_open.png` —— 设置区展开状态的基准效果图
- `seccheck_pvd_dep.png` —— 「仅PVD」档依赖提示（API Key 行）的基准效果图

⚠️ **当前状态：两份 PNG 在磁盘上均未找到**（已搜索 Desktop / Documents / Pictures /
RTL-SecCheck 项目目录及历史会话记录，仅文件名出现在交接要求里）。重验收时建议补拍
并存放至 `vscode-extension\docs\`（或与本文件同级），然后更新本节路径。

---

## 6. 历史坑清单（踩过就不会再踩）

### 6.1 Neo4j 5.x 只认「范围编码」的 Bolt 版本协商（F10 根因，2026-10-16）

- **症状**：`_neo4j_check` 报 unknown「connection closed after 0/4 bytes」——
  TCP 连上、发出 20 字节协商后服务端直接断连，0 字节响应。端口/密码/服务全正常
  （真 neo4j 驱动可连），纯粹是协商字节不对。
- **坑**：旧式**定版**编码（`0x00050000` = Bolt 5.0 之类，major<<16|minor<<8）
  会被 Neo4j 5.x 服务端直接挂断，连 00000000（noagree）都不回。**不要**自己拼
  版本号字段。
- **正解**：照抄官方 neo4j Python 驱动 5.x `get_handshake()` 的 16 字节
  （范围编码）：

  ```
  00 00 01 FF   v2 协商清单标记
  00 08 08 05   Bolt 5.x 范围
  00 02 04 04   Bolt 4.2–4.4
  00 00 00 03   Bolt 3.0
  ```

  （完整 20 字节 = magic `60 60 B0 17` + 上述 16 字节；见 `_bolt_handshake` /
  `tools/check_bolt.py`。）
- **服务端响应**：新式编码低两字节是 minor/major（如 `00 00 00 05` = Bolt 5.0）；
  `00 00 00 00` = 一个版本都没谈成（独立分类 version，别归 unknown）。

### 6.2 Bolt 消息带 struct 标记：SUCCESS = `b1 70`，FAILURE = `b1 7f`

- **坑**：在消息偏移 0 直接找裸 `0x70/0x7F` —— 真实服务端永远匹配不上，
  认证成败一律误判 unknown。F9 的 mock 测试没暴露，因为 mock 也按裸 0x70 写的。
- **正解**：`resp[0] == 0xB1` 时签名在 `resp[1]`、消息体从 `resp[2:]` 起；
  保留裸 0x70/0x7f 分支兼容简易 mock。**写协议 mock 前先抓真驱动的字节**
  （`tools/check_bolt.py raw` 模式即当时抓包的产物）。

### 6.3 排查这类「连不上但服务正常」问题的顺序（F10 实操沉淀）

1. netstat 找监听端口 + 归属 PID → `tasklist`/命令行确认进程身份（DBMS 的
   java 命令行里能直接看到 `--config-dir`，去读真实 neo4j.conf）；
2. HTTP GET 探测区分 http/bolt 口（bolt 口对 HTTP 也会挂断，别被假象误导）；
3. **用真驱动连一次**做对照（VerilogLAVD venv 自带 neo4j 包）——真驱动能连、
   手写代码不能连 = 协议实现问题，与服务端无关；
4. 假服务器抓真驱动的原始字节，逐字节对比重放。
