"""双引擎适配器：以子进程方式调用本地克隆的 VerilogLAVD / VeriPVD。

设计原则:
- 原仓库保持只读，不改它们的代码。
- 每个适配器任何一步失败都只降级（返回 warning），绝不中断整个扫描。
- 引擎路径、Python 解释器等都在 settings.json 里配置（见 settings 模块）。
"""
from __future__ import annotations

import glob
import json
import os
import subprocess
import sys

from unify import from_veriloglavd, from_veripvd


def _provider_of(model: str) -> str:
    m = (model or "").lower()
    if m.startswith("deepseek"):
        return "deepseek"
    if m.startswith("qwen"):
        return "qwen"
    if m.startswith("gpt") or m.startswith("o1") or m.startswith("o3"):
        return "gpt"
    if m.startswith("claude"):
        return "claude"
    if m.startswith("gemini"):
        return "gemini"
    return "deepseek"


def _run(cmd: list[str], cwd: str | None, env_extra: dict | None = None, timeout: int = 1800):
    """执行子进程，返回 (returncode, stdout+stderr)。编码问题在 Windows 上一律容错。"""
    # Strip PYTHON* variables: when the backend is launched from Vivado's Tcl,
    # the inherited environment contains PYTHONHOME/PYTHONPATH pointing at
    # Vivado's bundled Python 3.8, which breaks engine venvs with
    # "AssertionError: SRE module mismatch". Engine venvs are self-contained.
    env = {k: v for k, v in os.environ.copy().items()
           if not k.upper().startswith("PYTHON")}
    if env_extra:
        env.update(env_extra)
    p = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, timeout=timeout)
    out = (p.stdout or b"").decode("utf-8", errors="replace") + (p.stderr or b"").decode("utf-8", errors="replace")
    return p.returncode, out


# ================= VeriPVD =================
# 流程: 生成临时 config.yaml → 依次 run_single.py 三个模块 → 解析 outputs JSON
def run_veripvd(rtl_dir: str, scan_dir: str, settings: dict, api_key: str | None):
    logs, findings, warnings = [], [], []

    base = settings.get("veripvd_path", "")
    if not os.path.isdir(base):
        return findings, [f"VeriPVD path not configured or missing: '{base}' (set it in the web Settings page)"]
    py = settings.get("veripvd_python")
    if not py:
        cand = os.path.join(base, ".venv", "Scripts", "python.exe")
        py = cand if os.path.isfile(cand) else sys.executable

    scope = os.path.basename(scan_dir)
    out_root = os.path.join(scan_dir, "veripvd_out")
    cfg_path = os.path.join(scan_dir, "veripvd_config.yaml")
    rel_base = os.path.relpath  # noqa

    # 1) 生成 config（相对路径由 VeriPVD 从其项目根解析，这里用绝对路径最稳）
    llm_model = settings.get("llm_model", "deepseek-chat")
    provider = _provider_of(llm_model)
    cfg = (
        "inputs:\n"
        f"  - scope_id: {scope}\n"
        f"    rtl_dir: {json.dumps(rtl_dir)}\n"
        f"llm:\n"
        f"  provider: {provider}\n"
        f"  model: {llm_model}\n"
        f"output_dir: {json.dumps(out_root)}\n"
    )
    with open(cfg_path, "w", encoding="utf-8") as f:
        f.write(cfg)
    logs.append(f"[VeriPVD] config written: {cfg_path}")

    # 2) API key 通过环境变量传递（VeriPVD 从 env / .env 读取）
    env = {}
    if api_key:
        env.update({"DEEPSEEK_API_KEY": api_key, "OPENAI_API_KEY": api_key,
                    "ANTHROPIC_API_KEY": api_key, "GOOGLE_API_KEY": api_key})
        logs.append(f"[VeriPVD] API key injected, LLM enabled (model {llm_model})")
    else:
        logs.append("[VeriPVD] no API key -- running rtl_structure_graph only, LLM steps skipped")

    script = os.path.join(base, "src", "scripts", "run_single.py")
    modules = ["rtl_structure_graph"] + (["permission_chain", "vulnerability_analysis"] if api_key else [])
    for m in modules:
        try:
            rc, out = _run([py, script, "--module", m, "--scope", scope, "--config", cfg_path],
                           cwd=base, env_extra=env)
            tail = "\n".join(out.strip().splitlines()[-3:])
            if rc == 0:
                logs.append(f"[VeriPVD] module {m} done OK {tail}")
            else:
                # 失败时把真实报错尾部写进日志，界面可见
                err_lines = [l for l in out.strip().splitlines() if l.strip()][-4:] or ["(no output)"]
                for l in err_lines:
                    logs.append(f"[VeriPVD] module {m} stderr> {l}")
                logs.append(f"[VeriPVD] module {m} failed (rc={rc}), skipped")
                warnings.append(f"VeriPVD module {m} failed: {err_lines[-1] if err_lines else 'see scan log'}")
        except Exception as e:  # noqa: BLE001
            warnings.append(f"VeriPVD module {m} exception: {e}")
            logs.append(f"[VeriPVD] module {m} exception: {e}")

    # 3) 只解析权威结果: vulnerability_analysis/final_findings.json
    n = 0
    for fp in glob.glob(os.path.join(out_root, scope, "**", "final_findings.json"), recursive=True):
        try:
            with open(fp, encoding="utf-8") as f:
                raw = json.load(f)
            got = from_veripvd(raw)
            if got:
                findings.extend(got)
                n += len(got)
                logs.append(f"[VeriPVD] parsed {os.path.relpath(fp, scan_dir)} -> {len(got)} findings")
        except Exception as e:  # noqa: BLE001
            warnings.append(f"解析 {os.path.relpath(fp, scan_dir)} 失败: {e}")
    if n == 0 and api_key:
        warnings.append("未找到 final_findings.json（vulnerability_analysis 可能未产出结果，见上方模块日志）")
    return findings, logs + warnings


# ================= VerilogLAVD =================
# 依赖 Neo4j + pyverilog。MVP 阶段: 若配置了结果文件(结果 JSON/CSV 由论文复现管线
# 导出)则解析；若配置了 run_detection 入口则尝试子进程调用。失败一律降级。
def run_veriloglavd(rtl_dir: str, scan_dir: str, settings: dict):
    logs, findings, warnings = [], [], []
    base = settings.get("verilavlvd_path", "")
    py = settings.get("verilavlvd_python")
    if not py and base:
        cand = os.path.join(base, ".venv", "Scripts", "python.exe")
        py = cand if os.path.isfile(cand) else sys.executable
    if not py:
        py = sys.executable

    if not os.path.isdir(base):
        warnings.append(f"VerilogLAVD path not configured or missing: '{base}' (set it in the web Settings page)")
        return findings, logs + warnings

    # 方式 A: 直接尝试仓库自带检测入口（若后续版本参数有变，只需改这里的命令）
    entry = settings.get("verilavlvd_entry")  # 如 src/traversal_engine/run_detection.py
    if entry and os.path.isfile(os.path.join(base, entry)):
        try:
            rc, out = _run([py, entry, "--rtl-dir", rtl_dir, "--out", os.path.join(scan_dir, "lavd_out.json")],
                           cwd=base, timeout=3600)
            logs.append(f"[VerilogLAVD] run_detection rc={rc}")
            if rc == 0:
                res_fp = os.path.join(scan_dir, "lavd_out.json")
                if os.path.isfile(res_fp):
                    with open(res_fp, encoding="utf-8") as f:
                        findings.extend(from_veriloglavd(json.load(f)))
                    logs.append(f"[VerilogLAVD] parsed {len(findings)} findings")
                    return findings, logs
        except Exception as e:  # noqa: BLE001
            warnings.append(f"VerilogLAVD 子进程调用失败: {e}")

    # 方式 A2: 默认桥接器 — VeriPG 建图 + 图遍历模式检测（复用仓库 venv 与 Neo4j 配置）
    bridge = os.path.join(os.path.dirname(os.path.abspath(__file__)), "lavd_bridge.py")
    if os.path.isfile(bridge):
        out_fp = os.path.join(scan_dir, "lavd_out.json")
        cmd = [py, bridge, "--rtl-dir", rtl_dir, "--out", out_fp, "--lavd", base]
        if settings.get("neo4j_password"):
            cmd += ["--password", settings["neo4j_password"]]
        rc, out = _run(cmd, cwd=base, timeout=3600,
                       env_extra={"PYTHONUTF8": "1", "PYTHONIOENCODING": "utf-8"})
        tail = "\n".join(out.strip().splitlines()[-3:]) if out.strip() else ""
        logs.append(f"[VerilogLAVD] bridge rc={rc} {tail}")
        if rc == 0 and os.path.isfile(out_fp):
            try:
                raw = json.load(open(out_fp, encoding="utf-8"))
                items = []
                for fe in raw.get("files", []):
                    for pr in fe.get("patterns", []):
                        for hit in pr.get("hits", []):
                            items.append({
                                "cwe": pr.get("cwe", "unknown"),
                                "description": pr.get("desc") or pr.get("cwe", ""),
                                "severity": pr.get("severity", "medium"),
                                "files": [{"file": fe["file"],
                                           "line": int(hit.get("lineno") or 0),
                                           "name": hit.get("name", "")}],
                                "evidence": hit.get("evidence", []),
                            })
                got = from_veriloglavd(items)
                findings.extend(got)
                ok_files = sum(1 for fe in raw.get("files", []) if fe.get("status") == "ok")
                logs.append(f"[VerilogLAVD] graph+patterns done: {ok_files}/{len(raw.get('files', []))} files -> {len(got)} hits")
                return findings, logs
            except Exception as e:  # noqa: BLE001
                warnings.append(f"VerilogLAVD 结果解析失败: {e}")
        elif rc != 0:
            warnings.append("VerilogLAVD 桥接器运行失败（检查 Neo4j 是否启动、密码是否正确）")

    # 方式 B: 降级 —— 读取用户在设置里指定的"最近一次检测结果文件"
    cached = settings.get("verilavlvd_last_result")
    if cached and os.path.isfile(cached):
        try:
            with open(cached, encoding="utf-8") as f:
                findings.extend(from_veriloglavd(json.load(f)))
            logs.append(f"[VerilogLAVD] using cached result file: {cached} -> {len(findings)} findings")
            return findings, logs
        except Exception as e:  # noqa: BLE001
            warnings.append(f"VerilogLAVD 结果文件解析失败: {e}")

    warnings.append("VerilogLAVD 未能产出结果（需 Neo4j + pyverilog 环境，或配置 verilavlvd_entry / verilavlvd_last_result）")
    return findings, logs + warnings
