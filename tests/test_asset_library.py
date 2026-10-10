import json
import shutil
import sys
import unittest

from helpers import ROOT, WorkspaceFixture, png
sys.path.insert(0, str(ROOT / "scripts"))
from asset_library import candidate, import_asset, promote, verify_library
from flow_files import sha256


@unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "FFmpeg/FFprobe ausentes")
class LibraryTests(WorkspaceFixture, unittest.TestCase):
    def register(self):
        source = png(self.project / "assets" / "fixture.png")
        spec = {"schema_version": 1, "asset_id": "fixture", "version": "v1", "kind": "character",
                "tool": "image_gen", "generated_at": "2026-10-07T00:00:00Z",
                "prompt": "TECHNICAL FIXTURE ONLY", "observed_description": "Synthetic color test, not Lia.", "inputs": []}
        path = candidate(self.project, source, spec, workspace=self.workspace)
        approval = {"approved": True, "reviewer": "TEST FIXTURE", "at": "2026-10-07", "evidence": "Synthetic test only"}
        return source, path, approval

    def test_candidate_is_not_approved_and_missing_decision_cannot_promote(self):
        source, record, _ = self.register()
        self.assertFalse(json.loads(record.read_text(encoding="utf-8"))["approved"])
        self.assertEqual(verify_library(self.workspace)["approved_versions"], 0)
        with self.assertRaisesRegex(ValueError, "aprovação explícita"):
            promote(self.project, record.relative_to(self.project).as_posix(), {}, workspace=self.workspace)
        self.assertEqual(sha256(source), sha256(record.parent / "image.png"))

    def test_pinned_copy_is_independent_and_import_resets_ui(self):
        source, record, approval = self.register()
        library = promote(self.project, record.relative_to(self.project).as_posix(), approval, workspace=self.workspace)
        copy = import_asset(self.project, "fixture", "v1", "@Lia", workspace=self.workspace)
        data = json.loads((self.project / "project.json").read_text(encoding="utf-8"))
        self.assertTrue(data["assets"][0]["approved"])
        self.assertFalse(data["generation"]["ui_verified"])
        self.assertEqual(verify_library(self.workspace)["approved_versions"], 1)
        old = sha256(copy / "image.png")
        png(source, (200, 100, 20))
        png(library.parent / "image.png", (100, 80, 10))
        self.assertEqual(sha256(copy / "image.png"), old)
        with self.assertRaises(ValueError):
            verify_library(self.workspace)
        with self.assertRaises(FileExistsError):
            candidate(self.project, source, json.loads(record.read_text(encoding="utf-8")), workspace=self.workspace)

    def test_fake_image_and_path_escape_are_rejected(self):
        source, record, approval = self.register()
        spec = json.loads(record.read_text(encoding="utf-8"))
        spec["version"] = "v2"
        source.write_bytes(b"not an image")
        with self.assertRaises(ValueError):
            candidate(self.project, source, spec, workspace=self.workspace)
        with self.assertRaises(ValueError):
            promote(self.project, "../escape/record.json", approval, workspace=self.workspace)


if __name__ == "__main__":
    unittest.main()
