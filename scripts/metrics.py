"""Describe actual reconciled attempts and explicit reviews; missing data stays unknown."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from uuid import uuid4

from flow_files import ROOT, identifier, nonnegative_number, project_file, project_root, read_json, utc_now, write_json
from flow_ledger import read_csv
from flow_review import CRITERIA, decision_files, verify_decision


def metrics(project: Path) -> dict:
    _, attempts = read_csv(project / "attempts.csv")
    data = read_json(project / "project.json")
    ids, decisions, first, selected, unknown, spent = set(), {}, {}, {}, [], 0
    scene_ids = {s["id"] for s in data["scenes"]}
    defects = {key: {"minor": 0, "reject": 0, "reviewed": 0} for key in CRITERIA}
    for attempt in attempts:
        aid = identifier(attempt["attempt_id"])
        if aid in ids or attempt["scene_id"] not in scene_ids:
            raise ValueError("Tentativa duplicada ou cena inexistente.")
        ids.add(aid)
        first.setdefault(attempt["scene_id"], attempt)
        if attempt["status"] not in ("pending", "completed", "failed", "unknown"):
            raise ValueError("Status de tentativa inválido.")
        if attempt["charged_credits"]:
            charge = float(attempt["charged_credits"])
            if not nonnegative_number(charge):
                raise ValueError("Créditos inválidos.")
            spent += charge
        if attempt["status"] in ("pending", "unknown") or not attempt["charged_credits"]:
            unknown.append(aid)
        files = decision_files(project, aid)
        if files:
            decision = verify_decision(project, files[-1])
            decisions[aid] = decision
            for item in decision["criteria"]:
                severity = str(item["severity"])
                if severity != "NA":
                    defects[item["criterion"]]["reviewed"] += 1
                if severity in ("1", "2"):
                    defects[item["criterion"]]["minor" if severity == "1" else "reject"] += 1
            if decision.get("selected") is True:
                if attempt["scene_id"] in selected:
                    raise ValueError("Há mais de uma alternativa selecionada para a mesma cena; reconciliar seleção.")
                selected[attempt["scene_id"]] = decision
    conclusives = []
    for attempt in first.values():
        if attempt["attempt_id"] in unknown:
            continue
        if attempt["status"] == "failed":
            conclusives.append(False)
        elif attempt["status"] == "completed" and attempt["attempt_id"] in decisions:
            conclusives.append(decisions[attempt["attempt_id"]]["decision"] == "approved")
    selected_seconds, missing_duration = 0, []
    for decision in selected.values():
        report = read_json(project_file(project, decision["evidence_report"]))
        duration = report.get("video_duration_seconds")
        if not nonnegative_number(duration) or duration <= 0:
            missing_duration.append(decision["attempt_id"])
        else:
            selected_seconds += duration
    candidates = [read_json(p) for p in (project / "assets/candidates").glob("*/*/record.json")]
    return {"schema_version": 1, "created_at": utc_now(), "project_title": data.get("title"),
            "attempt_count": len(attempts), "reviewed_attempt_count": len(decisions),
            "review_coverage": len(decisions) / len(attempts) if attempts else None,
            "known_flow_credits": spent, "flow_credits_complete": not unknown,
            "unreconciled_attempts": unknown,
            "first_attempt_scene_denominator": len(conclusives), "first_attempt_scene_excluded": len(first) - len(conclusives),
            "first_attempt_approval_rate": sum(conclusives) / len(conclusives) if conclusives else None,
            "first_attempt_order": "append_order_in_attempts_csv", "defects": defects,
            "selected_attempts": {sid: d["attempt_id"] for sid, d in selected.items()},
            "selected_approved_seconds": selected_seconds if selected and not missing_duration else None,
            "missing_selected_duration": missing_duration,
            "flow_credits_per_selected_approved_second": spent / selected_seconds if selected_seconds > 0 and not unknown and not missing_duration else None,
            "registered_image_gen_outputs": len([c for c in candidates if c.get("tool") == "image_gen"]),
            "image_gen_cost_total": None,
            "note": "Custos de imagens não são créditos do Flow. Contagem de saídas registradas não é contagem de chamadas. Sem dados comparáveis, não há medida de eficácia."}


def markdown(data: dict) -> str:
    def display(value):
        return "INDISPONÍVEL" if value is None else str(value)
    lines = ["# Métricas do projeto", "", data.get("project_title", ""), "",
             f"- Tentativas: {data['attempt_count']}", f"- Tentativas com revisão formal: {data['reviewed_attempt_count']}",
             f"- Créditos conhecidos do Flow: {data['known_flow_credits']}",
             f"- Tentativas não reconciliadas: {', '.join(data['unreconciled_attempts']) or 'nenhuma'}",
             f"- Aprovação inicial: {display(data['first_attempt_approval_rate'])}; denominador: {data['first_attempt_scene_denominator']}; excluídas: {data['first_attempt_scene_excluded']}",
             f"- Segundos aprovados selecionados: {display(data['selected_approved_seconds'])}",
             f"- Créditos por segundo selecionado: {display(data['flow_credits_per_selected_approved_second'])}", "",
             "| Critério | Revisado | Defeito menor | Rejeição |", "|---|---:|---:|---:|"]
    lines.extend(f"| {key} | {value['reviewed']} | {value['minor']} | {value['reject']} |" for key, value in data["defects"].items())
    return "\n".join(lines + ["", data["note"], ""])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--write", action="store_true", help="Gravar uma nova execução JSON e Markdown em outputs/metrics.")
    args = parser.parse_args()
    try:
        project = project_root(ROOT / args.project)
        result = metrics(project)
        if args.write:
            directory = project_file(project, f"outputs/metrics/{uuid4().hex}")
            directory.mkdir(parents=True, exist_ok=False)
            write_json(directory / "metrics.json", result)
            (directory / "metrics.md").write_text(markdown(result), encoding="utf-8")
            print(f"Relatórios: {directory}")
        else:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
