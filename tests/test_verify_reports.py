"""Verification reports must retain earlier runs and include real record audits."""
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import shutil
import subprocess
import sys
import unittest
from unittest.mock import patch

from helpers import ROOT, WorkspaceFixture

sys.path.insert(0, str(ROOT / "scripts"))
import verify


class VerificationReportTests(WorkspaceFixture, unittest.TestCase):
    def setUp(self):
        super().setUp()
        shutil.copytree(ROOT / "scripts", self.workspace / "scripts", ignore=shutil.ignore_patterns("__pycache__"))
        shutil.copytree(ROOT / "config", self.workspace / "config")
        shutil.copyfile(ROOT / "sources.lock.json", self.workspace / "sources.lock.json")
        self.lock = json.loads((self.workspace / "sources.lock.json").read_text(encoding="utf-8"))
        (self.workspace / self.lock["directory"]).mkdir(parents=True)
        self.real_run = subprocess.run
        self.commands = []

    def tool_stub(self, command, **kwargs):
        # Only the unrelated external checks are substituted. The history CLI runs for real.
        self.commands.append(command)
        if Path(command[1]).name == "flow_review.py":
            return self.real_run(command, **kwargs)
        output = "{}"
        if command[0] == "git":
            output = self.lock["commit"] if "rev-parse" in command else ""
        elif Path(command[1]).name == "generate_storyboard_prompt.py":
            output = Path(command[2]).with_suffix(".md").read_text(encoding="utf-8").strip()
        elif "unittest" in command:
            output = "Temporary verification test log"
        return subprocess.CompletedProcess(command, 0, stdout=output, stderr="")

    def run_verification(self, runner=None):
        tools = {"tools": {"tesseract": {"available": False}}, "ffmpeg": None, "ffprobe": None}
        with patch.object(verify, "ROOT", self.workspace), \
                patch.object(sys, "argv", ["verify.py", "--project", str(self.project), "--skip-upstream-tests"]), \
                patch("subprocess.run", side_effect=runner or self.tool_stub), \
                patch("tesseract_tools.doctor", return_value=tools), redirect_stdout(io.StringIO()):
            return verify.main()

    def test_runs_and_previous_flat_logs_are_preserved(self):
        reports = self.workspace / "reports"
        reports.mkdir()
        legacy_log = reports / "local-tests.txt"
        legacy_log.write_text("Previous real log must survive", encoding="utf-8")
        self.assertEqual(self.run_verification(), 0)
        latest = reports / "verification.json"
        first_bytes = latest.read_bytes()
        first = json.loads(first_bytes)
        self.assertEqual(self.run_verification(), 0)
        second = json.loads(latest.read_text(encoding="utf-8"))
        archives = list((reports / "runs").glob("*/verification.json"))
        self.assertEqual(len(archives), 2)
        self.assertNotEqual(first["run_id"], second["run_id"])
        self.assertEqual((reports / "runs" / first["run_id"] / "verification.json").read_bytes(), first_bytes)
        self.assertEqual((reports / "runs" / second["run_id"] / "verification.json").read_bytes(), latest.read_bytes())
        self.assertEqual(legacy_log.read_text(encoding="utf-8"), "Previous real log must survive")
        for report in (first, second):
            self.assertTrue(report["planning_passed"])
            self.assertFalse(report["generation_ready"])
            for check in report["checks"]:
                if "log" in check:
                    self.assertTrue(check["log"].startswith(f"reports/runs/{report['run_id']}/"))
                    self.assertTrue((self.workspace / check["log"]).is_file())

    def test_history_audit_failure_fails_the_general_check(self):
        self.assertEqual(self.run_verification(), 0)
        (self.project / "outputs/.records.lock").write_text("Temporary interrupted record", encoding="utf-8")
        self.assertEqual(self.run_verification(), 1)
        report = json.loads((self.workspace / "reports/verification.json").read_text(encoding="utf-8"))
        history = next(item for item in report["checks"] if item["name"] == "record-integrity")
        self.assertFalse(history["passed"])
        details = json.loads((self.workspace / history["log"]).read_text(encoding="utf-8"))
        self.assertTrue(any(item["code"] == "records_lock" for item in details["errors"]))
        self.assertFalse(report["planning_passed"])
        self.assertTrue((self.project / "outputs/.records.lock").exists())

    def test_preexisting_latest_report_is_archived_before_replacement(self):
        reports = self.workspace / "reports"
        reports.mkdir()
        previous = reports / "verification.json"
        old_bytes = b'{"verified_at_utc":"previous run","checks":[]}'
        previous.write_bytes(old_bytes)
        (reports / "source-clean.txt").write_text("Previous log", encoding="utf-8")
        self.assertEqual(self.run_verification(), 0)
        archives = list((reports / "runs").glob("legacy-*/verification.json"))
        self.assertEqual(len(archives), 1)
        self.assertEqual(archives[0].read_bytes(), old_bytes)
        self.assertEqual((archives[0].parent / "source-clean.txt").read_text(encoding="utf-8"), "Previous log")

    def test_interrupted_run_does_not_replace_latest_completed_report(self):
        self.assertEqual(self.run_verification(), 0)
        latest = self.workspace / "reports/verification.json"
        before = latest.read_bytes()
        with self.assertRaises(OSError):
            self.run_verification(runner=lambda *args, **kwargs: (_ for _ in ()).throw(OSError("Temporary interruption")))
        self.assertEqual(latest.read_bytes(), before)
