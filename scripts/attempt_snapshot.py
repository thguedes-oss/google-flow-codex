"""Freeze a ready scene and register pending before the operator submits in Chrome."""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import shutil
import sys

from flow_files import ROOT, identifier, project_file, project_root, read_json, sha256, utc_now, write_json
from flow_ledger import read_csv, record_lock, write_csv

FROZEN_FIELDS = ("attempt_id", "utc", "scene_id", "model", "mode", "reference_version", "prompt_file", "expected_credits")


def submitted_prompt(text: str) -> str:
    matches = re.findall(r"VIDEO PROMPT[^\n]*\n\s*```[^\n]*\n(.*?)\n```", text, re.DOTALL)
    if len(matches) != 1:
        raise ValueError("Esperado exatamente um bloco VIDEO PROMPT para congelar o texto de envio.")
    return matches[0]


def verify_snapshot(project: Path, attempt_id: str, attempt: dict | None = None) -> dict:
    identifier(attempt_id)
    directory = project_file(project, f"outputs/attempts/{attempt_id}")
    path = project_file(directory, "snapshot.json")
    marker = read_json(project_file(directory, "registered.json"))
    if marker.get("snapshot_sha256") != sha256(path):
        raise ValueError("Manifesto do snapshot alterado.")
    data = read_json(path)
    if data.get("schema_version") != 1 or data.get("attempt_id") != attempt_id:
        raise ValueError("Identificação do snapshot inválida.")
    for item in data["files"]:
        if sha256(project_file(directory, item["file"])) != item["sha256"]:
            raise ValueError(f"Arquivo congelado alterado: {item['file']}")
    if attempt is None:
        _, rows = read_csv(project / "attempts.csv")
        matches = [row for row in rows if row["attempt_id"] == attempt_id]
        if len(matches) != 1:
            raise ValueError("Tentativa deve ter identificação única no CSV.")
        attempt = matches[0]
    if any(attempt.get(key) != data["attempt"].get(key) for key in FROZEN_FIELDS):
        raise ValueError("Campos originais da tentativa divergem do snapshot.")
    return data


def freeze(project: Path, scene_id: str, attempt_id: str, *, workspace: Path = ROOT,
           capabilities: dict | None = None, dry_run: bool = False) -> dict:
    from preflight import preflight
    project = project_root(project, workspace)
    identifier(attempt_id)
    result = preflight(project, capabilities, scene_id)
    if dry_run:
        return result
    if not result["generation_ready"]:
        raise ValueError("Cena não está pronta: " + "; ".join(result["errors"] + result["blockers"]))
    with record_lock(project):
        # Recheck after acquiring the lock; a prepared snapshot does not submit anything.
        result = preflight(project, capabilities, scene_id)
        if not result["generation_ready"]:
            raise ValueError("Prontidão mudou; refazer preflight.")
        fields, rows = read_csv(project / "attempts.csv")
        if any(row["attempt_id"] == attempt_id for row in rows):
            raise ValueError("ID de tentativa já usado.")
        data = read_json(project / "project.json")
        scene = next(s for s in data["scenes"] if s["id"] == scene_id)
        text = submitted_prompt(project_file(project, scene["prompt"]).read_text(encoding="utf-8"))
        directory = project_file(project, f"outputs/attempts/{attempt_id}")
        directory.mkdir(parents=True, exist_ok=False)
        files = []

        def copy(source: str, role: str):
            original = project_file(project, source)
            digest = sha256(original)
            destination = directory / f"{len(files):03d}-{role}{original.suffix}"
            shutil.copyfile(original, destination)
            if sha256(original) != digest or sha256(destination) != digest:
                raise ValueError("Arquivo mudou durante congelamento; snapshot parcial preservado.")
            files.append({"role": role, "source": source, "file": destination.name, "sha256": digest})

        copy("project.json", "project")
        copy(scene["prompt"], "prompt_source")
        for key in ("storyboard_spec", "storyboard_prompt", "review_plan"):
            if scene.get(key):
                copy(scene[key], key)
        for asset in data["assets"]:
            if asset["handle"] in scene["required_references"]:
                copy(asset["path"], "reference")
                if asset.get("library"):
                    copy(asset["library"]["record"], "library_record")
        mode = scene.get("mode", data["mode"])
        slots = ("initial", "final") if mode == "first-last-frame" else (("initial",) if mode == "first-frame" else ())
        for slot in slots:
            frame = scene["frames"][slot]
            copy(frame["path"], f"{slot}_frame")
            copy(frame["binding"]["evidence"], f"{slot}_binding")
        for handle in scene["required_references"] if mode == "references-to-video" else []:
            copy(scene["bindings"][handle]["evidence"], "binding")
        copy(data["generation"]["ui_evidence"], "ui_evidence")
        if scene.get("handoff"):
            copy(scene["handoff"]["review_decision"], "handoff_decision")
            copy(scene["handoff"]["frame"], "handoff_frame")
        prompt_path = directory / "submitted_prompt.txt"
        prompt_path.write_text(text, encoding="utf-8", newline="\n")
        files.append({"role": "submitted_prompt", "file": prompt_path.name, "sha256": sha256(prompt_path)})
        attempt = {key: "" for key in fields}
        values = {"attempt_id": attempt_id, "utc": utc_now(), "scene_id": scene_id, "model": data["model"],
                  "mode": scene.get("mode", data["mode"]), "reference_version": data["reference_version"],
                  "prompt_file": prompt_path.relative_to(project).as_posix(),
                  "expected_credits": str(data["generation"]["cost_per_result_credits"] * data["generation"]["results_per_attempt"]),
                  "status": "pending"}
        if set(values) - set(fields):
            raise ValueError("Cabeçalho CSV incompatível com registro de tentativa.")
        attempt.update(values)
        snapshot = {"schema_version": 1, "attempt_id": attempt_id, "created_at": utc_now(),
                    "plan_sha256": result["plan_sha256"], "attempt": attempt,
                    "project": data, "scene": scene, "files": files}
        write_json(directory / "snapshot.json", snapshot)
        # Detect modifications to any source while the remaining files were copied.
        if any(sha256(project_file(project, item["source"])) != item["sha256"] for item in files if "source" in item):
            raise ValueError("Originais mudaram durante congelamento; reconciliar snapshot órfão.")
        write_csv(project / "attempts.csv", fields, rows + [attempt])
        write_json(directory / "registered.json", {"snapshot_sha256": sha256(directory / "snapshot.json")})
        verify_snapshot(project, attempt_id)
        return {"snapshot": str(directory / "snapshot.json"), "status": "pending", "submitted": False}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("freeze", "verify"))
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--attempt", required=True)
    parser.add_argument("--scene")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    try:
        project = project_root(ROOT / args.project)
        if args.command == "verify":
            result = verify_snapshot(project, args.attempt)
            print(f"Snapshot íntegro: {result['attempt_id']}")
        else:
            if not args.scene:
                parser.error("freeze exige --scene")
            print(freeze(project, args.scene, args.attempt, dry_run=args.dry_run))
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
