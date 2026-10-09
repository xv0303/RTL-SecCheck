"""RTL-SecCheck 后端 — FastAPI 入口。

启动:  uvicorn main:app --host 127.0.0.1 --port 8321
页面:  http://127.0.0.1:8321
"""
from __future__ import annotations

import json
import os
import re
import shutil
import socket
import threading
import uuid
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, JSONResponse, Response
from pydantic import BaseModel

import engines
import fixgen
import graph as graph_mod
from unify import blank as new_finding

BASE = Path(__file__).resolve().parent.parent          # RTL-SecCheck/
SETTINGS_FP = BASE / "backend" / "settings.json"
SCANS_DIR = BASE / "scans"
FRONTEND = BASE / "frontend"

DEFAULT_SETTINGS = {
    "veripvd_path": "",              # clone of https://github.com/anwen0724/VeriPVD
    "veripvd_python": "",            # its venv python; auto-detected as <veripvd_path>/.venv if empty
    "verilavlvd_path": "",           # clone of https://github.com/Chip-Security-Lab/VerilogLAVD
    "verilavlvd_python": "",         # its venv python; auto-detected as <verilavlvd_path>/.venv if empty
    "verilavlvd_entry": "",          # 如 src/traversal_engine/run_detection.py，留空=走桥接器
    "verilavlvd_last_result": "",    # 论文复现管线导出的结果 JSON
    "iverilog_path": "",             # iverilog.exe; auto-detected via PATH if empty
    "llm_model": "deepseek-chat",
    "api_key": "",                   # 用户在网页填写后存这里（仅本机）
    "neo4j_uri": "bolt://localhost:7687",
    "neo4j_user": "neo4j",
    "neo4j_password": "",
}

app = FastAPI(title="RTL-SecCheck", version="0.1.0")
_JOBS: dict[str, dict] = {}   # scan_id -> {state, logs, warnings, findings, rtl_dir, engines}
_JOBS_LOCK = threading.Lock()

# first run: create a default settings.json so users can edit it directly (see README)
if not SETTINGS_FP.is_file():
    try:
        SETTINGS_FP.write_text(
            json.dumps(DEFAULT_SETTINGS, ensure_ascii=False, indent=2), encoding="utf-8")
    except Exception:
        pass


# ---------------- 设置 ----------------
def load_settings() -> dict:
    s = dict(DEFAULT_SETTINGS)
    if SETTINGS_FP.is_file():
        try:
            s.update(json.loads(SETTINGS_FP.read_text(encoding="utf-8")))
        except Exception:
            pass
    return s


def save_settings(s: dict):
    merged = load_settings()
    for k, v in s.items():
        if k in merged:
            merged[k] = v
    SETTINGS_FP.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")
    return merged


def _neo4j_alive(uri: str) -> bool:
    m = re.match(r"bolt://([^:/]+)(?::(\d+))?", uri or "")
    if not m:
        return False
    host = m.group(1) or "localhost"
    port = int(m.group(2) or 7687)
    try:
        with socket.create_connection((host, port), timeout=1.5):
            return True
    except OSError:
        return False


class SettingsIn(BaseModel):
    api_key: str | None = None
    llm_model: str | None = None
    veripvd_path: str | None = None
    veripvd_python: str | None = None
    verilavlvd_path: str | None = None
    verilavlvd_python: str | None = None
    verilavlvd_entry: str | None = None
    verilavlvd_last_result: str | None = None
    neo4j_uri: str | None = None
    neo4j_user: str | None = None
    neo4j_password: str | None = None


@app.get("/api/settings")
def get_settings():
    s = load_settings()
    masked = dict(s)
    if s.get("api_key"):
        masked["api_key"] = s["api_key"][:4] + "****" + s["api_key"][-4:]
    return {"settings": masked,
            "has_api_key": bool(s.get("api_key")),
            "neo4j_alive": _neo4j_alive(s.get("neo4j_uri", ""))}


@app.post("/api/settings")
def set_settings(body: SettingsIn):
    payload = {k: v for k, v in body.model_dump().items() if v is not None}
    # 前端传回掩码(****)时不覆盖真实 key
    if "api_key" in payload and "****" in str(payload["api_key"]):
        payload.pop("api_key")
    s = save_settings(payload)
    return {"ok": True, "has_api_key": bool(s.get("api_key")),
            "neo4j_alive": _neo4j_alive(s.get("neo4j_uri", ""))}


# ---------------- 扫描 ----------------
class ScanIn(BaseModel):
    rtl_dir: str
    engines: dict = {"lavd": True, "pvd": True}


@app.post("/api/scan")
def start_scan(body: ScanIn):
    scan_id = _launch_scan(body.rtl_dir, body.engines)
    return {"scan_id": scan_id}


def _launch_scan(rtl_dir: str, engines: dict | None = None) -> str:
    rtl = os.path.abspath(rtl_dir)
    if not os.path.isdir(rtl):
        raise HTTPException(400, f"RTL 目录不存在: {rtl}")
    scan_id = f"S-{uuid.uuid4().hex[:8]}"
    scan_dir = SCANS_DIR / scan_id
    scan_dir.mkdir(parents=True, exist_ok=True)
    job = {"state": "running", "logs": [], "warnings": [], "findings": [],
           "rtl_dir": rtl, "engines": engines or {"lavd": True, "pvd": True}, "scan_dir": str(scan_dir)}
    with _JOBS_LOCK:
        _JOBS[scan_id] = job
    threading.Thread(target=_scan_worker, args=(scan_id,), daemon=True).start()
    return scan_id


def _log(job, msg, warn=False):
    job["logs"].append(msg)
    if warn:
        job["warnings"].append(msg)


def _scan_worker(scan_id: str):
    with _JOBS_LOCK:
        job = _JOBS[scan_id]
    try:
        s = load_settings()
        api_key = s.get("api_key") or None
        if not api_key:
            _log(job, "[WARN] No LLM API key configured -- VeriPVD LLM steps will be skipped (rule mode)", warn=True)

        if job["engines"].get("pvd", True):
            _log(job, "[RUN] VeriPVD permission-flow analysis ...")
            f, lg = engines.run_veripvd(job["rtl_dir"], job["scan_dir"], s, api_key)
            job["logs"].extend(lg)
            job["findings"].extend(f)

        if job["engines"].get("lavd", True):
            _log(job, "[RUN] VerilogLAVD CWE detection ...")
            if not _neo4j_alive(s.get("neo4j_uri", "")):
                _log(job, "[WARN] Neo4j not detected -- CWE engine uses fallback (cached result or skip)", warn=True)
            f, lg = engines.run_veriloglavd(job["rtl_dir"], job["scan_dir"], s)
            job["logs"].extend(lg)
            job["findings"].extend(f)

        # 持久化报告
        report = {"scan_id": scan_id, "rtl_dir": job["rtl_dir"], "findings": job["findings"],
                  "warnings": job["warnings"]}
        (Path(job["scan_dir"]) / "report.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        _log(job, f"[DONE] Scan finished: {len(job['findings'])} findings, report saved")
        job["state"] = "done"
    except Exception as e:  # noqa: BLE001
        job["state"] = "error"
        _log(job, f"[FAIL] Scan aborted: {e}", warn=True)


@app.get("/api/scan/{scan_id}/status")
def scan_status(scan_id: str):
    job = _JOBS.get(scan_id)
    if not job:
        # 支持重启后读取历史报告
        fp = SCANS_DIR / scan_id / "report.json"
        if fp.is_file():
            rep = json.loads(fp.read_text(encoding="utf-8"))
            return {"state": "done", "logs": rep.get("warnings", []), "warnings": rep.get("warnings", []),
                    "progress": 100}
        raise HTTPException(404, "扫描不存在")
    prog = 60 if job["state"] == "running" else 100
    return {"state": job["state"], "logs": job["logs"][-40:], "warnings": job["warnings"], "progress": prog}


@app.get("/api/scan/{scan_id}/report")
def scan_report(scan_id: str):
    fp = SCANS_DIR / scan_id / "report.json"
    if not fp.is_file():
        raise HTTPException(404, "报告尚未生成")
    rep = json.loads(fp.read_text(encoding="utf-8"))
    hi = sum(1 for f in rep["findings"] if f["severity"] == "high")
    return {"scan_id": scan_id, "rtl_dir": rep["rtl_dir"], "findings": rep["findings"],
            "warnings": rep["warnings"], "summary": {"total": len(rep["findings"]), "high": hi}}


@app.get("/api/scans")
def list_scans():
    out = []
    if SCANS_DIR.is_dir():
        for d in sorted(SCANS_DIR.iterdir(), reverse=True):
            rp = d / "report.json"
            if rp.is_file():
                rep = json.loads(rp.read_text(encoding="utf-8"))
                out.append({"scan_id": d.name, "rtl_dir": rep["rtl_dir"], "total": len(rep["findings"])})
    return {"scans": out}


# ---------------- 修复建议（按需 LLM 生成） ----------------
@app.post("/api/scan/{scan_id}/fix/{finding_id}")
def gen_finding_fix(scan_id: str, finding_id: str):
    scan_dir = SCANS_DIR / scan_id
    if not (scan_dir / "report.json").is_file():
        raise HTTPException(404, "扫描不存在")
    s = load_settings()
    try:
        f = fixgen.generate_fix(str(scan_dir), scan_id, finding_id, s)
    except LookupError as e:
        raise HTTPException(404, str(e))
    except RuntimeError as e:
        raise HTTPException(400, str(e))
    except Exception as e:  # noqa: BLE001
        raise HTTPException(500, f"生成失败: {e}")
    return {"ok": True, "finding": f}


# ---------------- 图可视化 ----------------
@app.get("/api/scan/{scan_id}/graph")
def scan_graph(scan_id: str):
    fp = SCANS_DIR / scan_id / "report.json"
    if not fp.is_file():
        raise HTTPException(404, "报告尚未生成，无法构建图")
    rep = json.loads(fp.read_text(encoding="utf-8"))
    rtl = rep.get("rtl_dir")
    if not rtl or not os.path.isdir(rtl):
        raise HTTPException(400, "扫描的 RTL 目录不可用")
    return graph_mod.build_scan_graph(rtl, rep.get("findings", []))


# ---------------- 文件读取（代码定位） ----------------
@app.get("/api/file")
def read_file(path: str, scan_id: str = ""):
    # 相对路径: 按该次扫描的 rtl_dir 解析（finding 里的 file 通常是相对路径）
    real = os.path.abspath(path)
    if scan_id:
        fp = SCANS_DIR / scan_id / "report.json"
        if fp.is_file():
            try:
                rtl = json.loads(fp.read_text(encoding="utf-8")).get("rtl_dir", "")
            except Exception:
                rtl = ""
            if rtl and os.path.isdir(rtl):
                cand = os.path.abspath(os.path.join(rtl, path))
                if os.path.isfile(cand):
                    real = cand
    # 安全: 只允许读取已扫描工程与两个引擎仓库内的文本文件
    allowed_roots = [load_settings().get("veripvd_path", ""), load_settings().get("verilavlvd_path", "")]
    allowed_roots += [j["rtl_dir"] for j in _JOBS.values()]
    # 白名单加入所有历史扫描的 rtl_dir（后端重启后 _JOBS 为空也能读）
    if SCANS_DIR.is_dir():
        for d in SCANS_DIR.iterdir():
            rp = d / "report.json"
            if rp.is_file():
                try:
                    allowed_roots.append(json.loads(rp.read_text(encoding="utf-8")).get("rtl_dir", ""))
                except Exception:
                    pass
    allowed_roots = [os.path.abspath(r) for r in allowed_roots if r]
    if not any(real.startswith(r) for r in allowed_roots):
        raise HTTPException(403, f"路径不在允许范围内: {real}")
    if not os.path.isfile(real):
        raise HTTPException(404, "文件不存在")
    if os.path.splitext(real)[1].lower() not in {".v", ".sv", ".vh", ".svh", ".vhdl", ".vhd", ".tcl", ".json"}:
        raise HTTPException(400, "仅支持 RTL/文本文件预览")
    text = Path(real).read_text(encoding="utf-8", errors="replace")
    return {"file": real, "lines": text.splitlines()[:2000]}


# ---------------- Tcl 接口（Vivado 插件专用，全部纯文本、GET-only） ----------------
_TCL_TEXT = {"media_type": "text/plain; charset=utf-8"}


def _gbk_safe(s: str) -> str:
    """Vivado Tcl 控制台按本地代码页(GBK)显示：去掉 GBK 外的字符(如 ▶✔⚠)，保留中文。"""
    return s.encode("gbk", errors="replace").decode("gbk", errors="replace")


@app.get("/api/tcl/scan")
def tcl_scan(dir: str, engines: str = "both"):
    """engines: none | pvd | lavd | both"""
    eng = {"none": {"lavd": False, "pvd": False},
           "pvd": {"lavd": False, "pvd": True},
           "lavd": {"lavd": True, "pvd": False},
           "both": {"lavd": True, "pvd": True}}.get(engines, {"lavd": True, "pvd": True})
    scan_id = _launch_scan(dir, eng)
    return Response(f"SCAN_ID {scan_id}\nRTL {os.path.abspath(dir)}\n", **_TCL_TEXT)


@app.get("/api/tcl/status")
def tcl_status(scan_id: str):
    job = _JOBS.get(scan_id)
    lines = []
    if job:
        lines.append(f"STATE {job['state']}")
        lines += [f"LOG {l}" for l in job["logs"][-15:]]
    else:
        fp = SCANS_DIR / scan_id / "report.json"
        if fp.is_file():
            lines.append("STATE done")
            rep = json.loads(fp.read_text(encoding="utf-8"))
            lines += [f"LOG {w}" for w in rep.get("warnings", [])[-10:]]
        else:
            raise HTTPException(404, f"扫描 {scan_id} 不存在")
    return Response(_gbk_safe("\n".join(lines) + "\n"), **_TCL_TEXT)


@app.get("/api/tcl/report")
def tcl_report(scan_id: str):
    fp = SCANS_DIR / scan_id / "report.json"
    if not fp.is_file():
        raise HTTPException(404, f"报告尚未生成: {scan_id}")
    rep = json.loads(fp.read_text(encoding="utf-8"))
    lines = [f"SCAN {scan_id}", f"RTL {rep['rtl_dir']}", f"TOTAL {len(rep['findings'])}"]
    for f in rep["findings"]:
        loc = (f.get("location") or [{}])[0]
        fn = (loc.get("file") or "?").replace("\\", "/")
        desc = (f.get("description") or "").replace("\t", " ")[:90]
        lines.append(f"FINDING\t{f['id']}\t{f['severity']}\t{f['type']}\t{fn}:{loc.get('line', 0)}\t{desc}")
    return Response(_gbk_safe("\n".join(lines) + "\n"), **_TCL_TEXT)


@app.get("/api/tcl/fix")
def tcl_fix(scan_id: str, finding: str):
    fp = SCANS_DIR / scan_id / "report.json"
    if not fp.is_file():
        raise HTTPException(404, f"报告尚未生成: {scan_id}")
    s = load_settings()
    if not s.get("api_key"):
        raise HTTPException(400, "未配置 LLM API Key（网页设置页或 settings.json）")
    try:
        f = fixgen.generate_fix(str(SCANS_DIR / scan_id), scan_id, finding, s, lang="en")
    except LookupError as e:
        raise HTTPException(404, str(e))
    lines = [f"FIX {f['id']} [{f['severity']}] {f['type']}",
             f"LOCATION {(f.get('location') or [{}])[0].get('file', '?')}:" +
             str((f.get('location') or [{}])[0].get('line', 0)),
             "VERIFICATION " + json.dumps(f.get("verification", {}), ensure_ascii=False),
             "---"]
    lines += (f.get("fix_suggestion") or "").splitlines()
    return Response(_gbk_safe("\n".join(lines) + "\n"), **_TCL_TEXT)


@app.get("/api/tcl/open")
def tcl_open(scan_id: str, what: str = "graph"):
    """what: graph | report — 返回浏览器可打开的网页地址（复用网页版页面）"""
    fp = SCANS_DIR / scan_id / "report.json"
    if not fp.is_file():
        raise HTTPException(404, f"报告尚未生成: {scan_id}")
    page = "graph" if what == "graph" else "report"
    return Response(_gbk_safe(f"URL http://127.0.0.1:8321/?scan={scan_id}&page={page}\n"
                    f"HINT open the {'graph view' if page == 'graph' else 'full report'} in browser\n"), **_TCL_TEXT)


# ---------------- 静态页面 ----------------
@app.get("/")
def index():
    return FileResponse(FRONTEND / "index.html")


@app.get("/favicon.ico")
def favicon():
    return Response(status_code=204)
