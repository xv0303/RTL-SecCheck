"use strict";
/**
 * 引擎档位类型 + 未识别 cmd 的指令说明。
 *
 * 自由文本输入框已随 UI 重构删除（操作条改为下拉 + 按钮直选），原本的
 * 自然语言 parse() 不再有调用方，故整个退役。本文件现在只保留：
 *   - EngineMode：引擎档位类型（panelProvider / backend 两侧共用）
 *   - HELP_TEXT：宿主收到未识别 cmd 时在消息流内回复的指令说明（绝不弹窗）
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.HELP_TEXT = void 0;
/** 未识别 cmd → 消息流内回复的指令说明（「特别注意」要求的容错分支） */
exports.HELP_TEXT = [
    "未识别的指令。本面板没有文本输入，可用操作如下：",
    "• 底部操作条：选择引擎（切换即生效，无需确认）→ 点「▶ 启动并扫描」",
    "• 扫描完成后点操作条上方提示条里的「查看报告」，展开合并版报告卡",
    "• 点报告表格行展开详情：查看证据链 / 生成修复建议 / 查看依赖图",
    "• 操作条顶部「连接与扫描设置」：配置 Neo4j / API Key / 扫描目标目录",
    "• 进度卡「取消」按钮：取消本次扫描的进度跟踪",
].join("\n");
//# sourceMappingURL=commandParser.js.map