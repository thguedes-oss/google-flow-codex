"""Record explicit reviews, verify evidence and compare completed attempts locally."""
from __future__ import annotations

import argparse
from collections import Counter
import difflib
import json
from pathlib import Path
import sys
from uuid import uuid4

from flow_files import (ROOT, identifier, nonempty_text, nonnegative_number, project_file,
                        project_root, read_json, sha256, utc_now, write_json)
from flow_ledger import read_csv, record_lock, write_csv
from flow_review_plan import CRITERIA, validate_direction


def evidence_report(project: Path, value: str) -> tuple[Path, dict]:
    path = project_file(project, value)
    if not path.is_relative_to(project_file(project, "outputs/review")):
        raise ValueError("Relatório de evidências precisa estar em outputs/review.")
    report = read_json(path)
    video = project_file(project, report["source_file"])
    if not video.is_relative_to(project_file(project, "outputs")):
        raise ValueError("Vídeo fora de outputs.")
    if report.get("status") != "evidence_prepared" or sha256(video) != report["source_sha256"]:
        raise ValueError("Vídeo alterado ou evidências incompletas.")
    for sample in report["samples"]:
        if sha256(project_file(path.parent, sample["image"])) != sample["sha256"]:
            raise ValueError("PNG de evidência alterado.")
    if sha256(project_file(path.parent, report["contact_sheet"])) != report["contact_sheet_sha256"]:
        raise ValueError("Prancha de evidência alterada.")
    if (report["samples"][0]["frame_index"] != 0
            or report["samples"][-1]["frame_index"] != report["decoded_frame_count"] - 1
            or report["first_frame"] != report["samples"][0]["image"]
            or report["last_frame"] != report["samples"][-1]["image"]):
        raise ValueError("Evidências não identificam os frames reais de ponta.")
    return path, report


def decision_files(project: Path, attempt_id: str) -> list[Path]:
    parent = project_file(project, f"outputs/decisions/{identifier(attempt_id)}")
    return sorted(parent.glob("*/decision.json"), key=lambda p: (read_json(p)["created_at"], p.parent.name))


def verify_decision(project: Path, path: Path, *, require_latest: bool = True) -> dict:
    path = project_file(project, path.relative_to(project).as_posix())
    if not path.is_relative_to(project_file(project, "outputs/decisions")):
        raise ValueError("Decisão precisa estar em outputs/decisions.")
    marker = read_json(path.parent / "registered.json")
    if marker.get("decision_sha256") != sha256(path):
        raise ValueError("Decisão alterada ou fechamento interrompido.")
    data = read_json(path)
    if data.get("schema_version") != 1 or data["decision"] not in ("approved", "rejected"):
        raise ValueError("Decisão inválida.")
    files = decision_files(project, data["attempt_id"])
    if require_latest and (not files or files[-1] != path):
        raise ValueError("Decisão foi substituída por uma revisão posterior.")
    position = files.index(path)
    expected_previous = read_json(files[position - 1])["decision_id"] if position else None
    if data.get("supersedes") != expected_previous:
        raise ValueError("Cadeia de revisões inconsistente.")
    report_path, report = evidence_report(project, data["evidence_report"])
    if (sha256(report_path) != data["evidence_report_sha256"] or report["source_sha256"] != data["source_sha256"]
            or report["attempt_id"] != data["attempt_id"] or report["scene_id"] != data["scene_id"]):
        raise ValueError("Decisão não corresponde às evidências atuais.")
    _, attempts = read_csv(project / "attempts.csv")
    matches = [a for a in attempts if a["attempt_id"] == data["attempt_id"]]
    if (len(matches) != 1 or matches[0]["status"] != "completed" or matches[0]["scene_id"] != data["scene_id"]
            or matches[0]["output_file"] != report["source_file"]):
        raise ValueError("Decisão não corresponde a uma tentativa completed única.")
    fields, rows = read_csv(project / "review.csv")
    available = Counter(tuple(row.get(k, "") for k in fields) for row in rows)
    required = Counter(tuple(row.get(k, "") for k in fields) for row in data["review_rows"])
    if any(available[key] < count for key, count in required.items()):
        raise ValueError("Linhas de revisão ausentes ou alteradas no CSV.")
    validate_spec(data, report)
    return data


def validate_spec(spec: dict, report: dict) -> None:
    if spec.get("decision") not in ("approved", "rejected") or not isinstance(spec.get("reviewer"), str) or not spec["reviewer"].strip():
        raise ValueError("Preencha decision e reviewer com a decisão real.")
    if report.get("expected_direction") is not None:
        validate_direction(report["expected_direction"])
        if not isinstance(spec.get("intent_review"), str) or not spec["intent_review"].strip():
            raise ValueError("Direção planejada exige intent_review com a observação real do resultado.")
    criteria = spec.get("criteria")
    if not isinstance(criteria, list) or not criteria or not all(isinstance(c, dict) for c in criteria):
        raise ValueError("criteria precisa conter as observações reais.")
    names = [c.get("criterion") for c in criteria]
    if len(names) != len(set(names)) or set(names) - set(CRITERIA):
        raise ValueError("Critério desconhecido ou duplicado.")
    for item in criteria:
        if str(item.get("severity")) not in ("0", "1", "2", "NA") or not all(
                isinstance(item.get(key), str) and item[key].strip() for key in ("observation", "timestamps")):
            raise ValueError("Critério exige severity 0/1/2/NA, observation e timestamps ou justificativa NA.")
    if spec.get("decision") == "approved":
        if set(names) != set(CRITERIA) or any(str(c["severity"]) == "2" for c in criteria):
            raise ValueError("Aprovação exige todos os critérios, sem defeito de rejeição.")
        if spec.get("playback_completed") is not True:
            raise ValueError("Aprovação exige reprodução completa.")
        has_audio = any(s.get("codec_type") == "audio" for s in report["metadata"]["streams"])
        if has_audio and spec.get("audio_review") != "reviewed":
            raise ValueError("Aprovação exige inspeção do áudio existente.")
        if not has_audio and (spec.get("audio_review") != "not_applicable" or not isinstance(spec.get("audio_reason"), str) or not spec["audio_reason"].strip()):
            raise ValueError("Ausência de áudio exige not_applicable e justificativa.")
    if spec.get("selected") is True and spec.get("decision") != "approved":
        raise ValueError("Somente uma tentativa aprovada pode ser selecionada.")


def close_review(project: Path, attempt_id: str, spec: dict, *, workspace: Path = ROOT) -> Path:
    project = project_root(project, workspace)
    identifier(attempt_id)
    with record_lock(project):
        report_path, report = evidence_report(project, spec.get("evidence_report"))
        if report["attempt_id"] != attempt_id:
            raise ValueError("Relatório pertence a outra tentativa.")
        validate_spec(spec, report)
        previous = decision_files(project, attempt_id)
        previous_id = None
        if previous:
            previous_id = verify_decision(project, previous[-1])["decision_id"]
        if spec.get("supersedes") != previous_id:
            raise ValueError("Informe supersedes igual ao ID da revisão atual; primeira revisão usa null.")
        _, attempts = read_csv(project / "attempts.csv")
        matches = [a for a in attempts if a["attempt_id"] == attempt_id]
        if (len(matches) != 1 or matches[0]["status"] != "completed" or matches[0]["output_file"] != report["source_file"]
                or matches[0]["scene_id"] != report["scene_id"]):
            raise ValueError("Revisão exige tentativa completed única e mídia correspondente.")
        fields, rows = read_csv(project / "review.csv")
        new_rows = [{"attempt_id": attempt_id, "scene_id": report["scene_id"], "criterion": item["criterion"],
                     "severity": str(item["severity"]), "timestamps": item["timestamps"], "observation": item["observation"],
                     "decision": spec["decision"], "reviewer": spec["reviewer"]} for item in spec["criteria"]]
        decision_id = uuid4().hex
        directory = project_file(project, f"outputs/decisions/{attempt_id}/{decision_id}")
        directory.mkdir(parents=True, exist_ok=False)
        payload = dict(spec, schema_version=1, decision_id=decision_id, created_at=utc_now(), attempt_id=attempt_id,
                       scene_id=report["scene_id"], source_sha256=report["source_sha256"],
                       evidence_report_sha256=sha256(report_path), review_rows=new_rows)
        path = directory / "decision.json"
        write_json(path, payload)
        write_csv(project / "review.csv", fields, rows + new_rows)
        write_json(directory / "registered.json", {"decision_sha256": sha256(path)})
        verify_decision(project, path)
        return path


def compare_attempts(project: Path, left: str, right: str) -> dict:
    from attempt_snapshot import verify_snapshot
    snapshots = [verify_snapshot(project, identifier(aid)) for aid in (left, right)]
    if snapshots[0]["scene"]["id"] != snapshots[1]["scene"]["id"]:
        raise ValueError("Compare tentativas da mesma cena.")
    signatures, prompts, decisions = [], [], []
    for aid, snapshot in zip((left, right), snapshots):
        data, scene = snapshot["project"], snapshot["scene"]
        signatures.append({"model": data["model"], "mode": scene.get("mode", data["mode"]),
                           "aspect_ratio": data["aspect_ratio"], "duration": scene["duration_seconds"],
                           "title": data.get("title"), "state_in": scene["state_in"], "state_out": scene["state_out"],
                           "frames": {slot: frame.get("sha256") for slot, frame in scene.get("frames", {}).items()},
                           "generation": {k: data["generation"].get(k) for k in ("resolution", "audio", "results_per_attempt")},
                           "references": [(a["handle"], a["sha256"]) for a in data["assets"] if a["handle"] in scene["required_references"]]})
        files = decision_files(project, aid)
        decisions.append(verify_decision(project, files[-1]) if files else None)
        prompts.append(project_file(project, snapshot["attempt"]["prompt_file"]).read_text(encoding="utf-8"))
    return {"left": left, "right": right, "same_recorded_conditions": signatures[0] == signatures[1],
            "conditions": signatures, "decisions": decisions,
            "prompt_diff": "\n".join(difflib.unified_diff(prompts[0].splitlines(), prompts[1].splitlines(), fromfile=left, tofile=right)),
            "automatic_winner": None, "note": "Equivalência dos registros não garante determinismo do modelo."}


def audit_records(project: Path) -> dict:
    """Inspect generation and clip-review history, including records not in use."""
    from attempt_snapshot import verify_snapshot
    project = project.resolve()
    errors, warnings = [], []
    counts = {"attempts": 0, "snapshots": 0, "decisions": 0, "evidence_reports": 0}

    def issue(target, code, path, message):
        target.append({"code": code, "path": path.relative_to(project).as_posix(), "message": str(message)})

    def inspect(code, path, operation):
        try:
            project_file(project, path.relative_to(project).as_posix())
            return operation()
        except (OSError, ValueError, KeyError, TypeError, AttributeError, IndexError) as exc:
            issue(errors, code, path, exc)
            return None

    lock = project / "outputs/.records.lock"
    if lock.exists():
        issue(errors, "records_lock", lock, "Operação ativa ou interrompida; reconciliar antes de remover o lock.")

    def ledger(name, required):
        fields, rows = read_csv(project / name)
        if not set(required).issubset(fields):
            raise ValueError(f"{name}: cabeçalho incompleto.")
        return rows

    attempts = inspect("invalid_attempts_csv", project / "attempts.csv", lambda: ledger(
        "attempts.csv", ("attempt_id", "scene_id", "status", "charged_credits", "output_file")))
    attempt_map = {}
    for row in attempts or []:
        counts["attempts"] += 1

        def check_attempt():
            aid = identifier(row["attempt_id"])
            identifier(row["scene_id"])
            if aid in attempt_map:
                raise ValueError(f"Tentativa duplicada: {aid}.")
            attempt_map[aid] = row
            if row["status"] not in ("pending", "unknown", "completed", "failed"):
                raise ValueError(f"Status inválido: {aid}.")
            if row["charged_credits"] and not nonnegative_number(float(row["charged_credits"])):
                raise ValueError(f"Créditos inválidos: {aid}.")
            if row["status"] == "completed":
                video = project_file(project, row["output_file"])
                if not video.is_relative_to(project_file(project, "outputs")) or not video.is_file():
                    raise ValueError(f"Tentativa completed sem mídia local em outputs: {aid}.")
            if row["status"] in ("pending", "unknown") or not row["charged_credits"]:
                issue(warnings, "unreconciled_attempt", project / "attempts.csv", f"Reconciliar estado/gasto de {aid} no Flow.")
            if not (project / f"outputs/attempts/{aid}").exists():
                issue(warnings, "legacy_without_snapshot", project / "attempts.csv", f"Tentativa antiga sem congelamento: {aid}.")

        inspect("invalid_attempt", project / "attempts.csv", check_attempt)

    for directory in sorted((project / "outputs/attempts").glob("*")):
        counts["snapshots"] += 1
        if directory.name not in attempt_map:
            issue(errors, "orphan_snapshot", directory, "Pacote sem tentativa única correspondente no CSV.")
        inspect("invalid_snapshot", directory, lambda: verify_snapshot(project, directory.name))

    review_rows = inspect("invalid_review_csv", project / "review.csv", lambda: ledger(
        "review.csv", ("attempt_id", "scene_id", "criterion", "severity", "timestamps", "observation", "decision", "reviewer")))
    for row in review_rows or []:
        def check_row():
            aid = identifier(row["attempt_id"])
            if (aid not in attempt_map or row["scene_id"] != attempt_map[aid]["scene_id"]
                    or row["criterion"] not in CRITERIA or row["severity"] not in ("0", "1", "2", "NA")
                    or row["decision"] not in ("approved", "rejected")
                    or not all(nonempty_text(row[key]) for key in ("timestamps", "observation", "reviewer"))):
                raise ValueError(f"Linha de revisão inválida ou sem tentativa correspondente: {aid}.")
        inspect("invalid_review_row", project / "review.csv", check_row)

    referenced_reports, latest_selected, formal_attempts = set(), {}, set()
    for attempt_directory in sorted((project / "outputs/decisions").glob("*")):
        if not attempt_directory.is_dir():
            issue(errors, "incomplete_decision", attempt_directory, "Esperada uma pasta de decisões.")
            continue
        revisions = sorted(attempt_directory.iterdir())
        if not revisions:
            issue(errors, "incomplete_decision", attempt_directory, "Pasta de decisão vazia; reconciliar interrupção.")
        for directory in revisions:
            path = directory / "decision.json"
            if not path.is_file() or not (directory / "registered.json").is_file():
                issue(errors, "incomplete_decision", directory, "Decisão ou selo ausente; reconciliar interrupção.")
                continue
            counts["decisions"] += 1
            decision = inspect("invalid_decision", path, lambda: verify_decision(project, path, require_latest=False))
            if decision is None:
                continue
            if decision["attempt_id"] != attempt_directory.name:
                issue(errors, "invalid_decision", path, "Decisão arquivada sob outra tentativa.")
                continue
            formal_attempts.add(decision["attempt_id"])
            referenced_reports.add(project_file(project, decision["evidence_report"]))
            if decision_files(project, decision["attempt_id"])[-1] != path:
                issue(warnings, "superseded_decision", path, "Revisão substituída legitimamente; histórico preservado.")
            elif decision.get("selected") is True:
                sid = decision["scene_id"]
                if sid in latest_selected:
                    issue(errors, "conflicting_selection", path, f"Mais de uma tentativa selecionada para a cena {sid}.")
                latest_selected[sid] = path

    for directory in sorted((project / "outputs/review").glob("*/*")):
        path = directory / "review.json"
        if not path.is_file():
            failure = directory / "failure.json"
            if failure.is_file():
                def check_failure():
                    data = read_json(failure)
                    if (data.get("status") != "extraction_failed" or not nonempty_text(data.get("error"))
                            or data.get("attempt_id") != directory.parent.name or data.get("attempt_id") not in attempt_map):
                        raise ValueError("Registro de falha inválido ou sem tentativa correspondente.")
                    return data
                if inspect("invalid_failure", failure, check_failure) is not None:
                    issue(warnings, "failed_extraction", directory, "Extração com falha registrada; arquivos parciais não são evidências concluídas.")
            else:
                issue(errors, "incomplete_evidence", directory, "Relatório ou registro de falha ausente; reconciliar interrupção.")
            continue
        counts["evidence_reports"] += 1

        def check_evidence():
            _, report = evidence_report(project, path.relative_to(project).as_posix())
            attempt = attempt_map.get(report["attempt_id"])
            if (not attempt or attempt["status"] != "completed" or attempt["scene_id"] != report["scene_id"]
                    or attempt["output_file"] != report["source_file"] or path.parent.parent.name != report["attempt_id"]):
                raise ValueError("Evidências sem tentativa completed correspondente.")
            if report.get("expected_direction") is not None:
                validate_direction(report["expected_direction"])
            if path not in referenced_reports:
                issue(warnings, "unreviewed_evidence", path, "Evidências sem fechamento formal; nenhuma aprovação inferida.")
        inspect("invalid_evidence", path, check_evidence)

    for aid in sorted({r["attempt_id"] for r in review_rows or []} - formal_attempts):
        if aid in attempt_map:
            issue(warnings, "legacy_review_rows", project / "review.csv", f"Observações sem decisão formal válida: {aid}.")
    return {"schema_version": 1, "project": str(project), "passed": not errors,
            "counts": counts, "errors": errors, "warnings": warnings,
            "note": "Auditoria local de geração e revisão de clipes; não repara registros, não aprova mídia e não acessa o Flow."}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("close", "verify", "compare", "audit"))
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--attempt")
    parser.add_argument("--input", type=Path)
    parser.add_argument("--decision")
    parser.add_argument("--left")
    parser.add_argument("--right")
    args = parser.parse_args()
    try:
        project = project_root(ROOT / args.project)
        if args.command == "audit":
            result = audit_records(project)
            print(json.dumps(result, ensure_ascii=False, indent=2))
            return 0 if result["passed"] else 1
        elif args.command == "close":
            if not args.input or not args.attempt:
                parser.error("close exige --attempt e --input")
            print(close_review(project, args.attempt, read_json(args.input)))
        elif args.command == "verify":
            print(json.dumps(verify_decision(project, project_file(project, args.decision)), ensure_ascii=False, indent=2))
        else:
            print(json.dumps(compare_attempts(project, args.left, args.right), ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
