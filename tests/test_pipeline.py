"""Integration contracts using temporary synthetic media and approvals only."""
import csv
from datetime import date
import json
import shutil
import subprocess
import sys
import unittest
from unittest.mock import patch

from helpers import ROOT, WorkspaceFixture, png, technical_direction
sys.path.insert(0, str(ROOT / "scripts"))
from attempt_snapshot import freeze, verify_snapshot
from flow_files import sha256, write_json
from flow_ledger import read_csv, write_csv
from flow_review import CRITERIA, close_review, compare_attempts, verify_decision
from metrics import metrics
from preflight import handoff_check, plan_sha256, preflight
from review_clip import enhanced_samples, review_clip


@unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "FFmpeg/FFprobe ausentes")
class PipelineTests(WorkspaceFixture, unittest.TestCase):
    def ready(self, scene=None):
        self.caps = json.loads((ROOT / "config/flow-capabilities.json").read_text(encoding="utf-8"))
        self.caps["verified_on"] = date.today().isoformat()
        (self.project / "outputs/evidence.txt").write_text("SYNTHETIC TEST ONLY", encoding="utf-8")
        for index, asset in enumerate(self.data["assets"]):
            path = png(self.project / f"assets/fixture-{index}.png", (index * 50, 60, 90))
            asset.update(path=path.relative_to(self.project).as_posix(), approved=True, sha256=sha256(path))
        for item in self.data["scenes"]:
            item["bindings"] = {a["handle"]: {"flow_asset": "SYNTHETIC", "sha256": a["sha256"], "evidence": "outputs/evidence.txt"} for a in self.data["assets"]}
        self.data["generation"].update(budget_credits=100, authorization="SYNTHETIC TEST ONLY", cost_per_result_credits=20,
                                       resolution=720, audio={"intent": "ambient"}, ui_verified=True,
                                       ui_verified_on=date.today().isoformat(), ui_evidence="outputs/evidence.txt")
        self.data["generation"]["ui_plan_sha256"] = plan_sha256(self.project, self.data, scene)
        self.save()

    def video_attempt(self, attempt_id="technical-1", *, enhanced=False, event_video=False):
        video = self.project / f"outputs/{attempt_id}.mkv"
        if event_video:
            command = [shutil.which("ffmpeg"), "-nostdin", "-v", "error", "-y", "-f", "lavfi", "-i", "color=black:s=96x64:r=8:d=3",
                       "-f", "lavfi", "-i", "color=white:s=96x64:r=8:d=3", "-f", "lavfi", "-i", "anullsrc=r=8000:cl=mono:d=6",
                       "-filter_complex", "[0:v][1:v]concat=n=2:v=1:a=0[v]", "-map", "[v]", "-map", "2:a", "-c:v", "ffv1", "-c:a", "pcm_s16le", str(video)]
        else:
            command = [shutil.which("ffmpeg"), "-nostdin", "-v", "error", "-y", "-f", "lavfi", "-i", "testsrc2=s=96x64:r=8:d=2", "-c:v", "ffv1", str(video)]
        subprocess.run(command, check=True, capture_output=True, timeout=30)
        fields, rows = read_csv(self.project / "attempts.csv")
        matches = [r for r in rows if r["attempt_id"] == attempt_id]
        if matches:
            row = matches[0]
        else:
            row = {key: "" for key in fields}
            row.update(attempt_id=attempt_id, scene_id="01", model="veo-3.1-fast", mode="references-to-video", reference_version="test")
            rows.append(row)
        row.update(status="completed", charged_credits="20", output_file=video.relative_to(self.project).as_posix())
        write_csv(self.project / "attempts.csv", fields, rows)
        report_path = review_clip(self.project, attempt_id, workspace_root=self.workspace, enhanced=enhanced)
        return report_path, json.loads(report_path.read_text(encoding="utf-8"))

    def spec(self, path, *, audio=False):
        return {"evidence_report": path.relative_to(self.project).as_posix(), "reviewer": "SYNTHETIC FIXTURE ONLY",
                "decision": "approved", "selected": True, "supersedes": None, "playback_completed": True,
                "audio_review": "reviewed" if audio else "not_applicable", "audio_reason": "Technical video has no audio",
                "intent_review": "Synthetic contract inspection only, not production approval",
                "criteria": [{"criterion": key, "severity": "0", "timestamps": "0-2s", "observation": "Synthetic fixture, not a visual approval."} for key in CRITERIA]}

    def test_declared_cut_is_structural_but_needs_review(self):
        scene = self.data["scenes"][1]
        old = scene["state_in"]["camera"]
        scene["state_in"]["camera"] = "changed shot"
        scene["continuity_changes"] = [{"field": "camera", "before": old, "after": "changed shot", "reason": "Deliberate test cut"}]
        self.ready()
        result = preflight(self.project, self.caps)
        self.assertTrue(result["planning_passed"], result["errors"])
        self.assertFalse(result["generation_ready"])
        scene["continuity_changes"][0].update(reviewer="TEST", evidence="outputs/evidence.txt")
        self.ready()
        self.assertTrue(preflight(self.project, self.caps)["generation_ready"])
        scene["state_in"]["right_hand"] = "unexpected transfer"
        self.save()
        self.assertFalse(preflight(self.project, self.caps)["planning_passed"])

    def test_future_continuation_does_not_block_first_scene(self):
        self.data["scenes"][1].update(transition="continuation", mode="first-frame")
        self.ready("01")
        self.assertTrue(preflight(self.project, self.caps, "01")["generation_ready"])
        self.assertFalse(preflight(self.project, self.caps, "02")["generation_ready"])

    def test_frame_slots_replace_ingredient_bindings(self):
        self.data["mode"] = "first-last-frame"
        self.ready()
        for scene in self.data["scenes"]:
            scene["bindings"] = {}
            image = self.data["assets"][0]
            scene["frames"] = {slot: {"path": image["path"], "sha256": image["sha256"], "approved": True,
                                      "binding": {"flow_asset": "TEST SLOT", "sha256": image["sha256"], "evidence": "outputs/evidence.txt"}}
                               for slot in ("initial", "final")}
        self.data["generation"]["ui_plan_sha256"] = plan_sha256(self.project, self.data)
        self.save()
        self.assertTrue(preflight(self.project, self.caps)["generation_ready"])
        self.data["scenes"][0]["frames"]["final"]["binding"]["sha256"] = "bad"
        self.save()
        self.assertFalse(preflight(self.project, self.caps)["generation_ready"])

    def test_snapshot_copies_only_bindings_used_by_selected_mode(self):
        self.data["scenes"][0]["mode"] = "first-frame"
        self.ready("01")
        scene = self.data["scenes"][0]
        image = self.data["assets"][0]
        scene["bindings"] = {"@Lia": {"evidence": "outputs/obsolete-element.png"}}
        scene["frames"] = {
            "initial": {"path": image["path"], "sha256": image["sha256"], "approved": True,
                        "binding": {"flow_asset": "TEST SLOT", "sha256": image["sha256"], "evidence": "outputs/evidence.txt"}},
            "final": {"path": "assets/unused-final.png"}}
        self.data["generation"]["ui_plan_sha256"] = plan_sha256(self.project, self.data, "01")
        self.save()
        self.assertTrue(preflight(self.project, self.caps, "01")["generation_ready"])
        freeze(self.project, "01", "technical-mode", workspace=self.workspace, capabilities=self.caps)
        roles = {item["role"] for item in verify_snapshot(self.project, "technical-mode")["files"]}
        self.assertIn("initial_binding", roles)
        self.assertNotIn("binding", roles)
        self.assertNotIn("final_frame", roles)

    def test_resolution_and_audio_invalidate_ui_fingerprint(self):
        self.ready()
        for key, value in (("resolution", 360), ("audio", {"intent": "silent"})):
            original = self.data["generation"][key]
            self.data["generation"][key] = value
            self.save()
            self.assertFalse(preflight(self.project, self.caps)["generation_ready"])
            self.data["generation"][key] = original

    def test_snapshot_survives_prompt_edit_and_detects_tampering(self):
        self.ready("01")
        freeze(self.project, "01", "technical-1", workspace=self.workspace, capabilities=self.caps)
        snapshot = verify_snapshot(self.project, "technical-1")
        prompt = self.project / self.data["scenes"][0]["prompt"]
        prompt.write_text("Changed current prompt", encoding="utf-8")
        self.assertEqual(verify_snapshot(self.project, "technical-1"), snapshot)
        self.assertFalse(preflight(self.project, self.caps, "01")["generation_ready"])
        frozen = self.project / snapshot["attempt"]["prompt_file"]
        frozen.write_text("tampered", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "congelado alterado"):
            verify_snapshot(self.project, "technical-1")

    def test_zero_budget_dry_run_creates_nothing(self):
        before = (self.project / "attempts.csv").read_bytes()
        result = freeze(self.project, "01", "technical-1", workspace=self.workspace, dry_run=True)
        self.assertFalse(result["generation_ready"])
        with self.assertRaisesRegex(ValueError, "não está pronta"):
            freeze(self.project, "01", "technical-1", workspace=self.workspace)
        self.assertEqual((self.project / "attempts.csv").read_bytes(), before)
        self.assertFalse((self.project / "outputs/attempts").exists())

    def test_interrupted_snapshot_blocks_resubmission(self):
        self.ready("01")
        with patch("attempt_snapshot.write_csv", side_effect=OSError("simulated interruption")):
            with self.assertRaises(OSError):
                freeze(self.project, "01", "technical-1", workspace=self.workspace, capabilities=self.caps)
        self.assertTrue(any("órfão" in s for s in preflight(self.project, self.caps, "01")["blockers"]))

    def test_review_uses_frozen_states_and_comparison_preserves_both_prompts(self):
        self.ready("01")
        freeze(self.project, "01", "technical-1", workspace=self.workspace, capabilities=self.caps)
        self.video_attempt()
        prompt = self.project / self.data["scenes"][0]["prompt"]
        prompt.write_text(prompt.read_text(encoding="utf-8").replace("a small glance", "one deliberate glance"), encoding="utf-8")
        self.ready("01")
        freeze(self.project, "01", "technical-2", workspace=self.workspace, capabilities=self.caps)
        self.video_attempt("technical-2")
        comparison = compare_attempts(self.project, "technical-1", "technical-2")
        self.assertTrue(comparison["same_recorded_conditions"])
        self.assertIn("deliberate", comparison["prompt_diff"])
        old_state = self.data["scenes"][0]["state_out"].copy()
        self.data["scenes"][0]["state_out"]["right_hand"] = "changed current plan"
        self.save()
        path = review_clip(self.project, "technical-1", workspace_root=self.workspace)
        self.assertEqual(read_json_local(path)["expected_state_out"], old_state)

    def test_formal_review_requires_playback_criteria_and_audio(self):
        path, report = self.video_attempt(event_video=True)
        spec = self.spec(path, audio=True)
        for invalid in (dict(spec, playback_completed=False), dict(spec, criteria=spec["criteria"][:-1]), dict(spec, audio_review="not_applicable")):
            with self.assertRaises(ValueError):
                close_review(self.project, "technical-1", invalid, workspace=self.workspace)
        decision = close_review(self.project, "technical-1", spec, workspace=self.workspace)
        self.assertEqual(verify_decision(self.project, decision)["decision"], "approved")
        # A later explicit rejection supersedes approval; old approval cannot unlock a handoff.
        spec.update(decision="rejected", selected=False, supersedes=read_json_local(decision)["decision_id"])
        close_review(self.project, "technical-1", spec, workspace=self.workspace)
        with self.assertRaisesRegex(ValueError, "substituída"):
            verify_decision(self.project, decision)

    def test_direction_is_frozen_in_both_review_modes_and_requires_human_observation(self):
        path = self.project / self.data["scenes"][0]["review_plan"]
        plan = read_json_local(path)
        write_json(path, dict(plan, direction=technical_direction()), replace=True)
        self.ready("01")
        freeze(self.project, "01", "technical-1", workspace=self.workspace, capabilities=self.caps)
        write_json(path, dict(plan, direction=dict(technical_direction(), purpose="Changed current intention")), replace=True)
        report_path, report = self.video_attempt()
        self.assertFalse(report["enhanced"])
        self.assertEqual(report["expected_direction"]["purpose"], "Temporary continuity contract only")
        enhanced_path = review_clip(self.project, "technical-1", workspace_root=self.workspace, enhanced=True)
        self.assertEqual(read_json_local(enhanced_path)["expected_direction"], report["expected_direction"])
        spec = self.spec(report_path)
        for value in (None, "", "   "):
            with self.subTest(intent_review=value), self.assertRaises(ValueError):
                close_review(self.project, "technical-1", dict(spec, intent_review=value), workspace=self.workspace)
        decision = close_review(self.project, "technical-1", spec, workspace=self.workspace)
        self.assertEqual(verify_decision(self.project, decision)["intent_review"], spec["intent_review"])

    def test_legacy_review_without_direction_needs_no_intent_review(self):
        path = self.project / self.data["scenes"][0]["review_plan"]
        plan = read_json_local(path)
        plan.pop("direction", None)
        write_json(path, plan, replace=True)
        report_path, report = self.video_attempt()
        self.assertIsNone(report.get("expected_direction"))
        spec = self.spec(report_path)
        spec.pop("intent_review")
        decision = close_review(self.project, "technical-1", spec, workspace=self.workspace)
        self.assertEqual(verify_decision(self.project, decision)["decision"], "approved")

    def test_handoff_requires_exact_last_frame_and_explicit_approval(self):
        path, report = self.video_attempt()
        decision = close_review(self.project, "technical-1", self.spec(path), workspace=self.workspace)
        frame = path.parent / report["last_frame"]
        scene = self.data["scenes"][1]
        scene.update(handoff={"review_decision": decision.relative_to(self.project).as_posix(),
                              "frame": frame.relative_to(self.project).as_posix(), "sha256": sha256(frame),
                              "frame_approval": {"approved": True, "reviewer": "TEST", "at": "2026-10-07", "evidence": "Synthetic only"}},
                     frames={"initial": {"sha256": sha256(frame)}})
        handoff_check(self.project, self.data["scenes"][0], scene)
        scene["handoff"]["frame_approval"]["approved"] = False
        with self.assertRaises(ValueError):
            handoff_check(self.project, self.data["scenes"][0], scene)

    def test_enhanced_detects_cut_black_freeze_and_silence_preserving_video(self):
        path, report = self.video_attempt(enhanced=True, event_video=True)
        types = {a["type"] for a in report["technical_alerts"]}
        self.assertTrue({"scene_change", "black_start", "freeze_start", "silence_start"}.issubset(types), types)
        self.assertGreater(len(report["samples"]), 5)
        self.assertLessEqual(len(report["samples"]), 25)
        self.assertEqual(report["samples"][-1]["frame_index"], report["decoded_frame_count"] - 1)
        self.assertEqual(report["source_sha256"], sha256(self.project / report["source_file"]))

    def test_sampling_budget_deduplicates_and_preserves_endpoints(self):
        samples, omitted = enhanced_samples([n / 10 for n in range(100)],
                                           [{"seconds": n / 10, "expected": "test"} for n in range(100)], [])
        self.assertEqual(len(samples), 25)
        self.assertGreater(omitted, 0)
        self.assertEqual(samples[0]["frame_index"], 0)
        self.assertEqual(samples[-1]["frame_index"], 99)

    def test_changed_video_invalidates_review_and_metrics(self):
        path, report = self.video_attempt()
        decision = close_review(self.project, "technical-1", self.spec(path), workspace=self.workspace)
        with (self.project / report["source_file"]).open("ab") as stream:
            stream.write(b"modified technical fixture")
        with self.assertRaisesRegex(ValueError, "Vídeo alterado"):
            verify_decision(self.project, decision)
        with self.assertRaises(ValueError):
            metrics(self.project)

    def test_metrics_empty_complete_and_unknown_cost(self):
        self.assertIsNone(metrics(self.project)["first_attempt_approval_rate"])
        path, _ = self.video_attempt()
        close_review(self.project, "technical-1", self.spec(path), workspace=self.workspace)
        result = metrics(self.project)
        self.assertEqual(result["first_attempt_approval_rate"], 1)
        self.assertEqual(result["selected_approved_seconds"], 2)
        self.assertEqual(result["flow_credits_per_selected_approved_second"], 10)
        fields, rows = read_csv(self.project / "attempts.csv")
        rows[0]["charged_credits"] = ""
        write_csv(self.project / "attempts.csv", fields, rows)
        result = metrics(self.project)
        self.assertIsNone(result["flow_credits_per_selected_approved_second"])
        self.assertEqual(result["unreconciled_attempts"], ["technical-1"])


def read_json_local(path):
    return json.loads(path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
