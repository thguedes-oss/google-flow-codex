"""Local, versioned post-production; never sends prompts or generates Flow media."""
from __future__ import annotations

import argparse
from fractions import Fraction
import json
import math
from pathlib import Path
import shutil
import subprocess
import sys
from uuid import uuid4

from asset_library import verify_record
from flow_files import (ROOT, approval_valid, identifier, project_file, project_root,
                        read_json, sha256, utc_now, write_json)
from flow_review import decision_files, verify_decision
from tesseract_tools import configuration, doctor, invoke, resolve_tool
import flow_techniques


def integer(value, name: str, *, positive: bool = False) -> int:
    if type(value) is not int or value < (1 if positive else 0):
        raise ValueError(f"{name} precisa ser inteiro {'positivo' if positive else 'não negativo'}.")
    return value


def number(value, name: str, minimum: float = 0) -> float:
    if type(value) not in (int, float) or not math.isfinite(value) or value < minimum:
        raise ValueError(f"{name} inválido.")
    return value


def vector(value, size: int, name: str, *, color: bool = False) -> list:
    if not isinstance(value, list) or len(value) != size:
        raise ValueError(f"{name} exige {size} componentes.")
    for item in value:
        number(item, name, 0 if color else -float('inf'))
        if color and item > 1:
            raise ValueError("Canais de cor precisam estar entre 0 e 1.")
    return value


def probe(path: Path) -> dict:
    executable = shutil.which("ffprobe")
    if not executable:
        raise ValueError("FFprobe ausente; nenhuma instalação automática foi feita.")
    return json.loads(invoke(Path(executable), ["-v", "error", "-show_streams", "-show_format", "-of", "json", str(path)]))


def duration_ms(metadata: dict) -> int:
    values = [float(s["duration"]) for s in metadata["streams"] if s.get("duration") not in (None, "N/A")]
    if metadata.get("format", {}).get("duration") not in (None, "N/A"):
        values.append(float(metadata["format"]["duration"]))
    if not values or not math.isfinite(max(values)):
        raise ValueError("Duração da mídia não pôde ser determinada.")
    return round(max(values) * 1000)


def timeline(item: dict, total: int, *, source_duration: int | None = None) -> int:
    at = integer(item.get("at_ms"), "at_ms")
    if source_duration is not None:
        start = integer(item.get("in_ms"), "in_ms")
        end = integer(item.get("out_ms"), "out_ms", positive=True)
        if end <= start or end > source_duration:
            raise ValueError("Intervalo de origem inválido ou fora da mídia.")
        length = end - start
    else:
        length = integer(item.get("duration_ms"), "duration_ms", positive=True)
    if at + length > total:
        raise ValueError("Intervalo fora da duração da composição.")
    number(item.get("volume", 1), "volume")
    fade = integer(item.get("fade_ms", 0), "fade_ms")
    if fade and 2 * fade >= length:
        raise ValueError("Fade precisa ocupar menos da metade do intervalo.")
    return length


def validate_plan(project: Path, plan: dict, *, workspace: Path = ROOT) -> dict:
    project = project_root(project, workspace)
    if plan.get("schema_version") != 1 or plan.get("kind") not in ("edit", "animatic", "design"):
        raise ValueError("Plano exige schema_version=1 e kind edit/animatic/design.")
    if not isinstance(plan.get("title"), str) or not plan["title"].strip():
        raise ValueError("Título do trabalho pendente.")
    delivery = plan.get("delivery", {})
    width, height = (integer(delivery.get(key), key, positive=True) for key in ("width", "height"))
    if max(width, height) > 7680 or width * height > 33177600:
        raise ValueError("Canvas excede os limites documentados.")
    total = integer(delivery.get("duration_ms"), "duration_ms", positive=True)
    if plan["kind"] != "design":
        if delivery.get("fps") not in (24, 30, 60) or type(delivery.get("fps")) is not int:
            raise ValueError("FPS precisa ser 24, 30 ou 60.")
        size = {"720p": 720, "1080p": 1080, "4k": 2160}.get(delivery.get("resolution"))
        if size is None or min(width, height) != size or (width / height) not in (16/9, 9/16, 1):
            raise ValueError("Vídeo exige canvas 16:9, 9:16 ou 1:1 compatível com resolution.")
        if delivery.get("audio_expected") not in (True, False) or type(delivery.get("audio_expected")) is not bool:
            raise ValueError("Declare audio_expected verdadeiro ou falso.")
    for key in ("clips", "resources", "images", "texts", "rectangles", "audio", "native_actions", "techniques"):
        if not isinstance(plan.get(key, []), list):
            raise ValueError(f"{key} precisa ser uma lista.")
    if not any(plan.get(key) for key in ("clips", "images", "texts", "rectangles")):
        raise ValueError("Materiais visuais pendentes.")
    if plan["kind"] in ("animatic", "design") and plan.get("clips"):
        raise ValueError("Use kind edit para montar clipes.")
    if plan["kind"] == "design" and plan.get("audio"):
        raise ValueError("Peça estática não usa áudio.")
    sources, resources = [], {}
    for item in plan.get("resources", []):
        key = identifier(item.get("id"))
        if key in resources or item.get("kind") not in ("image", "audio", "font"):
            raise ValueError("Recurso duplicado ou tipo inválido.")
        path = project_file(project, item.get("path"))
        if not path.is_file() or sha256(path) != item.get("sha256") or not item.get("origin"):
            raise ValueError("Recurso ausente, alterado ou sem origem.")
        if item["kind"] == "font":
            if path.suffix.lower() not in (".ttf", ".otf", ".ttc") or not item.get("license"):
                raise ValueError("Fonte exige TTF/OTF/TTC e identificação de licença.")
        elif not approval_valid(item.get("approval")):
            raise ValueError("Imagem/áudio de pós-produção exige aprovação real registrada.")
        metadata = probe(path) if item["kind"] != "font" else None
        if metadata:
            streams = metadata["streams"]
            if item["kind"] == "audio" and not any(s.get("codec_type") == "audio" for s in streams):
                raise ValueError("Recurso de áudio não possui stream de áudio.")
            if item["kind"] == "image":
                from flow_files import inspect_image
                inspect_image(path)
        sources.append({"id": key, "kind": item["kind"], "path": item["path"], "sha256": item["sha256"]})
        resources[key] = dict(item, metadata=metadata)
    for index, clip in enumerate(plan.get("clips", [])):
        if clip.get("fade_ms", 0):
            raise ValueError("Fade de clipe requer ações nativas com o relógio de origem conferido; anime gráficos pelo plano.")
        aid = identifier(clip.get("attempt_id"))
        files = decision_files(project, aid)
        if not files:
            raise ValueError(f"Tentativa {aid} sem revisão formal.")
        decision = verify_decision(project, files[-1])
        if decision["decision"] != "approved":
            raise ValueError(f"Tentativa {aid} não aprovada.")
        report = read_json(project_file(project, decision["evidence_report"]))
        metadata = probe(project_file(project, report["source_file"]))
        timeline(clip, total, source_duration=duration_ms(metadata))
        sources.append({"id": f"clip-{index}", "kind": "video", "path": report["source_file"],
                        "sha256": decision["source_sha256"], "attempt_id": aid,
                        "decision": files[-1].relative_to(project).as_posix(), "decision_sha256": sha256(files[-1])})
    for image in plan.get("images", []):
        timeline(image, total)
        if "handle" in image:
            manifest = read_json(project / "project.json")
            matches = [a for a in manifest["assets"] if a["handle"] == image["handle"]]
            if len(matches) != 1 or matches[0].get("approved") is not True:
                raise ValueError("Handle de imagem sem aprovação vigente.")
            asset = matches[0]
            path = project_file(project, asset.get("path"))
            if sha256(path) != asset.get("sha256"):
                raise ValueError("Imagem do handle alterada.")
            if asset.get("library"):
                record_path = project_file(project, asset["library"]["record"])
                if sha256(record_path) != asset["library"]["record_sha256"]:
                    raise ValueError("Registro da imagem alterado.")
                record = verify_record(record_path.parent)
                if record.get("approved") is not True or record["sha256"] != asset["sha256"]:
                    raise ValueError("Imagem da biblioteca não aprovada.")
            sources.append({"id": f"handle-{len(sources)}", "kind": "image", "path": asset["path"],
                            "sha256": asset["sha256"], "handle": image["handle"]})
            probe(path)
        elif resources.get(image.get("resource"), {}).get("kind") != "image":
            raise ValueError("Imagem exige handle aprovado ou resource de imagem.")
        if image.get("fit", "contain") not in ("contain", "cover"):
            raise ValueError("fit precisa ser contain ou cover.")
    for text in plan.get("texts", []):
        timeline(text, total)
        if not isinstance(text.get("text"), str) or not text["text"].strip() or resources.get(text.get("font"), {}).get("kind") != "font":
            raise ValueError("Texto e fonte real são obrigatórios.")
        if text.get("align", "left") not in ("left", "center", "right"):
            raise ValueError("align precisa ser left, center ou right.")
        if text.get("role", "title") not in ("title", "caption", "label"):
            raise ValueError("Papel do texto inválido.")
        if text.get("role") == "caption" and not text.get("transcript_evidence"):
            raise ValueError("Legenda exige origem dos termos e tempos conferidos.")
        vector(text.get("position"), 2, "position")
        vector(text.get("box"), 2, "box")
        if min(text["box"]) <= 0:
            raise ValueError("Caixa de texto precisa ser positiva.")
        number(text.get("font_size"), "font_size", 1)
        vector(text.get("color", [1, 1, 1, 1]), 4, "color", color=True)
    for rect in plan.get("rectangles", []):
        timeline(rect, total)
        vector(rect.get("position"), 2, "position")
        vector(rect.get("size"), 2, "size")
        if min(rect["size"]) <= 0:
            raise ValueError("Retângulo precisa ter dimensões positivas.")
        vector(rect.get("color"), 4, "color", color=True)
    for audio in plan.get("audio", []):
        if audio.get("fade_ms", 0):
            raise ValueError("Envelopes de áudio exigem ações nativas conferidas; fade_ms é reservado aos gráficos.")
        resource = resources.get(audio.get("resource"), {})
        if resource.get("kind") != "audio":
            raise ValueError("Camada de áudio exige resource de áudio.")
        timeline(audio, total, source_duration=duration_ms(resource["metadata"]))
    if plan.get("native_actions") and not all(isinstance(a, dict) for a in plan["native_actions"]):
        raise ValueError("native_actions exige objetos da API nativa.")
    technique_files = flow_techniques.validate(plan)
    return {"schema_version": 1, "valid": True, "kind": plan["kind"], "sources": sources,
            "technique_files": technique_files,
            "generation_calls": 0, "visual_approval": False}


def transform(position=None, scale=None) -> dict:
    return {"anchorPoint": [0, 0], "position": position or [0, 0], "scale": scale or [100, 100],
            "rotation": 0, "opacity": 100}


def playback(at: int, length: int, source_start: int = 0) -> dict:
    return {"type": "windowed", "inputRange": {"start": at, "duration": length},
            "mapping": {"type": "linear", "input": {"start": at, "duration": length},
                        "output": {"start": source_start, "duration": length}}, "inputOffsetMs": 0}


class Engine:
    def __init__(self, directory: Path, *, tools_workspace: Path = ROOT):
        self.executable = resolve_tool("tesseract", tools_workspace)
        if json.loads(invoke(self.executable, ["telemetry", "status"])).get("enabled") is not False:
            raise ValueError("Telemetria habilitada; desative explicitamente antes de produzir.")
        self.directory, self.counter = directory, 0

    def call(self, *arguments, timeout=180) -> str:
        self.counter += 1
        return invoke(self.executable, list(map(str, arguments)),
                      log=self.directory / "logs" / f"{self.counter:03d}-{arguments[0]}", timeout=timeout)


def revision_directory(project: Path, revision: str) -> Path:
    return project_file(project, f"outputs/postproduction/{identifier(revision)}")


def prepare(project: Path, plan: dict, revision: str, *, workspace: Path = ROOT,
            tools_workspace: Path = ROOT) -> Path:
    checked = validate_plan(project, plan, workspace=workspace)
    directory = revision_directory(project, revision)
    directory.mkdir(parents=True, exist_ok=False)
    try:
        engine = Engine(directory, tools_workspace=tools_workspace)
        doc = directory / "Project.tsrct"
        write_json(directory / "plan.json", plan)
        for args, name in [(("project", "schema", "--document"), "document.schema.json"),
                           (("project", "schema"), "actions.schema.json")]:
            (directory / name).write_text(engine.call(*args), encoding="utf-8")
        engine.call("project", "create", "--project", doc)
        resources = {r["id"]: r for r in plan.get("resources", [])}
        imports, fonts = {}, {}
        for source in checked["sources"]:
            path = project_file(project, source["path"])
            if source["kind"] == "font":
                imported = json.loads(engine.call("project", "import-font", "--project", doc, "--file", path))
                fonts[source["id"]] = imported
            elif source["sha256"] not in imports:
                asset_id = "asset-" + str(len(imports))
                args = ["project", "import-video" if source["kind"] == "video" else "import-asset",
                        "--project", doc, "--file", path, "--asset-id", asset_id]
                if source["kind"] != "video":
                    args += ["--kind", source["kind"]]
                engine.call(*args)
                imports[source["sha256"]] = asset_id
        editable = directory / "editable.json"
        engine.call("project", "checkout", "--project", doc, "--output", editable)
        data = read_json(editable)
        delivery = plan["delivery"]
        data["dimensions"] = {k: delivery[k] for k in ("width", "height")}
        data["duration"] = delivery["duration_ms"] / 1000
        composition = data["composition"]
        composition["name"] = plan["title"]
        layers, actions, next_id = [], [], 1
        layer_ids = {}

        def fade(item, lid):
            ms = item.get("fade_ms", 0)
            if not ms:
                return
            length = (item["out_ms"] - item["in_ms"]) if "out_ms" in item else item["duration_ms"]
            actions.append({"type": "setFxPropertyKeyframes", "compositionId": composition["id"],
                "property": {"layerId": lid, "propertyType": "opacity"}, "keyframes": [
                    {"id": f"fade-{lid}-{n}", "layerTime": time, "value": {"type": "float", "value": value},
                     "easing": {"type": "linear"}} for n, (time, value) in enumerate(
                        [(0, 0), (ms, 100), (length - ms - 1, 100), (length - 1, 0)])]})

        for index, clip in enumerate(plan.get("clips", [])):
            layer_ids[f"clip:{index}"] = next_id
            source = next(s for s in checked["sources"] if s["id"] == f"clip-{index}")
            length = clip["out_ms"] - clip["in_ms"]
            layers.append({"type": "Video", "id": next_id, "name": clip["attempt_id"], "blendMode": "normal",
                "playback": playback(clip["at_ms"], length, clip["in_ms"]), "sourceRange": {"start": clip["in_ms"], "duration": length},
                "sourceIntrinsicDuration": duration_ms(probe(project_file(project, source["path"]))),
                "volume": clip.get("volume", 1), "transform": clip.get("transform", transform()),
                "source": {"assetId": imports[source["sha256"]], "fit": clip.get("fit", "contain")}})
            next_id += 1
        for index, image in enumerate(plan.get("images", [])):
            layer_ids[f"image:{index}"] = next_id
            source = next(s for s in checked["sources"] if s.get("handle") == image["handle"]) if "handle" in image else resources[image["resource"]]
            meta = probe(project_file(project, source["path"]))
            stream = next(s for s in meta["streams"] if s["codec_type"] == "video")
            ratio = (max if image.get("fit") == "cover" else min)(delivery["width"] / stream["width"], delivery["height"] / stream["height"])
            default = transform([(delivery["width"] - ratio * stream["width"]) / 2,
                                 (delivery["height"] - ratio * stream["height"]) / 2], [100 * ratio, 100 * ratio])
            layers.insert(0, {"type": "Image", "id": next_id, "name": image.get("handle", image.get("resource")),
                "blendMode": "normal", "activeRange": {"start": image["at_ms"], "duration": image["duration_ms"]},
                "transform": image.get("transform", default), "source": {"assetId": imports[source["sha256"]], "fit": "contain"}})
            fade(image, next_id)
            next_id += 1
        for index, audio in enumerate(plan.get("audio", [])):
            layer_ids[f"audio:{index}"] = next_id
            source = resources[audio["resource"]]
            length = audio["out_ms"] - audio["in_ms"]
            layers.append({"type": "Audio", "id": next_id, "name": audio["resource"],
                "playback": playback(audio["at_ms"], length, audio["in_ms"]), "sourceRange": {"start": audio["in_ms"], "duration": length},
                "sourceIntrinsicDuration": duration_ms(probe(project_file(project, source["path"]))),
                "source": {"assetId": imports[source["sha256"]]}, "volume": audio.get("volume", 1), "captionsEnabled": False})
            next_id += 1
        composition["layers"] = layers
        write_json(editable, data, replace=True)
        engine.call("project", "commit", "--project", doc, "--file", editable)
        for index, item in enumerate(plan.get("rectangles", [])):
            layer_ids[f"rectangle:{index}"] = next_id
            actions.insert(0, {"type": "createFxRectLayer", "compositionId": composition["id"], "layerId": next_id,
                "name": item.get("name", "Graphic"), "insertIndex": 0,
                "activeRange": {"start": item["at_ms"], "duration": item["duration_ms"]},
                "transform": transform(item["position"]), "rect": {"size": item["size"], "fillColor": item["color"]}})
            fade(item, next_id)
            next_id += 1
        for index, item in enumerate(plan.get("texts", [])):
            layer_ids[f"text:{index}"] = next_id
            font = fonts[item["font"]]
            # A collection requires an explicitly selected face; ordinary files return one face.
            if "fontFamily" not in font:
                faces = font.get("faces", [])
                matches = [f for f in faces if f.get("fontFamily") == item.get("font_family") and f.get("fontStyle") == item.get("font_style")]
                if len(matches) != 1:
                    raise ValueError("Selecione font_family e font_style reais da coleção importada.")
                font = matches[0]
            actions.append({"type": "createFxTextLayer", "compositionId": composition["id"], "layerId": next_id,
                "name": item.get("role", "title"), "insertIndex": 0,
                "activeRange": {"start": item["at_ms"], "duration": item["duration_ms"]}, "transform": transform(item["position"]),
                "sourceText": {"text": item["text"], "fontFamily": font["fontFamily"], "fontStyle": font["fontStyle"],
                    "fontSize": item["font_size"], "fillColor": item.get("color", [1, 1, 1, 1]),
                    "justification": item.get("align", "left"), "boxText": True, "boxPosition": [0, 0], "boxSize": item["box"]}})
            fade(item, next_id)
            next_id += 1
        actions.extend(plan.get("native_actions", []))
        if actions:
            actions_path = directory / "actions.json"
            actions_path.write_text(json.dumps(actions, ensure_ascii=False, allow_nan=False), encoding="utf-8")
            engine.call("project", "apply", "--project", doc, "--actions", actions_path)
        if plan.get("techniques"):
            engine.call("project", "checkout", "--project", doc, "--output", directory / "techniques-editable.json")
            data = read_json(directory / "techniques-editable.json")
            technique_actions = flow_techniques.compile_document(plan, data, layer_ids)
            write_json(directory / "techniques-editable.json", data, replace=True)
            engine.call("project", "commit", "--project", doc, "--file", directory / "techniques-editable.json")
            if technique_actions:
                write_json(directory / "technique-actions.json", technique_actions)
                engine.call("project", "apply", "--project", doc, "--actions", directory / "technique-actions.json")
        # Recheck real approvals and source bytes after import, before publishing the revision seal.
        if validate_plan(project, plan, workspace=workspace) != checked:
            raise ValueError("Materiais ou decisões mudaram durante a preparação.")
        inspected = engine.call("project", "inspect", "--project", doc, "--pretty")
        (directory / "inspect.json").write_text(inspected, encoding="utf-8")
        record = {"schema_version": 1, "status": "prepared_unreviewed", "created_at": utc_now(),
                  "plan_sha256": sha256(directory / "plan.json"), "document_sha256": sha256(doc),
                  "sources": checked["sources"], "technique_files": checked["technique_files"],
                  "engine": "0.3.1", "visual_approval": False}
        write_json(directory / "revision.json", record)
        write_json(directory / "registered.json", {"revision_sha256": sha256(directory / "revision.json")})
        return directory
    except Exception as exc:
        write_json(directory / "failure.json", {"status": "failed", "error": str(exc), "at": utc_now()})
        raise


def verify_revision(project: Path, revision: str, *, workspace: Path = ROOT) -> tuple[Path, dict, dict]:
    directory = revision_directory(project, revision)
    record = read_json(directory / "revision.json")
    if read_json(directory / "registered.json")["revision_sha256"] != sha256(directory / "revision.json"):
        raise ValueError("Registro da revisão alterado.")
    if (record.get("status") != "prepared_unreviewed" or sha256(directory / "Project.tsrct") != record["document_sha256"]
            or sha256(directory / "plan.json") != record["plan_sha256"]):
        raise ValueError("Fonte editável ou plano alterado; prepare uma nova revisão.")
    plan = read_json(directory / "plan.json")
    checked = validate_plan(project, plan, workspace=workspace)
    if checked["sources"] != record["sources"]:
        raise ValueError("Aprovação ou seleção substituída; prepare uma nova revisão.")
    if checked["technique_files"] != record.get("technique_files", []):
        raise ValueError("Receita, catálogo ou shader alterado; prepare uma nova revisão.")
    return directory, record, plan


def render(project: Path, revision: str, *, preview_only: bool = False, workspace: Path = ROOT,
           tools_workspace: Path = ROOT) -> Path:
    directory, record, plan = verify_revision(project, revision, workspace=workspace)
    run = directory / "renders" / uuid4().hex
    run.mkdir(parents=True, exist_ok=False)
    try:
        delivery = plan["delivery"]
        profile = configuration(tools_workspace).get("export_profiles", {}).get(delivery.get("resolution"))
        if plan["kind"] != "design" and not preview_only and not profile:
            raise ValueError("Resolução sem perfil de exportação verificado nesta versão.")
        engine = Engine(run, tools_workspace=tools_workspace)
        doc = directory / "Project.tsrct"
        engine.call("preview", "--project", doc, "--time", min(1, delivery["duration_ms"] / 2000), "--output", run / "Preview.png")
        metadata = probe(run / "Preview.png")
        still = next(s for s in metadata["streams"] if s["codec_type"] == "video")
        if (still["width"], still["height"]) != (delivery["width"], delivery["height"]):
            raise ValueError("Dimensões da prévia divergem do plano.")
        outputs = [run / "Preview.png"]
        if plan["kind"] != "design":
            engine.call("filmstrip", "--project", doc, "--start-ms", 0, "--duration-ms", delivery["duration_ms"],
                        "--interval-ms", max(1, delivery["duration_ms"] // 8), "--output", run / "Filmstrip.png", timeout=600)
            outputs.append(run / "Filmstrip.png")
            if not preview_only:
                video = run / "Video.mp4"
                engine.call("export", "--project", doc, "--output", video, "--resolution", profile["cli_resolution"],
                            "--fps", delivery["fps"], timeout=1800)
                native_metadata = probe(video)
                native_stream = next(s for s in native_metadata["streams"] if s["codec_type"] == "video")
                if min(native_stream["width"], native_stream["height"]) != profile["native_short_edge"]:
                    raise ValueError("A saída nativa diverge do perfil verificado; não redimensionar automaticamente.")
                metadata = probe(video)
                stream = next(s for s in metadata["streams"] if s["codec_type"] == "video")
                audio = any(s["codec_type"] == "audio" for s in metadata["streams"])
                if (stream["width"], stream["height"]) != (delivery["width"], delivery["height"]) or Fraction(stream["avg_frame_rate"]) != delivery["fps"]:
                    raise ValueError("Resolução ou FPS do vídeo divergem do plano.")
                if abs(duration_ms(metadata) - delivery["duration_ms"]) > 1000 / delivery["fps"] + 50:
                    raise ValueError("Duração exportada diverge do plano.")
                if delivery["audio_expected"] and not audio:
                    raise ValueError("Áudio esperado ausente.")
                ffmpeg = shutil.which("ffmpeg")
                if not ffmpeg:
                    raise ValueError("FFmpeg ausente para verificar decodificação.")
                invoke(Path(ffmpeg), ["-nostdin", "-v", "error", "-xerror", "-i", str(video), "-f", "null", "-"],
                       log=run / "decode", timeout=1800)
                outputs.append(video)
        verify_revision(project, revision, workspace=workspace)
        write_json(run / "render.json", {"schema_version": 1,
            "status": "previewed_unreviewed" if preview_only else "rendered_unreviewed", "created_at": utc_now(),
            "revision_sha256": sha256(directory / "revision.json"), "document_sha256": record["document_sha256"],
            "kind": plan["kind"], "metadata": metadata, "visual_approval": False,
            "audio_listened": False, "playback_completed": False,
            "export_profile": profile,
            "outputs": [{"path": p.name, "sha256": sha256(p)} for p in outputs]})
        write_json(run / "registered.json", {"render_sha256": sha256(run / "render.json")})
        return run
    except Exception as exc:
        write_json(run / "failure.json", {"status": "failed", "error": str(exc), "at": utc_now()})
        raise


def convert(project: Path, revision: str, target: str, *, workspace: Path = ROOT,
            tools_workspace: Path = ROOT) -> Path:
    if target not in ("premiere", "after-effects"):
        raise ValueError("Destino Adobe inválido.")
    directory, _, plan = verify_revision(project, revision, workspace=workspace)
    executable = resolve_tool("converter", tools_workspace)
    run = directory / "conversions" / uuid4().hex
    run.mkdir(parents=True, exist_ok=False)
    try:
        arguments = ["convert", str(directory / "Project.tsrct"), "--to", target, "--output", str(run / "package"), "--json"]
        if plan["kind"] != "design":
            arguments += ["--fps", str(plan["delivery"]["fps"])]
        stdout = invoke(executable, arguments, log=run / "logs", timeout=1800)
        extension = "*.prproj" if target == "premiere" else "*.aep"
        matches = list((run / "package").rglob(extension))
        if not matches:
            raise ValueError("Conversor terminou sem produzir o projeto esperado.")
        verify_revision(project, revision, workspace=workspace)
        write_json(run / "conversion.json", {"schema_version": 1, "status": "converted_adobe_unverified",
            "target": target, "converter_version": "0.2.1", "revision_sha256": sha256(directory / "revision.json"),
            "adobe_verified": False, "result": json.loads(stdout),
            "files": [{"path": p.relative_to(run).as_posix(), "sha256": sha256(p)}
                      for p in sorted((run / "package").rglob("*")) if p.is_file()],
            "warnings_log": "logs/stderr.txt"})
        return run
    except Exception as exc:
        write_json(run / "failure.json", {"status": "failed", "error": str(exc), "at": utc_now()})
        raise


def close_review(project: Path, revision: str, run_id: str, spec: dict, *, workspace: Path = ROOT) -> Path:
    directory, _, plan = verify_revision(project, revision, workspace=workspace)
    run = directory / "renders" / identifier(run_id)
    report = read_json(run / "render.json")
    if read_json(run / "registered.json").get("render_sha256") != sha256(run / "render.json"):
        raise ValueError("Relatório de render alterado ou incompleto.")
    if report["revision_sha256"] != sha256(directory / "revision.json"):
        raise ValueError("Render não corresponde à revisão atual.")
    for item in report["outputs"]:
        if sha256(project_file(run, item["path"])) != item["sha256"]:
            raise ValueError("Exportação alterada após render.")
    if spec.get("schema_version") != 1 or spec.get("decision") not in ("approved", "rejected") or not all(
            isinstance(spec.get(key), str) and spec[key].strip() for key in ("reviewer", "observations")):
        raise ValueError("Revisão exige decisão, reviewer e observações reais.")
    if spec["decision"] == "approved":
        if report["status"] != "rendered_unreviewed":
            raise ValueError("Aprovação final exige render completo.")
        if spec.get("visual_inspection_completed") is not True:
            raise ValueError("Aprovação exige inspeção visual.")
        if plan["kind"] != "design" and spec.get("playback_completed") is not True:
            raise ValueError("Aprovação exige reprodução completa.")
        has_audio = any(s.get("codec_type") == "audio" for s in report["metadata"]["streams"])
        if has_audio and spec.get("audio_review") != "reviewed":
            raise ValueError("Aprovação exige escuta do áudio existente.")
        if not has_audio and (spec.get("audio_review") != "not_applicable" or not isinstance(spec.get("audio_reason"), str) or not spec["audio_reason"].strip()):
            raise ValueError("Ausência de áudio exige justificativa.")
    dest = run / "reviews" / uuid4().hex
    dest.mkdir(parents=True, exist_ok=False)
    write_json(dest / "decision.json", dict(spec, schema_version=1, created_at=utc_now(),
               render_sha256=sha256(run / "render.json"), revision_sha256=sha256(directory / "revision.json")))
    write_json(dest / "registered.json", {"decision_sha256": sha256(dest / "decision.json")})
    return dest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("doctor", "validate", "prepare", "preview", "render", "convert", "review"))
    parser.add_argument("--project", type=Path)
    parser.add_argument("--plan", help="Plano relativo à pasta do vídeo.")
    parser.add_argument("--revision")
    parser.add_argument("--target", choices=("premiere", "after-effects"))
    parser.add_argument("--run")
    parser.add_argument("--input", help="Revisão relativa à pasta do vídeo.")
    args = parser.parse_args()
    try:
        if args.command == "doctor":
            result = doctor()
        else:
            if not args.project:
                parser.error("--project obrigatório")
            project = project_root(ROOT / args.project)
            if args.command in ("validate", "prepare"):
                plan = read_json(project_file(project, args.plan))
                result = validate_plan(project, plan) if args.command == "validate" else str(prepare(project, plan, args.revision))
            elif args.command in ("preview", "render"):
                result = str(render(project, args.revision, preview_only=args.command == "preview"))
            elif args.command == "convert":
                result = str(convert(project, args.revision, args.target))
            else:
                result = str(close_review(project, args.revision, args.run, read_json(project_file(project, args.input))))
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
