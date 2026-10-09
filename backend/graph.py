"""图可视化数据构建。

MVP 策略（零额外依赖，纯标准库）:
1. 轻量解析 RTL 目录下所有 .v/.sv —— module 定义 + 实例化语句 → 模块依赖图
2. 把该次扫描的 findings 按文件映射到模块节点上（高亮 + 计数）
3. 若 findings 的 evidence 里有权限链步骤，作为附加边/说明返回

后续增强点: VeriPVD rtl_structure_graph 的 JSON 直接导入（等一次真实扫描
产出后按字段精调），以及 Neo4j 图查询。
"""
from __future__ import annotations

import os
import re
from pathlib import Path

VERILOG_EXT = {".v", ".sv", ".vh", ".svh"}
MODULE_RE = re.compile(r"\bmodule\s+(\w+)\s*(?:\(|;|#)")
INST_RE = re.compile(r"\b([A-Za-z_]\w*)\s+(\w+)\s*(#\([^)]*\))?\s*\(")
KEYWORDS = {"module", "endmodule", "input", "output", "inout", "wire", "reg", "always",
            "assign", "initial", "if", "else", "case", "begin", "end", "posedge", "negedge",
            "parameter", "localparam", "function", "task", "generate", "for", "while"}


def _strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//[^\n]*", "", text)
    return text


def parse_rtl_graph(rtl_dir: str) -> dict:
    """扫描目录，返回 {modules: {name: file}, instances: [(parent, child, file)]}"""
    modules: dict[str, str] = {}
    inst_hits: list[tuple[str, str, str]] = []

    for root, _dirs, files in os.walk(rtl_dir):
        for fn in files:
            if os.path.splitext(fn)[1].lower() not in VERILOG_EXT:
                continue
            fp = os.path.join(root, fn)
            try:
                text = _strip_comments(Path(fp).read_text(encoding="utf-8", errors="replace"))
            except OSError:
                continue
            rel = os.path.relpath(fp, rtl_dir).replace("\\", "/")
            for m in MODULE_RE.finditer(text):
                modules.setdefault(m.group(1), rel)
            for m in INST_RE.finditer(text):
                mod, inst = m.group(1), m.group(2)
                if mod in KEYWORDS:
                    continue
                inst_hits.append((mod, rel))   # parent 未知，先按文件归属
    # 第二遍: 把实例化归属到包含它的 module（按文本位置）
    edges: set[tuple[str, str]] = set()
    for root, _dirs, files in os.walk(rtl_dir):
        for fn in files:
            if os.path.splitext(fn)[1].lower() not in VERILOG_EXT:
                continue
            fp = os.path.join(root, fn)
            try:
                text = _strip_comments(Path(fp).read_text(encoding="utf-8", errors="replace"))
            except OSError:
                continue
            rel = os.path.relpath(fp, rtl_dir).replace("\\", "/")
            # 记录每个 module 的文本区间
            spans = [(m.group(1), m.start()) for m in MODULE_RE.finditer(text)]
            ends = [m.end() for m in re.finditer(r"\bendmodule\b", text)]
            for m in INST_RE.finditer(text):
                mod, inst = m.group(1), m.group(2)
                if mod in KEYWORDS or mod not in modules:
                    continue
                # 找包含该位置的 module
                parent = None
                for name, start in spans:
                    if start < m.start():
                        parent = name
                if parent and parent != mod:
                    edges.add((parent, mod))
    return {"modules": modules, "edges": sorted(edges)}


def file_to_module(rtl_dir: str) -> dict[str, str]:
    g = parse_rtl_graph(rtl_dir)
    return {}  # placeholder, real mapping built in build_scan_graph


def build_scan_graph(rtl_dir: str, findings: list[dict]) -> dict:
    """返回前端 Cytoscape 风格 elements: nodes + edges，节点带 findings 计数。"""
    g = parse_rtl_graph(rtl_dir)
    modules = g["modules"]
    edges = g["edges"]

    # findings 按 file → 模块
    node_hits: dict[str, list] = {}
    unmapped_files: set[str] = set()
    for f in findings or []:
        for loc in f.get("location", []):
            fn = (loc.get("file") or "").replace("\\", "/")
            base = os.path.basename(fn)
            hit = None
            for name, mf in modules.items():
                if os.path.basename(mf) == base:
                    hit = name
                    break
            if hit:
                node_hits.setdefault(hit, []).append(f)
            elif base:
                unmapped_files.add(base)

    nodes = [{"id": n, "file": mf, "findings": len(node_hits.get(n, [])),
              "max_sev": max((x.get("severity", "low") for x in node_hits.get(n, [])),
                             key=lambda s: {"high": 3, "medium": 2, "low": 1}.get(s, 0),
                             default=None)}
             for n, mf in modules.items()]
    # 文件上有 finding 但没解析到对应模块 → 也作为节点展示（孤儿文件）
    for base in sorted(unmapped_files):
        cnt = sum(1 for f in (findings or []) for loc in f.get("location", [])
                  if os.path.basename((loc.get("file") or "")).replace("\\", "/") == base)
        nodes.append({"id": base, "file": base, "findings": cnt,
                      "max_sev": "high" if cnt and any(
                          f.get("severity") == "high" for f in findings
                          for loc in f.get("location", [])
                          if os.path.basename((loc.get("file") or "")) == base) else ("medium" if cnt else None)})

    # ---- 大图截断: 超过 MAX_NODES 时保留「有发现的模块 + 高关联度模块及其邻居」----
    MAX_NODES = 300
    total_nodes = len(nodes)
    truncated = False
    if total_nodes > MAX_NODES:
        truncated = True
        degree: dict[str, int] = {}
        for a, b in edges:
            degree[a] = degree.get(a, 0) + 1
            degree[b] = degree.get(b, 0) + 1
        keep = {n["id"] for n in nodes if n["findings"] > 0}
        # 先补高关联度节点，再补它们的直接邻居
        by_deg = sorted(degree, key=lambda k: -degree[k])
        for nid in by_deg:
            if len(keep) >= MAX_NODES:
                break
            keep.add(nid)
        for a, b in edges:
            if len(keep) >= MAX_NODES + 80:
                break
            if a in keep:
                keep.add(b)
            elif b in keep:
                keep.add(a)
        nodes = [n for n in nodes if n["id"] in keep]
        edges = [(a, b) for a, b in edges if a in keep and b in keep]

    return {"nodes": nodes, "edges": [{"source": a, "target": b} for a, b in edges],
            "meta": {"total_modules": total_nodes, "truncated": truncated}}
