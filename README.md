# RTL-SecCheck

RTL-SecCheck 是一个面向 Verilog RTL 的本地硬件安全分析工具，提供 Web 界面、VS Code 插件和 Vivado Tcl 插件。它将 VerilogLAVD 的 CWE 结构化检测与 VeriPVD 的权限流分析整合到同一套扫描流程中。

一次扫描可以生成：

- 统一漏洞报告：漏洞类型、严重级别、文件位置和证据链
- 模块依赖图：展示模块之间的连接关系，并标注漏洞位置
- 修复建议：针对单个 finding 生成 LLM 修复建议，并支持基础编译验证
- 多入口使用：VS Code 面板和 Vivado Tcl Console

## 项目组成

```text
RTL 目录
   │
   ▼
RTL-SecCheck 后端（FastAPI，默认端口 8321）
   ├── VerilogLAVD：解析 RTL → Neo4j 属性图 → CWE 模式检测
   └── VeriPVD：生成权限流分析配置 → 结构分析 → LLM 分析
   │
   ├── VS Code 插件：侧边栏扫描、报告、依赖图和修复建议
   └── Vivado Tcl 插件：扫描、状态、报告和修复建议
```

## 依赖环境（Windows）

| 组件 | 用途 | 说明 |
|---|---|---|
| Python 3.10+ | 运行后端 | 安装时建议勾选 Add Python to PATH |
| Git | 下载项目和检测引擎 | 用于克隆 VeriPVD、VerilogLAVD |
| Neo4j Desktop | VerilogLAVD 图数据库 | 使用 LAVD 检测前启动数据库 |
| iverilog | 修复建议基础验证 | 可选，未安装时跳过编译验证 |
| Vivado | Vivado Tcl 插件 | 可选，VS Code 插件不依赖 Vivado |
| LLM API Key | VeriPVD LLM 分析和修复建议 | 未配置时使用规则模式和本地降级建议 |

后端 `requirements.txt` 只包含 RTL-SecCheck 后端本身的依赖：FastAPI、Uvicorn 和 Pydantic。VerilogLAVD 与 VeriPVD 的依赖安装在各自引擎目录的虚拟环境中。

## 快速开始

### 1. 下载项目

```bat
git clone https://github.com/xv0303/RTL-SecCheck.git
cd RTL-SecCheck
```

也可以在 GitHub 项目页面下载 ZIP 压缩包：

<https://github.com/xv0303/RTL-SecCheck>

### 2. 创建后端环境并安装依赖

```bat
python -m venv backend\.venv
backend\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

### 3. 下载检测引擎

```bat
git clone https://github.com/anwen0724/VeriPVD
git clone https://github.com/Chip-Security-Lab/VerilogLAVD
```

按照两个引擎仓库各自的 README 创建并安装它们的虚拟环境。引擎依赖不会重复写入 RTL-SecCheck 的后端依赖文件。

### 4. 启动后端

在项目根目录双击 `start.bat`，或者手动运行：

```bat
backend\.venv\Scripts\python.exe -m uvicorn --app-dir backend main:app --host 127.0.0.1 --port 8321
```

启动后端后，VS Code 插件和 Vivado Tcl 插件即可连接本地 API 服务。

## 配置

首次启动后端会自动创建 `backend/settings.json`。可以通过 VS Code 设置面板或文本编辑器修改：

```json
{
  "veripvd_path": "C:/tools/VeriPVD",
  "verilavlvd_path": "C:/tools/VerilogLAVD",
  "neo4j_uri": "bolt://localhost:7687",
  "neo4j_user": "neo4j",
  "neo4j_password": "your-neo4j-password",
  "api_key": "your-llm-api-key",
  "llm_model": "deepseek-chat",
  "rtl_dir": "C:/path/to/rtl"
}
```

主要字段说明：

| 字段 | 说明 |
|---|---|
| `veripvd_path` | VeriPVD 仓库路径 |
| `verilavlvd_path` | VerilogLAVD 仓库路径 |
| `neo4j_uri`、`neo4j_user`、`neo4j_password` | Neo4j 连接信息 |
| `api_key` | LLM 服务商 API Key，仅保存在本机 |
| `llm_model` | 使用的模型名称，例如 `deepseek-chat`、`gpt-4o`、`claude-sonnet-4` 或 `gemini-2.5-pro` |
| `rtl_dir` | 默认扫描目录 |

设置保存按字段合并，并使用线程锁和临时文件原子替换，多个保存请求不会互相覆盖。

## 使用 VS Code 插件

VS Code 插件负责面板交互，后端服务负责扫描和报告处理。插件安装后需要连接本地 RTL-SecCheck 后端。

### 从插件市场安装

在 VS Code 扩展市场搜索 `RTL-SecCheck`，点击安装。首次打开面板时，插件会自动探测本地后端；如果未检测到后端，面板会显示安装步骤和“重新连接”按钮。

### 从 VSIX 安装

项目的 `vscode-extension` 目录包含 VSIX 安装包。也可以在 VS Code 中选择：

```text
扩展 → … → 从 VSIX 安装
```

或者运行：

```bat
code --install-extension vscode-extension\csl-rtl-seccheck-0.1.1.vsix
```

如果插件无法自动定位项目根目录，可以在 VS Code 设置中配置 `cslRtlSeccheck.projectRoot`，指向包含 `backend/main.py` 的 RTL-SecCheck 目录。

## 使用 VS Code 面板

1. 在 VS Code 中打开 RTL-SecCheck 面板。
2. 在“扫描目标目录”中选择 RTL 目录。
3. 在引擎下拉框中选择“双引擎”“仅 LAVD”或“仅 PVD”。
4. 点击“启动并扫描”。
5. 在报告卡中查看漏洞、证据链和文件位置。
6. 点击“查看依赖图”分析模块关系。
7. 在具体 finding 中生成修复建议。

进度条统一使用后端返回的 `0–100` 百分比，并限制在合法范围内。未知模型会直接返回明确错误，不会静默发送到其他服务商。

## 使用 Vivado Tcl 插件

在 Vivado Tcl Console 中运行：

```tcl
source {C:/path/to/RTL-SecCheck/tcl/seccheck.tcl}
seccheck help
```

常用命令：

| 命令 | 作用 |
|---|---|
| `seccheck start` | 启动本地后端 |
| `seccheck scan <rtl_dir> [pvd\|lavd\|both]` | 启动扫描 |
| `seccheck status` | 查看扫描进度和日志 |
| `seccheck report` | 查看漏洞报告 |
| `seccheck fix <finding_id>` | 生成修复建议 |
| `seccheck graph` | 将当前扫描的依赖图导出为 JSON 文件 |

Vivado Tcl 的 `seccheck graph` 会在当前目录生成 `RTL-SecCheck-<scan_id>-graph.json`。需要交互式查看依赖图时，请打开 VS Code RTL-SecCheck 面板。

## 本版本修复内容

- 进度条统一使用后端 `0–100` 百分比，并限制在合法范围内。
- 未知模型直接报错并停止请求，不再静默回退到 DeepSeek。
- 设置保存使用线程锁、最新配置合并和原子替换，避免并发覆盖与半截 JSON。
- 目录保存确认增加请求标识，迟到响应不会覆盖用户的新输入。
- 扫描会话隔离，取消、重扫或切换后端后，旧响应会被丢弃。
- 轮询请求串行执行，避免重复轮询和旧状态覆盖新状态。
- Windows 盘符、空格和中文路径可以正确解析。
- 修复建议失败后可以重试，成功建议会被缓存。
- Claude、Gemini 等模型使用对应的原生接口。
- VS Code 面板在检测不到后端时提供安装指引和“重新连接”按钮。

## 测试

扩展端回归测试：

```bat
node --test tests/extension.test.cjs
```

后端测试：

```bat
backend\.venv\Scripts\python.exe -B -m unittest discover -s tests -p test_backend.py -v
```

测试使用模拟网络响应和虚拟 Key，不会向真实模型服务商发送请求。

## 目录结构

```text
RTL-SecCheck/
├── backend/              后端服务和检测协调逻辑
├── vscode-extension/     VS Code 插件源码和 VSIX
├── tcl/                  Vivado Tcl 插件
├── examples/             示例 RTL 工程
├── tests/                自动化测试
├── requirements.txt      后端依赖
└── start.bat             Windows 启动脚本
```

## 相关项目

- [VerilogLAVD](https://github.com/Chip-Security-Lab/VerilogLAVD)
- [VeriPVD](https://github.com/anwen0724/VeriPVD)

## 安全提示

`backend/settings.json` 可能包含 API Key 和 Neo4j 密码。该文件已加入 `.gitignore`，请不要将它提交到 GitHub。

## License

MIT。VerilogLAVD、VeriPVD 及其依赖项目遵循各自的许可证。
