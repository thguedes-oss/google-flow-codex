"""Historical audit reads temporary bookkeeping; it never repairs or approves it."""
import json
import shutil
import subprocess
import sys
import unittest
from unittest.mock import patch

from helpers import ROOT, WorkspaceFixture
import test_pipeline as pipeline

sys.path.insert(0, str(ROOT / "scripts"))
import flow_review
from attempt_snapshot import freeze
from flow_files import sha256
from flow_ledger import read_csv, write_csv


@unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "FFmpeg/FFprobe ausentes")
class RecordAuditTests(WorkspaceFixture, unittest.TestCase):
    ready = pipeline.PipelineTests.ready
    video_attempt = pipeline.PipelineTests.video_attempt
    spec = pipeline.PipelineTests.spec

    def audit(self):
        self.assertTrue(callable(getattr(flow_review, "audit_records", None)), "Auditoria histórica ainda ausente")
        return flow_review.audit_records(self.project)

    def fingerprint(self):
        return {p.relative_to(self.project).as_posix(): sha256(p)
                for p in self.project.rglob("*") if p.is_file()}

    def test_empty_audit_is_read_only_and_requires_no_tools(self):
        before = self.fingerprint()
        with patch("subprocess.run", side_effect=AssertionError("Audit must not run tools")):
            report = self.audit()
        self.assertTrue(report["passed"], report)
        self.assertEqual(report["counts"], {"attempts": 0, "snapshots": 0, "decisions": 0, "evidence_reports": 0})
        self.assertEqual(before, self.fingerprint())

    def test_valid_superseded_decisions_are_not_errors(self):
        self.ready("01")
        freeze(self.project, "01", "technical-1", workspace=self.workspace, capabilities=self.caps)
        path, _ = self.video_attempt()
        first = flow_review.close_review(self.project, "technical-1", self.spec(path), workspace=self.workspace)
        replacement = self.spec(path)
        replacement.update(decision="rejected", selected=False,
                           supersedes=json.loads(first.read_text(encoding="utf-8"))["decision_id"])
        flow_review.close_review(self.project, "technical-1", replacement, workspace=self.workspace)
        before = self.fingerprint()
        report = self.audit()
        self.assertTrue(report["passed"], report)
        self.assertEqual(report["counts"], {"attempts": 1, "snapshots": 1, "decisions": 2, "evidence_reports": 1})
        self.assertTrue(any(item["code"] == "superseded_decision" for item in report["warnings"]))
        self.assertEqual(before, self.fingerprint())

    def test_altered_snapshot_is_reported(self):
        self.ready("01")
        freeze(self.project, "01", "technical-1", workspace=self.workspace, capabilities=self.caps)
        frozen = self.project / "outputs/attempts/technical-1/submitted_prompt.txt"
        frozen.write_text("Modified test fixture", encoding="utf-8")
        before = self.fingerprint()
        report = self.audit()
        self.assertFalse(report["passed"])
        self.assertTrue(any(item["code"] == "invalid_snapshot" for item in report["errors"]))
        self.assertEqual(before, self.fingerprint())

    def test_altered_evidence_and_decision_seal_are_reported(self):
        path, data = self.video_attempt()
        decision = flow_review.close_review(self.project, "technical-1", self.spec(path), workspace=self.workspace)
        image = path.parent / data["samples"][0]["image"]
        image.write_bytes(b"Changed technical evidence")
        (decision.parent / "registered.json").write_text("{}", encoding="utf-8")
        report = self.audit()
        self.assertFalse(report["passed"])
        self.assertTrue(any(item["code"] == "invalid_evidence" for item in report["errors"]))
        self.assertTrue(any(item["code"] == "invalid_decision" for item in report["errors"]))

    def test_partial_and_orphan_records_and_lock_are_preserved(self):
        (self.project / "outputs/.records.lock").write_text("Interrupted technical fixture", encoding="utf-8")
        (self.project / "outputs/attempts/orphan").mkdir(parents=True)
        (self.project / "outputs/decisions/orphan/partial").mkdir(parents=True)
        (self.project / "outputs/review/orphan/partial").mkdir(parents=True)
        before = self.fingerprint()
        report = self.audit()
        self.assertFalse(report["passed"])
        codes = {item["code"] for item in report["errors"]}
        self.assertTrue({"records_lock", "orphan_snapshot", "incomplete_decision", "incomplete_evidence"} <= codes, report)
        self.assertEqual(before, self.fingerprint())
        self.assertTrue((self.project / "outputs/.records.lock").exists())

    def test_legacy_attempt_and_unreviewed_evidence_are_warnings(self):
        self.video_attempt()
        report = self.audit()
        self.assertTrue(report["passed"], report)
        codes = {item["code"] for item in report["warnings"]}
        self.assertTrue({"legacy_without_snapshot", "unreviewed_evidence"} <= codes, report)

    def test_audit_rejects_csv_ambiguity_and_orphan_review_rows(self):
        ledger = self.project / "attempts.csv"
        original = ledger.read_bytes()
        header = ledger.read_text(encoding="utf-8").strip()
        ledger.write_text(header + ",charged_credits\n", encoding="utf-8")
        self.assertFalse(self.audit()["passed"])
        ledger.write_bytes(original)
        fields, rows = read_csv(self.project / "review.csv")
        row = {key: "" for key in fields}
        row.update(attempt_id="missing", scene_id="01", criterion="face", severity="0",
                   timestamps="0", observation="Temporary test only", decision="approved", reviewer="TEST")
        write_csv(self.project / "review.csv", fields, rows + [row])
        report = self.audit()
        self.assertFalse(report["passed"])
        self.assertTrue(any(item["code"] == "invalid_review_row" for item in report["errors"]))

    def test_explicit_failed_extraction_is_a_warning(self):
        self.video_attempt()
        directory = self.project / "outputs/review/technical-1/failed"
        directory.mkdir(parents=True)
        (directory / "failure.json").write_text(json.dumps({"status": "extraction_failed", "attempt_id": "technical-1",
                                                            "error": "Temporary fixture"}), encoding="utf-8")
        report = self.audit()
        self.assertTrue(report["passed"], report)
        self.assertTrue(any(item["code"] == "failed_extraction" for item in report["warnings"]))

    def test_invalid_failure_record_does_not_hide_interrupted_extraction(self):
        directory = self.project / "outputs/review/orphan/partial"
        directory.mkdir(parents=True)
        (directory / "failure.json").write_text("{}", encoding="utf-8")
        report = self.audit()
        self.assertFalse(report["passed"])
        self.assertTrue(any(item["code"] == "invalid_failure" for item in report["errors"]))

    def test_cli_audit_returns_json_and_failure_exit_code(self):
        shutil.copytree(ROOT / "scripts", self.workspace / "scripts", ignore=shutil.ignore_patterns("__pycache__"))
        command = [sys.executable, "-X", "utf8", str(self.workspace / "scripts/flow_review.py"),
                   "audit", "--project", str(self.project)]
        result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(json.loads(result.stdout)["passed"])
        (self.project / "outputs/.records.lock").write_text("Technical lock", encoding="utf-8")
        result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", timeout=20)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertFalse(json.loads(result.stdout)["passed"])
