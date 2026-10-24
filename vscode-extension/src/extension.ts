/**
 * 扩展入口。
 *
 * 激活时把对话式侧边栏注册到 cslRtlSeccheck.panel 视图；
 * 停用时回收**本扩展自己拉起的** uvicorn 进程，避免孤儿进程一直占着 8321。
 */
import * as vscode from "vscode";

import { CslRtlSeccheckPanelProvider } from "./panelProvider";
import { DiagnosticsManager } from "./diagnostics";
import * as backend from "./backend";

let provider: CslRtlSeccheckPanelProvider | undefined;
let diagnostics: DiagnosticsManager | undefined;

export function activate(context: vscode.ExtensionContext): void {
  diagnostics = new DiagnosticsManager();
  provider = new CslRtlSeccheckPanelProvider(context, diagnostics);

  context.subscriptions.push(
    diagnostics,

    // 侧边栏面板本体
    vscode.window.registerWebviewViewProvider(
      CslRtlSeccheckPanelProvider.viewId,
      provider,
      {
        webviewOptions: {
          // 切走再切回来不丢消息流，避免重扫
          retainContextWhenHidden: true,
        },
      }
    ),

    // 命令面板入口（只是把侧边栏亮出来，不弹任何对话框）
    vscode.commands.registerCommand("cslRtlSeccheck.openPanel", () => {
      void vscode.commands.executeCommand(`${CslRtlSeccheckPanelProvider.viewId}.focus`);
    }),

    vscode.commands.registerCommand("cslRtlSeccheck.scan", async () => {
      await vscode.commands.executeCommand(`${CslRtlSeccheckPanelProvider.viewId}.focus`);
      provider?.requestScan();
    }),

    // 视图标题栏齿轮（view/title, group=navigation）：只向 Webview 发切换消息，
    // 不弹任何窗口。视图尚未解析时先 focus 把它展开；toggleSettings() 会把
    // 这次点击记成待发意图，等 Webview 的 ready 到达后补发，避免点击无反应。
    vscode.commands.registerCommand("cslRtlSeccheck.toggleSettings", async () => {
      if (!provider?.isViewReady()) {
        await vscode.commands.executeCommand(
          `${CslRtlSeccheckPanelProvider.viewId}.focus`
        );
      }
      provider?.toggleSettings();
    }),

    // 配置 → 面板 的同步方向（引擎下拉在用户没动过时要跟着设置走）
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration("cslRtlSeccheck")) {
        provider?.onConfigChanged();
      }
    })
  );
}

/**
 * 停用扩展时回收后端进程。
 *
 * 注意边界：deactivate() 只在 VSCode 正常退出时被调用。如果 VSCode 被任务管理器
 * 强杀、或者扩展宿主崩溃，这里不会执行，仍可能残留 uvicorn —— 这是已知限制。
 *
 * stopBackend() 内部会检查进程所有权和退出状态：只有本扩展拉起的活跃进程才会被杀，
 * 用户或 Vivado Tcl 已经起好的后端不受影响。
 */
export async function deactivate(): Promise<void> {
  provider?.dispose();
  try {
    await backend.stopBackend();
  } catch {
    /* 停用阶段不抛异常 */
  }
  provider = undefined;
  diagnostics = undefined;
}
