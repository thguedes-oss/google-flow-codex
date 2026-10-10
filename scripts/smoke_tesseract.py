"""Explicit native-engine smoke test. All synthetic media stays in a temporary directory."""
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import sys

from flow_files import ROOT, sha256, utc_now, write_json
from flow_ledger import read_csv, write_csv
from flow_review import CRITERIA, close_review
from review_clip import review_clip
from tesseract_pipeline import prepare, render, convert, validate_plan, probe, verify_revision
from tesseract_tools import invoke, resolve_tool


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--keep-temporary", action="store_true", help="Preserva somente a pasta temporária para inspeção técnica.")
    parser.add_argument("--report", type=Path, default=ROOT / "reports/tesseract-smoke.json")
    args = parser.parse_args()
    temporary = tempfile.TemporaryDirectory(prefix="flow-tesseract-technical-")
    workspace = Path(temporary.name)
    payload = {"schema_version": 1, "started_at": utc_now(), "generation_calls": 0, "flow_credits_spent": 0,
               "fixture_kind": "synthetic_temporary_only", "adobe_application_verified": False,
               "playback_completed": False, "audio_listened": False, "checks": []}
    preserved = [ROOT / "sources.lock.json", *[ROOT / "projects/exemplo-duas-cenas" / name
                  for name in ("project.json", "attempts.csv", "review.csv")]]
    hashes = {str(p.relative_to(ROOT)): sha256(p) for p in preserved}
    try:
        ffmpeg = Path(shutil.which("ffmpeg") or "")
        project = workspace / "projects" / "vídeo técnico com espaços"
        shutil.copytree(ROOT / "projects/exemplo-duas-cenas", project)
        approval = {"approved": True, "reviewer": "SYNTHETIC TEMPORARY TEST ONLY", "at": utc_now(), "evidence": "technical fixture"}
        clips = []
        for index, frequency in enumerate((440, 880)):
            path = project / f"outputs/synthetic-{index}.mp4"
            invoke(ffmpeg, ["-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i", "testsrc2=s=1280x720:r=24:d=2",
                "-f", "lavfi", "-i", f"sine=frequency={frequency}:sample_rate=48000:duration=2",
                "-c:v", "libx264", "-preset", "ultrafast", "-crf", "18", "-pix_fmt", "yuv420p", "-c:a", "aac", "-shortest", str(path)])
            fields, rows = read_csv(project / "attempts.csv")
            aid = f"synthetic-{index}"
            row = dict.fromkeys(fields, "")
            row.update(attempt_id=aid, scene_id=f"0{index+1}", status="completed", output_file=path.relative_to(project).as_posix(),
                       expected_credits="0", charged_credits="0")
            write_csv(project / "attempts.csv", fields, rows + [row])
            evidence = review_clip(project, aid, workspace_root=workspace)
            close_review(project, aid, {"evidence_report": evidence.relative_to(project).as_posix(),
                "decision": "approved", "selected": True, "supersedes": None, "reviewer": approval["reviewer"],
                "playback_completed": True, "audio_review": "reviewed",
                "intent_review": "SYNTHETIC CONTRACT FIXTURE; NOT PRODUCTION APPROVAL",
                "criteria": [{"criterion": criterion, "severity": "0", "timestamps": "0-2s",
                              "observation": "SYNTHETIC CONTRACT FIXTURE; NOT PRODUCTION APPROVAL"} for criterion in CRITERIA]}, workspace=workspace)
            clips.append({"attempt_id": aid, "in_ms": 500 if index == 0 else 250,
                          "out_ms": 1500 if index == 0 else 1250, "at_ms": index * 1000, "volume": 0.6})
        font = project / "assets/SegoeUI-Technical.ttf"
        shutil.copyfile(Path("C:/Windows/Fonts/segoeui.ttf"), font)
        wav = project / "assets/synthetic-tone.wav"
        invoke(ffmpeg, ["-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i",
                       "sine=frequency=220:sample_rate=48000:duration=2", "-c:a", "pcm_s16le", str(wav)])
        image = project / "assets/technical.png"
        invoke(ffmpeg, ["-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i",
                       "color=c=0x123456:s=320x180", "-frames:v", "1", str(image)])
        font_resource = {"id": "font", "kind": "font", "path": font.relative_to(project).as_posix(),
            "sha256": sha256(font), "origin": "Local Windows font; temporary technical test", "license": "Windows installed font; not redistributed"}
        plan = {"schema_version": 1, "kind": "edit", "title": "Temporary native-engine test",
            "delivery": {"width": 1280, "height": 720, "duration_ms": 2000, "fps": 24, "resolution": "720p", "audio_expected": True},
            "clips": clips, "resources": [font_resource, {"id": "tone", "kind": "audio", "path": wav.relative_to(project).as_posix(),
                "sha256": sha256(wav), "origin": "Synthetic tone, temporary technical test", "approval": approval}],
            "texts": [{"role": "title", "text": "Prévia técnica: ação, café e João", "font": "font", "position": [60, 40],
                       "box": [1160, 100], "font_size": 48, "at_ms": 0, "duration_ms": 2000, "fade_ms": 200}],
            "audio": [{"resource": "tone", "at_ms": 0, "in_ms": 0, "out_ms": 2000, "volume": 0.1}],
            "rectangles": [{"name": "Technical title background", "position": [40, 20], "size": [1200, 120],
                            "color": [0, 0, 0, 0.8], "at_ms": 0, "duration_ms": 2000}]}
        before = {p: sha256(project / p) for p in ("project.json", "attempts.csv", "review.csv")}
        revision = prepare(project, plan, "native-smoke", workspace=workspace)
        payload["checks"].append("native_project_prepared_and_reopened")
        output = render(project, "native-smoke", workspace=workspace)
        payload["checks"].append("mp4_dimensions_fps_duration_audio_and_full_decode")
        video = output / "Video.mp4"
        audio_path = output / "decoded-audio.f32"
        invoke(ffmpeg, ["-nostdin", "-v", "error", "-n", "-i", str(video), "-map", "0:a:0", "-f", "f32le", str(audio_path)])
        import struct
        samples = struct.unpack("<" + "f" * (audio_path.stat().st_size // 4), audio_path.read_bytes())
        peak = max(map(abs, samples))
        if not 0.001 < peak < 1:
            raise ValueError(f"Unexpected synthetic audio peak: {peak}")
        payload["audio_peak_measured"] = peak
        payload["checks"].append("synthetic_audio_non_silent_and_not_clipped")
        inspect = json.loads((revision / "inspect.json").read_text(encoding="utf-8"))
        payload["inspect_structure_keys"] = list(inspect)
        # Compare an unobscured area against the actual selected source moments.
        differences = []
        for index, clip in enumerate(clips):
            source = project / f"outputs/synthetic-{index}.mp4"
            raw = []
            for media, seconds in ((source, (clip["in_ms"] + 500) / 1000), (video, (clip["at_ms"] + 500) / 1000)):
                command = [str(ffmpeg), "-nostdin", "-v", "error", "-ss", str(seconds), "-i", str(media),
                           "-vf", "crop=640:400:100:250", "-frames:v", "1", "-pix_fmt", "rgb24", "-f", "rawvideo", "-"]
                raw.append(subprocess.run(command, check=True, capture_output=True, timeout=30).stdout)
            if len(raw[0]) != len(raw[1]) or not raw[0]:
                raise ValueError("Cut/source comparison produced no matching frames.")
            difference = sum(abs(a-b) for a, b in zip(*raw)) / len(raw[0])
            differences.append(difference)
            if difference > 12:
                raise ValueError(f"Selected source interval does not match rendered cut: {difference}")
        payload["cut_mean_absolute_pixel_differences"] = differences
        payload["checks"].append("source_trim_and_timeline_cut_match_encoded_frames")
        payload["conversion_failures"] = []
        for target in ("after-effects", "premiere"):
            try:
                converted = convert(project, "native-smoke", target, workspace=workspace)
            except ValueError as exc:
                if target != "premiere" or "portable ASCII relative path" not in str(exc):
                    raise
                payload["conversion_failures"].append({"target": target, "source_kind": "hybrid_text_graphics",
                    "status": "failed", "error": str(exc), "partial_output_is_deliverable": False})
                continue
            payload["checks"].append(f"{target}_package_created_adobe_unverified")
            payload.setdefault("conversions", {})[target] = json.loads((converted / "conversion.json").read_text(encoding="utf-8"))
        native_edit = copy.deepcopy(plan)
        native_edit.update(title="Native Premiere technical fixture", texts=[], rectangles=[])
        native_edit["resources"] = [r for r in native_edit["resources"] if r["kind"] != "font"]
        prepare(project, native_edit, "premiere-native-smoke", workspace=workspace)
        converted = convert(project, "premiere-native-smoke", "premiere", workspace=workspace)
        payload["conversions"]["premiere-native"] = json.loads((converted / "conversion.json").read_text(encoding="utf-8"))
        payload["checks"].append("premiere_native_cuts_audio_package_created_adobe_unverified")
        design = copy.deepcopy(plan)
        design.update(kind="design", title="Static technical fixture", clips=[], audio=[],
                      delivery={"width": 640, "height": 360, "duration_ms": 2000}, resources=[font_resource])
        design["texts"][0].update(position=[30, 30], box=[580, 120], font_size=28, fade_ms=0)
        design["rectangles"][0].update(position=[0, 0], size=[640, 360], color=[0.03, 0.08, 0.15, 1])
        prepare(project, design, "design-smoke", workspace=workspace)
        design_output = render(project, "design-smoke", workspace=workspace)
        payload["checks"].append("editable_static_design_png_dimensions_and_reopen")
        animatic = {"schema_version": 1, "kind": "animatic", "title": "Synthetic animatic only",
            "delivery": plan["delivery"], "resources": [{"id": "image", "kind": "image", "path": image.relative_to(project).as_posix(),
             "sha256": sha256(image), "origin": "Synthetic temporary fixture", "approval": approval}, font_resource],
            "images": [{"resource": "image", "at_ms": 0, "duration_ms": 2000}], "texts": copy.deepcopy(plan["texts"])}
        animatic["delivery"] = dict(plan["delivery"], audio_expected=False)
        prepare(project, animatic, "animatic-smoke", workspace=workspace)
        animatic_output = render(project, "animatic-smoke", workspace=workspace)
        payload["checks"].append("approved_image_animatic_export")
        white_pixels = []
        for seconds in (0, 0.5):
            result = subprocess.run([str(ffmpeg), "-nostdin", "-v", "error", "-ss", str(seconds), "-i",
                str(animatic_output / "Video.mp4"), "-vf", "crop=1160:100:60:40", "-frames:v", "1",
                "-pix_fmt", "gray", "-f", "rawvideo", "-"], check=True, capture_output=True, timeout=30)
            white_pixels.append(sum(value > 200 for value in result.stdout))
        if white_pixels[1] - white_pixels[0] < 100:
            raise ValueError(f"Title fade did not become visible in encoded video: {white_pixels}")
        payload["animated_title_white_pixels_start_and_half_second"] = white_pixels
        payload["checks"].append("editable_title_fade_visible_in_encoded_frames")
        payload["export_profiles_verified"] = [{"resolution": "720p", "width": 1280, "height": 720, "fps": 24}]
        for name, width, height, resolution, fps in (("portrait", 720, 1280, "720p", 30),
                ("square", 720, 720, "720p", 60), ("1080", 1920, 1080, "1080p", 24),
                ("4k", 3840, 2160, "4k", 24)):
            variant = copy.deepcopy(animatic)
            variant["texts"] = []
            variant["delivery"].update(width=width, height=height, resolution=resolution, fps=fps)
            prepare(project, variant, name + "-smoke", workspace=workspace)
            render(project, name + "-smoke", workspace=workspace)
            payload["export_profiles_verified"].append({"resolution": resolution, "width": width, "height": height, "fps": fps})
        payload["checks"].append("portrait_square_1080_and_4k_exact_canvas_profiles")
        if {p: sha256(project / p) for p in before} != before:
            raise ValueError("Post-production modified source ledgers or project manifest.")
        payload["checks"].append("original_generation_manifest_and_ledgers_preserved")
        payload["status"] = "passed_with_limitations" if payload["conversion_failures"] else "passed"
        payload["temporary_previews"] = [str(p) for p in (output / "Preview.png", output / "Filmstrip.png",
            design_output / "Preview.png", animatic_output / "Preview.png")] if args.keep_temporary else []
        payload["temporary_directory"] = str(workspace) if args.keep_temporary else None
    except Exception as exc:
        payload.update(status="failed", error=str(exc), temporary_directory=str(workspace) if args.keep_temporary else None)
    finally:
        payload["production_files_unchanged"] = {str(p.relative_to(ROOT)): sha256(p) for p in preserved} == hashes
        if not payload["production_files_unchanged"]:
            payload["status"] = "failed"
        payload["finished_at"] = utc_now()
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        if args.keep_temporary:
            temporary._finalizer.detach()
        else:
            temporary.cleanup()
    print(json.dumps({k: v for k, v in payload.items() if k != "conversions"}, ensure_ascii=False, indent=2))
    return 0 if payload["status"] in ("passed", "passed_with_limitations") else 1


if __name__ == "__main__":
    sys.exit(main())
