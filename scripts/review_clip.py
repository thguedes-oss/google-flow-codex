"""Prepare local review evidence from a completed attempt; never approves or generates video."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import sys
from uuid import uuid4

from flow_files import identifier, project_file, read_json, sha256
from flow_ledger import read_csv
from flow_review_plan import load_review_plan, validate_moments

ROOT = Path(__file__).resolve().parents[1]


class ReviewError(ValueError):
    """An input or media-processing error that can be shown to the operator."""


def run_media(command: list[str]) -> str:
    try:
        result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8",
                                errors="replace", timeout=120, shell=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise ReviewError(f"Não foi possível executar {Path(command[0]).name}: {exc}") from exc
    if result.returncode:
        detail = result.stderr.strip()[-2000:]
        raise ReviewError(f"{Path(command[0]).name} falhou ao ler/processar a mídia: {detail}")
    return result.stdout


def probe_json(command: list[str]) -> dict:
    try:
        data = json.loads(run_media(command))
        if not isinstance(data, dict):
            raise ValueError("resposta não é um objeto")
        return data
    except (json.JSONDecodeError, ValueError) as exc:
        raise ReviewError(f"Resposta inválida do FFprobe: {exc}") from exc


def select_samples(timestamps: list[float]) -> list[dict]:
    """Choose nearest presentation-time samples, preserving exact first and last frames."""
    if not timestamps or any(not math.isfinite(t) for t in timestamps):
        raise ReviewError("O vídeo não contém frames com timestamps finitos.")
    if any(b < a for a, b in zip(timestamps, timestamps[1:])):
        raise ReviewError("Timestamps fora de ordem; revisar a mídia antes de extrair evidências.")
    first, last = timestamps[0], timestamps[-1]
    selected = {}
    for percent in (0, 25, 50, 75, 100):
        target = first + (last - first) * percent / 100
        if percent == 0:
            index = 0
        elif percent == 100:
            index = len(timestamps) - 1
        else:
            index = min(range(len(timestamps)), key=lambda i: (abs(timestamps[i] - target), i))
        sample = selected.setdefault(index, {"frame_index": index, "pts_seconds": timestamps[index],
                                             "relative_seconds": timestamps[index] - first,
                                             "targets_percent": []})
        sample["targets_percent"].append(percent)
    return [selected[index] for index in sorted(selected)]


def load_attempt(project: Path, attempt_id: str) -> tuple[dict, dict, dict, Path]:
    try:
        identifier(attempt_id)
    except ValueError as exc:
        raise ReviewError(f"ID de tentativa inválido: {exc}") from exc
    fields, rows = read_csv(project / "attempts.csv")
    if not {"attempt_id", "scene_id", "output_file", "status"}.issubset(fields):
        raise ReviewError("Cabeçalho de attempts.csv incompleto.")
    for row in rows:
        identifier(row["attempt_id"])
        identifier(row["scene_id"])
    matches = [row for row in rows if row["attempt_id"] == attempt_id]
    if len(matches) != 1:
        raise ReviewError(f"Tentativa {attempt_id}: esperada uma identificação única; encontradas {len(matches)}.")
    attempt = matches[0]
    if attempt.get("status") != "completed":
        raise ReviewError("A tentativa precisa estar completed. Reconcilie estados pendentes ou desconhecidos no Flow.")
    snapshot_directory = project_file(project, f"outputs/attempts/{attempt_id}")
    if snapshot_directory.exists():
        from attempt_snapshot import verify_snapshot
        try:
            data = verify_snapshot(project, attempt_id, attempt)["project"]
        except (OSError, ValueError, TypeError, KeyError) as exc:
            raise ReviewError(f"Congelamento/snapshot incompleto ou inválido: {exc}") from exc
    else:
        data = read_json(project / "project.json")
    if not isinstance(data, dict) or data.get("schema_version") != 1:
        raise ReviewError("Manifesto da tentativa precisa usar schema_version=1.")
    scenes = data.get("scenes")
    if not isinstance(scenes, list) or not all(isinstance(scene, dict) for scene in scenes):
        raise ReviewError("Lista de cenas inválida em project.json.")
    scene_matches = [scene for scene in scenes if scene.get("id") == attempt.get("scene_id")]
    if len(scene_matches) != 1:
        raise ReviewError("A tentativa precisa identificar uma cena única existente no projeto.")
    outputs = project_file(project, "outputs")
    video = project_file(project, attempt.get("output_file"))
    if not video.is_relative_to(outputs) or not video.is_file():
        raise ReviewError("O vídeo da tentativa deve existir dentro de outputs/ do projeto.")
    return data, attempt, scene_matches[0], video


def parse_alerts(text: str, kind: str) -> list[dict]:
    alerts = []
    pts = 0.0
    names = {"lavfi.scd.time": "scene_change", "lavfi.black_start": "black_start", "lavfi.black_end": "black_end",
             "lavfi.freezedetect.freeze_start": "freeze_start", "lavfi.freezedetect.freeze_end": "freeze_end",
             "lavfi.silence_start": "silence_start", "lavfi.silence_end": "silence_end"}
    for line in text.splitlines():
        match = re.search(r"pts_time:([\d.eE+-]+)", line)
        if match:
            pts = float(match[1])
        key, separator, value = line.strip().partition("=")
        if separator and key in names:
            moment = float(value)
            if not math.isfinite(moment):
                raise ReviewError("Detector retornou timestamp inválido.")
            alerts.append({"type": names[key], "pts_seconds": moment, "observed_at_pts": pts, "stream": kind})
    return alerts


def detect_events(video: Path, video_stream: int, metadata: dict, tools: dict) -> tuple[list[dict], dict]:
    filters = "scdet=threshold=10,blackdetect=d=2:pix_th=0.10:pic_th=0.98,freezedetect=n=-60dB:d=2"
    text = run_media([tools["ffmpeg"], "-nostdin", "-v", "error", "-i", str(video), "-map", f"0:{video_stream}",
                      "-vf", filters + ",metadata=mode=print:file='pipe\\:1'", "-an", "-f", "null", "-"])
    alerts = parse_alerts(text, "video")
    audio_streams = [s for s in metadata.get("streams", []) if s.get("codec_type") == "audio"]
    audio_filter = "silencedetect=n=-60dB:d=2"
    if audio_streams:
        audio_index = audio_streams[0]["index"]
        text = run_media([tools["ffmpeg"], "-nostdin", "-v", "error", "-i", str(video), "-map", f"0:{audio_index}",
                          "-af", audio_filter + ",ametadata=mode=print:file='pipe\\:1'", "-vn", "-f", "null", "-"])
        alerts.extend(parse_alerts(text, "audio"))
    return alerts, {"video_filters": filters, "audio_filters": audio_filter if audio_streams else None,
                    "audio_stream_index": audio_streams[0]["index"] if audio_streams else None,
                    "note": "Alertas técnicos, não defeitos semânticos nem decisões de aprovação."}


def enhanced_samples(timestamps: list[float], moments: list[dict], alerts: list[dict]) -> tuple[list[dict], int]:
    validate_moments(moments)
    selected = {s["frame_index"]: dict(s, reasons=["baseline"]) for s in select_samples(timestamps)}
    omitted = 0

    def add(index, reason):
        nonlocal omitted
        if index in selected:
            selected[index]["reasons"].append(reason)
        elif len(selected) < 25:
            selected[index] = {"frame_index": index, "pts_seconds": timestamps[index],
                               "relative_seconds": timestamps[index] - timestamps[0], "targets_percent": [], "reasons": [reason]}
        else:
            omitted += 1

    for moment in moments:
        seconds = moment.get("seconds")
        index = min(range(len(timestamps)), key=lambda i: (abs(timestamps[i] - timestamps[0] - seconds), i))
        add(index, {"planned_seconds": seconds, "expected": moment["expected"], "criterion": moment.get("criterion")})
    for event in sorted(alerts, key=lambda a: a["pts_seconds"]):
        index = min(range(len(timestamps)), key=lambda i: (abs(timestamps[i] - event["pts_seconds"]), i))
        indices = (max(0, index - 1), index, min(len(timestamps) - 1, index + 1)) if event["type"] == "scene_change" else (index,)
        for candidate in indices:
            add(candidate, event["type"])
    return [selected[index] for index in sorted(selected)], omitted


def review_clip(project: Path, attempt_id: str, *, workspace_root: Path = ROOT, enhanced: bool = False) -> Path:
    project = project.resolve()
    projects_root = (workspace_root / "projects").resolve()
    if project == projects_root or not project.is_relative_to(projects_root):
        raise ReviewError("O projeto deve estar dentro de projects/.")
    data, attempt, scene, video = load_attempt(project, attempt_id)
    tools = {name: shutil.which(name) for name in ("ffmpeg", "ffprobe")}
    missing = [name for name, executable in tools.items() if not executable]
    if missing:
        raise ReviewError(f"Ferramentas ausentes no PATH: {', '.join(missing)}. Nenhuma instalação automática foi feita.")
    original_hash = sha256(video)
    metadata = probe_json([tools["ffprobe"], "-v", "error", "-show_streams", "-show_format", "-of", "json", str(video)])
    video_streams = [stream for stream in metadata.get("streams", [])
                     if stream.get("codec_type") == "video" and not stream.get("disposition", {}).get("attached_pic")]
    if not video_streams:
        raise ReviewError("A mídia não contém um stream de vídeo reproduzível.")
    video_stream = video_streams[0]
    stream_index = video_stream["index"]
    frame_data = probe_json([tools["ffprobe"], "-v", "error", "-select_streams", str(stream_index),
                             "-show_frames", "-show_entries", "frame=best_effort_timestamp_time,duration_time",
                             "-of", "json", str(video)])
    try:
        timestamps = [float(frame["best_effort_timestamp_time"]) for frame in frame_data.get("frames", [])]
    except (KeyError, TypeError, ValueError) as exc:
        raise ReviewError("FFprobe não forneceu timestamps reais para todos os frames.") from exc
    samples = select_samples(timestamps)
    last_duration = frame_data["frames"][-1].get("duration_time")
    duration_seconds = None
    if last_duration is not None and float(last_duration) > 0:
        duration_seconds = timestamps[-1] - timestamps[0] + float(last_duration)
    elif video_stream.get("duration") is not None and float(video_stream["duration"]) > 0:
        duration_seconds = float(video_stream["duration"])
    alerts, detectors, omitted = [], None, 0
    moment_warnings = []
    plan = {"moments": []}
    if scene.get("review_plan"):
        snapshot_path = project_file(project, f"outputs/attempts/{attempt_id}/snapshot.json")
        if snapshot_path.is_file():
            from attempt_snapshot import verify_snapshot
            snapshot = verify_snapshot(project, attempt_id, attempt)
            matches = [item for item in snapshot["files"] if item["role"] == "review_plan"]
            if len(matches) != 1:
                raise ReviewError("Snapshot exige um único plano de revisão congelado.")
            plan_path = project_file(snapshot_path.parent, matches[0]["file"])
        else:
            plan_path = project_file(project, scene["review_plan"])
        plan = load_review_plan(plan_path)
    if enhanced:
        alerts, detectors = detect_events(video, stream_index, metadata, tools)
        samples, omitted = enhanced_samples(timestamps, plan["moments"], alerts)
        available_duration = duration_seconds if duration_seconds is not None else timestamps[-1] - timestamps[0]
        moment_warnings = [{"moment_index": index, "seconds": moment["seconds"],
                            "available_duration_seconds": available_duration, "sampling": "nearest_endpoint"}
                           for index, moment in enumerate(plan["moments"]) if moment["seconds"] > available_duration]
    output_parent = project_file(project, f"outputs/review/{attempt_id}")
    if not output_parent.is_relative_to(project_file(project, "outputs")):
        raise ReviewError("A pasta de revisão deve ficar dentro de outputs/.")
    output_parent.mkdir(parents=True, exist_ok=True)
    run_directory = output_parent / uuid4().hex
    run_directory.mkdir(exist_ok=False)
    try:
        for sample in samples:
            image_name = f"frame-{sample['frame_index']:06d}.png"
            run_media([tools["ffmpeg"], "-nostdin", "-hide_banner", "-loglevel", "error", "-n",
                       "-i", str(video), "-map", f"0:{stream_index}", "-vf",
                       f"select=eq(n\\,{sample['frame_index']})", "-frames:v", "1", "-fps_mode", "passthrough",
                       str(run_directory / image_name)])
            image_path = run_directory / image_name
            if not image_path.is_file() or image_path.stat().st_size == 0:
                raise ReviewError(f"O frame {sample['frame_index']} não foi extraído.")
            sample.update(image=image_name, sha256=sha256(image_path))
        # Fixed tiles preserve aspect ratio, including portrait and rotated video.
        grid_command = [tools["ffmpeg"], "-nostdin", "-hide_banner", "-loglevel", "error", "-n"]
        filters = []
        for index, sample in enumerate(samples):
            grid_command.extend(["-i", str(run_directory / sample["image"])])
            filters.append(f"[{index}:v]scale=320:240:force_original_aspect_ratio=decrease,"
                           f"pad=320:240:(ow-iw)/2:(oh-ih)/2,setsar=1[p{index}]")
        if len(samples) == 1:
            filters.append("[p0]null[grid]")
        elif len(samples) <= 5:
            filters.append("".join(f"[p{i}]" for i in range(len(samples))) + f"hstack=inputs={len(samples)}[grid]")
        else:
            layout = "|".join(f"{(i % 5) * 320}_{(i // 5) * 240}" for i in range(len(samples)))
            filters.append("".join(f"[p{i}]" for i in range(len(samples))) + f"xstack=inputs={len(samples)}:layout={layout}:fill=black[grid]")
        grid_command.extend(["-filter_complex", ";".join(filters), "-map", "[grid]", "-frames:v", "1",
                             str(run_directory / "contact-sheet.png")])
        run_media(grid_command)
        if sha256(video) != original_hash:
            raise ReviewError("O vídeo mudou durante a extração; evidências inválidas. Reconcilie a mídia antes de repetir.")
        report = {
            "schema_version": 1, "created_at_utc": datetime.now(timezone.utc).isoformat(),
            "status": "evidence_prepared", "attempt_id": attempt_id, "scene_id": scene["id"],
            "project_title": data.get("title"), "source_file": video.relative_to(project).as_posix(),
            "source_sha256": original_hash, "source_unchanged": True,
            "attempt": attempt, "expected_state_in": scene.get("state_in"), "expected_state_out": scene.get("state_out"),
            "expected_direction": plan.get("direction"),
            "metadata": metadata, "selected_video_stream_index": stream_index,
            "decoded_frame_count": len(timestamps), "samples": samples,
            "video_duration_seconds": duration_seconds, "decoded_span_seconds": timestamps[-1] - timestamps[0],
            "first_frame": samples[0]["image"], "last_frame": samples[-1]["image"],
            "contact_sheet": "contact-sheet.png", "contact_sheet_sha256": sha256(run_directory / "contact-sheet.png"),
            "contact_sheet_order": "left_to_right_chronological" if len(samples) <= 5 else "left_to_right_top_to_bottom_chronological", "thumbnail_size": [320, 240],
            "enhanced": enhanced, "technical_alerts": alerts, "detectors": detectors,
            "omitted_additional_sample_count": omitted,
            "planned_moment_warnings": moment_warnings,
            "snapshot_status": "frozen" if project_file(project, f"outputs/attempts/{attempt_id}/snapshot.json").is_file() else "legacy_without_snapshot",
            "tool_versions": {name: run_media([executable, "-version"]).splitlines()[0]
                              for name, executable in tools.items()},
            "visual_approval": None, "audio_review": None, "continuation_reference_approved": False,
            "note": "Evidências locais. Reproduza o vídeo completo com áudio e registre a revisão manual. "
                    "O último frame só pode servir de referência após aprovação visual do clipe."
        }
        report_path = run_directory / "review.json"
        report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        return report_path
    except (ReviewError, OSError) as exc:
        (run_directory / "failure.json").write_text(json.dumps({
            "status": "extraction_failed", "attempt_id": attempt_id, "source_sha256_before": original_hash,
            "error": str(exc), "visual_approval": None
        }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        raise ReviewError(f"{exc} Evidências parciais preservadas em {run_directory}.") from exc


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", required=True, type=Path, help="Pasta do vídeo dentro de projects/.")
    parser.add_argument("--attempt", required=True, help="ID único de uma tentativa completed.")
    parser.add_argument("--enhanced", action="store_true", help="Momentos planejados e alertas técnicos; máximo de 25 frames.")
    args = parser.parse_args()
    try:
        report_path = review_clip(ROOT / args.project, args.attempt, enhanced=args.enhanced)
    except (ReviewError, OSError, ValueError, TypeError, KeyError) as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1
    print(f"Evidências: {report_path}")
    print("Revisão visual e áudio pendentes; nenhuma aprovação ou crédito foi alterado.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
