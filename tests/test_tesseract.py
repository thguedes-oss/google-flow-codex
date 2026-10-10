"""Post-production contracts; synthetic assets exist only in temporary workspaces."""
import copy
import json
from pathlib import Path
import shutil
import subprocess
import sys
import unittest
from unittest.mock import patch
import zipfile

from helpers import ROOT, WorkspaceFixture, png
sys.path.insert(0, str(ROOT / "scripts"))
from flow_files import sha256, write_json
from flow_ledger import read_csv, write_csv
from flow_review import CRITERIA, close_review
from review_clip import review_clip
import tesseract_pipeline as pipeline
import tesseract_tools as tools


def technical_approval():
    return {"approved": True, "reviewer": "SYNTHETIC TEST ONLY", "at": "2026-10-07", "evidence": "temporary fixture"}


class PostproductionTests(WorkspaceFixture, unittest.TestCase):
    def setUp(self):
        super().setUp()
        image = png(self.project / "assets/temporary.png")
        self.plan = {"schema_version": 1, "kind": "design", "title": "Technical fixture only",
                     "delivery": {"width": 320, "height": 240, "duration_ms": 1000},
                     "resources": [{"id": "test-image", "kind": "image", "path": "assets/temporary.png",
                                    "sha256": sha256(image), "origin": "synthetic temporary test", "approval": technical_approval()}],
                     "images": [{"resource": "test-image", "at_ms": 0, "duration_ms": 1000}]}

    def approved_clip(self):
        video = self.project / "outputs/temporary.mp4"
        subprocess.run([shutil.which("ffmpeg"), "-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i",
                        "testsrc2=s=96x64:r=8:d=2", "-c:v", "libx264", "-pix_fmt", "yuv420p", str(video)],
                       check=True, capture_output=True, timeout=30)
        fields, rows = read_csv(self.project / "attempts.csv")
        row = dict.fromkeys(fields, "")
        row.update(attempt_id="technical", scene_id="01", output_file="outputs/temporary.mp4", status="completed")
        write_csv(self.project / "attempts.csv", fields, rows + [row])
        evidence = review_clip(self.project, "technical", workspace_root=self.workspace)
        spec = {"evidence_report": evidence.relative_to(self.project).as_posix(), "reviewer": "SYNTHETIC TEST ONLY",
                "decision": "approved", "selected": True, "supersedes": None, "playback_completed": True,
                "audio_review": "not_applicable", "audio_reason": "Synthetic silent fixture",
                "intent_review": "Temporary technical fixture, not a production verdict",
                "criteria": [{"criterion": key, "severity": "0", "timestamps": "0-2s",
                              "observation": "Technical fixture only"} for key in CRITERIA]}
        decision = close_review(self.project, "technical", spec, workspace=self.workspace)
        self.plan.update(kind="edit", delivery={"width": 1280, "height": 720, "duration_ms": 1000,
                        "fps": 24, "resolution": "720p", "audio_expected": False}, resources=[], images=[],
                        clips=[{"attempt_id": "technical", "in_ms": 500, "out_ms": 1500, "at_ms": 0}])
        return video, decision, spec

    def validate(self):
        return pipeline.validate_plan(self.project, self.plan, workspace=self.workspace)

    def sealed_revision(self):
        directory = pipeline.revision_directory(self.project, "v1")
        directory.mkdir(parents=True)
        (directory / "Project.tsrct").write_bytes(b"synthetic contract fixture, not native media")
        write_json(directory / "plan.json", self.plan)
        record = {"status": "prepared_unreviewed", "plan_sha256": sha256(directory / "plan.json"),
                  "document_sha256": sha256(directory / "Project.tsrct"), "sources": self.validate()["sources"],
                  "technique_files":self.validate()["technique_files"]}
        write_json(directory / "revision.json", record)
        write_json(directory / "registered.json", {"revision_sha256": sha256(directory / "revision.json")})
        return directory

    def test_validation_is_read_only_and_does_not_resolve_or_install_engine(self):
        before = {p.relative_to(self.project).as_posix(): sha256(p) for p in self.project.rglob("*") if p.is_file()}
        with patch.object(pipeline, "Engine", side_effect=AssertionError("No engine during validation")):
            self.assertTrue(self.validate()["valid"])
        after = {p.relative_to(self.project).as_posix(): sha256(p) for p in self.project.rglob("*") if p.is_file()}
        self.assertEqual(before, after)

    def test_missing_or_changed_resource_is_rejected(self):
        (self.project / "assets/temporary.png").write_bytes(b"changed")
        with self.assertRaisesRegex(ValueError, "alterado"):
            self.validate()

    def test_paths_cannot_escape_project(self):
        for path in ("../external.png", str(self.project / "assets/temporary.png")):
            self.plan["resources"][0]["path"] = path
            with self.assertRaisesRegex(ValueError, "fora do projeto"):
                self.validate()

    def test_unapproved_resource_and_unapproved_handle_are_rejected(self):
        self.plan["resources"][0]["approval"] = None
        with self.assertRaisesRegex(ValueError, "aprovação real"):
            self.validate()
        self.plan.update(resources=[], images=[{"handle": "@Lia", "at_ms": 0, "duration_ms": 1000}])
        with self.assertRaisesRegex(ValueError, "sem aprovação"):
            self.validate()

    def test_invalid_time_values_and_canvas_are_rejected(self):
        for bad in (-1, True, 1.5, float("nan")):
            self.plan["images"][0]["at_ms"] = bad
            with self.assertRaises(ValueError):
                self.validate()
        self.plan["images"][0]["at_ms"] = 500
        with self.assertRaisesRegex(ValueError, "fora da duração"):
            self.validate()

    def test_real_approval_and_trim_are_required(self):
        video, decision, spec = self.approved_clip()
        self.assertTrue(self.validate()["valid"])
        for start, end in [(500, 500), (1500, 500), (0, 3000)]:
            self.plan["clips"][0].update(in_ms=start, out_ms=end)
            with self.assertRaisesRegex(ValueError, "Intervalo de origem"):
                self.validate()
        self.plan["clips"][0].update(in_ms=500, out_ms=1500)
        video.write_bytes(video.read_bytes() + b"changed")
        with self.assertRaisesRegex(ValueError, "Vídeo alterado"):
            self.validate()

    def test_pending_attempt_is_rejected_even_with_old_approval(self):
        self.approved_clip()
        fields, rows = read_csv(self.project / "attempts.csv")
        rows[0]["status"] = "unknown"
        write_csv(self.project / "attempts.csv", fields, rows)
        with self.assertRaisesRegex(ValueError, "completed"):
            self.validate()

    def test_superseded_or_rejected_review_invalidates_revision(self):
        _, decision, spec = self.approved_clip()
        original = self.validate()
        spec.update(supersedes=json.loads(decision.read_text(encoding="utf-8"))["decision_id"], decision="rejected", selected=False)
        close_review(self.project, "technical", spec, workspace=self.workspace)
        with self.assertRaisesRegex(ValueError, "não aprovada"):
            self.validate()
        self.assertEqual(original["sources"][0]["decision"], decision.relative_to(self.project).as_posix())

    def test_replacement_approval_invalidates_prepared_revision(self):
        _, decision, spec = self.approved_clip()
        self.sealed_revision()
        spec["supersedes"] = json.loads(decision.read_text(encoding="utf-8"))["decision_id"]
        close_review(self.project, "technical", spec, workspace=self.workspace)
        with self.assertRaisesRegex(ValueError, "substituída"):
            pipeline.verify_revision(self.project, "v1", workspace=self.workspace)

    def test_clip_review_tampering_is_rejected(self):
        _, decision, _ = self.approved_clip()
        decision.write_text(decision.read_text(encoding="utf-8") + " ", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Decisão alterada"):
            self.validate()

    def test_revision_document_and_plan_changes_are_rejected(self):
        directory = self.sealed_revision()
        pipeline.verify_revision(self.project, "v1", workspace=self.workspace)
        for name in ("Project.tsrct", "plan.json"):
            path = directory / name
            original = path.read_bytes()
            path.write_bytes(original + b" ")
            with self.assertRaisesRegex(ValueError, "alterado"):
                pipeline.verify_revision(self.project, "v1", workspace=self.workspace)
            path.write_bytes(original)

    def test_recipe_change_invalidates_prepared_revision(self):
        self.plan.update(kind="animatic",delivery={"width":1280,"height":720,"duration_ms":1000,
            "fps":24,"resolution":"720p","audio_expected":False},
            techniques=[{"id":"native.color","sources":["image:0"],"start_frame":0,"duration_frames":24,"params":{}}])
        self.sealed_revision()
        pipeline.verify_revision(self.project,"v1",workspace=self.workspace)
        original=pipeline.flow_techniques.sha256
        with patch.object(pipeline.flow_techniques,"sha256",side_effect=lambda path:
                "f"*64 if str(path).endswith("color.wgsl") else original(path)):
            with self.assertRaisesRegex(ValueError,"Receita"):
                pipeline.verify_revision(self.project,"v1",workspace=self.workspace)

    def test_render_failure_never_registers_partial_success(self):
        directory = self.sealed_revision()
        with patch.object(pipeline, "Engine", side_effect=ValueError("synthetic render failure")):
            with self.assertRaisesRegex(ValueError, "render failure"):
                pipeline.render(self.project, "v1", workspace=self.workspace)
        run, = (directory / "renders").iterdir()
        self.assertTrue((run / "failure.json").is_file())
        self.assertFalse((run / "render.json").exists())
        self.assertFalse((run / "registered.json").exists())

    def test_converter_failure_and_missing_artifact_are_not_success(self):
        directory = self.sealed_revision()
        original_invoke = pipeline.invoke
        for response in (ValueError("synthetic conversion failure"), "{}"):
            def conversion_result(executable, arguments, **kwargs):
                if executable == Path("fixture.exe"):
                    if isinstance(response, Exception):
                        raise response
                    return response
                return original_invoke(executable, arguments, **kwargs)
            with patch.object(pipeline, "resolve_tool", return_value=Path("fixture.exe")), patch.object(
                    pipeline, "invoke", side_effect=conversion_result):
                with self.assertRaises(ValueError):
                    pipeline.convert(self.project, "v1", "premiere", workspace=self.workspace)
        runs = list((directory / "conversions").iterdir())
        self.assertEqual(len(runs), 2)
        for run in runs:
            self.assertTrue((run / "failure.json").exists())
            self.assertFalse((run / "conversion.json").exists())

    def test_final_review_requires_intact_render_and_real_inspection(self):
        directory = self.sealed_revision()
        run = directory / "renders/technical"
        run.mkdir(parents=True)
        image = png(run / "Preview.png")
        report = {"revision_sha256": sha256(directory / "revision.json"), "status": "rendered_unreviewed",
                  "metadata": {"streams": [{"codec_type": "video"}]},
                  "outputs": [{"path": "Preview.png", "sha256": sha256(image)}]}
        write_json(run / "render.json", report)
        write_json(run / "registered.json", {"render_sha256": sha256(run / "render.json")})
        spec = {"schema_version": 1, "reviewer": "SYNTHETIC TEST ONLY", "decision": "approved",
                "observations": "Temporary contract fixture only", "visual_inspection_completed": False,
                "audio_review": "not_applicable", "audio_reason": "Static technical image"}
        with self.assertRaisesRegex(ValueError, "inspeção visual"):
            pipeline.close_review(self.project, "v1", "technical", spec, workspace=self.workspace)
        spec["visual_inspection_completed"] = True
        for field in ("reviewer", "observations", "audio_reason"):
            with self.subTest(field=field), self.assertRaises(ValueError):
                pipeline.close_review(self.project, "v1", "technical", dict(spec, **{field: "   "}), workspace=self.workspace)
        result = pipeline.close_review(self.project, "v1", "technical", spec, workspace=self.workspace)
        self.assertTrue((result / "registered.json").exists())
        report["status"] = "previewed_unreviewed"
        write_json(run / "render.json", report, replace=True)
        with self.assertRaisesRegex(ValueError, "Relatório de render alterado"):
            pipeline.close_review(self.project, "v1", "technical", spec, workspace=self.workspace)

    def test_revision_reuse_is_rejected_before_engine_execution(self):
        directory = pipeline.revision_directory(self.project, "v1")
        directory.mkdir(parents=True)
        sentinel = directory / "sentinel.txt"
        sentinel.write_text("preserve", encoding="utf-8")
        with patch.object(pipeline, "Engine", side_effect=AssertionError("Must not execute")):
            with self.assertRaises(FileExistsError):
                pipeline.prepare(self.project, self.plan, "v1", workspace=self.workspace)
        self.assertEqual(sentinel.read_text(encoding="utf-8"), "preserve")

    def test_failed_prepare_is_not_a_registered_revision(self):
        with patch.object(pipeline, "Engine", side_effect=ValueError("render engine unavailable")):
            with self.assertRaisesRegex(ValueError, "unavailable"):
                pipeline.prepare(self.project, self.plan, "v1", workspace=self.workspace)
        directory = pipeline.revision_directory(self.project, "v1")
        self.assertTrue((directory / "failure.json").is_file())
        self.assertFalse((directory / "registered.json").exists())


class PortableToolsTests(WorkspaceFixture, unittest.TestCase):
    def setUp(self):
        super().setUp()
        shutil.copytree(ROOT / "config", self.workspace / "config")

    def test_checksum_checks_both_download_and_fixed_pin(self):
        archive = self.workspace / "bundle.zip"
        archive.write_bytes(b"technical download fixture")
        checksum = self.workspace / "bundle.zip.sha256"
        checksum.write_text(sha256(archive) + "  bundle.zip", encoding="utf-8")
        tools.verify_archive(archive, checksum, sha256(archive))
        for expected in ("0" * 64, "invalid"):
            with self.assertRaisesRegex(ValueError, "SHA-256"):
                tools.verify_archive(archive, checksum, expected)
        archive.write_bytes(b"changed")
        with self.assertRaises(ValueError):
            tools.verify_archive(archive, checksum, checksum.read_text().split()[0])

    def test_zip_paths_are_checked_before_extraction(self):
        archive = self.workspace / "unsafe.zip"
        with zipfile.ZipFile(archive, "w") as bundle:
            bundle.writestr("../outside.txt", "bad")
        destination = self.workspace / "unpacked"
        destination.mkdir()
        with self.assertRaisesRegex(ValueError, "inseguro"):
            tools.extract_archive(archive, destination)
        self.assertFalse((self.workspace / "outside.txt").exists())

    def test_version_mismatch_is_rejected(self):
        for version in ("tsrct 0.2.0", "tsrct 0.3.10"):
            with patch.object(tools, "invoke", return_value=version):
                with self.assertRaisesRegex(ValueError, "incompatível"):
                    tools.check_version(Path("fixture.exe"), "0.3.1")

    @unittest.skipUnless(sys.platform == "win32", "Windows portable installer")
    def test_bad_download_checksum_cannot_publish_or_execute_bundle(self):
        def wrong_download(url, destination):
            destination.write_bytes(b"0" * 64 if destination.suffix == ".sha256" else b"wrong download")
        with patch.object(tools, "download", side_effect=wrong_download), patch.object(
                tools, "check_version", side_effect=AssertionError("Never execute an unverified bundle")):
            with self.assertRaisesRegex(ValueError, "SHA-256"):
                tools.install("tesseract", self.workspace)
        self.assertFalse(tools.tool_directory("tesseract", self.workspace).exists())
        self.assertEqual(len(list((self.workspace / ".work").rglob("failure.json"))), 1)

    @unittest.skipUnless(sys.platform == "win32", "Windows portable installer")
    def test_existing_tool_directory_is_never_replaced_on_install_failure(self):
        directory = tools.tool_directory("tesseract", self.workspace)
        directory.mkdir(parents=True)
        sentinel = directory / "preserve.txt"
        sentinel.write_text("existing installation", encoding="utf-8")
        with patch.object(tools, "download", side_effect=AssertionError("Do not replace an existing install")):
            with self.assertRaises(ValueError):
                tools.install("tesseract", self.workspace)
        self.assertEqual(sentinel.read_text(encoding="utf-8"), "existing installation")

    def test_missing_tool_doctor_never_installs(self):
        with patch.object(tools, "download", side_effect=AssertionError("Must not download")):
            result = tools.doctor(self.workspace)
        self.assertFalse(result["tools"]["tesseract"]["available"])
        self.assertFalse((self.workspace / ".work").exists())

    @unittest.skipUnless(sys.platform == "win32", "Windows portable installer")
    def test_failed_download_keeps_error_and_does_not_publish_installation(self):
        with patch.object(tools, "download", side_effect=OSError("offline")):
            with self.assertRaisesRegex(OSError, "offline"):
                tools.install("tesseract", self.workspace)
        self.assertFalse(tools.tool_directory("tesseract", self.workspace).exists())
        self.assertEqual(len(list((self.workspace / ".work").rglob("failure.json"))), 1)


if __name__ == "__main__":
    unittest.main()
