"""Shared model routing for scanning, key validation and fix generation.

Protocol references:
https://developers.openai.com/api/reference/resources/chat
https://platform.claude.com/docs/en/api/overview
https://ai.google.dev/api/generate-content
"""
from __future__ import annotations

import re

BASE_URLS = {
    "deepseek": "https://api.deepseek.com/v1",
    "qwen": "https://dashscope.aliyuncs.com/compatible-mode/v1",
    "gpt": "https://api.openai.com/v1",
    "claude": "https://api.anthropic.com/v1",
    "gemini": "https://generativelanguage.googleapis.com/v1beta",
    "glm": "https://open.bigmodel.cn/api/paas/v4",
    "moonshot": "https://api.moonshot.cn/v1",
}


def provider_of(model: str) -> str:
    name = (model or "").strip().lower()
    for prefix in BASE_URLS:
        if name.startswith(prefix):
            return prefix
    if re.match(r"^o\d+(?:-|$)", name) or name.startswith("chatgpt-"):
        return "gpt"
    raise ValueError(f"无法识别模型服务商：{model!r}，请检查 llm_model；不会自动发送到其他服务商")


def model_list_endpoint(model: str) -> tuple[str, str, str]:
    provider = provider_of(model)
    style = {"claude": "anthropic", "gemini": "google"}.get(provider, "bearer")
    return provider, BASE_URLS[provider] + "/models", style
