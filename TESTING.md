# v0.1.1 验证记录

## 自动回归

在项目根目录运行（需先安装扩展开发依赖及后端依赖）：

```powershell
Push-Location vscode-extension
npm run compile
Pop-Location
node --test tests/extension.test.cjs
backend\.venv\Scripts\python.exe -B -m unittest discover -s tests -p test_backend.py -v
```

测试使用模拟网络响应和虚拟 Key，不向模型服务商发送请求。

- 扩展：目录连续编辑、迟到确认、首次设置尚未到达时扫描、保存失败重试、点击时目录快照、取消及新扫描后的旧响应隔离、串行轮询、修复请求合并和重试、完整响应超时、进程启动互斥及退出清理、扫描命令、Windows 路径和进度。
- 后端：统一服务商路由、未知模型零网络请求、各协议认证头和响应解析、空回复报错、显式兼容网关、同 finding 在途合并、失败可重试、不同 finding 并发写回以及设置 patch 并发保存。
- 打包：检查 VSIX 版本、命令贡献、所有运行脚本与构建输出一致；核对 panel.html / panel.css 与修改前完全相同。

## 人工联调范围

真实 VS Code 交互、实际 Neo4j/检测引擎及真实模型 Key 尚需在使用环境联调。未执行真实引擎扫描或付费模型请求；自动回归不代替这些集成验证。

安装新 VSIX 后，应重启使用旧模块的后端进程，确保扩展与后端均使用新代码。后端地址保持不变，settings.json 与历史扫描报告不在本次替换范围内。

## 协议依据

- [OpenAI Chat Completions](https://developers.openai.com/api/reference/resources/chat)
- [Claude API overview](https://platform.claude.com/docs/en/api/overview)
- [Gemini generateContent](https://ai.google.dev/api/generate-content)
