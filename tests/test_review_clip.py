"""Technical fixtures only: no Flow requests, production attempts or visual approvals."""
import csv
import json
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from preflight import sha256
from review_clip import ReviewError, load_attempt, review_clip, select_samples


class ReviewFixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="flow-revisão-test-")
        self.addCleanup(self.temp.cleanup)
        self.workspace = Path(self.temp.name)
        self.project = self.workspace / "projects" / "vídeo com espaços"
        shutil.copytree(ROOT / "projects/exemplo-duas-cenas", self.project)
        self.video = self.project / "outputs" / "clipe técnico 01.mkv"
        self.video.write_bytes(b"placeholder fixture, not a production video")
        self.row = {"attempt_id": "test-01", "scene_id": "01", "output_file": self.video.relative_to(self.project).as_posix(),
                    "status": "completed", "expected_credits": "0", "charged_credits": "0"}
        self.write_attempts(self.row)

    def write_attempts(self, *rows):
        with (self.project / "attempts.csv").open(encoding="utf-8", newline="") as stream:
            fields = next(csv.reader(stream))
        with (self.project / "attempts.csv").open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)


class ReviewInputTests(ReviewFixture):
    def test_missing_and_duplicate_attempts_are_rejected(self):
        for rows in [(), (self.row, self.row)]:
            self.write_attempts(*rows)
            with self.assertRaisesRegex(ReviewError, "identificação única"):
                load_attempt(self.project, "test-01")

    def test_noncompleted_attempts_are_rejected(self):
        for status in ("pending", "unknown", "failed"):
            self.write_attempts(dict(self.row, status=status))
            with self.assertRaisesRegex(ReviewError, "completed"):
                load_attempt(self.project, "test-01")

    def test_scene_and_attempt_identifiers_must_be_valid(self):
        self.write_attempts(dict(self.row, scene_id="missing"))
        with self.assertRaisesRegex(ReviewError, "cena única"):
            load_attempt(self.project, "test-01")
        with self.assertRaisesRegex(ReviewError, "ID de tentativa inválido"):
            load_attempt(self.project, "../escape")

    def test_input_paths_must_stay_in_outputs_and_exist(self):
        for output in ("../escape.mkv", str(self.video), "prompts/cena-01.md", "outputs/missing.mkv"):
            self.write_attempts(dict(self.row, output_file=output))
            with self.assertRaises(ValueError):
                load_attempt(self.project, "test-01")

    def test_project_cannot_escape_workspace(self):
        with self.assertRaisesRegex(ReviewError, "dentro de projects"):
            review_clip(self.workspace, "test-01", workspace_root=self.workspace)

    def test_missing_tools_report_error_without_creating_output(self):
        with patch("review_clip.shutil.which", return_value=None):
            with self.assertRaisesRegex(ReviewError, "ffmpeg, ffprobe"):
                review_clip(self.project, "test-01", workspace_root=self.workspace)
        self.assertFalse((self.project / "outputs/review").exists())

    def test_time_based_sampling_differs_from_frame_fraction_for_vfr(self):
        samples = select_samples([0, 0.1, 0.2, 1.2, 1.21, 2, 4])
        quarter = next(sample for sample in samples if 25 in sample["targets_percent"])
        self.assertEqual(quarter["frame_index"], 3)
        self.assertEqual(samples[-1]["frame_index"], 6)

    def test_invalid_timestamps_are_rejected_and_equal_times_keep_last_frame(self):
        for times in ([], [float("nan")], [float("inf")], [1, 0]):
            with self.assertRaises(ReviewError):
                select_samples(times)
        self.assertEqual([s["frame_index"] for s in select_samples([0, 0])], [0, 1])


@unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "FFmpeg/FFprobe ausentes")
class ReviewMediaTests(ReviewFixture):
    def encode(self, *, frames=16, vfr=False, h264=False, audio=False):
        command = [shutil.which("ffmpeg"), "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
                   "-f", "lavfi", "-i", "testsrc2=size=96x64:rate=8:duration=2"]
        if audio:
            command.extend(["-f", "lavfi", "-i", "sine=frequency=440:sample_rate=8000:duration=2", "-c:a", "pcm_s16le"])
        if vfr:
            command.extend(["-vf", "setpts=if(lt(N\\,8)\\,N\\,8+(N-8)*3)/(8*TB)", "-fps_mode", "vfr"])
        command.extend(["-frames:v", str(frames), "-c:v", "libx264" if h264 else "ffv1"])
        if h264:
            command.extend(["-bf", "3", "-g", "16"])
        subprocess.run([*command, str(self.video)], check=True, capture_output=True, timeout=30)

    def extract(self):
        path = review_clip(self.project, "test-01", workspace_root=self.workspace)
        return path, json.loads(path.read_text(encoding="utf-8"))

    def pixels(self, path, *, reverse=False):
        command = [shutil.which("ffmpeg"), "-nostdin", "-hide_banner", "-loglevel", "error", "-i", str(path), "-map", "0:v:0"]
        if reverse:
            command.extend(["-vf", "reverse"])
        return subprocess.run([*command, "-frames:v", "1", "-pix_fmt", "rgb24", "-f", "rawvideo", "pipe:1"],
                              check=True, capture_output=True, timeout=30).stdout

    def test_normal_video_audio_last_frame_and_bookkeeping_are_preserved(self):
        self.encode(audio=True, h264=True)
        protected = [self.video, self.project / "project.json", self.project / "attempts.csv", self.project / "review.csv"]
        hashes = {path: sha256(path) for path in protected}
        report_path, report = self.extract()
        self.assertEqual(report["decoded_frame_count"], 16)
        self.assertEqual(len(report["samples"]), 5)
        self.assertEqual(report["samples"][-1]["frame_index"], 15)
        self.assertEqual(self.pixels(report_path.parent / report["last_frame"]), self.pixels(self.video, reverse=True))
        self.assertEqual(self.pixels(report_path.parent / report["first_frame"]), self.pixels(self.video))
        self.assertEqual(hashes, {path: sha256(path) for path in protected})
        self.assertTrue(any(stream["codec_type"] == "audio" for stream in report["metadata"]["streams"]))
        self.assertIsNone(report["visual_approval"])
        self.assertFalse(report["continuation_reference_approved"])
        self.assertTrue((report_path.parent / "contact-sheet.png").is_file())
        grid = (report_path.parent / "contact-sheet.png").read_bytes()
        self.assertEqual(struct.unpack(">II", grid[16:24]), (1600, 240))

    def test_vfr_uses_real_timestamps_and_exact_last_frame(self):
        self.encode(vfr=True)
        path, report = self.extract()
        self.assertEqual(report["decoded_frame_count"], 16)
        self.assertEqual(report["samples"][-1]["frame_index"], 15)
        self.assertGreater(report["samples"][-1]["relative_seconds"], 3)
        quarter = next(sample for sample in report["samples"] if 25 in sample["targets_percent"])
        self.assertGreater(quarter["frame_index"], 4)
        self.assertEqual(self.pixels(path.parent / report["last_frame"]), self.pixels(self.video, reverse=True))

    def test_one_and_two_frame_clips_deduplicate_samples(self):
        for frames in (1, 2):
            with self.subTest(frames=frames):
                self.encode(frames=frames)
                path, report = self.extract()
                self.assertEqual(len(report["samples"]), frames)
                self.assertEqual(sum(len(s["targets_percent"]) for s in report["samples"]), 5)
                self.assertTrue((path.parent / "contact-sheet.png").is_file())

    def test_new_run_preserves_previous_evidence(self):
        self.encode()
        first, _ = self.extract()
        hashes = {path: sha256(path) for path in first.parent.iterdir()}
        second, _ = self.extract()
        self.assertNotEqual(first.parent, second.parent)
        self.assertEqual(hashes, {path: sha256(path) for path in first.parent.iterdir()})

    def test_corrupt_media_is_rejected(self):
        with self.assertRaisesRegex(ReviewError, "FFprobe|ffprobe"):
            self.extract()
        self.assertFalse((self.project / "outputs/review").exists())

    def test_redirected_review_directory_cannot_write_outside_outputs(self):
        self.encode(frames=1)
        from review_clip import project_file as original_project_file

        def redirected_path(root, value):
            if value == "outputs/review/test-01":
                return root / "prompts" / "redirected-review"
            return original_project_file(root, value)

        with patch("review_clip.project_file", side_effect=redirected_path):
            with self.assertRaisesRegex(ReviewError, "pasta de revisão"):
                self.extract()
        self.assertFalse((self.project / "prompts/redirected-review").exists())

    def test_source_change_during_extraction_marks_evidence_as_failed(self):
        self.encode()
        from review_clip import run_media as original_run

        def change_after_grid(command):
            result = original_run(command)
            if command[-1].endswith("contact-sheet.png"):
                with self.video.open("ab") as stream:
                    stream.write(b"changed technical fixture")
            return result

        with patch("review_clip.run_media", side_effect=change_after_grid):
            with self.assertRaisesRegex(ReviewError, "vídeo mudou"):
                self.extract()
        self.assertEqual(len(list((self.project / "outputs/review").rglob("failure.json"))), 1)
        self.assertEqual(list((self.project / "outputs/review").rglob("review.json")), [])


if __name__ == "__main__":
    unittest.main()
