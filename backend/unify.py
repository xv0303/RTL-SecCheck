"""统一 Finding Schema — 所有引擎的检测结果都归一化为这个结构。

后续网页版 / VSCode 插件 / Vivado Tcl 全部消费这个 Schema。
"""
from __future__ import annotations

import itertools
from typing import Any

_SEQ = itertools.count(1)


def new_id() -> str:
    return f"V-{next(_SEQ):03d}"


def blank(**kw) -> dict:
    f = {
        "id": kw.get("id") or new_id(),
        "source": kw.get("source", "unknown"),      # veriloglavd | veripvd
        "type": kw.get("type", "unknown"),          # CWE-xxxx | permission-bypass | ...
        "severity": kw.get("severity", "medium"),   # high | medium | low
        "description": kw.get("description", ""),
        "location": kw.get("location", []),         # [{file, line}]
        "evidence": kw.get("evidence", []),         # 图遍历路径 / 权限链步骤
        "fix_suggestion": kw.get("fix_suggestion", ""),
        "verification": kw.get("verification", {"tool": "iverilog", "status": "pending"}),
    }
    return f


# ---------------- VeriPVD 输出 → 统一 Schema ----------------
# VeriPVD 的输出在 outputs/<scope>/ 下（permission_chain / vulnerability_analysis 等
# 模块的 JSON）。不同版本字段命名可能不同，这里做 best-effort 解析：
# 递归寻找带 severity/level 与 file/line/location 特征的 dict。
_SEV_MAP = {"critical": "high", "error": "high", "high": "high",
            "warning": "medium", "medium": "medium", "info": "low", "low": "low"}


def _walk(obj: Any):
    if isinstance(obj, dict):
        yield obj
        for v in obj.values():
            yield from _walk(v)
    elif isinstance(obj, list):
        for v in obj:
            yield from _walk(v)


def _pick(d: dict, *names):
    for n in names:
        if n in d and d[n] not in (None, ""):
            return d[n]
    return None


def from_veripvd(raw: Any) -> list[dict]:
    """优先按 vulnerability_analysis/final_findings.json 的精确 schema 解析;
    结构不符时退回通用递归解析(best-effort)。"""
    if isinstance(raw, dict) and isinstance(raw.get("findings"), list) and raw.get("schema_version"):
        out = []
        for f in raw["findings"]:
            if not isinstance(f, dict):
                continue
            locs = [{"file": l.get("file", ""),
                     "line": l.get("line_start") or 0,
                     "module": l.get("module", "")}
                    for l in f.get("affected_locations") or [] if isinstance(l, dict)]
            sev = "medium"
            conf = str(f.get("confidence") or "").lower()
            if f.get("status") == "confirmed_finding" and "high" in conf:
                sev = "high"
            elif f.get("status") == "confirmed_finding":
                sev = "high"  # 已确认的权限漏洞默认高危
            chain = []
            for e in f.get("evidence") or []:
                if isinstance(e, dict):
                    loc = f"{e.get('file','')}:{e.get('line_start','')}" if e.get("file") else ""
                    chain.append((loc + " " if loc else "") + str(e.get("description") or e.get("supports_claim") or ""))
            out.append(blank(
                id=f.get("finding_id") or None,
                source="veripvd",
                type=str(f.get("vulnerability_category") or "permission-bypass"),
                severity=sev,
                description=str(f.get("summary") or ""),
                location=locs,
                evidence=chain,
                fix_suggestion=str(f.get("recommended_follow_up") or ""),
            ))
        return out

    # ---- 通用兜底(旧格式/未知格式) ----
    out = []
    for d in _walk(raw):
        desc = _pick(d, "description", "summary", "finding", "issue", "reason", "explanation")
        if not isinstance(desc, str) or len(desc) < 6:
            continue
        sev_raw = str(_pick(d, "severity", "level", "risk", "priority") or "medium").lower()
        locs = []
        loc = _pick(d, "location", "location_info", "position")
        if isinstance(loc, dict):
            locs.append({"file": loc.get("file") or loc.get("path") or "", "line": loc.get("line") or 0})
        elif _pick(d, "file", "path"):
            locs.append({"file": _pick(d, "file", "path"), "line": _pick(d, "line", "line_no") or 0})
        for extra in _pick(d, "locations", "involved_locations") or []:
            if isinstance(extra, dict):
                locs.append({"file": extra.get("file") or extra.get("path") or "", "line": extra.get("line") or 0})
        ptype = _pick(d, "type", "category", "vulnerability_type", "cwe") or "permission-bypass"
        if isinstance(ptype, str) and not ptype.startswith("CWE"):
            ptype = ptype if ptype in ("permission-bypass",) else f"permission-{ptype}"
        out.append(blank(
            source="veripvd",
            type=str(ptype),
            severity=_SEV_MAP.get(sev_raw, "medium"),
            description=desc,
            location=locs,
            evidence=_pick(d, "chain", "evidence", "chain_path", "path") or [],
            fix_suggestion=_pick(d, "fix", "suggestion", "fix_suggestion", "recommendation") or "",
        ))
    return out


# ---------------- VerilogLAVD 输出 → 统一 Schema ----------------
def from_veriloglavd(raw: Any) -> list[dict]:
    """raw 支持两种形态:
    1. list[dict]: 每条 {cwe / type, file(s), line(s), path(图遍历路径), ...}
    2. dict: {"findings": [...] } 或 {cwe_id: [命中记录,...]}
    """
    if isinstance(raw, dict) and "findings" in raw:
        raw = raw["findings"]
    items: list = []
    if isinstance(raw, list):
        items = raw
    elif isinstance(raw, dict):
        for k, v in raw.items():
            if isinstance(v, list):
                for hit in v:
                    hit = hit if isinstance(hit, dict) else {"detail": str(hit)}
                    hit.setdefault("cwe", k)
                    items.append(hit)
    out = []
    for it in items:
        if not isinstance(it, dict):
            continue
        cwe = str(_pick(it, "cwe", "cwe_id", "type", "pattern") or "unknown")
        if not cwe.startswith("CWE"):
            cwe = f"CWE-{cwe}" if cwe.isdigit() else cwe
        locs = []
        for f in _pick(it, "files", "file", "location") or []:
            if isinstance(f, dict):
                locs.append({"file": f.get("file") or f.get("path") or "", "line": f.get("line") or 0})
            elif isinstance(f, str):
                locs.append({"file": f, "line": 0})
        out.append(blank(
            source="veriloglavd",
            type=cwe,
            severity=_SEV_MAP.get(str(_pick(it, "severity", "level") or "medium").lower(), "medium"),
            description=str(_pick(it, "description", "detail", "message", "reason") or cwe),
            location=locs,
            evidence=_pick(it, "path", "traversal_path", "evidence") or [],
        ))
    return out
