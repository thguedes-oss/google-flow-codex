"""Pinned portable Tesseract tools. Only explicit install downloads software."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path, PurePosixPath
import platform
import re
import subprocess
import sys
import urllib.request
from uuid import uuid4
import zipfile

from flow_files import ROOT, project_file, read_json, sha256, utc_now, write_json


def configuration(workspace: Path = ROOT) -> dict:
    data = read_json(workspace / "config/tesseract.json")
    if data.get("schema_version") != 1 or data.get("platform") != "windows-x86_64":
        raise ValueError("Configuração Tesseract não suportada.")
    return data


def invoke(executable: Path, arguments: list[str], *, log: Path | None = None,
           timeout: int = 180) -> str:
    command = [str(executable), *map(str, arguments)]
    try:
        result = subprocess.run(command, capture_output=True, timeout=timeout, shell=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        if log:
            log.mkdir(parents=True, exist_ok=False)
            for stream in ("stdout", "stderr"):
                value = getattr(exc, stream, None) or b""
                (log / f"{stream}.txt").write_text(value.decode("utf-8", errors="replace") if isinstance(value, bytes) else value, encoding="utf-8")
            write_json(log / "command.json", {"arguments": command, "exit_code": None, "error": str(exc), "at": utc_now()})
        raise
    stdout, stderr = (value.decode("utf-8", errors="replace") for value in (result.stdout, result.stderr))
    if log:
        log.mkdir(parents=True, exist_ok=False)
        (log / "stdout.txt").write_text(stdout, encoding="utf-8")
        (log / "stderr.txt").write_text(stderr, encoding="utf-8")
        write_json(log / "command.json", {"arguments": command, "exit_code": result.returncode,
                                         "at": utc_now()})
    if result.returncode:
        raise ValueError(f"{executable.name} terminou com código {result.returncode}: {stderr.strip() or stdout.strip()}")
    return stdout


def check_version(executable: Path, version: str) -> str:
    actual = invoke(executable, ["--version"]).strip()
    if not re.search(r"(?<![\d.])" + re.escape(version) + r"(?![\d.])", actual):
        raise ValueError(f"Versão incompatível: esperado {version}; observado {actual}.")
    return actual


def tool_directory(name: str, workspace: Path = ROOT) -> Path:
    config = configuration(workspace)
    return project_file(workspace, config["tools_directory"]) / f"{name}-{config['tools'][name]['version']}"


def resolve_tool(name: str, workspace: Path = ROOT) -> Path:
    pin = configuration(workspace)["tools"][name]
    directory = tool_directory(name, workspace)
    if not (directory / "installation.json").is_file():
        raise ValueError(f"{name} {pin['version']} ausente. Execute tesseract_tools.py install --tool {name}.")
    record = read_json(directory / "installation.json")
    if record.get("pin") != pin or record.get("status") != "verified":
        raise ValueError("Instalação não corresponde à configuração fixada.")
    for item in record["files"]:
        if sha256(project_file(directory, item["path"])) != item["sha256"]:
            raise ValueError(f"Arquivo da instalação alterado: {item['path']}")
    executable = project_file(directory, record["executable"])
    check_version(executable, pin["version"])
    return executable


def download(url: str, destination: Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": "FLOW-Tesseract-Setup/1"})
    with urllib.request.urlopen(request, timeout=60) as response, destination.open("xb") as output:
        while chunk := response.read(1024 * 1024):
            output.write(chunk)


def verify_archive(archive: Path, checksum_file: Path, expected: str) -> None:
    published = checksum_file.read_text(encoding="utf-8").split()[0].lower()
    if not re.fullmatch(r"[0-9a-f]{64}", published) or published != expected or sha256(archive) != expected:
        raise ValueError("SHA-256 do download diverge do checksum publicado ou da versão fixada.")


def extract_archive(archive: Path, destination: Path) -> None:
    with zipfile.ZipFile(archive) as bundle:
        names = set()
        for item in bundle.infolist():
            path = PurePosixPath(item.filename.replace("\\", "/"))
            if (path.is_absolute() or ".." in path.parts or ":" in item.filename
                    or (item.external_attr >> 16) & 0o170000 == 0o120000):
                raise ValueError("Caminho inseguro no ZIP.")
            key = str(path).casefold()
            if key in names:
                raise ValueError("Caminho duplicado no ZIP.")
            names.add(key)
            project_file(destination, str(path))
        bundle.extractall(destination)


def install(name: str, workspace: Path = ROOT) -> dict:
    if sys.platform != "win32" or platform.machine().lower() not in ("amd64", "x86_64"):
        raise ValueError("Esta integração portátil exige Windows x86_64.")
    pin = configuration(workspace)["tools"][name]
    directory = tool_directory(name, workspace)
    if directory.exists():
        executable = resolve_tool(name, workspace)
        return {"status": "already_verified", "executable": str(executable)}
    directory.parent.mkdir(parents=True, exist_ok=True)
    staging = directory.parent / f"download-{name}-{uuid4().hex}"
    staging.mkdir(exist_ok=False)
    base = f"https://github.com/{pin['repository']}/releases/download/v{pin['version']}/"
    try:
        archive = staging / pin["archive"]
        checksum = staging / (pin["archive"] + ".sha256")
        download(base + checksum.name, checksum)
        download(base + archive.name, archive)
        verify_archive(archive, checksum, pin["sha256"])
        extracted = staging / "portable"
        extracted.mkdir()
        extract_archive(archive, extracted)
        matches = list(extracted.rglob(pin["executable"]))
        if len(matches) != 1:
            raise ValueError("ZIP não contém um executável único esperado.")
        executable = matches[0]
        version = check_version(executable, pin["version"])
        if name == "tesseract":
            status = json.loads(invoke(executable, ["telemetry", "status"]))
            if status.get("enabled") is not False:
                invoke(executable, ["telemetry", "disable"])
            if json.loads(invoke(executable, ["telemetry", "status"])).get("enabled") is not False:
                raise ValueError("Não foi possível confirmar telemetria desativada.")
        files = [{"path": p.relative_to(extracted).as_posix(), "sha256": sha256(p)}
                 for p in sorted(extracted.rglob("*")) if p.is_file()]
        write_json(extracted / "installation.json", {"status": "verified", "pin": pin,
                   "version_observed": version, "installed_at": utc_now(), "download_url": base + archive.name,
                   "executable": executable.relative_to(extracted).as_posix(), "files": files})
        extracted.rename(directory)
        return {"status": "installed_verified", "executable": str(resolve_tool(name, workspace))}
    except Exception as exc:
        write_json(staging / "failure.json", {"status": "failed", "error": str(exc), "at": utc_now()})
        raise


def doctor(workspace: Path = ROOT) -> dict:
    import shutil
    output = {"schema_version": 1, "tools": {}, "ffmpeg": shutil.which("ffmpeg"),
              "ffprobe": shutil.which("ffprobe"), "generation_calls": 0}
    for name in configuration(workspace)["tools"]:
        try:
            executable = resolve_tool(name, workspace)
            output["tools"][name] = {"available": True, "executable": str(executable)}
            if name == "tesseract":
                status = json.loads(invoke(executable, ["telemetry", "status"]))
                output["tools"][name]["telemetry"] = status
                if status.get("enabled") is not False:
                    raise ValueError("Telemetria não está desativada.")
        except (OSError, ValueError, KeyError, subprocess.SubprocessError) as exc:
            output["tools"][name] = {"available": False, "error": str(exc)}
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("doctor", "install"))
    parser.add_argument("--tool", choices=("tesseract", "converter", "all"), default="all")
    args = parser.parse_args()
    try:
        result = doctor() if args.command == "doctor" else {
            name: install(name) for name in configuration()["tools"] if args.tool in (name, "all")}
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
