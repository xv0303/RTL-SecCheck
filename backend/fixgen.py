"""按需修复建议生成：LLM 针对单条 finding 的具体代码生成修复方案 + iverilog 基线验证。

VeriPVD 的 vulnerability_analysis 有时不输出 recommended_follow_up 字段，
此模块作为兜底：用用户配置的 LLM key 按需生成每条 finding 专属的修复建议，
保证不同 finding 的建议内容互不相同、且引用真实代码行。
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import threading
import urllib.request
from concurrent.futures import Future
from pathlib import Path
from urllib.parse import quote

from llm_providers import BASE_URLS, provider_of


def _resolve_iverilog(settings: dict | None) -> str | None:
    """定位 iverilog：settings['iverilog_path'] 优先，其次 PATH 自动探测。找不到返回 None（降级）。"""
    p = (settings or {}).get("iverilog_path") or ""
    if p and os.path.isfile(p):
        return p
    return shutil.which("iverilog")

def _base_url(model: str) -> str:
    return BASE_URLS[provider_of(model)]


def llm_chat(prompt: str, settings: dict, timeout: int = 180, lang: str = "zh") -> str:
    """调用 openai 兼容 chat API，返回文本。lang 控制回答语言（Tcl 控制台只能显示 ASCII，走 en）。"""
    key = settings.get("api_key") or ""
    model = settings.get("llm_model") or "deepseek-chat"
    provider = provider_of(model)
    custom_base = settings.get("llm_base_url")
    base = (custom_base or BASE_URLS[provider]).rstrip("/")
    sysmsg = ("你是硬件安全专家，精通 Verilog RTL 漏洞修复。回答用中文，"
              "代码用 ```verilog 代码块。输出紧凑，不要客套话。" if lang == "zh" else
              "You are a hardware security expert specializing in Verilog RTL vulnerability "
              "fixes. Answer in ENGLISH, use ```verilog code blocks. Be compact, no pleasantries.")
    headers = {"Content-Type": "application/json"}
    # An explicitly configured custom endpoint retains its existing OpenAI-compatible protocol.
    if provider == "claude" and not custom_base:
        endpoint = base + "/messages"
        headers.update({"x-api-key": key, "anthropic-version": "2023-06-01"})
        payload = {"model": model, "system": sysmsg, "max_tokens": 4096,
                   "messages": [{"role": "user", "content": prompt}]}
    elif provider == "gemini" and not custom_base:
        endpoint = f"{base}/models/{quote(model, safe='')}:generateContent"
        headers["x-goog-api-key"] = key
        payload = {"systemInstruction": {"parts": [{"text": sysmsg}]},
                   "contents": [{"role": "user", "parts": [{"text": prompt}]}]}
    else:
        endpoint = base + "/chat/completions"
        headers["Authorization"] = f"Bearer {key}"
        payload = {"model": model, "messages": [
            {"role": "system", "content": sysmsg},
            {"role": "user", "content": prompt}]}
        if provider != "gpt":
            payload["temperature"] = 0.2
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        endpoint, data=body, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        data = json.loads(r.read().decode("utf-8"))
    if provider == "claude" and not custom_base:
        text = "\n".join(p.get("text", "") for p in data.get("content", []) if p.get("type") == "text")
    elif provider == "gemini" and not custom_base:
        text = "\n".join(p.get("text", "") for p in
                         (data.get("candidates") or [{}])[0].get("content", {}).get("parts", [])
                         if not p.get("thought"))
    else:
        text = data["choices"][0]["message"].get("content")
    if not isinstance(text, str) or not text.strip():
        raise RuntimeError("模型未返回文字建议，请重试或检查模型配置")
    return text


# ---------------- 代码上下文 ----------------
def _read_snippet(path: str, line: int, ctx: int = 15) -> str:
    try:
        lines = Path(path).read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return "(无法读取文件)"
    lo, hi = max(0, line - ctx - 1), min(len(lines), line + ctx)
    out = [f"{i+1:5d} | {lines[i]}" for i in range(lo, hi)]
    return "\n".join(out) if out else "(空文件)"


def _context_for(finding: dict, rtl_dir: str) -> str:
    parts = []
    for loc in (finding.get("location") or [])[:3]:
        fp = loc.get("file") or ""
        if fp and not os.path.isabs(fp):
            cand = os.path.join(rtl_dir, fp)
            fp = cand if os.path.isfile(cand) else fp
        if os.path.isfile(fp):
            parts.append(f"--- {os.path.basename(fp)} (问题行 {loc.get('line','?')}) ---\n"
                         + _read_snippet(fp, int(loc.get("line") or 1)))
    return "\n\n".join(parts) or "(无代码上下文)"


# ---------------- iverilog 基线验证 ----------------
def iverilog_baseline(rtl_dir: str, settings: dict | None = None) -> dict:
    """编译 rtl_dir 下所有 .v 文件，返回 {status, detail}。"""
    iverilog = _resolve_iverilog(settings)
    if not iverilog:
        return {"tool": "iverilog", "status": "unavailable",
                "detail": "iverilog not found (set 'iverilog_path' in Settings, or add it to PATH)"}
    vfiles = [str(p) for p in Path(rtl_dir).rglob("*.v")]
    if not vfiles:
        return {"tool": "iverilog", "status": "no-source", "detail": "no .v files in directory"}
    out = tempfile.NamedTemporaryFile(suffix=".vvp", delete=False).name
    try:
        proc = subprocess.run(
            [iverilog, "-g2012", "-o", out] + vfiles,
            capture_output=True, text=True, timeout=120, cwd=rtl_dir)
        if proc.returncode == 0:
            n = len(vfiles)
            return {"tool": "iverilog", "status": "pass",
                    "detail": f"baseline compile OK: {n} Verilog files (-g2012)"}
        err = "\n".join(proc.stderr.strip().splitlines()[-4:])
        return {"tool": "iverilog", "status": "fail", "detail": f"compile failed: {err}"}
    except subprocess.TimeoutExpired:
        return {"tool": "iverilog", "status": "timeout", "detail": "compile timeout (>120s)"}
    finally:
        try:
            os.unlink(out)
        except OSError:
            pass


# ---------------- 主入口 ----------------
_PROMPT = """请为下面这条硬件安全检测结果生成修复方案。

## 漏洞信息
- 编号: {fid}
- 类型: {ftype}
- 严重度: {sev}
- 描述: {desc}
- 证据链:
{evidence}

## 相关代码
{code}

请严格按以下三节输出（用 markdown）：
### 根因
针对上述代码的具体根因（引用信号名/行号，2-4 句）。
### 修复方案
给出修改后的 Verilog 代码块（只给需要改动的 always/assign 片段，注明所属模块与位置），说明改动点。
### 专项验证
针对这类漏洞的仿真验证方法：给出一段 testbench 激励/断言代码块，验证修复后漏洞场景不再发生（例如尝试在锁定状态下写入敏感寄存器并断言无效果）。
"""


_PROMPT_EN = """Please generate a fix plan for the following hardware security finding.

## Vulnerability info
- ID: {fid}
- Type: {ftype}
- Severity: {sev}
- Description: {desc}
- Evidence chain:
{evidence}

## Related code
{code}

Output strictly in these three markdown sections (in English):
### Root cause
The specific root cause, referencing signal names / line numbers (2-4 sentences).
### Fix
Give the modified Verilog code block (only the always/assign snippets that need to change, name the module and location) and explain the changes.
### Verification
Simulation verification for this vulnerability class: give a testbench stimulus/assertion code block proving the attack scenario no longer succeeds after the fix (e.g. writing a sensitive register while locked has no effect).
"""


_STATE_LOCK = threading.Lock()
_REPORT_LOCKS: dict[str, threading.Lock] = {}
_INFLIGHT: dict[tuple[str, str, str], Future] = {}


def generate_fix(scan_dir: str, scan_id: str, finding_id: str, settings: dict, lang: str = "zh") -> dict:
    """Coalesce simultaneous requests for the same finding; failed calls remain retryable."""
    report_path = str((Path(scan_dir) / "report.json").resolve())
    key = (report_path, finding_id, lang)
    with _STATE_LOCK:
        report_lock = _REPORT_LOCKS.setdefault(report_path, threading.Lock())
        future = _INFLIGHT.get(key)
        owner = future is None
        if owner:
            future = Future()
            _INFLIGHT[key] = future
    if not owner:
        return future.result()
    try:
        result = _generate_fix(scan_dir, scan_id, finding_id, settings, lang, report_lock)
        future.set_result(result)
        return result
    except BaseException as e:
        future.set_exception(e)
        raise
    finally:
        with _STATE_LOCK:
            _INFLIGHT.pop(key, None)


def _generate_fix(scan_dir: str, scan_id: str, finding_id: str, settings: dict,
                  lang: str, report_lock) -> dict:
    """lang: zh=网页用中文; en=Vivado Tcl 控制台用（其控制台无法显示非 ASCII）。"""
    rep_fp = Path(scan_dir) / "report.json"
    with report_lock:
        rep = json.loads(rep_fp.read_text(encoding="utf-8"))
    finding = next((f for f in rep["findings"] if f.get("id") == finding_id), None)
    if finding is None:
        raise LookupError(f"finding {finding_id} 不存在")
    if not settings.get("api_key"):
        raise RuntimeError("未配置 LLM API Key")

    rtl = rep.get("rtl_dir", "")
    code = _context_for(finding, rtl)
    evidence = "\n".join(f"  {i+1}. {e}" for i, e in enumerate((finding.get("evidence") or [])[:6])) or "  (无)"
    tpl = _PROMPT if lang == "zh" else _PROMPT_EN
    prompt = tpl.format(fid=finding_id, ftype=finding.get("type", "?"),
                        sev=finding.get("severity", "?"),
                        desc=finding.get("description", ""),
                        evidence=evidence, code=code)
    text = llm_chat(prompt, settings, lang=lang)

    finding["fix_suggestion"] = text
    # 每条 finding 独立跑 iverilog 基线（同一工程结果一致，但附带 finding 专项验证步骤）
    if not finding.get("verification") or finding["verification"].get("status") in (None, "pending"):
        finding["verification"] = iverilog_baseline(rtl, settings)
    # The LLM and compiler run outside the lock. Merge into the latest report, then replace
    # atomically so concurrent fixes and report readers never observe a partial JSON file.
    with report_lock:
        latest = json.loads(rep_fp.read_text(encoding="utf-8"))
        current = next((f for f in latest["findings"] if f.get("id") == finding_id), None)
        if current is None:
            raise LookupError(f"finding {finding_id} 不存在")
        current.update(fix_suggestion=text, verification=finding.get("verification"))
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=rep_fp.parent,
                                             prefix=".report-", suffix=".tmp", delete=False) as tmp:
                temporary = tmp.name
                json.dump(latest, tmp, ensure_ascii=False, indent=2)
            os.replace(temporary, rep_fp)
        finally:
            if temporary and os.path.exists(temporary):
                os.unlink(temporary)
    return current
