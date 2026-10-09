# RTL-SecCheck

Local-first RTL hardware security analysis tool: **web UI + Vivado Tcl plugin**, powered by two
open-source detection engines.

- **VerilogLAVD** — CWE vulnerability detection via property-graph traversal
  ([Chip-Security-Lab/VerilogLAVD](https://github.com/Chip-Security-Lab/VerilogLAVD))
- **VeriPVD** — LLM-based cross-module permission-flow analysis
  ([anwen0724/VeriPVD](https://github.com/anwen0724/VeriPVD))

One scan gives you: a unified finding report, an interactive module-dependency graph with
vulnerability annotations, and per-finding LLM fix suggestions with an iverilog baseline check.

```
RTL dir ──► RTL-SecCheck backend (FastAPI, port 8321)
              ├─► VerilogLAVD: pyverilog parse ─► Neo4j graph ─► CWE pattern traversal
              └─► VeriPVD:     config gen ─► structure graph ─► permission chain ─► LLM analysis
                        │
        ┌───────────────┴────────────────┐
        ▼                                ▼
   Web UI (browser)              Vivado Tcl plugin (seccheck.tcl)
   report / graph / fix          scan / status / report / fix / graph
```

## Requirements (Windows)

| Component | Needed for | Note |
|---|---|---|
| Python 3.10+ | backend | check "Add python.exe to PATH" in installer |
| Git | cloning repos | [git-scm.com](https://git-scm.com) |
| Neo4j Desktop | VerilogLAVD graph DB | free, [neo4j.com/download](https://neo4j.com/download) — start the DB before scanning |
| iverilog | fix verification (optional) | [bleyer.org/icarus](http://bleyer.org/icarus) — auto-detected from PATH, or set path in Settings |
| Vivado | Tcl plugin only (optional) | any recent version; the web UI works without it |
| LLM API key | VeriPVD LLM analysis + fix suggestions | DeepSeek/Qwen/GLM/OpenAI-compatible. Without a key the tool runs in rule mode (VeriPVD LLM steps skipped) |

## Quick start

```bat
git clone <this-repo-url> RTL-SecCheck
cd RTL-SecCheck

:: create the backend venv and install dependencies (ONCE)
python -m venv backend\.venv
backend\.venv\Scripts\python.exe -m pip install -r requirements.txt

git clone https://github.com/anwen0724/VeriPVD
git clone https://github.com/Chip-Security-Lab/VerilogLAVD
```

> If `python` is not recognized, install Python 3.10+ from
> [python.org](https://www.python.org/downloads/) and check **"Add python.exe to PATH"**
> during setup, then reopen the terminal.

Note on dependencies: the backend itself only needs `fastapi + uvicorn + pydantic` (see
`requirements.txt` — LLM calls use the stdlib). `pyverilog` / `neo4j` are dependencies of the
**engine repos** and go into each engine's own venv, as above.

Set up each engine repo's own Python environment following its README (typically
`python -m venv .venv` + `pip install -r requirements.txt` inside each repo).

**Configure:** the first launch auto-creates `backend/settings.json`. Open it in any text
editor and fill in your values:

```json
{
  "veripvd_path":    "C:/tools/VeriPVD",
  "verilavlvd_path": "C:/tools/VerilogLAVD",
  "neo4j_password":  "your-neo4j-password",
  "api_key":         "sk-your-llm-api-key",
  "llm_model":       "deepseek-chat"
}
```

| Field | Meaning |
|---|---|
| `veripvd_path` / `verilavlvd_path` | paths to the two engine clones (their `.venv` pythons are auto-detected) |
| `neo4j_password` | must match your Neo4j database |
| `api_key` / `llm_model` | LLM key + model (e.g. `deepseek-chat`); without a key the tool runs in rule mode |

Settings are re-read on every request — save the file and you're done (restart `start.bat` if
in doubt). The web **Settings** page edits the same file; use whichever you prefer.

Try it on the bundled demo: scan `examples/demo_soc` — a 6-module SoC with planted, hint-free
vulnerabilities (no giveaway comments, so it fairly tests whether the tool really works).

## Using the web UI

1. **Scan** page: enter an RTL directory, click scan (engines run in the background)
2. **Report** page: unified findings with severity/type/location/evidence; "generate fix
   suggestion" calls the LLM per finding (30–60 s) and runs an iverilog baseline compile
3. **Graph** page: module dependency graph with findings mapped onto nodes
4. **Settings** page: paths, API key (masked after save, stored locally only)

## Using the Vivado Tcl plugin

In Vivado's Tcl Console:

```tcl
source {C:/path/to/RTL-SecCheck/tcl/seccheck.tcl}
seccheck help
```

Sourcing **auto-starts the backend** if it is not running yet (a minimized service window
appears; keep it open). You can also start/stop it manually with `seccheck start` or by
double-clicking `start.bat`.

| Command | Effect |
|---|---|
| `seccheck start` | start the local backend from here |
| `seccheck scan <rtl_dir> [none\|pvd\|lavd\|both]` | start a background scan |
| `seccheck status` | progress / logs |
| `seccheck report` | findings table (id / severity / file:line) |
| `seccheck fix <finding_id>` | LLM fix suggestion in English (30–60 s) |
| `seccheck graph` | open the graph view in browser |
| `seccheck web [report\|graph]` | open the full web UI |

Note: the Vivado Tcl console cannot display non-ASCII text, so all plugin output is English by
design; use `seccheck web` for the full UI.

## Known limitations

- VerilogLAVD integration ships with one built-in structural pattern seed (`CWE-STRUCT-SEQ-COND`);
  the paper's full 37-CWE template set can be added to `backend/lavd_patterns.json`
- VeriPG clears the whole Neo4j database on each graph build — do not share the DB with other tools
- VeriPVD line numbers are often module-level granularity (its LLM output schema)
- `seccheck fix` calls the LLM every time (no cache) — each call costs tokens

## Credits

Built on top of [VerilogLAVD](https://github.com/Chip-Security-Lab/VerilogLAVD) (ACL 2026) and
[VeriPVD](https://github.com/anwen0724/VeriPVD). Please cite the original papers if you use this
tool in research.
