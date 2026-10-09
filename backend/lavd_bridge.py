"""LAVD 桥接器 — 对任意 RTL 目录跑 VerilogLAVD 的「建图 + 图遍历检测」。

必须用 VerilogLAVD 仓库的 venv 运行（需要 pyverilog + neo4j）:
    <lavd>/.venv/Scripts/python.exe lavd_bridge.py --rtl-dir <dir> --out <result.json>

- 复用仓库的 veripg_construct.VeriPG（AST/CFG/DDG → Neo4j）与 TraversalEngine
- Neo4j 连接信息: 优先命令行/环境变量，否则自动从 run_detection.py 的 CONFIG 解析
  （即用户复现论文时配置的连接信息，密码不经过对话传输）
- ⚠ VeriPG 每次建图前会清空 Neo4j 当前数据库（LAVD 单文件分析的原生行为）
- 模式集: 从 lavd_patterns.json 加载（默认内置结构模式；论文 CWE 模板可后续加入）
"""
from __future__ import annotations

import argparse
import copy
import glob
import json
import os
import re
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))


def load_repo_config(lavd_base: str):
    """从 run_detection.py 解析 URI/USERNAME/PASSWORD（不在对话中展示密码）。"""
    fp = os.path.join(lavd_base, "src", "traversal_engine", "run_detection.py")
    src = open(fp, encoding="utf-8").read()
    uri = re.search(r'URI\s*=\s*["\']([^"\']+)["\']', src)
    user = re.search(r'USERNAME\s*=\s*["\']([^"\']+)["\']', src)
    pwd = re.search(r'PASSWORD\s*=\s*["\']([^"\']*)["\']', src)
    return (uri.group(1) if uri else "bolt://localhost:7687",
            user.group(1) if user else "neo4j",
            pwd.group(1) if pwd else "")


def main():
    # 保险: 未在 UTF-8 模式时以 PYTHONUTF8=1 重启自身（pyverilog 需按 UTF-8 读含中文注释的源码）
    if not sys.flags.utf8_mode:
        env = dict(os.environ, PYTHONUTF8="1", PYTHONIOENCODING="utf-8")
        os.execve(sys.executable, [sys.executable] + sys.argv, env)

    ap = argparse.ArgumentParser()
    ap.add_argument("--rtl-dir", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--lavd", default=None, help="path to the VerilogLAVD repo (required)")
    ap.add_argument("--patterns", default=os.path.join(HERE, "lavd_patterns.json"))
    ap.add_argument("--uri"), ap.add_argument("--user")
    ap.add_argument("--password", help="留空则自动从 run_detection.py 读取")
    ap.add_argument("--clear-db", action="store_true", help="确认允许清空 Neo4j 当前库")
    args = ap.parse_args()
    if not args.lavd or not os.path.isdir(args.lavd):
        print(json.dumps({"error": "veriloglavd_path_missing",
                          "detail": "pass --lavd <path to VerilogLAVD repo>"}, ensure_ascii=False))
        sys.exit(2)

    te_dir = os.path.join(args.lavd, "src", "traversal_engine")
    if te_dir not in sys.path:
        sys.path.insert(0, te_dir)

    from neo4j import GraphDatabase          # noqa: E402
    import veripg_construct                  # noqa: E402
    import traversal_functions               # noqa: F401  导入即注册遍历原语
    from traversal_engine import TraversalEngine   # noqa: E402
    from function_registry import FUNCTION_REGISTRY  # noqa: E402

    uri = args.uri or os.environ.get("NEO4J_URI") or load_repo_config(args.lavd)[0]
    user = args.user or os.environ.get("NEO4J_USER") or "neo4j"
    pwd = args.password or os.environ.get("NEO4J_PASSWORD") or load_repo_config(args.lavd)[2]
    if not pwd:
        print(json.dumps({"error": "no_password"}, ensure_ascii=False))
        sys.exit(2)

    patterns = json.load(open(args.patterns, encoding="utf-8"))
    vfiles = sorted(glob.glob(os.path.join(args.rtl_dir, "**", "*.v"), recursive=True))
    if not vfiles:
        print(json.dumps({"error": f"no .v files under {args.rtl_dir}"}, ensure_ascii=False))
        sys.exit(2)

    # 命中节点的结构路径（证据链）: 沿 AST/CFG/DDG 边收集后代语句节点
    EVIDENCE_CYPHER = (
        "MATCH (a)-[r:AST|CFG|DDG*1..6]->(d) WHERE elementId(a)=$eid "
        "WITH DISTINCT d WHERE d.lineno IS NOT NULL "
        "RETURN coalesce(d.name, head(labels(d))) AS name, d.lineno AS line "
        "ORDER BY line LIMIT 40"
    )

    # 证据链只保留关键结构节点（If/赋值/块），过滤表达式碎片噪声
    KEY_NODES = {"Always", "IfStatement", "NonblockingSubstitution",
                 "BlockingSubstitution", "CaseStatement", "ForStatement",
                 "WhileStatement", "Block"}

    def evidence_for(session, eid: str, hit_line) -> list:
        ev, fallback = [], []
        seen = set()
        try:
            for rec in session.run(EVIDENCE_CYPHER, eid=eid):
                name, line = rec["name"], rec["line"]
                key = (name, line)
                if key in seen or (line is not None and str(line) == str(hit_line)):
                    continue
                seen.add(key)
                txt = f"line {line}: {name} node on the matched structural path"
                if name in KEY_NODES:
                    ev.append(txt)
                elif len(fallback) < 3:
                    fallback.append(txt)
                if len(ev) >= 5:
                    break
        except Exception:
            pass
        return ev if ev else fallback

    results = []
    for vf in vfiles:
        entry = {"file": os.path.relpath(vf, args.rtl_dir).replace("\\", "/"),
                 "patterns": [], "nodes": 0, "rels": 0}
        t0 = time.time()
        try:
            driver = GraphDatabase.driver(uri, auth=(user, pwd))
            try:
                nodes_count, rels_count = veripg_construct.VeriPG(vf, driver)
                entry["nodes"], entry["rels"] = nodes_count, rels_count
                with driver.session() as session:
                    engine = TraversalEngine(session, FUNCTION_REGISTRY)
                    for pat in patterns:
                        try:
                            hits = engine.execute(copy.deepcopy(pat["pattern"]))
                            hits = hits if isinstance(hits, list) else []
                            details = []
                            for eid in hits:
                                rec = session.run(
                                    "MATCH (n) WHERE elementId(n) = $eid "
                                    "RETURN n.name AS name, n.lineno AS lineno",
                                    eid=eid).single()
                                info = {"name": rec["name"] if rec else "?",
                                        "lineno": rec["lineno"] if rec else "?"}
                                info["evidence"] = (
                                    [f"Always block matched at line {info['lineno']} ({info['name']})"]
                                    + evidence_for(session, eid, info["lineno"]))
                                details.append(info)
                            entry["patterns"].append({
                                "cwe": pat.get("cwe", "unknown"),
                                "desc": pat.get("desc", ""),
                                "severity": pat.get("severity", "medium"),
                                "hit_count": len(hits),
                                "hits": details,
                            })
                        except Exception as pe:  # 单个模式失败不影响其余
                            entry["patterns"].append({"cwe": pat.get("cwe", "?"),
                                                      "error": str(pe)[:200]})
            finally:
                driver.close()
            entry["status"] = "ok"
        except Exception as e:  # noqa: BLE001
            entry["status"] = "error"
            entry["error"] = str(e)[:300]
        entry["time"] = round(time.time() - t0, 1)
        results.append(entry)
        print(f"[lavd_bridge] {entry['file']}: {entry['status']} "
              f"({entry['nodes']}n/{entry['rels']}r, {entry['time']}s)", file=sys.stderr)

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump({"uri": uri, "pattern_count": len(patterns),
                   "files": results}, f, ensure_ascii=False, indent=1)
    print(f"[lavd_bridge] done -> {args.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
