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
import tempfile
import threading
import urllib.error
import urllib.request
import uuid
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, JSONResponse, Response
from pydantic import BaseModel

import engines
import fixgen
import graph as graph_mod
from unify import blank as new_finding
from llm_providers import model_list_endpoint

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
    "rtl_dir": "",                   # 扫描目标目录；空 = 扩展端默认（当前文件目录/工作区根）
}

app = FastAPI(title="RTL-SecCheck", version="0.1.0")
_JOBS: dict[str, dict] = {}   # scan_id -> {state, logs, warnings, findings, rtl_dir, engines}
_JOBS_LOCK = threading.Lock()
_SETTINGS_LOCK = threading.Lock()

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
    # Directory autosave and credential saves may arrive on separate worker threads.
    with _SETTINGS_LOCK:
        merged = load_settings()
        for k, v in s.items():
            if k in merged:
                merged[k] = v
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=SETTINGS_FP.parent,
                                             prefix=".settings-", suffix=".tmp", delete=False) as tmp:
                temporary = tmp.name
                json.dump(merged, tmp, ensure_ascii=False, indent=2)
            os.replace(temporary, SETTINGS_FP)
        finally:
            if temporary and os.path.exists(temporary):
                os.unlink(temporary)
        return merged


# ---------------- Neo4j / API Key 即时校验（保存设置后用新配置现场试连） ----------------
#
# 设计约束：
#   * 纯 stdlib 手写最小 Bolt 握手（magic + 版本协商 + HELLO/basic 认证），
#     不给后端引入 neo4j 驱动依赖。旧的 _neo4j_alive() 只做 TCP 端口探测，
#     密码错了也报「在线」（假在线），已整体废弃，所有调用点统一走这里。
#   * 任何异常都归到 unknown + 原始摘要（截断 200 字），校验绝不能把后端搞崩。
#   * 每次调用现场试连、无任何缓存 —— 保存后立即按新配置重算，不吃旧结果。


def _trunc(text: str, limit: int = 200) -> str:
    """原始错误摘要，截断到 limit 字内（超时/无法解析等场景的兜底文案）。"""
    s = re.sub(r"\s+", " ", str(text)).strip()
    return s[:limit] + ("…" if len(s) > limit else "")


def _err_summary(e: Exception, limit: int = 200) -> str:
    return _trunc(str(e), limit)


def _diag(msg: str) -> None:
    """诊断日志：打到 stdout（扩展拉起后端时 stdout 进 backend/service.log）。"""
    print(f"[{datetime.now():%H:%M:%S}] {msg}", flush=True)


def _ps_str(v: str) -> bytes:
    """PackStream 字符串编码（tiny / 8-bit / 16-bit 长度三档足够）。"""
    b = v.encode("utf-8")
    n = len(b)
    if n < 16:
        return bytes((0x80 | n,)) + b
    if n < 256:
        return b"\xd0" + bytes((n,)) + b
    return b"\xd1" + n.to_bytes(2, "big") + b


def _ps_read_str(buf: bytes, off: int) -> tuple[str, int]:
    m = buf[off]
    off += 1
    if 0x80 <= m <= 0x8F:
        n = m & 0x0F
    elif m == 0xD0:
        n = buf[off]
        off += 1
    elif m == 0xD1:
        n = int.from_bytes(buf[off:off + 2], "big")
        off += 2
    elif m == 0xD2:
        n = int.from_bytes(buf[off:off + 4], "big")
        off += 4
    else:
        raise ValueError(f"not a string marker: {m:#x}")
    if off + n > len(buf):
        raise ValueError("string length overruns buffer")
    return buf[off:off + n].decode("utf-8", "replace"), off + n


def _recv_exact(sock: socket.socket, n: int) -> bytes:
    out = b""
    while len(out) < n:
        chunk = sock.recv(n - len(out))
        if not chunk:
            raise ConnectionError(f"connection closed after {len(out)}/{n} bytes")
        out += chunk
    return out


def _recv_bolt_message(sock: socket.socket, cap: int = 1 << 20) -> bytes:
    """读一条 Bolt 消息：若干 chunk（2 字节大端长度 + 数据），0x0000 结束。"""
    data = b""
    while True:
        size = int.from_bytes(_recv_exact(sock, 2), "big")
        if size == 0:
            return data
        if len(data) + size > cap:
            raise ValueError("bolt response exceeds size cap")
        data += _recv_exact(sock, size)


def _parse_bolt_failure(buf: bytes) -> tuple[str, str]:
    """解析 FAILURE 响应里的 {code, message}；解析不了就返回空串（分类不受影响）。"""
    off = 0
    m = buf[off]
    off += 1
    if 0xA0 <= m <= 0xAF:
        n = m & 0x0F
    elif m == 0xD8:
        n = buf[off]
        off += 1
    elif m == 0xD9:
        n = int.from_bytes(buf[off:off + 2], "big")
        off += 2
    else:
        return "", ""
    code = text = ""
    for _ in range(n):
        k, off = _ps_read_str(buf, off)
        v, off = _ps_read_str(buf, off)
        if k == "code":
            code = v
        elif k == "message":
            text = v
    return code, text


def _bolt_server_version(resp: bytes) -> str:
    """从 SUCCESS 响应 metadata 里取 server 字段（如 "Neo4j/5.3.0"，
    去掉 "Neo4j/" 前缀返回 "5.3.0"）。取不到返回空串 —— 只影响展示，不影响判定。"""
    key = _ps_str("server")
    i = resp.find(key)
    if i < 0:
        return ""
    try:
        val, _ = _ps_read_str(resp, i + len(key))
    except Exception:
        return ""
    return val.removeprefix("Neo4j/")


def _bolt_handshake(sock: socket.socket, user: str, password: str) -> tuple[str, str]:
    """完成版本协商 + HELLO。返回 (status, detail)，
    status ∈ ok/auth/noagree/unknown；ok 时 detail 为服务端版本号（可空）。"""
    # 版本协商：Neo4j 5.x 服务端只认「范围编码」的新式协商 —— 旧式定版 offers
    # （0x00050000 之类）会被直接断连（实测 Neo4j 5.3.0，复现见 tools/check_bolt.py）。
    # 以下 16 字节与官方 neo4j Python 驱动 5.x 的 get_handshake() 完全一致：
    #   00 00 01 FF = v2 协商清单标记；00 08 08 05 = Bolt 5.x 范围；
    #   00 02 04 04 = Bolt 4.2–4.4；00 00 00 03 = Bolt 3.0
    sock.sendall(b"\x60\x60\xb0\x17"
                 + bytes.fromhex("000001ff000808050002040400000003"))
    ver = int.from_bytes(_recv_exact(sock, 4), "big")
    if ver == 0:
        _diag("[BOLT] version negotiation rejected: 00000000 (no supported version)")
        return "noagree", ""
    # 新式编码低两字节是 minor/major（如 00 00 00 05 = Bolt 5.0），打进日志备查
    _diag(f"[BOLT] version negotiated: 0x{ver:08X} (Bolt {ver & 0xFF}.{(ver >> 8) & 0xFF})")

    # HELLO: struct(1) + signature 0x01 + map{user_agent, scheme=basic, principal, credentials}
    hello = (
        b"\xb1\x01\xa4"
        + _ps_str("user_agent") + _ps_str("rtl-seccheck/0.1")
        + _ps_str("scheme") + _ps_str("basic")
        + _ps_str("principal") + _ps_str(user)
        + _ps_str("credentials") + _ps_str(password)
    )
    sock.sendall(len(hello).to_bytes(2, "big") + hello + b"\x00\x00")

    resp = _recv_bolt_message(sock)
    if not resp:
        _diag("[BOLT] handshake failed: 0 bytes, connection closed")
        return "unknown", "0 bytes, connection closed"
    # Bolt 消息 = struct 标记 + 签名：SUCCESS = b1 70 <map>，FAILURE = b1 7f <map>。
    # （旧实现曾在偏移 0 直接找裸 0x70/0x7F，真实服务端永远匹配不上，一律误判 unknown）
    sig = resp[1] if (len(resp) > 1 and resp[0] == 0xB1) else resp[0]
    if sig == 0x70:      # SUCCESS
        return "ok", _bolt_server_version(resp)
    if sig == 0x7F:      # FAILURE → HELLO 阶段基本都是认证被拒
        body = resp[2:] if resp[0] == 0xB1 else resp[1:]
        code, text = _parse_bolt_failure(body)
        _diag(f"[BOLT] auth failure, raw head: {resp[:16].hex()}")
        return "auth", _trunc(f"{code}: {text}" if code else text)
    _diag(f"[BOLT] unexpected handshake response, raw head: {resp[:16].hex()}")
    return "unknown", resp[:16].hex()


def _neo4j_check(uri: str, user: str, password: str) -> dict:
    """bolt 握手 + 认证探测，返回 {ok, kind, message}。绝不抛异常。"""
    m = re.match(r"bolt://([^:/]+)(?::(\d+))?", uri or "")
    if not m:
        return {"ok": False, "kind": "format",
                "message": f"Neo4j URI 格式无效（应以 bolt:// 开头，当前：{uri or '空'}）"}
    if not user or not password:
        return {"ok": False, "kind": "auth",
                "message": "Neo4j 认证失败：未配置用户名/密码"}
    host = m.group(1) or "localhost"
    port = int(m.group(2) or 7687)
    try:
        with socket.create_connection((host, port), timeout=5) as sock:
            sock.settimeout(5)
            status, detail = _bolt_handshake(sock, user, password)
    except ConnectionRefusedError:
        # WinError 10061：端口上没有进程在听
        return {"ok": False, "kind": "refused",
                "message": f"Neo4j 连接被拒：请检查端口（当前 {uri}）与 Neo4j Desktop 显示是否一致"}
    except socket.timeout:
        return {"ok": False, "kind": "timeout",
                "message": f"Neo4j 连接超时（{host}:{port}，5 秒无响应）"}
    except Exception as e:
        # DNS 解析失败、网络不可达、握手解析异常……一律原始摘要兜底
        _diag(f"[BOLT] connect/handshake error on {host}:{port}: {_err_summary(e)}")
        return {"ok": False, "kind": "unknown",
                "message": f"Neo4j 连接失败：{_err_summary(e)}"}
    if status == "ok":
        ver_part = f"（{detail}，握手+认证通过）" if detail else "（握手+认证通过）"
        return {"ok": True, "kind": "ok", "message": f"Neo4j 在线{ver_part}"}
    if status == "auth":
        detail_part = f"（{detail}）" if detail else ""
        return {"ok": False, "kind": "auth",
                "message": f"Neo4j 认证失败：请检查用户名/密码{detail_part}"}
    if status == "noagree":
        # 服务端回了 00000000：一个版本都没谈成 —— 与「响应异常」分开的独立分类
        return {"ok": False, "kind": "version",
                "message": "Bolt 版本不兼容：服务端未接受任何协商版本"
                           "（Bolt 3.0 / 4.2–4.4 / 5.x），请确认目标是 Neo4j 服务"}
    return {"ok": False, "kind": "unknown",
            "message": f"Neo4j 握手异常：{detail or 'unexpected response'}"}


def _api_key_check(api_key: str | None, llm_model: str) -> dict:
    """
    API Key 轻量校验：GET /models 列表（零 token）。返回 {ok, kind, message, provider}。
    网络不通时降级为格式校验并注明「未联网验证」，绝不抛异常、绝不阻塞保存。
    """
    try:
        provider, url, style = model_list_endpoint(llm_model)
    except ValueError as e:
        return {"ok": False, "kind": "format", "provider": "unknown", "message": str(e)}
    if not api_key:
        return {"ok": False, "kind": "missing", "provider": provider,
                "message": "API Key 未配置（LLM 分析与修复建议将降级）"}
    fmt_ok = not any(c.isspace() for c in api_key)
    headers = {"Content-Type": "application/json"}
    if style == "anthropic":
        headers["x-api-key"] = api_key
        headers["anthropic-version"] = "2023-06-01"
    elif style == "google":
        headers["x-goog-api-key"] = api_key
    else:
        headers["Authorization"] = f"Bearer {api_key}"
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=10) as r:
            r.read()
        return {"ok": True, "kind": "ok", "provider": provider,
                "message": f"API Key 校验通过（{provider}）"}
    except urllib.error.HTTPError as e:
        body = ""
        try:
            body = e.read().decode("utf-8", errors="replace")
        except Exception:
            pass
        if e.code in (401, 403):
            return {"ok": False, "kind": "auth", "provider": provider,
                    "message": f"API Key 校验失败：认证被拒（{provider}），"
                               f"请确认 Key 与 llm_model（{llm_model}）同一家"}
        return {"ok": False, "kind": "http", "provider": provider,
                "message": f"API Key 校验失败：HTTP {e.code}（{_trunc(body)}）"}
    except Exception as e:
        # 网络不通 / 超时：降级为格式校验，如实注明未联网验证
        if not fmt_ok:
            return {"ok": False, "kind": "format", "provider": provider,
                    "message": "API Key 格式可疑（含空白字符）"}
        return {"ok": True, "kind": "offline", "provider": provider,
                "message": f"API Key 已配置（格式检查通过，未联网验证：{_err_summary(e)}）"}


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
    rtl_dir: str | None = None
    # F9 引入的旧开关（扩展端 veripvdPath 后台同步曾传 true 跳过校验）。
    # L1 起校验范围改由 patch 实际包含的字段决定（见 set_settings），
    # 本字段仅保留兼容接收、不再影响校验行为；也不再写入设置文件。
    # 注：不叫 validate —— 那会与 pydantic BaseModel 自身属性重名。
    skip_validation: bool | None = None


def _neo4j_check_of(s: dict) -> dict:
    return _neo4j_check(s.get("neo4j_uri", ""), s.get("neo4j_user", ""),
                        s.get("neo4j_password", ""))


@app.get("/api/settings")
def get_settings():
    s = load_settings()
    masked = dict(s)
    if s.get("api_key"):
        masked["api_key"] = s["api_key"][:4] + "****" + s["api_key"][-4:]
    neo = _neo4j_check_of(s)
    return {"settings": masked,
            "has_api_key": bool(s.get("api_key")),
            "neo4j_alive": neo["ok"],
            # 纯增量字段：分类文案 —— 失败给原因（端口被拒/认证失败/超时…），
            # 成功给「Neo4j 在线（版本，握手+认证通过）」（F10 起成功也带文案，
            # 依赖行据此显示服务端版本；旧消费者只在失败时读该字段，不受影响）
            "neo4j_reason": neo["message"]}


@app.post("/api/settings")
def set_settings(body: SettingsIn):
    payload = {k: v for k, v in body.model_dump().items() if v is not None}
    # 前端传回掩码(****)时不覆盖真实 key
    if "api_key" in payload and "****" in str(payload["api_key"]):
        payload.pop("api_key")
    # L1：skip_validation 不再决定校验范围（见下），只把它从 payload 剔除；
    # 保留字段是为了兼容旧客户端，避免老扩展的 veripvdPath 同步被 422。
    payload.pop("skip_validation", None)
    s = save_settings(payload)

    # L1：校验范围由 patch 实际包含的字段决定（不再无条件做 Neo4j 握手）：
    #   - 含 neo4j_uri/user/password → 校验 Neo4j（本地握手 + 认证）
    #   - 含 api_key                → 校验 API Key（联网 GET /models，最坏 10s）
    #   - 只含 rtl_dir / veripvd_path 等 → 不做任何校验（不握手、不联网）
    # 目录静默保存因此天然低成本。响应里 neo4j_alive / neo4j_reason 只在
    # 确实执行了 Neo4j 校验时出现（字段范围校验，旧字段保留、路由不变）。
    touched_neo = any(k in payload for k in ("neo4j_uri", "neo4j_user", "neo4j_password"))
    touched_key = "api_key" in payload

    out = {"ok": True, "has_api_key": bool(s.get("api_key"))}
    validation = {}
    if touched_neo:
        # 用刚合并落盘的新配置现场试连（patch 没带密码就用盘上的真实密码），
        # 不吃任何旧探测结果；校验失败不回滚、不阻塞保存
        neo = _neo4j_check_of(s)
        out["neo4j_alive"] = neo["ok"]
        # 同 GET：成功也带文案（含服务端版本），失败带分类原因
        out["neo4j_reason"] = neo["message"]
        validation["neo4j"] = neo
    if touched_key:
        validation["api_key"] = _api_key_check(
            s.get("api_key"), s.get("llm_model", "deepseek-chat")
        )
    if validation:
        out["validation"] = validation
    return out


# ---------------- 扫描 ----------------
class ScanIn(BaseModel):
    rtl_dir: str
    engines: dict = {"lavd": True, "pvd": True}


@app.post("/api/scan")
def start_scan(body: ScanIn):
    scan_id = _launch_scan(body.rtl_dir, body.engines)
    return {"scan_id": scan_id}


def _norm_engines(engines: dict | None) -> dict:
    """归一化引擎选择: 未知键忽略、缺键默认 True、值转 bool。"""
    e = {"lavd": True, "pvd": True}
    if isinstance(engines, dict):
        e["lavd"] = bool(engines.get("lavd", True))
        e["pvd"] = bool(engines.get("pvd", True))
    return e


def _launch_scan(rtl_dir: str, engines: dict | None = None) -> str:
    rtl = os.path.abspath(rtl_dir)
    if not os.path.isdir(rtl):
        raise HTTPException(400, f"RTL 目录不存在: {rtl}")
    eng = _norm_engines(engines)
    if not (eng["lavd"] or eng["pvd"]):
        raise HTTPException(400, "至少选择一个检测引擎: LAVD(结构化CWE检测) / PVD(权限流分析)")
    scan_id = f"S-{uuid.uuid4().hex[:8]}"
    scan_dir = SCANS_DIR / scan_id
    scan_dir.mkdir(parents=True, exist_ok=True)
    job = {"state": "running", "logs": [], "warnings": [], "findings": [],
           "rtl_dir": rtl, "engines": eng, "scan_dir": str(scan_dir)}
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
        eng = job["engines"]
        engine_summary = {"veriloglavd": {"ran": eng["lavd"], "findings": 0},
                          "veripvd": {"ran": eng["pvd"], "findings": 0}}
        api_key = s.get("api_key") or None
        if eng["pvd"] and not api_key:
            _log(job, "[WARN] No LLM API key configured -- VeriPVD LLM steps will be skipped (rule mode)", warn=True)

        if eng["pvd"]:
            _log(job, "[RUN] VeriPVD permission-flow analysis ...")
            f, lg = engines.run_veripvd(job["rtl_dir"], job["scan_dir"], s, api_key)
            job["logs"].extend(lg)
            job["findings"].extend(f)
            engine_summary["veripvd"]["findings"] = len(f)
            _log(job, f"[DONE] VeriPVD: {len(f)} findings")

        if eng["lavd"]:
            _log(job, "[RUN] VerilogLAVD CWE detection ...")
            neo = _neo4j_check_of(s)
            if not neo["ok"]:
                _log(job, f"[WARN] Neo4j check failed: {neo['message']} -- CWE engine uses fallback (cached result or skip)", warn=True)
            f, lg = engines.run_veriloglavd(job["rtl_dir"], job["scan_dir"], s)
            job["logs"].extend(lg)
            job["findings"].extend(f)
            engine_summary["veriloglavd"]["findings"] = len(f)
            _log(job, f"[DONE] VerilogLAVD: {len(f)} findings")

        # 持久化报告（engines + engine_summary 记录本次实际运行的引擎）
        report = {"scan_id": scan_id, "rtl_dir": job["rtl_dir"], "findings": job["findings"],
                  "engines": eng, "engine_summary": engine_summary,
                  "warnings": job["warnings"]}
        (Path(job["scan_dir"]) / "report.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        _log(job, f"[DONE] Scan finished: {len(job['findings'])} findings, report saved")
        job["state"] = "done"
    except Exception as e:  # noqa: BLE001
        job["state"] = "error"
        _log(job, f"[FAIL] Scan aborted: {e}", warn=True)


def _report_engines(rep: dict) -> dict | None:
    """报告中的引擎选择；旧报告无 engines 字段时从 finding.source 推断（全空则返回 None）。"""
    eng = rep.get("engines")
    if isinstance(eng, dict) and ("lavd" in eng or "pvd" in eng):
        return {"lavd": bool(eng.get("lavd")), "pvd": bool(eng.get("pvd"))}
    fs = rep.get("findings", [])
    if fs:
        return {"lavd": any(f.get("source") == "veriloglavd" for f in fs),
                "pvd": any(f.get("source") == "veripvd" for f in fs)}
    return None


@app.get("/api/scan/{scan_id}/status")
def scan_status(scan_id: str):
    job = _JOBS.get(scan_id)
    if not job:
        # 支持重启后读取历史报告
        fp = SCANS_DIR / scan_id / "report.json"
        if fp.is_file():
            rep = json.loads(fp.read_text(encoding="utf-8"))
            return {"state": "done", "logs": rep.get("warnings", []), "warnings": rep.get("warnings", []),
                    "engines": _report_engines(rep), "progress": 100}
        raise HTTPException(404, "扫描不存在")
    prog = 60 if job["state"] == "running" else 100
    return {"state": job["state"], "logs": job["logs"][-40:], "warnings": job["warnings"],
            "engines": job.get("engines"), "progress": prog}


@app.get("/api/scan/{scan_id}/report")
def scan_report(scan_id: str):
    fp = SCANS_DIR / scan_id / "report.json"
    if not fp.is_file():
        raise HTTPException(404, "报告尚未生成")
    rep = json.loads(fp.read_text(encoding="utf-8"))
    hi = sum(1 for f in rep["findings"] if f["severity"] == "high")
    by_engine = {"veriloglavd": sum(1 for f in rep["findings"] if f.get("source") == "veriloglavd"),
                 "veripvd": sum(1 for f in rep["findings"] if f.get("source") == "veripvd")}
    return {"scan_id": scan_id, "rtl_dir": rep["rtl_dir"], "findings": rep["findings"],
            "warnings": rep["warnings"], "engines": _report_engines(rep),
            "summary": {"total": len(rep["findings"]), "high": hi, "by_engine": by_engine}}


@app.get("/api/scans")
def list_scans():
    out = []
    if SCANS_DIR.is_dir():
        for d in sorted(SCANS_DIR.iterdir(), reverse=True):
            rp = d / "report.json"
            if rp.is_file():
                rep = json.loads(rp.read_text(encoding="utf-8"))
                out.append({"scan_id": d.name, "rtl_dir": rep["rtl_dir"],
                            "total": len(rep["findings"]), "engines": _report_engines(rep)})
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


def _ascii_safe(s: str) -> str:
    """Tcl 端的最后兜底：无法英文描述的内容替换为 '?'（正常路径不应走到这里）。"""
    return s.encode("ascii", errors="replace").decode("ascii", errors="replace")


# 旧报告（无 description_en 字段）的 Tcl 端英文回退表：CWE 类型 -> 一行英文说明
CWE_EN = {
    "CWE-226": "if branch rewrites key/secret-family registers - sensitive info may be exposed to an untrusted observer.",
    "CWE-1231": "Lock/security-config register written under runtime conditions - verify the write path is privilege-checked.",
    "CWE-1232": "Debug/lock-family signal in the condition while the branch rewrites lock/protected-config registers - lock control may be reachable from debug mode.",
    "CWE-1234": "Debug-family signal and lock-family write coexist in the same if (paper Fig.4 TDP) - lock state may be tampered via the debug interface.",
    "CWE-1243": "Combinational/assign path directly reads key/secret-family data - the key may be exposed to untrusted functions.",
    "CWE-1244": "Privilege/password-family data mixed on a combinational or debug-gated path - inconsistent authorization policy.",
    "CWE-1245": "Case arm count differs from 2^(selector width) - missing state/branch coverage; default arm not verifiable (LOW, needs review).",
    "CWE-1255": "Password/key-family data compared or latched in timing paths - possible timing side channel.",
    "CWE-1258": "Nonblocking assignment rewrites a key/secret-family register - the key may be exposed/overwritten without security control.",
    "CWE-1262": "Request/write-enable-family signal in the condition while the branch rewrites key/secret registers - key writes may lack a privilege check.",
    "CWE-1271": "Enable-family signal in the condition while the branch rewrites lock/jtag/dbg/key registers - unlock path may miss a state check.",
    "CWE-1300": "Secret-family data drives branch/timing behavior - potential timing side channel.",
}


@app.get("/api/tcl/scan")
def tcl_scan(dir: str, engines: str = "both"):
    """engines: pvd | lavd | both（none/其他值被拒绝——空扫描没有意义）"""
    if engines not in ("pvd", "lavd", "both"):
        return Response(_gbk_safe("ERROR select at least one engine: pvd | lavd | both\n"),
                        status_code=400, **_TCL_TEXT)
    if not os.path.isdir(dir):
        return Response(_gbk_safe(f"ERROR RTL directory not found: {dir}\n"),
                        status_code=400, **_TCL_TEXT)
    eng = {"pvd": {"lavd": False, "pvd": True},
           "lavd": {"lavd": True, "pvd": False},
           "both": {"lavd": True, "pvd": True}}[engines]
    scan_id = _launch_scan(dir, eng)
    return Response(f"SCAN_ID {scan_id}\nRTL {os.path.abspath(dir)}\n"
                    f"ENGINES {','.join(k for k in ('lavd', 'pvd') if eng[k])}\n", **_TCL_TEXT)


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
            raise HTTPException(404, f"scan {scan_id} not found")
    return Response(_gbk_safe("\n".join(lines) + "\n"), **_TCL_TEXT)


@app.get("/api/tcl/report")
def tcl_report(scan_id: str):
    fp = SCANS_DIR / scan_id / "report.json"
    if not fp.is_file():
        raise HTTPException(404, f"report not ready for {scan_id}")
    rep = json.loads(fp.read_text(encoding="utf-8"))
    eng = _report_engines(rep) or {}
    lines = [f"SCAN {scan_id}", f"RTL {rep['rtl_dir']}",
             "ENGINES " + ",".join(k for k in ("lavd", "pvd") if eng.get(k)),
             f"TOTAL {len(rep['findings'])}"]
    for f in rep["findings"]:
        loc = (f.get("location") or [{}])[0]
        fn = (loc.get("file") or "?").replace("\\", "/")
        # Vivado Tcl 控制台只可靠显示 ASCII：LAVD 检出用英文描述
        # （新报告取 finding.description_en，旧报告回退 CWE_EN 类型级英文）
        if f.get("source") == "veriloglavd":
            desc = (f.get("description_en") or CWE_EN.get(f.get("type", ""), "")
                    or _ascii_safe(f.get("description") or ""))
        else:
            desc = f.get("description") or ""
        desc = desc.replace("\t", " ")[:110]
        lines.append(f"FINDING\t{f['id']}\t{f['severity']}\t{f['type']}\t{fn}:{loc.get('line', 0)}\t{desc}")
    return Response(_gbk_safe("\n".join(lines) + "\n"), **_TCL_TEXT)


@app.get("/api/tcl/fix")
def tcl_fix(scan_id: str, finding: str):
    fp = SCANS_DIR / scan_id / "report.json"
    if not fp.is_file():
        raise HTTPException(404, f"report not ready for {scan_id}")
    s = load_settings()
    if not s.get("api_key"):
        raise HTTPException(400, "no LLM API key configured (set it on the web Settings page or in settings.json)")
    try:
        f = fixgen.generate_fix(str(SCANS_DIR / scan_id), scan_id, finding, s, lang="en")
    except LookupError as e:
        raise HTTPException(404, _ascii_safe(str(e)))
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
        raise HTTPException(404, f"report not ready for {scan_id}")
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
