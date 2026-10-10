"""Read-only checks for a Flow scene plan; never sends prompts or generates media."""
from __future__ import annotations

import argparse
from datetime import date
import hashlib
import json
from pathlib import Path
import re
import sys
from flow_files import (inspect_image, approval_valid, read_json, project_file, sha256,
                        nonnegative_number, nonempty_text, identifier)
from flow_ledger import read_csv
from flow_review_plan import load_review_plan

ROOT = Path(__file__).resolve().parents[1]
CAPABILITIES = ROOT / "config/flow-capabilities.json"


def plan_sha256(project: Path, data: dict, scene_id: str | None = None) -> str:
    """Bind a recorded UI check to the exact prompts, assets and settings reviewed."""
    plan = {key: data.get(key) for key in ("surface", "model", "mode", "aspect_ratio", "reference_version")}
    plan["selected_scene"] = scene_id
    selected = [s for s in data["scenes"] if scene_id is None or s["id"] == scene_id]
    handles = {h for s in selected for h in s["required_references"]}
    plan["assets"] = [{key: a.get(key) for key in ("handle", "path", "sha256", "library")} for a in data["assets"] if a["handle"] in handles]
    plan["scenes"] = [{key: s.get(key) for key in ("id", "mode", "duration_seconds", "required_references", "transition", "state_in", "state_out", "continuity_changes", "frames", "handoff", "bindings", "review_plan")} for s in selected]
    for scene, record in zip(selected, plan["scenes"]):
        record["prompt_sha256"] = sha256(project_file(project, scene["prompt"]))
        if scene.get("review_plan"):
            record["review_plan_sha256"] = sha256(project_file(project, scene["review_plan"]))
    plan["generation"] = {key: data["generation"].get(key) for key in ("results_per_attempt", "cost_per_result_credits", "resolution", "audio")}
    return hashlib.sha256(json.dumps(plan, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()


def transition_check(project: Path, previous: dict, scene: dict) -> tuple[list[str], list[str]]:
    errors, blockers = [], []
    before, after = previous["state_out"], scene["state_in"]
    differences = {k for k in before.keys() | after.keys() if k not in before or k not in after or before[k] != after[k]}
    changes = scene.get("continuity_changes", [])
    if not isinstance(changes, list) or not all(isinstance(c, dict) for c in changes):
        return ["continuity_changes precisa ser uma lista de objetos."], []
    declared = {c.get("field") for c in changes}
    if scene["transition"] == "continuation":
        if differences or changes:
            errors.append("Continuação exige igualdade dos estados; mudanças devem usar um corte.")
    elif declared != differences or len(declared) != len(changes):
        errors.append("Entrada diverge da saída anterior sem declaração exata de cada mudança.")
    for change in changes:
        key = change.get("field")
        if (not isinstance(key, str) or change.get("before") != before.get(key)
                or change.get("after") != after.get(key) or not nonempty_text(change.get("reason"))):
            errors.append("Mudança precisa declarar field, before, after e reason corretos.")
        if not nonempty_text(change.get("reviewer")) or not nonempty_text(change.get("evidence")):
            blockers.append("Mudança narrativa ainda precisa de revisão explícita.")
        elif not project_file(project, change["evidence"]).is_file():
            blockers.append("Evidência da revisão da mudança narrativa ausente.")
    return errors, blockers


def frame_checks(project: Path, scene: dict, mode: str) -> list[str]:
    blockers = []
    for slot in ("initial", "final") if mode == "first-last-frame" else ("initial",):
        try:
            frame = scene.get("frames", {}).get(slot, {})
            path = project_file(project, frame.get("path"))
            if frame.get("approved") is not True or sha256(path) != frame.get("sha256"):
                raise ValueError("Frame não aprovado ou hash divergente.")
            inspect_image(path)
            binding = frame.get("binding", {})
            if (not nonempty_text(binding.get("flow_asset")) or binding.get("sha256") != frame["sha256"]
                    or not project_file(project, binding.get("evidence")).is_file()):
                raise ValueError("Vinculação e evidência do slot ainda não registradas.")
        except (OSError, ValueError, KeyError, TypeError) as exc:
            blockers.append(f"Slot {slot}: {exc}")
    return blockers


def handoff_check(project: Path, previous: dict, scene: dict) -> None:
    from flow_review import verify_decision
    handoff = scene.get("handoff")
    if not isinstance(handoff, dict):
        raise ValueError("Revisar frame real de passagem e registrar handoff do clipe aprovado.")
    decision = verify_decision(project, project_file(project, handoff.get("review_decision")))
    if decision["decision"] != "approved" or decision["scene_id"] != previous["id"]:
        raise ValueError("Origem precisa ser um clipe aprovado da cena anterior.")
    report_path = project_file(project, decision["evidence_report"])
    report = read_json(report_path)
    last_frame = project_file(report_path.parent, report["last_frame"])
    frame = project_file(project, handoff.get("frame"))
    if (sha256(frame) != sha256(last_frame) or sha256(frame) != handoff.get("sha256")
            or not approval_valid(handoff.get("frame_approval"))):
        raise ValueError("Frame de passagem divergente ou sem aprovação explícita.")
    if scene.get("frames", {}).get("initial", {}).get("sha256") != handoff["sha256"]:
        raise ValueError("Slot inicial não corresponde ao frame de passagem aprovado.")


def preflight(project: Path, capabilities: dict | None = None, scene_id: str | None = None) -> dict:
    project = project.resolve()
    errors, blockers = [], []
    report = {"project": str(project), "planning_passed": False, "generation_ready": False,
              "errors": errors, "blockers": blockers, "credits_spent": 0, "planned_video_credits": None,
              "selected_scene": scene_id, "legacy_attempts_without_snapshot": []}
    try:
        data = read_json(project / "project.json")
        caps = capabilities if capabilities is not None else read_json(CAPABILITIES)
        if not isinstance(data, dict) or data.get("schema_version") != 1:
            raise ValueError("project.json precisa usar schema_version=1.")
        if data.get("surface") != "flow":
            errors.append("Este preflight se aplica ao Flow, não à Gemini API.")
        profiles = caps["models"].get(data.get("model"), {})
        durations = profiles.get(data.get("mode"), [])
        if not durations:
            errors.append("Combinação modelo/modo não coberta pela tabela local.")
        if data.get("aspect_ratio") not in caps["aspect_ratios"]:
            errors.append("Proporção não suportada pela tabela local.")
        if caps["verified_on"] != date.today().isoformat():
            blockers.append("Revalidar a documentação de capacidades para o dia de produção.")
        assets = data.get("assets")
        scenes = data.get("scenes")
        generation = data.get("generation")
        if not isinstance(assets, list) or not assets or not all(isinstance(a, dict) for a in assets):
            raise ValueError("assets precisa ser uma lista não vazia de objetos.")
        if not isinstance(scenes, list) or not scenes or not all(isinstance(s, dict) for s in scenes):
            raise ValueError("scenes precisa ser uma lista não vazia de objetos.")
        if not isinstance(generation, dict):
            raise ValueError("generation precisa ser um objeto.")
        if scene_id is not None and len([s for s in scenes if s.get("id") == scene_id]) != 1:
            raise ValueError("Cena selecionada inexistente ou duplicada.")
        selected_handles = {h for s in scenes if scene_id is None or s["id"] == scene_id for h in s.get("required_references", [])}
        asset_map = {}
        for asset in assets:
            handle = asset.get("handle")
            if not isinstance(handle, str) or not re.fullmatch(r"@[A-Z][A-Za-z0-9]*", handle):
                errors.append(f"Handle inválido: {handle}")
                continue
            if handle in asset_map:
                errors.append(f"Referência duplicada: {handle}")
            asset_map[handle] = asset
            if handle not in selected_handles:
                continue
            if asset.get("approved") is not True:
                blockers.append(f"{handle}: referência visual ainda não aprovada.")
            if not asset.get("path"):
                blockers.append(f"{handle}: arquivo visual ausente.")
            else:
                image = project_file(project, asset["path"])
                if not image.is_file():
                    blockers.append(f"{handle}: arquivo visual não encontrado.")
                elif asset.get("sha256") != sha256(image):
                    blockers.append(f"{handle}: SHA-256 ausente ou diferente dos bytes atuais.")
                else:
                    try:
                        inspect_image(image)
                        if asset.get("library"):
                            from asset_library import verify_record
                            reference = asset["library"]
                            record_path = project_file(project, reference["record"])
                            record = verify_record(record_path.parent)
                            if (sha256(record_path) != reference["record_sha256"] or record.get("approved") is not True
                                    or record["sha256"] != asset["sha256"]):
                                raise ValueError("Cópia da biblioteca ou aprovação divergente.")
                    except (OSError, ValueError) as exc:
                        blockers.append(f"{handle}: {exc}")
        scene_ids, previous = set(), None
        for scene in scenes:
            sid = identifier(scene.get("id"))
            active = scene_id is None or sid == scene_id
            mode = scene.get("mode", data.get("mode"))
            durations = profiles.get(mode, [])
            if not isinstance(sid, str) or not sid or sid in scene_ids:
                errors.append(f"ID de cena inválido ou duplicado: {sid}")
            scene_ids.add(sid)
            duration = scene.get("duration_seconds")
            if type(duration) is not int or duration not in durations:
                errors.append(f"Cena {sid}: duração incompatível com o modelo/modo.")
            required = scene.get("required_references")
            if not isinstance(required, list) or not required or not all(isinstance(h, str) for h in required):
                raise ValueError(f"Cena {sid}: required_references deve conter os handles usados.")
            if len(required) != len(set(required)):
                errors.append(f"Cena {sid}: referência repetida.")
            unknown = set(required) - asset_map.keys()
            if unknown:
                errors.append(f"Cena {sid}: referências não declaradas: {sorted(unknown)}")
            prompt = project_file(project, scene.get("prompt"))
            if not prompt.is_file():
                errors.append(f"Cena {sid}: prompt ausente.")
            else:
                text = prompt.read_text(encoding="utf-8")
                if "VIDEO PROMPT" not in text or "validate:ignore" in text:
                    errors.append(f"Cena {sid}: bloco de vídeo ausente ou lint desativado.")
                prompt_handles = set(re.findall(r"@[A-Za-z][A-Za-z0-9]*", text))
                if set(required) != prompt_handles:
                    errors.append(f"Cena {sid}: handles do prompt diferem das referências exigidas.")
            for key in ("storyboard_spec", "storyboard_prompt"):
                if not project_file(project, scene.get(key)).is_file():
                    errors.append(f"Cena {sid}: {key} ausente.")
            if scene.get("review_plan"):
                try:
                    load_review_plan(project_file(project, scene["review_plan"]))
                except (OSError, ValueError, TypeError, KeyError) as exc:
                    errors.append(f"Cena {sid}: plano de revisão inválido: {exc}")
            if not isinstance(scene.get("state_in"), dict) or not scene["state_in"] or not isinstance(scene.get("state_out"), dict) or not scene["state_out"]:
                errors.append(f"Cena {sid}: estados de entrada/saída ausentes.")
            if previous is None:
                if scene.get("transition") != "opening":
                    errors.append(f"Cena {sid}: primeira transição deve ser opening.")
            else:
                if scene.get("transition") not in ("cut", "continuation"):
                    errors.append(f"Cena {sid}: declarar cut ou continuation.")
                transition_errors, transition_blockers = transition_check(project, previous, scene)
                errors.extend(f"Cena {sid}: {value}" for value in transition_errors)
                if active:
                    blockers.extend(f"Cena {sid}: {value}" for value in transition_blockers)
                if scene.get("transition") == "continuation" and active:
                    try:
                        if mode not in ("first-frame", "first-last-frame"):
                            raise ValueError("Continuação requer modo de frames e slot inicial compatível.")
                        handoff_check(project, previous, scene)
                    except (OSError, ValueError, KeyError, TypeError) as exc:
                        blockers.append(f"Cena {sid}: {exc}")
            previous = scene
            bindings = scene.get("bindings", {})
            if not isinstance(bindings, dict):
                raise ValueError(f"Cena {sid}: bindings precisa ser um objeto.")
            if active and mode in ("first-frame", "first-last-frame"):
                blockers.extend(f"Cena {sid}: {value}" for value in frame_checks(project, scene, mode))
            for handle in required if active and mode == "references-to-video" else []:
                binding = bindings.get(handle)
                asset = asset_map.get(handle, {})
                if not isinstance(binding, dict) or not nonempty_text(binding.get("flow_asset")) or not binding.get("sha256") or binding.get("sha256") != asset.get("sha256"):
                    blockers.append(f"Cena {sid}: vinculação real de {handle} no Flow ainda não registrada.")
                elif not nonempty_text(binding.get("evidence")) or not project_file(project, binding.get("evidence")).is_file():
                    blockers.append(f"Cena {sid}: evidência da vinculação de {handle} ausente.")
        ledger = project / "attempts.csv"
        spent, has_unknown = 0, False
        attempt_ids = set()
        fields, rows = read_csv(ledger)
        if not {"attempt_id", "scene_id", "status", "charged_credits"}.issubset(fields):
            raise ValueError("attempts.csv não contém os campos necessários.")
        for row in rows:
            attempt_id = identifier(row["attempt_id"])
            if not attempt_id or attempt_id in attempt_ids or row["scene_id"] not in scene_ids:
                errors.append(f"Tentativa com ID/referência de cena inválida: {attempt_id}")
            attempt_ids.add(attempt_id)
            if row["status"] not in ("pending", "completed", "failed", "unknown"):
                errors.append(f"Status de tentativa inválido: {attempt_id}")
            if row["status"] in ("pending", "unknown") or not row["charged_credits"]:
                has_unknown = True
            if row["charged_credits"]:
                charge = float(row["charged_credits"])
                if not nonnegative_number(charge):
                    raise ValueError("Créditos de tentativa inválidos.")
                spent += charge
            bundle = project_file(project, f"outputs/attempts/{attempt_id}/snapshot.json")
            if bundle.is_file():
                from attempt_snapshot import verify_snapshot
                try:
                    verify_snapshot(project, attempt_id, row)
                except (OSError, ValueError, KeyError) as exc:
                    blockers.append(f"Tentativa {attempt_id}: snapshot inconsistente: {exc}")
            else:
                report["legacy_attempts_without_snapshot"].append(attempt_id)
        for directory in (project / "outputs/attempts").glob("*"):
            if directory.is_dir() and directory.name not in attempt_ids:
                blockers.append(f"Snapshot órfão {directory.name}: reconciliar operação interrompida.")
        report["credits_spent"] = spent
        if has_unknown:
            blockers.append("Há tentativa pendente/desconhecida ou gasto não reconciliado; não reenviar.")
        budget = generation.get("budget_credits")
        count = generation.get("results_per_attempt")
        cost = generation.get("cost_per_result_credits")
        if not nonnegative_number(budget):
            errors.append("Orçamento deve ser um número finito não negativo.")
        else:
            if spent > budget:
                blockers.append("Gasto registrado excede o orçamento.")
            if budget == 0:
                blockers.append("Orçamento de geração é zero.")
        if type(count) is not int or count < 1:
            errors.append("Quantidade de resultados deve ser um inteiro positivo.")
        if not nonnegative_number(cost):
            blockers.append("Custo por resultado ainda não confirmado na interface.")
        elif type(count) is int and count > 0:
            planned = cost * count * (len(scenes) if scene_id is None else 1)
            report["planned_video_credits"] = planned
            if nonnegative_number(budget) and spent + planned > budget:
                blockers.append("Orçamento restante insuficiente para as cenas planejadas.")
        if not isinstance(generation.get("authorization"), str) or not generation["authorization"].strip():
            blockers.append("Autorização de produção pelo usuário não registrada.")
        resolution, audio = generation.get("resolution"), generation.get("audio")
        if resolution is None:
            blockers.append("Resolução ainda não conferida na interface.")
        elif type(resolution) is not int or resolution <= 0:
            errors.append("Resolução deve ser um inteiro positivo em linhas, como 720.")
        if not isinstance(audio, dict) or audio.get("intent") == "unspecified":
            blockers.append("Plano de áudio ainda não registrado.")
        elif audio.get("intent") not in ("ambient", "dialogue", "silent", "music"):
            errors.append("Intenção de áudio inválida.")
        elif audio["intent"] == "dialogue" and not nonempty_text(audio.get("language")):
            blockers.append("Idioma do diálogo pendente.")
        evidence = generation.get("ui_evidence")
        if generation.get("ui_verified") is not True or generation.get("ui_verified_on") != date.today().isoformat() or not nonempty_text(evidence) or not project_file(project, evidence).is_file():
            blockers.append("Preflight específico da interface ainda não registrado para hoje.")
        if not errors:
            fingerprint = plan_sha256(project, data, scene_id)
            report["plan_sha256"] = fingerprint
            if generation.get("ui_plan_sha256") != fingerprint:
                blockers.append("Configuração/prompts atuais ainda não vinculados ao preflight da interface.")
        if data.get("mode") == "extend":
            blockers.append("Extensão exige inspeção da mídia de origem fora deste preflight de cenas novas.")
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as exc:
        errors.append(str(exc))
    report["planning_passed"] = not errors
    report["generation_ready"] = not errors and not blockers
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project", type=Path)
    parser.add_argument("--require-ready", action="store_true")
    parser.add_argument("--scene", help="Verificar prontidão apenas desta cena; a estrutura inteira continua validada.")
    args = parser.parse_args()
    result = preflight(args.project, scene_id=args.scene)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 2 if result["errors"] else (1 if args.require_ready and not result["generation_ready"] else 0)


if __name__ == "__main__":
    sys.exit(main())
