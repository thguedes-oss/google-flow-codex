"""Local file contracts shared by Flow helpers. No network or generation calls."""
from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
from uuid import uuid4

ROOT = Path(__file__).resolve().parents[1]


def project_file(root: Path, value: str) -> Path:
    if not isinstance(value, str) or not value.strip():
        raise ValueError("Caminho relativo ausente.")
    path = (root / value).resolve()
    if Path(value).is_absolute() or not path.is_relative_to(root.resolve()):
        raise ValueError(f"Caminho fora do projeto: {value}")
    return path


def project_root(value: Path, workspace: Path = ROOT) -> Path:
    project = value.resolve()
    parent = (workspace / "projects").resolve()
    if project == parent or not project.is_relative_to(parent):
        raise ValueError("O projeto deve estar dentro de projects/.")
    return project


def identifier(value: str) -> str:
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,79}", value):
        raise ValueError("ID inválido: use até 80 letras sem acentos, números, _ ou -.")
    return value


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def nonnegative_number(value) -> bool:
    return type(value) in (int, float) and math.isfinite(value) and value >= 0


def nonempty_text(value) -> bool:
    return isinstance(value, str) and bool(value.strip())


def read_json(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    if not isinstance(data, dict):
        raise ValueError(f"JSON precisa ser um objeto: {path.name}")
    return data


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_json(path: Path, value: dict, *, replace: bool = False) -> None:
    text = json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + "\n"
    if not replace:
        with path.open("x", encoding="utf-8", newline="\n") as stream:
            stream.write(text)
        return
    temporary = path.with_name(path.name + "." + uuid4().hex + ".tmp")
    try:
        temporary.write_text(text, encoding="utf-8", newline="\n")
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def approval_valid(value) -> bool:
    return (isinstance(value, dict) and value.get("approved") is True
            and all(isinstance(value.get(key), str) and value[key].strip()
                    for key in ("reviewer", "at", "evidence")))


def inspect_image(path: Path, *, decode: bool = False) -> dict:
    probe = shutil.which("ffprobe")
    if not probe:
        raise ValueError("FFprobe ausente; não foi instalado automaticamente.")
    if path.suffix.lower() not in (".png", ".jpg", ".jpeg", ".webp"):
        raise ValueError("Referência precisa ser PNG, JPEG ou WebP.")
    command = [probe, "-v", "error", "-count_frames", "-show_streams", "-of", "json", str(path)]
    result = subprocess.run(command, capture_output=True, timeout=30, shell=False)
    if result.returncode:
        raise ValueError("Referência não é uma imagem decodificável.")
    streams = json.loads(result.stdout).get("streams", [])
    videos = [s for s in streams if s.get("codec_type") == "video"]
    if len(videos) != 1:
        raise ValueError("Referência precisa conter uma única imagem.")
    video = videos[0]
    if (video.get("codec_name") not in ("png", "mjpeg", "webp")
            or video.get("nb_read_frames") != "1"
            or video.get("width", 0) <= 0 or video.get("height", 0) <= 0):
        raise ValueError("Referência precisa ser uma imagem estática PNG/JPEG/WebP válida.")
    if decode:
        ffmpeg = shutil.which("ffmpeg")
        if not ffmpeg:
            raise ValueError("FFmpeg ausente; não foi instalado automaticamente.")
        decoded = subprocess.run([ffmpeg, "-nostdin", "-v", "error", "-xerror", "-i", str(path),
                                  "-frames:v", "1", "-f", "null", "-"], capture_output=True,
                                 timeout=30, shell=False)
        if decoded.returncode:
            raise ValueError("Falha ao decodificar a imagem de referência.")
    return {"codec": video["codec_name"], "width": video["width"], "height": video["height"]}
