/**
 * Diagnostics API 封装 —— 把 finding 画成源码上的波浪线。
 *
 * 这是面板外仅有的两处原生联动之一（另一处是点「文件:行号」跳转）。
 * severity 映射按需求固定：high→Error / medium→Warning / low→Info。
 */
import * as vscode from "vscode";
import * as path from "path";
import { Finding } from "./backend";

/** 波浪线覆盖整行用的「行尾」列号。VSCode 会自行裁剪，给个够大的值即可。 */
const LINE_END = Number.MAX_SAFE_INTEGER;

function severityOf(s: string): vscode.DiagnosticSeverity {
  switch ((s || "").toLowerCase()) {
    case "high":
      return vscode.DiagnosticSeverity.Error;
    case "medium":
      return vscode.DiagnosticSeverity.Warning;
    case "low":
      return vscode.DiagnosticSeverity.Information;
    default:
      return vscode.DiagnosticSeverity.Information;
  }
}

/** 引擎显示名：后端的 source 是 "veriloglavd"/"veripvd" */
function engineLabel(source?: string): string {
  if (source === "veriloglavd") return "VerilogLAVD";
  if (source === "veripvd") return "VeriPVD";
  return source || "未知引擎";
}

export class DiagnosticsManager implements vscode.Disposable {
  private readonly collection: vscode.DiagnosticCollection;

  constructor() {
    this.collection = vscode.languages.createDiagnosticCollection("cslRtlSeccheck");
  }

  dispose(): void {
    this.collection.dispose();
  }

  /** 每次新扫描开始前清掉上一轮 */
  clear(): void {
    this.collection.clear();
  }

  /**
   * 用一次扫描的 findings 刷新全部波浪线。
   *
   * @param findings 报告里的 findings 数组
   * @param rtlDir   本次扫描的 RTL 根目录 —— finding.location[0].file 通常是
   *                 相对这个目录的路径，需要拼回绝对路径才能挂到文件上
   */
  setFindings(findings: Finding[], rtlDir: string): void {
    this.clear();

    const byFile = new Map<string, vscode.Diagnostic[]>();

    for (const f of findings) {
      const loc = (f.location && f.location[0]) || undefined;
      if (!loc || !loc.file) continue;

      // file 可能是相对路径（相对 rtl_dir），也可能是绝对路径
      const abs = path.isAbsolute(loc.file)
        ? loc.file
        : path.join(rtlDir, loc.file);

      // 后端 line 是 1-based，VSCode 是 0-based
      const line0 = Math.max(0, (loc.line ?? 1) - 1);
      const range = new vscode.Range(line0, 0, line0, LINE_END);

      const msg = [
        `[${f.id}] ${f.description || f.type || "发现安全风险"}`,
        `引擎: ${engineLabel(f.source)}${f.type ? ` · 类型: ${f.type}` : ""}`,
      ].join("\n");

      const diag = new vscode.Diagnostic(range, msg, severityOf(f.severity));
      diag.source = "CSL_RTL_SecCheck";
      diag.code = f.id;

      const list = byFile.get(abs);
      if (list) list.push(diag);
      else byFile.set(abs, [diag]);
    }

    for (const [file, diags] of byFile) {
      this.collection.set(vscode.Uri.file(file), diags);
    }
  }
}
