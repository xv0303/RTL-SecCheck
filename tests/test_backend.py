"""Offline regressions. Dummy keys only; every HTTP/LLM call is mocked."""
import json
import sys
import tempfile
import threading
import unittest
from concurrent.futures import Future, ThreadPoolExecutor
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "backend"))
import fixgen
import engines
import main
from llm_providers import provider_of, model_list_endpoint


class RoutingTests(unittest.TestCase):
    def test_all_routes_and_unknown_model(self):
        for model, provider in [("deepseek-chat", "deepseek"), ("qwen-plus", "qwen"),
                                ("gpt-4o", "gpt"), ("o3", "gpt"), ("o4-mini", "gpt"),
                                ("claude-sonnet-4", "claude"), ("gemini-2.5-pro", "gemini")]:
            with self.subTest(model=model):
                self.assertEqual(provider_of(model), provider)
                self.assertEqual(engines._provider_of(model), provider)
                self.assertEqual(model_list_endpoint(model)[0], provider)
                self.assertEqual(fixgen._base_url(model), model_list_endpoint(model)[1].removesuffix("/models"))
        with patch("urllib.request.urlopen") as http:
            with self.assertRaises(ValueError):
                fixgen.llm_chat("dummy code", {"api_key": "dummy", "llm_model": "unrecognized"})
            self.assertFalse(main._api_key_check("dummy", "unrecognized")["ok"])
            http.assert_not_called()

    def test_native_and_compatible_requests(self):
        for model, host, header, response, payload_field in [
            ("claude-sonnet-4", "api.anthropic.com", "X-api-key", {"content": [{"type": "text", "text": "suggestion"}]}, "max_tokens"),
            ("gemini-2.5-pro", "generativelanguage.googleapis.com", "X-goog-api-key", {"candidates": [{"content": {"parts": [{"text": "suggestion"}]}}]}, "contents"),
            ("o3", "api.openai.com", "Authorization", {"choices": [{"message": {"content": "suggestion"}}]}, "messages"),
            ("deepseek-chat", "api.deepseek.com", "Authorization", {"choices": [{"message": {"content": "suggestion"}}]}, "messages"),
        ]:
            with self.subTest(model=model), patch("urllib.request.urlopen") as http:
                http.return_value.__enter__.return_value.read.return_value = json.dumps(response).encode()
                self.assertEqual(fixgen.llm_chat("dummy code", {"api_key": "dummy", "llm_model": model}), "suggestion")
                request = http.call_args.args[0]
                self.assertEqual(request.host, host)
                self.assertIn(header, request.headers)
                payload = json.loads(request.data)
                self.assertIn(payload_field, payload)
                if model == "o3":
                    self.assertNotIn("temperature", payload)

    def test_empty_response_is_failure_and_custom_gateway_remains_explicit(self):
        with patch("urllib.request.urlopen") as http:
            http.return_value.__enter__.return_value.read.return_value = b'{"choices":[{"message":{"content":""}}]}'
            with self.assertRaises(RuntimeError):
                fixgen.llm_chat("code", {"api_key": "dummy", "llm_model": "gpt-4o"})
            http.return_value.__enter__.return_value.read.return_value = b'{"choices":[{"message":{"content":"ok"}}]}'
            result = fixgen.llm_chat("code", {"api_key": "dummy", "llm_model": "claude-sonnet-4", "llm_base_url": "http://mock.invalid/v1"})
            self.assertEqual(result, "ok")
            self.assertEqual(http.call_args.args[0].full_url, "http://mock.invalid/v1/chat/completions")


class PersistenceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.directory = Path(self.tmp.name)
        self.report = self.directory / "report.json"
        self.report.write_text(json.dumps({"rtl_dir": self.tmp.name, "findings": [
            {"id": "F-A", "verification": {"status": "pass"}},
            {"id": "F-B", "verification": {"status": "pass"}}]}), encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    def test_parallel_fixes_preserve_both_updates_and_valid_json(self):
        barrier = threading.Barrier(2)
        def llm(prompt, *args, **kwargs):
            barrier.wait(timeout=3)
            return "suggestion for " + ("F-A" if "F-A" in prompt else "F-B")
        with patch.object(fixgen, "llm_chat", llm), ThreadPoolExecutor(2) as pool:
            results = list(pool.map(lambda fid: fixgen.generate_fix(self.tmp.name, "S-test", fid, {"api_key": "dummy"}), ["F-A", "F-B"]))
        report = json.loads(self.report.read_text(encoding="utf-8"))
        self.assertEqual(len(results), 2)
        self.assertTrue(all(f.get("fix_suggestion") for f in report["findings"]))
        self.assertEqual(list(self.directory.glob(".report-*.tmp")), [])

    def test_same_finding_is_coalesced_and_failure_can_retry(self):
        entered, joined, release = threading.Event(), threading.Event(), threading.Event()
        class ObservedFuture(Future):
            def result(self, *args, **kwargs):
                joined.set()
                return super().result(*args, **kwargs)
        def llm(*args, **kwargs):
            entered.set()
            if not release.wait(3):
                raise RuntimeError("test did not release LLM")
            return "ok"
        with patch.object(fixgen, "Future", ObservedFuture), patch.object(fixgen, "llm_chat", side_effect=llm) as call, ThreadPoolExecutor(2) as pool:
            first = pool.submit(fixgen.generate_fix, self.tmp.name, "S-test", "F-A", {"api_key": "dummy"})
            self.assertTrue(entered.wait(3))
            second = pool.submit(fixgen.generate_fix, self.tmp.name, "S-test", "F-A", {"api_key": "dummy"})
            self.assertTrue(joined.wait(3)); release.set()
            self.assertEqual(first.result()["fix_suggestion"], "ok")
            self.assertEqual(second.result()["fix_suggestion"], "ok")
            self.assertEqual(call.call_count, 1)
        with patch.object(fixgen, "llm_chat", side_effect=RuntimeError("offline")):
            with self.assertRaises(RuntimeError):
                fixgen.generate_fix(self.tmp.name, "S-test", "F-B", {"api_key": "dummy"})
        with patch.object(fixgen, "llm_chat", return_value="recovered"):
            self.assertEqual(fixgen.generate_fix(self.tmp.name, "S-test", "F-B", {"api_key": "dummy"})["fix_suggestion"], "recovered")

    def test_settings_patches_do_not_overwrite_each_other(self):
        settings = self.directory / "settings.json"
        settings.write_text("{}", encoding="utf-8")
        with patch.object(main, "SETTINGS_FP", settings), ThreadPoolExecutor(4) as pool:
            list(pool.map(main.save_settings, [{"rtl_dir": "C:/RTL"}, {"api_key": "dummy"}, {"neo4j_user": "user"}, {"neo4j_password": "dummy"}]))
        saved = json.loads(settings.read_text(encoding="utf-8"))
        self.assertEqual(saved["rtl_dir"], "C:/RTL")
        self.assertEqual(saved["api_key"], "dummy")
        self.assertEqual(saved["neo4j_user"], "user")
        self.assertEqual(saved["neo4j_password"], "dummy")

    def test_directory_only_save_does_not_validate_keys_or_database(self):
        with patch.object(main, "SETTINGS_FP", self.directory / "settings.json"), patch.object(main, "_neo4j_check_of") as neo, patch.object(main, "_api_key_check") as key:
            result = main.set_settings(main.SettingsIn(rtl_dir="C:/RTL"))
            self.assertTrue(result["ok"])
            self.assertNotIn("validation", result)
            neo.assert_not_called(); key.assert_not_called()


if __name__ == "__main__":
    unittest.main()
