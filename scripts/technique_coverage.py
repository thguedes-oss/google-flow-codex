"""Offline coverage gate: every enabled recipe must match actual native-render evidence."""
from __future__ import annotations
import argparse
from collections import Counter
import json
from pathlib import Path

from flow_files import ROOT,project_file,read_json,sha256,utc_now,write_json


def audit(root=ROOT):
    errors=[]
    inventories=[]
    lock=read_json(root/"sources.lock.json")
    for source in lock["supplements"]:
        if "inventory" not in source:
            continue
        inventory=read_json(project_file(root,source["inventory"]["path"]))
        inventories.extend(inventory["files"])
        for item in inventory["files"]:
            destination=project_file(root,item["destination"].split("#",1)[0])
            if not destination.is_file():
                errors.append(f"Destino documental ausente: {source['id']}:{item['path']}")
    native=read_json(root/"resources/techniques/catalog.json")
    native_report=read_json(root/"reports/techniques-smoke.json")
    if native_report.get("status")!="passed":
        errors.append("Smoke de receitas nativas não passou.")
    cases={c["id"] for c in native_report.get("cases",[]) if c.get("status")=="passed"}
    for entry in native["effects"]:
        if entry["status"]=="enabled" and entry["id"] not in cases:
            errors.append(f"Receita habilitada sem render: {entry['id']}")
        if entry["status"]=="enabled" and entry["id"] not in ("native.flash","native.audio-gain"):
            formats={case.get("format") for case in native_report.get("cases",[]) if case["id"]==entry["id"] and case.get("status")=="passed"}
            if formats!={"landscape","portrait","square"}:
                errors.append(f"Receita sem prova nos três formatos: {entry['id']}")

    def fingerprints(items,required,label):
        if not isinstance(items,list) or not required.issubset({i.get("path") for i in items if isinstance(i,dict)}):
            errors.append(f"Hashes obrigatórios ausentes: {label}.")
            return
        for item in items:
            if sha256(project_file(root,item["path"]))!=item["sha256"]:
                errors.append(f"Implementação mudou após {label}: {item['path']}")

    fingerprints(native_report.get("recipe_files"),{"scripts/flow_techniques.py","resources/techniques/catalog.json",
        "resources/techniques/color.wgsl"},"smoke nativo")
    gl=read_json(root/"resources/gl-transitions/catalog.json")
    gl_report=read_json(root/"reports/gl-transitions-smoke.json")
    results={entry["id"]:entry for entry in gl_report["results"]}
    expected={"gl."+p.stem for p in (root/"vendor/gl-transitions/transitions").glob("*.glsl")}
    if {e["id"] for e in gl["effects"]}!=expected or len(expected)!=125 or len(gl["effects"])!=125:
        errors.append("Catálogo GL não cobre os 125 shaders individualmente.")
    for entry in gl["effects"]:
        implementation=entry.get("implementation",{})
        if implementation and sha256(project_file(root,implementation["path"]))!=implementation["sha256"]:
            errors.append(f"WGSL divergente: {entry['id']}")
        if sha256(project_file(root,entry["source"]["path"]))!=entry["source"]["sha256"]:
            errors.append(f"GLSL de origem divergente: {entry['id']}")
        if entry["status"]!="enabled":
            continue
        result=results.get(entry["id"],{})
        if (result.get("status")!="rendered" or result.get("implementation_sha256")!=implementation.get("sha256")
                or not all(result.get("pixel_checks",{}).get(k) is True for k in
                    ("compiled","non_passthrough","endpoint_orientation_aspect","transparent_rgb_zero"))):
            errors.append(f"Efeito habilitado sem prova atual de pixels: {entry['id']}")
        aspects=result.get("aspects",[])
        if {a["aspect"] for a in aspects}!={"landscape","portrait","square"}:
            errors.append(f"Prova de formatos incompleta: {entry['id']}")
        for aspect in aspects:
            if sha256(project_file(root,aspect["report"]))!=aspect["report_sha256"]:
                errors.append(f"Relatório de formato alterado: {entry['id']} {aspect['aspect']}")
    integration=read_json(root/"reports/technique-pipeline-smoke.json")
    if (integration.get("status")!="passed" or integration.get("decoded_audio_byte_identical") is not True
            or integration.get("production_files_unchanged") is not True):
        errors.append("Prova de integração, janela, alpha ou áudio pendente.")
    fingerprints(integration.get("implementation_files"),{"scripts/tesseract_pipeline.py","scripts/flow_techniques.py",
        "scripts/smoke_technique_pipeline.py"},"integração do pipeline")
    fade=next(e for e in gl["effects"] if e["id"]=="gl.fade")
    fingerprints(integration.get("frozen_technique_files"),{"scripts/flow_techniques.py","resources/techniques/catalog.json",
        "resources/techniques/color.wgsl","resources/gl-transitions/catalog.json",fade["implementation"]["path"]},"integração de receitas/shaders")
    return {"schema_version":1,"verified_at":utc_now(),"passed":not errors,"errors":errors,
        "inventory_files":len(inventories),"documentary_classification":dict(Counter(i["applicability"] for i in inventories)),
        "duplicate_groups":len(read_json(root/"config/source-inventories/duplicates.json")["groups"]),
        "native":dict(Counter(e["status"] for e in native["effects"])),
        "gl":dict(Counter(e["status"] for e in gl["effects"])),
        "gl_rendered_cases":sum(len(r.get("aspects",[])) for r in gl_report["results"]),
        "production_media_generated":0,"flow_credits_spent":0,
        "note":"Cobertura documental, execução técnica e aprovação visual são avaliações separadas."}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report",type=Path)
    args=parser.parse_args()
    try:
        result=audit()
    except (OSError,ValueError,KeyError,TypeError) as exc:
        result={"passed":False,"errors":[str(exc)]}
    if args.report:
        write_json(args.report,result,replace=args.report.exists())
    print(json.dumps(result,ensure_ascii=False,indent=2))
    return 0 if result["passed"] else 1


if __name__=="__main__":
    raise SystemExit(main())
