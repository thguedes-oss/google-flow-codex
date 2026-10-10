"""Meaningful controls: zero budget, stale bindings, handoff drift and unknown sends."""
import csv
from datetime import date
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from preflight import preflight, plan_sha256
from helpers import png, technical_direction


class PreflightTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="flow-local-test-")
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name) / "project"
        shutil.copytree(ROOT / "projects/exemplo-duas-cenas", self.project)
        self.data = json.loads((self.project / "project.json").read_text(encoding="utf-8"))
        self.caps = json.loads((ROOT / "config/flow-capabilities.json").read_text(encoding="utf-8"))
        self.caps["verified_on"] = date.today().isoformat()

    def check(self):
        (self.project / "project.json").write_text(json.dumps(self.data), encoding="utf-8")
        return preflight(self.project, self.caps)

    def recorded_conditions(self):
        # Synthetic files for bookkeeping tests only; never visual approvals.
        evidence = self.project / "outputs/test-evidence.txt"
        evidence.write_text("synthetic evidence fixture", encoding="utf-8")
        for index, asset in enumerate(self.data["assets"]):
            path = f"assets/test-{index}.png"
            raw = png(self.project / path, (index * 30, 60, 90)).read_bytes()
            asset.update(path=path, approved=True, sha256=hashlib.sha256(raw).hexdigest())
        for scene in self.data["scenes"]:
            scene["bindings"] = {a["handle"]: {"flow_asset": f"test-{a['handle']}", "sha256": a["sha256"], "evidence": "outputs/test-evidence.txt"} for a in self.data["assets"]}
        self.data["generation"].update(budget_credits=40, authorization="synthetic test only", cost_per_result_credits=20,
                                      resolution=720, audio={"intent": "ambient"},
                                      ui_verified=True, ui_verified_on=date.today().isoformat(), ui_evidence="outputs/test-evidence.txt")
        self.data["generation"]["ui_plan_sha256"] = plan_sha256(self.project, self.data)

    def test_example_is_valid_planning_and_cannot_generate(self):
        result = self.check()
        self.assertTrue(result["planning_passed"], result["errors"])
        self.assertFalse(result["generation_ready"])
        self.assertEqual(result["credits_spent"], 0)
        self.assertIn("Orçamento de geração é zero.", result["blockers"])

    def test_direction_must_be_complete_when_present(self):
        path = self.project / self.data["scenes"][0]["review_plan"]
        plan = json.loads(path.read_text(encoding="utf-8"))
        for direction in (None, {}, dict(technical_direction(), purpose="   "),
                          dict(technical_direction(), action_result=12),
                          {k: v for k, v in technical_direction().items() if k != "graphics_intent"}):
            with self.subTest(direction=direction):
                path.write_text(json.dumps(dict(plan, direction=direction)), encoding="utf-8")
                self.assertFalse(self.check()["planning_passed"])
        path.write_text(json.dumps(dict(plan, direction=technical_direction())), encoding="utf-8")
        self.assertTrue(self.check()["planning_passed"])
        plan.pop("direction", None)
        path.write_text(json.dumps(plan), encoding="utf-8")
        self.assertTrue(self.check()["planning_passed"])

    def test_direction_change_invalidates_ui_fingerprint(self):
        self.recorded_conditions()
        path = self.project / self.data["scenes"][0]["review_plan"]
        plan = json.loads(path.read_text(encoding="utf-8"))
        path.write_text(json.dumps(dict(plan, direction=technical_direction())), encoding="utf-8")
        self.assertFalse(self.check()["generation_ready"])

    def test_zero_budget_blocks_even_when_every_other_condition_is_recorded(self):
        self.recorded_conditions()
        self.assertTrue(self.check()["generation_ready"])
        self.data["generation"]["budget_credits"] = 0
        self.assertFalse(self.check()["generation_ready"])

    def test_current_capabilities_accept_omni_first_last_and_quality_six(self):
        for model, mode, duration in [("omni-flash-1.1", "first-last-frame", 8), ("veo-3.1-quality", "first-frame", 6)]:
            self.data.update(model=model, mode=mode)
            for scene in self.data["scenes"]:
                scene["duration_seconds"] = duration
            self.assertTrue(self.check()["planning_passed"])
        self.data.update(model="veo-3.1-quality", mode="references-to-video")
        self.assertFalse(self.check()["planning_passed"])

    def test_hand_transfer_between_scenes_is_rejected(self):
        self.data["scenes"][1]["state_in"]["right_hand"] = "vazia"
        self.data["scenes"][1]["state_in"]["left_hand"] = "@Caneca"
        self.assertFalse(self.check()["planning_passed"])

    def test_reference_bytes_changed_after_binding_cannot_generate(self):
        self.recorded_conditions()
        (self.project / self.data["assets"][0]["path"]).write_bytes(b"changed asset")
        result = self.check()
        self.assertFalse(result["generation_ready"])
        self.assertTrue(any("SHA-256" in value for value in result["blockers"]))

    def test_unknown_attempt_blocks_resubmission(self):
        self.recorded_conditions()
        with (self.project / "attempts.csv").open("a", encoding="utf-8", newline="") as stream:
            csv.writer(stream).writerow(["test-1", "", "01", "veo-3.1-fast", "references-to-video", "test", "", "", "20", "", "unknown", "", ""])
        self.assertFalse(self.check()["generation_ready"])

    def test_changed_prompt_invalidates_the_recorded_ui_check(self):
        self.recorded_conditions()
        prompt = self.project / self.data["scenes"][0]["prompt"]
        prompt.write_text(prompt.read_text(encoding="utf-8") + "\nChanged action.\n", encoding="utf-8")
        self.assertFalse(self.check()["generation_ready"])

    def test_insufficient_budget_blocks_the_planned_scenes(self):
        self.recorded_conditions()
        self.data["generation"]["budget_credits"] = 39
        self.assertFalse(self.check()["generation_ready"])

    def test_paths_cannot_escape_the_project(self):
        self.data["assets"][0]["path"] = "../outside.png"
        self.assertFalse(self.check()["planning_passed"])

    def test_negative_budget_is_rejected(self):
        self.data["generation"]["budget_credits"] = -1
        self.assertFalse(self.check()["planning_passed"])


if __name__ == "__main__":
    unittest.main()
