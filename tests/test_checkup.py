"""Regression probes use copied projects and temporary technical fixtures only."""
import copy
import json
import shutil
import sys
import unittest

from helpers import ROOT, WorkspaceFixture
import test_pipeline as pipeline

sys.path.insert(0, str(ROOT / "scripts"))
from attempt_snapshot import freeze, verify_snapshot
from flow_ledger import read_csv, write_csv
from flow_review_plan import load_review_plan
from preflight import plan_sha256, preflight
from review_clip import load_attempt, review_clip


@unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "FFmpeg/FFprobe ausentes")
class CheckupValidationTests(WorkspaceFixture, unittest.TestCase):
    ready = pipeline.PipelineTests.ready
    video_attempt = pipeline.PipelineTests.video_attempt

    def test_preflight_rejects_ambiguous_or_malformed_csv_before_credit_sum(self):
        self.ready("01")
        ledger = self.project / "attempts.csv"
        fields, _ = read_csv(ledger)
        row = {key: "" for key in fields}
        row.update(attempt_id="old", scene_id="01", status="failed", charged_credits="120")
        values = [row[key] for key in fields]
        cases = [(fields + ["charged_credits"], values + ["0"]),
                 (fields, values + ["extra"]), (fields, values[:-1])]
        for header, record in cases:
            with self.subTest(header=header, record=record):
                ledger.write_text(",".join(header) + "\n" + ",".join(record) + "\n", encoding="utf-8")
                result = preflight(self.project, self.caps, "01")
                self.assertFalse(result["planning_passed"], result)
                self.assertFalse(result["generation_ready"])
                self.assertEqual(result["credits_spent"], 0)

    def test_preflight_rejects_invalid_attempt_and_scene_identifiers(self):
        self.ready("01")
        ledger = self.project / "attempts.csv"
        fields, _ = read_csv(ledger)
        for aid in ("   ", "bad/id", "..", "a" * 81):
            with self.subTest(attempt=aid):
                row = {key: "" for key in fields}
                row.update(attempt_id=aid, scene_id="01", status="failed", charged_credits="0")
                write_csv(ledger, fields, [row])
                self.assertFalse(preflight(self.project, self.caps, "01")["planning_passed"])
        write_csv(ledger, fields, [])
        self.data["scenes"][0]["id"] = "bad/id"
        self.save()
        self.assertFalse(preflight(self.project, self.caps)["planning_passed"])

    def test_unclosed_csv_quote_cannot_hide_a_later_charged_attempt(self):
        self.ready("01")
        ledger = self.project / "attempts.csv"
        fields, _ = read_csv(ledger)
        old = {key: "" for key in fields}
        old.update(attempt_id="old", scene_id="01", status="failed", charged_credits="0", decision='"')
        spent = dict(old, attempt_id="spent", charged_credits="100", decision="rejected")
        ledger.write_text(
            ",".join(fields) + "\n" + ",".join(old[key] for key in fields) + "\n"
            + ",".join(spent[key] for key in fields) + "\n", encoding="utf-8")
        result = preflight(self.project, self.caps, "01")
        self.assertFalse(result["planning_passed"], result)
        self.assertFalse(result["generation_ready"])
        with self.assertRaisesRegex(ValueError, "CSV"):
            read_csv(ledger)

    def test_csv_reader_preserves_valid_quoted_multiline_observations(self):
        ledger = self.project / "review.csv"
        fields, _ = read_csv(ledger)
        row = {key: "" for key in fields}
        row.update(attempt_id="technical", scene_id="01", observation='First line, with "quotes".\nSecond line.')
        write_csv(ledger, fields, [row])
        self.assertEqual(read_csv(ledger), (fields, [row]))

    def test_review_loader_uses_strict_csv_reader(self):
        fields, _ = read_csv(self.project / "attempts.csv")
        row = {key: "" for key in fields}
        row.update(attempt_id="technical", scene_id="01", status="completed", output_file="outputs/probe.txt")
        (self.project / "outputs/probe.txt").write_text("Loader probe only", encoding="utf-8")
        (self.project / "attempts.csv").write_text(
            ",".join(fields + ["status"]) + "\n" + ",".join(row[k] for k in fields) + ",completed\n",
            encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "CSV"):
            load_attempt(self.project, "technical")

    def test_review_moments_are_validated_during_planning(self):
        path = self.project / self.data["scenes"][0]["review_plan"]
        plan = json.loads(path.read_text(encoding="utf-8"))
        valid = {"seconds": 0, "expected": "Inspect the intended action"}
        bad = [None, "text", {}, dict(valid, seconds=True), dict(valid, seconds=-1),
               dict(valid, seconds=float("nan")), dict(valid, seconds=float("inf")),
               dict(valid, expected=" \t\n"), dict(valid, expected=5),
               dict(valid, criterion="unknown"), dict(valid, criterion=None)]
        for moment in bad:
            with self.subTest(moment=moment):
                path.write_text(json.dumps(dict(plan, moments=[moment])), encoding="utf-8")
                self.assertFalse(preflight(self.project)["planning_passed"])
                with self.assertRaises(ValueError):
                    load_review_plan(path)
        path.write_text(json.dumps({"schema_version": 1, "moments": [valid]}), encoding="utf-8")
        self.assertTrue(preflight(self.project)["planning_passed"])
        self.assertEqual(load_review_plan(path)["moments"], [valid])

    def test_continuity_reason_is_structural_and_reviewer_is_readiness(self):
        scene = self.data["scenes"][1]
        before = scene["state_in"]["camera"]
        scene["state_in"]["camera"] = "Deliberate temporary cut"
        change = {"field": "camera", "before": before, "after": scene["state_in"]["camera"],
                  "reason": "   ", "reviewer": "TEST", "evidence": "outputs/evidence.txt"}
        scene["continuity_changes"] = [change]
        self.ready("02")
        self.assertFalse(preflight(self.project, self.caps, "02")["planning_passed"])
        change.update(reason="Intentional cut", reviewer=" \t ")
        self.data["generation"]["ui_plan_sha256"] = plan_sha256(self.project, self.data, "02")
        self.save()
        result = preflight(self.project, self.caps, "02")
        self.assertTrue(result["planning_passed"], result)
        self.assertFalse(result["generation_ready"])

    def test_binding_labels_and_dialogue_language_require_real_text(self):
        self.ready("01")
        original = copy.deepcopy(self.data)
        for value in (" \t ", 7, ["text"]):
            with self.subTest(binding=value):
                self.data = copy.deepcopy(original)
                self.data["scenes"][0]["bindings"]["@Lia"]["flow_asset"] = value
                self.data["generation"]["ui_plan_sha256"] = plan_sha256(self.project, self.data, "01")
                self.save()
                self.assertFalse(preflight(self.project, self.caps, "01")["generation_ready"])
            with self.subTest(language=value):
                self.data = copy.deepcopy(original)
                self.data["generation"]["audio"] = {"intent": "dialogue", "language": value}
                self.data["generation"]["ui_plan_sha256"] = plan_sha256(self.project, self.data, "01")
                self.save()
                self.assertFalse(preflight(self.project, self.caps, "01")["generation_ready"])

    def test_frame_binding_label_rejects_whitespace(self):
        self.data["mode"] = "first-frame"
        self.ready("01")
        asset = self.data["assets"][0]
        self.data["scenes"][0]["frames"] = {"initial": {
            "path": asset["path"], "sha256": asset["sha256"], "approved": True,
            "binding": {"flow_asset": "   ", "sha256": asset["sha256"], "evidence": "outputs/evidence.txt"}}}
        self.data["generation"]["ui_plan_sha256"] = plan_sha256(self.project, self.data, "01")
        self.save()
        self.assertFalse(preflight(self.project, self.caps, "01")["generation_ready"])

    def test_shared_json_reader_accepts_windows_bom(self):
        self.ready("01")
        self.save()
        path = self.project / "project.json"
        path.write_text(path.read_text(encoding="utf-8"), encoding="utf-8-sig")
        self.assertTrue(preflight(self.project, self.caps, "01")["planning_passed"])

    def test_frozen_review_survives_missing_or_broken_current_manifest(self):
        self.ready("01")
        freeze(self.project, "01", "frozen", workspace=self.workspace, capabilities=self.caps)
        _, original = self.video_attempt("frozen")
        frozen = verify_snapshot(self.project, "frozen")
        manifest = self.project / "project.json"
        for broken in (True, False):
            with self.subTest(broken=broken):
                if broken:
                    manifest.write_text("{", encoding="utf-8")
                else:
                    manifest.unlink()
                try:
                    path = review_clip(self.project, "frozen", workspace_root=self.workspace)
                except (ValueError, OSError) as exc:
                    self.fail(f"A revisão congelada ainda depende do manifesto atual: {exc}")
                report = json.loads(path.read_text(encoding="utf-8"))
                self.assertEqual(report["expected_direction"], original["expected_direction"])
                self.assertEqual(report["expected_state_in"], original["expected_state_in"])
                self.assertEqual(verify_snapshot(self.project, "frozen"), frozen)

    def test_partial_snapshot_never_falls_back_to_live_manifest(self):
        fields, _ = read_csv(self.project / "attempts.csv")
        row = {key: "" for key in fields}
        row.update(attempt_id="partial", scene_id="01", status="completed", output_file="outputs/probe.txt")
        write_csv(self.project / "attempts.csv", fields, [row])
        (self.project / "outputs/probe.txt").write_text("Loader probe only", encoding="utf-8")
        directory = self.project / "outputs/attempts/partial"
        directory.mkdir(parents=True)
        for content in (None, "{}"):
            with self.subTest(marker=content):
                if content:
                    (directory / "registered.json").write_text(content, encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "congelamento|snapshot|Snapshot"):
                    load_attempt(self.project, "partial")

    def test_out_of_range_moment_is_reported_and_keeps_endpoint_sampling(self):
        plan_path = self.project / self.data["scenes"][0]["review_plan"]
        plan_path.write_text(json.dumps({"schema_version": 1, "moments": [
            {"seconds": 999, "expected": "Inspect the planned end"}]}), encoding="utf-8")
        _, report = self.video_attempt(enhanced=True)
        warnings = report.get("planned_moment_warnings", [])
        self.assertEqual(len(warnings), 1)
        self.assertEqual(warnings[0]["seconds"], 999)
        self.assertEqual(warnings[0]["sampling"], "nearest_endpoint")
        self.assertEqual(report["samples"][-1]["frame_index"], report["decoded_frame_count"] - 1)
        self.assertTrue(any(isinstance(reason, dict) and reason.get("planned_seconds") == 999
                            for reason in report["samples"][-1]["reasons"]))
