# run_detection.py
# VerilogLAVD 复现入口：Verilog -> VeriPG(Neo4j) -> 图遍历检测
#
# 背景：官方 experiment_realworld.ipynb 依赖的 graph_pattern.py 未随仓库发布，
#       因此本脚本内置一个演示用的图遍历模式（结构模式），跑通"建图 -> 检测"全流程。
#       每次检测一个文件（VeriPG() 每次会清空数据库重建）。
#
# 用法：
#   python run_detection.py                          # 每个数据类别默认测前 2 个 .v 文件
#   python run_detection.py --limit 5                # 每类别前 5 个
#   python run_detection.py --file path/to/xx.v      # 检测单个文件
#
# 前置条件：
#   1. pip install pyverilog neo4j tqdm
#   2. Icarus Verilog 已安装且在 PATH 中（pyverilog 依赖 iverilog，Vivado 不能替代）
#   3. Neo4j 5.x 已启动，下方 CONFIG 填好连接信息

import argparse
import copy
import glob
import os
import time

from neo4j import GraphDatabase

import traversal_functions  # noqa: F401  导入即把遍历原语注册进 FUNCTION_REGISTRY
from traversal_engine import TraversalEngine
from function_registry import FUNCTION_REGISTRY
import veripg_construct

# ========== CONFIG：改成你的 Neo4j 实际连接信息 ==========
URI = "bolt://localhost:7687"
USERNAME = "neo4j"
PASSWORD = "123456789"
# =========================================================

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DATASET_DIR = os.path.join(REPO_ROOT, "datasets", "data")

# 演示模式（结构模式）：
#   找出所有 Always 块，满足：CFG 后代中存在 If 语句，
#   且该 If 的 AST 后代中存在非阻塞赋值 "<="（NonblockingSubstitution）。
#   这是"受条件控制的时序赋值"这一类漏洞（如 CWE-1231 可选复位缺失）的公共结构要素。
#   真实 CWE 模式按同样格式编写，或由 LLM 模板生成（template_extraction，需另行补齐缺失文件）。
DEMO_PATTERN = {
    "Func": "Node",
    "Params": ["Always"],
    "Filter": {
        "Operator": "AND",
        "Condition": [
            {
                "Path": [
                    {"Func": "CFGOffspring", "Params": ["If"]},
                    {"Func": "CFGOffspring", "Params": ["<="]},
                ]
            }
        ],
    },
}


def get_node_info(session, element_id):
    """根据 elementId 取节点的类型与行号，便于定位"""
    rec = session.run(
        "MATCH (n) WHERE elementId(n) = $eid RETURN n.name AS name, n.lineno AS lineno",
        eid=element_id,
    ).single()
    if rec is None:
        return {"name": "?", "lineno": "?"}
    return {"name": rec["name"], "lineno": rec["lineno"]}


def detect_one(file_path, pattern):
    """对单个 Verilog 文件：建 VeriPG 图 -> 执行图遍历模式 -> 返回命中结果"""
    driver = GraphDatabase.driver(URI, auth=(USERNAME, PASSWORD))
    try:
        nodes_count, rels_count = veripg_construct.VeriPG(file_path, driver)
        with driver.session() as session:
            engine = TraversalEngine(session, FUNCTION_REGISTRY)
            t0 = time.time()
            hits = engine.execute(copy.deepcopy(pattern))
            elapsed = time.time() - t0
            hits = hits if isinstance(hits, list) else []
            details = [get_node_info(session, eid) for eid in hits]
        return {
            "nodes": nodes_count,
            "rels": rels_count,
            "hits": hits,
            "details": details,
            "time": elapsed,
        }
    finally:
        driver.close()


def collect_default_files(per_category):
    """每个 CWE 类别取前 per_category 个 .v 文件（含 NonVulnerability 对照组）"""
    files = []
    for category in sorted(os.listdir(DATASET_DIR)):
        cat_dir = os.path.join(DATASET_DIR, category)
        if not os.path.isdir(cat_dir):
            continue
        v_files = sorted(glob.glob(os.path.join(cat_dir, "**", "*.v"), recursive=True))
        files.extend(v_files[:per_category])
    return files


def main():
    parser = argparse.ArgumentParser(description="VerilogLAVD 复现：建图 + 图遍历检测")
    parser.add_argument("--file", help="指定单个 Verilog 文件路径")
    parser.add_argument("--limit", type=int, default=2, help="每个类别取的文件数（默认 2）")
    args = parser.parse_args()

    if args.file:
        files = [args.file]
    else:
        files = collect_default_files(args.limit)

    if not files:
        print("未找到任何 .v 文件，请检查 datasets/data 目录或用 --file 指定文件")
        return

    print(f"共 {len(files)} 个待检测文件\n")
    ok, fail = 0, 0
    for fp in files:
        rel = os.path.relpath(fp, REPO_ROOT)
        print("=" * 64)
        try:
            r = detect_one(fp, DEMO_PATTERN)
            print(f"文件: {rel}")
            print(f"VeriPG: {r['nodes']} 节点 / {r['rels']} 关系, 用时 {r['time']:.3f}s")
            print(f"命中 {len(r['hits'])} 处:")
            for d in r["details"]:
                print(f"  - {d['name']} (line {d['lineno']})")
            ok += 1
        except Exception as e:
            print(f"文件: {rel}")
            print(f"失败: {e}")
            fail += 1
    print("=" * 64)
    print(f"完成：成功 {ok}，失败 {fail}")


if __name__ == "__main__":
    main()
