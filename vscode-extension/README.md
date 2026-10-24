# CSL_RTL_SecCheck

RTL 安全检测的 VSCode 侧边栏扩展。扫描、报告和修复建议均在面板内完成，不弹系统通知窗口。

## 功能

- **扫描**：在头部设置扫描目录，选择引擎后点「启动并扫描」。目录回车或失焦时保存；扫描使用点击时的目录。
- **报告**：完成后点「查看报告」，展开表格、来源统计和依赖图入口，不另开标签页。
- **修复**：在 finding 展开行生成文字建议；失败后原按钮可重试，成功结果在当前扫描会话中缓存，不自动应用修改。
- **引擎**：通过头部下拉框选择双引擎、仅 LAVD 或仅 PVD。
- **后端自启**：8321 未监听时自动 spawn uvicorn；关闭 VSCode 时回收自己拉起的进程

## 使用

1. 安装 `csl-rtl-seccheck-0.1.1.vsix`，并使用同一版本的 RTL-SecCheck 后端源码。
2. 点活动栏的盾牌图标打开面板
3. 填写扫描目录、选择引擎并启动扫描；标题栏齿轮可展开连接设置。
4. 进度卡「取消」只停止当前进度跟踪，后端任务可能继续完成。

## 设置

| 设置项 | 默认 | 说明 |
|---|---|---|
| `cslRtlSeccheck.engine` | `both` | 检测引擎：`both` / `lavd` / `pvd` |
| `cslRtlSeccheck.backendUrl` | `http://127.0.0.1:8321` | 后端地址 |
| `cslRtlSeccheck.veripvdPath` | 空 | VeriPVD 仓库路径，非空时同步到后端 |
| `cslRtlSeccheck.projectRoot` | 空 | 项目根目录，留空自动探测 |

## 开发

```bash
npm install
npm run compile
npx @vscode/vsce package
```

按 `F5` 起 Extension Development Host 调试。

## 设计约束

面板内**不使用** `showQuickPick` / `showInformationMessage` / `showErrorMessage` / `withProgress` / `createWebviewPanel`。
唯一的原生联动是点击 `文件:行号` 跳转源码，以及 Diagnostics API 在对应行画波浪线（high→Error / medium→Warning / low→Info）。

Webview 内不发起任何 `fetch`，所有 HTTP 由扩展宿主代理，API Key 不进入 Webview。
