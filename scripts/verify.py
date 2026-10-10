"""Verify the pinned source, local controls and prepared prompts without using Flow."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
from pathlib import Path
import re
import shutil
import subprocess
import sys
from uuid import uuid4

from flow_files import identifier, project_file, project_root, read_json, write_json
from preflight import preflight

ROOT = Path(__file__).resolve().parents[1]


def run_id() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + "-" + uuid4().hex[:8]


def preserve_previous_report(reports: Path) -> None:
    latest = reports / "verification.json"
    if not latest.is_file():
        return
    try:
        previous = read_json(latest)
        archived = reports / "runs" / identifier(previous.get("run_id")) / "verification.json"
        if archived.is_file() and archived.read_bytes() == latest.read_bytes():
            return
    except (OSError, ValueError, TypeError):
        pass
    # Preserve pre-versioning reports, including their existing flat logs, as bytes.
    legacy = reports / "runs" / ("legacy-" + run_id())
    legacy.mkdir(parents=True, exist_ok=False)
    for path in reports.iterdir():
        if path.is_file():
            shutil.copyfile(path, legacy / path.name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path("projects/exemplo-duas-cenas"))
    parser.add_argument("--skip-upstream-tests", action="store_true")
    parser.add_argument("--require-ready", action="store_true")
    parser.add_argument("--scene", help="Prontidão desta cena; a validação estrutural continua completa.")
    args = parser.parse_args()
    try:
        project = project_root(ROOT / args.project, ROOT)
    except ValueError as exc:
        parser.error(str(exc))
    reports = ROOT / "reports"
    reports.mkdir(exist_ok=True)
    preserve_previous_report(reports)
    verification_id = run_id()
    run_directory = reports / "runs" / verification_id
    run_directory.mkdir(parents=True, exist_ok=False)
    checks = []

    def run_check(name: str, command: list[str], expected: str | None = None) -> subprocess.CompletedProcess:
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
        output = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout + result.stderr)
        log = run_directory / f"{name}.txt"
        log.write_text(output, encoding="utf-8")
        passed = result.returncode == 0 and (expected is None or result.stdout.strip() == expected)
        checks.append({"name": name, "passed": passed, "exit_code": result.returncode, "log": log.relative_to(ROOT).as_posix()})
        print(f"{'PASS' if passed else 'FAIL'} {name}", flush=True)
        return result

    lock = read_json(ROOT / "sources.lock.json")
    vendor = ROOT / lock["directory"]
    source_ok = False
    if vendor.is_dir():
        head = run_check("source-commit", ["git", "-C", str(vendor), "rev-parse", "HEAD"], lock["commit"])
        status = run_check("source-clean", ["git", "-C", str(vendor), "status", "--porcelain"], "")
        reviewed_copy = head.returncode == 0 and head.stdout.strip() == lock["commit"] and status.returncode == 0 and not status.stdout.strip()
        if reviewed_copy:
            manifest = run_check("source-integrity", [sys.executable, str(vendor / "scripts/verify_package.py"), str(vendor), "--require-manifest", "--json"])
            source_ok = manifest.returncode == 0
    else:
        checks.append({"name": "vendor-exists", "passed": False})
    run_check("supplement-integrity", [sys.executable, str(ROOT / "scripts/source_integrity.py")])
    if (ROOT / "resources/techniques/catalog.json").is_file():
        run_check("technique-coverage", [sys.executable, str(ROOT / "scripts/technique_coverage.py")])
    run_check("library-integrity", [sys.executable, str(ROOT / "scripts/asset_library.py"), "verify"])
    run_check("record-integrity", [sys.executable, str(ROOT / "scripts/flow_review.py"), "audit", "--project", str(project)])
    run_check("local-tests", [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"])
    if not args.skip_upstream_tests and source_ok:
        run_check("upstream-tests", [sys.executable, str(ROOT / "scripts/upstream_tests.py")])
    result = preflight(project, scene_id=args.scene)
    if result["planning_passed"] and source_ok:
        data = read_json(project / "project.json")
        for index, scene in enumerate(data["scenes"], 1):
            duration = str(scene["duration_seconds"])
            common = ["--segment-length", duration, "--surface", "unspecified", "--model", "unspecified", "--mode", "unspecified", "--json"]
            for kind, field, extra in [("video", "prompt", ["--beat-mode", "coverage"]),
                                       ("storyboard", "storyboard_prompt", ["--beat-mode", "off", "--no-require-audio"])]:
                run_check(f"scene-{index:02d}-{kind}", [sys.executable, str(vendor / "scripts/validate.py"), str(project_file(project, scene[field])), *common, *extra])
            storyboard = project_file(project, scene["storyboard_prompt"])
            run_check(f"scene-{index:02d}-storyboard-render", [sys.executable, str(vendor / "scripts/generate_storyboard_prompt.py"), str(project_file(project, scene["storyboard_spec"]))], storyboard.read_text(encoding="utf-8").strip())
            # stdout is a prepared prompt, never submitted to an image model.
    structural_ok = result["planning_passed"] and all(check["passed"] for check in checks)
    ready = structural_ok and result["generation_ready"]
    # Optional post-production has its own readiness; it never authorizes Flow generation.
    from tesseract_tools import configuration, doctor
    from tesseract_pipeline import validate_plan
    tool_status = doctor()
    postproduction = {"configured": (project / "postproduction.json").is_file(), "ready": False,
                      "blockers": [], "tools": tool_status}
    if postproduction["configured"]:
        try:
            post_plan = read_json(project / "postproduction.json")
            postproduction["validation"] = validate_plan(project, post_plan)
            if not tool_status["tools"]["tesseract"]["available"]:
                postproduction["blockers"].append("Motor portátil indisponível; instalação explícita necessária.")
            if post_plan["kind"] != "design" and post_plan["delivery"]["resolution"] not in configuration()["export_profiles"]:
                postproduction["blockers"].append("Resolução sem perfil de exportação verificado.")
            postproduction["ready"] = not postproduction["blockers"]
        except (OSError, ValueError, KeyError, TypeError) as exc:
            postproduction["blockers"].append(str(exc))
    payload = {"run_id": verification_id, "project": project.relative_to(ROOT).as_posix(),
               "verified_at_utc": datetime.now(timezone.utc).isoformat(), "python": sys.version.split()[0],
               "python_executable": sys.executable, "source": lock, "checks": checks,
               "upstream_tests_requested": not args.skip_upstream_tests, "preflight": result,
               "planning_passed": structural_ok, "generation_ready": ready, "postproduction": postproduction,
               "media_generated_by_setup": 0, "generation_credits_spent_by_setup": 0,
               "note": "Validação local não comprova qualidade visual nem autoriza gastos no Flow."}
    write_json(run_directory / "verification.json", payload)
    write_json(reports / "verification.json", payload, replace=True)
    print(f"planning_passed={str(structural_ok).lower()}, generation_ready={str(ready).lower()}")
    print(f"Créditos registrados no projeto: {result['credits_spent']}. Gerações executadas por este programa: 0.")
    for error in result["errors"]:
        print(f"ERRO: {error}")
    for blocker in result["blockers"]:
        print(f"PENDENTE: {blocker}")
    print(f"Relatório: {reports / 'verification.json'}")
    print(f"Execução arquivada: {run_directory}")
    return 1 if not structural_ok or (args.require_ready and not ready) else 0


if __name__ == "__main__":
    sys.exit(main())
