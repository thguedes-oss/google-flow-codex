"""Register real images, record explicit approval and import pinned local copies."""
from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import sys

from flow_files import (ROOT, approval_valid, identifier, inspect_image, project_file,
                        project_root, read_json, sha256, utc_now, write_json)


def candidate(project: Path, image: Path, specification: dict, *, workspace: Path = ROOT) -> Path:
    project = project_root(project, workspace)
    asset_id, version = identifier(specification.get("asset_id")), identifier(specification.get("version"))
    if specification.get("schema_version") != 1 or specification.get("kind") not in ("character", "location", "prop", "scene", "frame"):
        raise ValueError("Registro de imagem: schema_version=1 e tipo de material válido são necessários.")
    if specification.get("tool") not in ("image_gen", "user-provided"):
        raise ValueError("Origem deve ser image_gen ou user-provided.")
    for field in ("generated_at", "prompt", "observed_description"):
        if not isinstance(specification.get(field), str) or not specification[field].strip():
            raise ValueError(f"Registro de imagem: preencher {field} com dados reais.")
    inputs = specification.get("inputs", [])
    if not isinstance(inputs, list):
        raise ValueError("inputs precisa ser uma lista.")
    checked_inputs = []
    for record in inputs:
        path = project_file(project, record.get("path"))
        if not path.is_file() or record.get("sha256") != sha256(path) or not record.get("role"):
            raise ValueError("Referência de entrada ausente, alterada ou sem papel declarado.")
        inspect_image(path)
        checked_inputs.append((record, path))
    original_hash = sha256(image)
    info = inspect_image(image, decode=True)
    directory = project_file(project, f"assets/candidates/{asset_id}/{version}")
    directory.mkdir(parents=True, exist_ok=False)
    destination = directory / ("image" + image.suffix.lower())
    shutil.copyfile(image, destination)
    if sha256(destination) != original_hash or sha256(image) != original_hash:
        raise ValueError("Imagem mudou durante o registro; candidato incompleto preservado.")
    archived_inputs = []
    for index, (record, path) in enumerate(checked_inputs):
        input_directory = directory / "inputs"
        input_directory.mkdir(exist_ok=True)
        copy = input_directory / f"{index:02d}{path.suffix.lower()}"
        shutil.copyfile(path, copy)
        if sha256(copy) != record["sha256"]:
            raise ValueError("Input mudou durante o registro; candidato incompleto preservado.")
        archived_inputs.append(dict(record, archived_file=copy.relative_to(directory).as_posix()))
    payload = dict(specification, inputs=archived_inputs, approved=False, approval=None,
                   registered_at=utc_now(), file=destination.name, sha256=original_hash, image=info)
    write_json(directory / "record.json", payload)
    return directory / "record.json"


def verify_record(directory: Path) -> dict:
    record = read_json(directory / "record.json")
    image = project_file(directory, record.get("file"))
    if not image.is_file() or sha256(image) != record.get("sha256"):
        raise ValueError("Imagem registrada ausente ou com hash divergente.")
    inspect_image(image)
    for item in record.get("inputs", []):
        if sha256(project_file(directory, item.get("archived_file"))) != item.get("sha256"):
            raise ValueError("Input arquivado alterado.")
    if record.get("approved") is True and not approval_valid(record.get("approval")):
        raise ValueError("Aprovação da biblioteca incompleta.")
    return record


def promote(project: Path, candidate_path: str, approval: dict, *, workspace: Path = ROOT) -> Path:
    project = project_root(project, workspace)
    if not approval_valid(approval):
        raise ValueError("É necessária uma aprovação explícita com reviewer, at e evidence.")
    verify_library(workspace)
    source = project_file(project, candidate_path)
    if not source.is_relative_to(project_file(project, "assets/candidates")) or source.name != "record.json":
        raise ValueError("Selecione o record.json de um candidato do projeto.")
    record = verify_record(source.parent)
    library = project_file(workspace, "library")
    catalog = read_json(library / "catalog.json")
    key = (identifier(record["asset_id"]), identifier(record["version"]))
    if any((a["asset_id"], a["version"]) == key for a in catalog["assets"]):
        raise ValueError("Versão já catalogada; crie outra versão, sem substituir a anterior.")
    directory = project_file(library, f"assets/{key[0]}/{key[1]}")
    directory.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(source.parent, directory)
    record.update(approved=True, approval=approval, source_project=project.relative_to(workspace).as_posix())
    write_json(directory / "record.json", record, replace=True)
    verify_record(directory)
    catalog["assets"].append({"asset_id": key[0], "version": key[1],
                              "directory": directory.relative_to(library).as_posix(),
                              "record_sha256": sha256(directory / "record.json")})
    write_json(library / "catalog.json", catalog, replace=True)
    return directory / "record.json"


def library_record(workspace: Path, asset_id: str, version: str) -> tuple[Path, dict]:
    library = project_file(workspace, "library")
    catalog = read_json(library / "catalog.json")
    matches = [a for a in catalog["assets"] if a["asset_id"] == asset_id and a["version"] == version]
    if len(matches) != 1:
        raise ValueError("Esperada uma versão única na biblioteca.")
    directory = project_file(library, matches[0]["directory"])
    if sha256(directory / "record.json") != matches[0]["record_sha256"]:
        raise ValueError("Registro da biblioteca alterado.")
    record = verify_record(directory)
    if record.get("approved") is not True:
        raise ValueError("Material não aprovado.")
    return directory, record


def import_asset(project: Path, asset_id: str, version: str, handle: str, *, workspace: Path = ROOT) -> Path:
    project = project_root(project, workspace)
    directory, record = library_record(workspace, identifier(asset_id), identifier(version))
    data = read_json(project / "project.json")
    matches = [a for a in data["assets"] if a["handle"] == handle]
    if len(matches) != 1 or matches[0].get("kind") != record["kind"]:
        raise ValueError("Declare um handle único e de tipo correspondente no manifesto antes de importar.")
    destination = project_file(project, f"assets/library/{asset_id}/{version}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(directory, destination)
    verify_record(destination)
    matches[0].update(path=(destination / record["file"]).relative_to(project).as_posix(),
                      sha256=record["sha256"], approved=True, description=record["observed_description"],
                      library={"asset_id": asset_id, "version": version,
                               "record": (destination / "record.json").relative_to(project).as_posix(),
                               "record_sha256": sha256(destination / "record.json")})
    for scene in data["scenes"]:
        scene.get("bindings", {}).pop(handle, None)
    data["reference_version"] = "library-" + sha256(destination / "record.json")[:12]
    data["generation"].update(ui_verified=False, ui_verified_on=None, ui_evidence=None, ui_plan_sha256=None)
    write_json(project / "project.json", data, replace=True)
    return destination


def verify_library(workspace: Path = ROOT) -> dict:
    catalog = read_json(workspace / "library/catalog.json")
    if catalog.get("schema_version") != 1 or not isinstance(catalog.get("assets"), list):
        raise ValueError("Catálogo inválido.")
    keys = [(a["asset_id"], a["version"]) for a in catalog["assets"]]
    if len(keys) != len(set(keys)):
        raise ValueError("Versão duplicada no catálogo.")
    for asset_id, version in keys:
        library_record(workspace, asset_id, version)
    # An interrupted promotion is visible instead of being silently adopted.
    declared = {project_file(workspace / "library", a["directory"]) for a in catalog["assets"]}
    disk = {p.resolve() for p in (workspace / "library/assets").glob("*/*") if p.is_dir()}
    if disk != declared:
        raise ValueError("Biblioteca contém registros órfãos ou ausentes; reconciliar antes de importar.")
    return {"schema_version": 1, "verified": True, "approved_versions": len(keys)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    create = sub.add_parser("candidate")
    create.add_argument("--project", type=Path, required=True)
    create.add_argument("--image", type=Path, required=True)
    create.add_argument("--input", type=Path, required=True)
    approve = sub.add_parser("promote")
    approve.add_argument("--project", type=Path, required=True)
    approve.add_argument("--candidate", required=True)
    approve.add_argument("--approval", type=Path, required=True)
    select = sub.add_parser("import")
    select.add_argument("--project", type=Path, required=True)
    select.add_argument("--asset", required=True)
    select.add_argument("--version", required=True)
    select.add_argument("--handle", required=True)
    sub.add_parser("verify")
    args = parser.parse_args()
    try:
        if args.command == "candidate":
            result = candidate(ROOT / args.project, args.image, read_json(args.input))
        elif args.command == "promote":
            result = promote(ROOT / args.project, args.candidate, read_json(args.approval))
        elif args.command == "import":
            result = import_asset(ROOT / args.project, args.asset, args.version, args.handle)
        else:
            result = verify_library()
        print(result)
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
