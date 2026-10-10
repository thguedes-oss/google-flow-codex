"""Check supplementary reference copies without executing their code or contacting the network."""
from __future__ import annotations

import argparse
from datetime import date
import json
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import urlsplit

from preflight import project_file, sha256

ROOT = Path(__file__).resolve().parents[1]


def check_web_url(value: str) -> None:
    if not isinstance(value, str) or not value.strip():
        raise ValueError("URL da fonte web ausente.")
    parsed = urlsplit(value)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username is not None or parsed.password is not None:
        raise ValueError("Fonte web exige URL HTTPS sem credenciais.")


def check_supplements(root: Path, supplements: list[dict]) -> list[dict]:
    results = []
    if not isinstance(supplements, list) or not supplements:
        return [{"id": "supplements", "passed": False, "errors": ["Fontes complementares ausentes."]}]
    for source in supplements:
        errors = []
        source_id = source.get("id", "unknown") if isinstance(source, dict) else "unknown"
        try:
            directory = project_file(root, source["directory"])
            vendor = (root / "vendor").resolve()
            if directory == vendor or not directory.is_relative_to(vendor):
                raise ValueError("Fonte complementar deve ficar dentro de vendor/.")
            if not directory.is_dir():
                raise ValueError("Cópia complementar ausente.")
            if source["type"] == "web-snapshot":
                check_web_url(source.get("url"))
                if not isinstance(source.get("verified_on"), str) or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", source["verified_on"]):
                    raise ValueError("Consulta web exige data AAAA-MM-DD.")
                date.fromisoformat(source["verified_on"])
                for key in ("attribution", "license", "rights_note"):
                    if not isinstance(source.get(key), str) or not source[key].strip():
                        raise ValueError(f"Fonte web exige {key}.")
            elif not re.fullmatch(r"[0-9a-f]{40}", source["commit"]):
                raise ValueError("Commit fixado inválido.")
            if source["type"] == "git":
                if not (directory / ".git").exists():
                    raise ValueError("Clone independente ausente.")
                for command, expected in [(["rev-parse", "HEAD"], source["commit"]),
                                          (["status", "--porcelain", "--untracked-files=all"], "")]:
                    result = subprocess.run(["git", "-C", str(directory), *command], capture_output=True,
                                            text=True, encoding="utf-8", errors="replace", timeout=30)
                    if result.returncode or result.stdout.strip() != expected:
                        errors.append(f"Git {command[0]} diverge da cópia fixada ou contém alterações locais.")
            elif source["type"] not in ("snapshot", "web-snapshot"):
                raise ValueError("Tipo de fonte desconhecido.")
            files = source["files"]
            if not isinstance(files, list) or not files:
                raise ValueError("Lista de arquivos e hashes ausente.")
            for item in files:
                if source["type"] == "web-snapshot":
                    check_web_url(item.get("source_url"))
                path = project_file(directory, item["path"])
                if not path.is_file():
                    errors.append(f"Arquivo ausente: {item['path']}")
                elif not re.fullmatch(r"[0-9a-f]{64}", item["sha256"]) or sha256(path) != item["sha256"]:
                    errors.append(f"SHA-256 divergente: {item['path']}")
            if "inventory" in source:
                descriptor = source["inventory"]
                inventory_path = project_file(root, descriptor["path"])
                inventory_root = (root / "config/source-inventories").resolve()
                if not inventory_path.is_relative_to(inventory_root):
                    raise ValueError("Inventário deve ficar em config/source-inventories/.")
                if not re.fullmatch(r"[0-9a-f]{64}", descriptor["sha256"]) or sha256(inventory_path) != descriptor["sha256"]:
                    raise ValueError("SHA-256 do inventário divergente.")
                inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
                if inventory["source_id"] != source_id or inventory["commit"] != source["commit"]:
                    raise ValueError("Origem ou commit do inventário divergente.")
                entries = inventory["files"]
                if not isinstance(entries, list) or not entries:
                    raise ValueError("Inventário vazio.")
                listed = set()
                for item in entries:
                    for key in ("path", "sha256", "category", "observed_license", "applicability", "destination", "reason"):
                        if not isinstance(item.get(key), str) or not item[key].strip():
                            raise ValueError(f"Inventário exige {key}.")
                    if item["path"] in listed:
                        raise ValueError("Caminho duplicado no inventário.")
                    listed.add(item["path"])
                    path = project_file(directory, item["path"])
                    if not path.is_file() or not re.fullmatch(r"[0-9a-f]{64}", item["sha256"]) or sha256(path) != item["sha256"]:
                        errors.append(f"Inventário: arquivo/hash divergente: {item['path']}")
                if source["type"] == "git":
                    tracked = subprocess.run(["git", "-C", str(directory), "ls-files", "-z"],
                        capture_output=True, check=True, timeout=30).stdout.decode("utf-8").split("\0")
                    actual = set(filter(None, tracked))
                    disk = {p.relative_to(directory).as_posix() for p in directory.rglob("*")
                            if p.is_file() and ".git" not in p.relative_to(directory).parts}
                    if disk != actual:
                        errors.append(f"Arquivos locais fora da lista versionada: {sorted(disk - actual)}; ausentes: {sorted(actual - disk)}")
                else:
                    actual = {p.relative_to(directory).as_posix() for p in directory.rglob("*") if p.is_file()}
                if actual != listed:
                    errors.append(f"Cobertura do inventário divergente; omitidos={sorted(actual - listed)}, extras={sorted(listed - actual)}")
        except (OSError, ValueError, TypeError, KeyError, subprocess.TimeoutExpired, subprocess.CalledProcessError) as exc:
            errors.append(str(exc))
        results.append({"id": source_id, "passed": not errors, "errors": errors})
    return results


def duplicate_groups(root: Path, supplements: list[dict]) -> list[dict]:
    """Keep every source/path origin, including identical files within one source."""
    by_hash = {}
    for source in supplements:
        if "inventory" not in source:
            continue
        descriptor = source["inventory"]
        path = project_file(root, descriptor["path"])
        if sha256(path) != descriptor["sha256"]:
            raise ValueError("Inventário de origem alterado durante checagem de duplicatas.")
        inventory = json.loads(path.read_text(encoding="utf-8"))
        for item in inventory["files"]:
            by_hash.setdefault(item["sha256"], []).append({
                "source_id": source["id"], "path": item["path"], "destination": item["destination"]})
    return [{"sha256": digest, "origins": sorted(origins, key=lambda x: (x["source_id"], x["path"], x["destination"]))}
            for digest, origins in sorted(by_hash.items()) if len(origins) > 1]


def check_duplicate_inventory(root: Path, lock: dict) -> dict | None:
    if "duplicate_inventory" not in lock:
        return None
    errors = []
    try:
        descriptor = lock["duplicate_inventory"]
        path = project_file(root, descriptor["path"])
        if not path.is_relative_to((root / "config/source-inventories").resolve()):
            raise ValueError("Inventário de duplicatas deve ficar em config/source-inventories/.")
        if not re.fullmatch(r"[0-9a-f]{64}", descriptor["sha256"]) or sha256(path) != descriptor["sha256"]:
            raise ValueError("SHA-256 do inventário de duplicatas divergente.")
        data = json.loads(path.read_text(encoding="utf-8"))
        if data.get("schema_version") != 1 or data.get("groups") != duplicate_groups(root, lock["supplements"]):
            raise ValueError("Grupos de duplicatas divergem dos inventários de origem.")
    except (OSError, ValueError, TypeError, KeyError, AttributeError) as exc:
        errors.append(str(exc))
    return {"id": "duplicate-inventory", "passed": not errors, "errors": errors}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lock", type=Path, default=ROOT / "sources.lock.json")
    args = parser.parse_args()
    try:
        lock = json.loads(args.lock.read_text(encoding="utf-8"))
        results = check_supplements(ROOT, lock.get("supplements"))
        duplicates = check_duplicate_inventory(ROOT, lock)
        if duplicates is not None:
            results.append(duplicates)
    except (OSError, ValueError, AttributeError) as exc:
        results = [{"id": "lock", "passed": False, "errors": [str(exc)]}]
    print(json.dumps({"sources": results, "passed": all(item["passed"] for item in results)}, ensure_ascii=False, indent=2))
    return 0 if all(item["passed"] for item in results) else 1


if __name__ == "__main__":
    sys.exit(main())
