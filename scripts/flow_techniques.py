"""Explicit local recipes. No network, provider calls, approval or source retiming."""
from __future__ import annotations

import copy
from fractions import Fraction
import math
from pathlib import Path
import re

from flow_files import ROOT, project_file, read_json, sha256

NATIVE = "resources/techniques/catalog.json"
GL = "resources/gl-transitions/catalog.json"


def frame_window(start: int, duration: int, fps: int) -> tuple[int, int]:
    """Millisecond half-open bounds contain exactly the requested export samples."""
    # A frame is evaluated at n/fps. Floor starts (ceil would hide its sample).
    return math.floor(Fraction(start * 1000, fps)), math.floor(Fraction((start + duration) * 1000, fps))


def catalog(root: Path = ROOT) -> dict:
    entries = {}
    for path in (NATIVE, GL):
        if not (root / path).exists():
            continue
        data = read_json(root / path)
        if data.get("schema_version") != 1:
            raise ValueError("Catálogo de técnicas inválido.")
        for effect in data["effects"]:
            if effect["id"] in entries:
                raise ValueError("Técnica duplicada no catálogo.")
            entries[effect["id"]] = dict(effect, catalog_path=path)
    return entries


def parameter(value, definition):
    kind = definition["type"]
    if kind.startswith("vec"):
        if not isinstance(value, list) or len(value) != int(kind[-1]):
            raise ValueError(f"Parâmetro {definition['name']} exige {kind}.")
        for component in value:
            parameter(component, dict(definition, type="float"))
        return
    if kind == "bool":
        if type(value) is not bool:
            raise ValueError("Parâmetro booleano inválido.")
        return
    if type(value) not in (int, float) or not math.isfinite(value) or (kind == "int" and type(value) is not int):
        raise ValueError("Parâmetro numérico inválido.")
    if value < definition.get("min", -math.inf) or value > definition.get("max", math.inf):
        raise ValueError("Parâmetro fora dos limites do catálogo.")


def source_item(plan, reference):
    if not isinstance(reference, str) or not re.fullmatch(r"(clip|image|text|rectangle|audio):[0-9]+", reference):
        raise ValueError("Referência exige clip:N, image:N, text:N, rectangle:N ou audio:N.")
    kind, index = reference.split(":")
    collection = {"clip": "clips", "image": "images", "text": "texts", "rectangle": "rectangles", "audio":"audio"}[kind]
    if int(index) >= len(plan.get(collection, [])):
        raise ValueError("Fonte da técnica ausente.")
    item = plan[collection][int(index)]
    length = item["out_ms"] - item["in_ms"] if kind in ("clip","audio") else item["duration_ms"]
    return kind, item, item["at_ms"], length


def params(entry, item):
    return {p["name"]: item.get("params", {}).get(p["name"], p["default"]) for p in entry["parameters"]}


def validate(plan: dict, *, root: Path = ROOT) -> list[dict]:
    items = plan.get("techniques", [])
    if not isinstance(items, list):
        raise ValueError("techniques precisa ser lista.")
    if not items:
        return []
    fps = plan.get("delivery", {}).get("fps")
    if plan.get("kind") == "design" or fps not in (24, 30, 60) or type(fps) is not int:
        raise ValueError("Técnicas em frames exigem vídeo a 24, 30 ou 60 fps.")
    if plan.get("native_actions"):
        raise ValueError("Separe native_actions e techniques em revisões para evitar trilhas concorrentes.")
    entries = catalog(root)
    frozen = {NATIVE, "scripts/flow_techniques.py"}
    tracks = []
    for item in items:
        if not isinstance(item, dict) or set(item) - {"id", "sources", "start_frame", "duration_frames", "params"}:
            raise ValueError("Campos de técnica inválidos.")
        entry = entries.get(item.get("id"))
        if not entry or entry.get("status") != "enabled":
            raise ValueError("Técnica desconhecida ou ainda não habilitada com evidência.")
        for key in ("start_frame", "duration_frames"):
            value = item.get(key)
            if type(value) is not int or value < (1 if key == "duration_frames" else 0):
                raise ValueError("Intervalo da técnica exige frames inteiros válidos.")
        if (item["id"].startswith("gl.") or item["id"] in ("native.fade","native.transform","native.text-reveal","native.shape-reveal","native.audio-gain")) and item["duration_frames"] < 2:
            raise ValueError("Animação exige pelo menos dois frames distintos.")
        start, end = frame_window(item["start_frame"], item["duration_frames"], fps)
        if (item["start_frame"] + item["duration_frames"]) * 1000 > plan["delivery"]["duration_ms"] * fps:
            raise ValueError("Intervalo da técnica fora da composição.")
        references = item.get("sources")
        count_min = entry.get("sources_min", 2)
        count_max = entry.get("sources_max", 2)
        if (not isinstance(references, list) or not all(isinstance(r,str) for r in references)
                or not count_min <= len(references) <= count_max or len(set(references)) != len(references)):
            raise ValueError("Quantidade de fontes da técnica inválida.")
        supplied = item.get("params", {})
        if not isinstance(supplied, dict) or set(supplied) - {p["name"] for p in entry["parameters"]}:
            raise ValueError("Parâmetros desconhecidos.")
        for definition in entry["parameters"]:
            value = supplied.get(definition["name"], definition["default"])
            parameter(value, definition)
            if definition.get("source_type","").startswith("ivec") and any(type(v) is not int for v in value):
                raise ValueError("Vetor inteiro exige componentes inteiras.")
        if item["id"] == "native.collage":
            p = params(entry,item)
            width,height = (plan["delivery"][k] for k in ("width","height"))
            rows = math.ceil(len(references)/2)
            if min(width-2*p["margin"]-p["gap"],height-2*p["margin"]-(rows-1)*p["gap"]) <= 0:
                raise ValueError("Margens e espaçamento da colagem não cabem no canvas.")
        for reference in references:
            kind, source, at, length = source_item(plan, reference)
            if (kind == "audio") != (item["id"] == "native.audio-gain"):
                raise ValueError("Envelope exige audio:N; técnicas visuais exigem fonte visual.")
            if item["id"] == "native.text-reveal" and kind != "text" or item["id"] == "native.shape-reveal" and kind != "rectangle":
                raise ValueError("Tipo de fonte incompatível com a técnica.")
            if item["id"].startswith("gl.") and kind not in ("clip", "image"):
                raise ValueError("Transição GL exige clipes ou imagens.")
            if start < at or end > at + length:
                raise ValueError("Efeito fora do intervalo selecionado; fontes não serão estendidas.")
            if source.get("fade_ms"):
                raise ValueError("Não combine fade_ms e técnica na mesma fonte.")
            # One property owner per source window; reject ambiguity instead of last-writer wins.
            if any(ref == reference and start <= other_end and other_start <= end for ref, other_start, other_end in tracks):
                raise ValueError("Técnicas sobrepostas ou contíguas na mesma fonte exigem uma janela de separação.")
            tracks.append((reference, start, end))
        frozen.add(entry["catalog_path"])
        implementation = entry.get("implementation")
        if isinstance(implementation, dict):
            path = implementation["path"]
            if sha256(project_file(root, path)) != implementation["sha256"]:
                raise ValueError("Shader alterado em relação ao catálogo.")
            frozen.add(path)
        elif implementation and implementation.endswith(".wgsl"):
            frozen.add(implementation)
    return [{"path": path, "sha256": sha256(project_file(root, path))} for path in sorted(frozen)]


def keyframes(composition, lid, prop, times_values, label):
    scalar = prop in ("opacity", "rotation","positionX","positionY","scaleX","scaleY","volume")
    return {"type": "setFxPropertyKeyframes", "compositionId": composition,
        "property": {"layerId": lid, "propertyType": prop}, "keyframes": [
            {"id": f"{label}-{prop}-{n}", "layerTime": time,
             "value": {"type": "float" if scalar else "vector2", "value": value},
             "easing": {"type": "linear"}} for n, (time, value) in enumerate(times_values)]}


def compile_document(plan, data, layer_ids, *, root: Path = ROOT):
    """Add windowed, silent helper copies; keep selected source clocks and gains intact."""
    validate(plan, root=root)
    entries = catalog(root)
    composition = data["composition"]
    layers = composition["layers"]
    by_id = {layer["id"]: layer for layer in layers}
    next_id = max(by_id, default=0) + 1
    actions = []
    width, height = (plan["delivery"][k] for k in ("width", "height"))
    fps = plan["delivery"]["fps"]
    for index, item in enumerate(plan.get("techniques", [])):
        name = item["id"]
        p = params(entries[name], item)
        start, end = frame_window(item["start_frame"], item["duration_frames"], fps)
        label = f"technique-{index}"
        if name == "native.audio-gain":
            reference=item["sources"][0]
            target=by_id[layer_ids[reference]]
            _,source,at,length=source_item(plan,reference)
            last=math.floor(Fraction((item["start_frame"]+item["duration_frames"]-1)*1000,fps))
            values=[(start-at,p["from_gain"]),(last-at,p["to_gain"])]
            if start>at:
                values.insert(0,(start-at-1,target.get("volume",1)))
            if end<at+length:
                values.append((end-at,target.get("volume",1)))
            actions.append(keyframes(composition["id"],target["id"],"volume",values,label))
            continue
        if name == "native.flash":
            layers.insert(0, {"type": "Rect", "id": next_id, "name": label,
                "activeRange": {"start": start, "duration": end-start}, "blendMode": "normal",
                "transform": {"anchorPoint": [0, 0], "position": [0, 0], "scale": [100, 100], "rotation": 0, "opacity": 100},
                "rect": {"size": [width, height], "fillColor": p["color"]}})
            next_id += 1
            continue
        copies = []
        for reference in item["sources"]:
            original = by_id[layer_ids[reference]]
            clone = copy.deepcopy(original)
            clone.update(id=next_id, name=label + "-" + reference)
            next_id += 1
            kind, source, at, length = source_item(plan, reference)
            if kind == "clip":
                source_start = source["in_ms"] + start - at
                clone["playback"] = {"type": "windowed", "inputRange": {"start": start, "duration": end-start},
                    "mapping": {"type": "linear", "input": {"start": start, "duration": end-start},
                    "output": {"start": source_start, "duration": end-start}}, "inputOffsetMs": 0}
                clone["sourceRange"] = {"start": source_start, "duration": end-start}
                clone["volume"] = 0
            else:
                clone["activeRange"] = {"start": start, "duration": end-start}
            copies.append(clone)
        if name.startswith("gl."):
            entry = entries[name]
            parameters = [{"name": "progress", "default": 0, "min": 0, "max": 1},
                          {"name": "ratio", "default": width/height, "min": 0.001, "max": 100}]
            for definition in entry["parameters"]:
                value = p[definition["name"]]
                values = value if isinstance(value, list) else [value]
                for channel, scalar in enumerate(values):
                    parameters.append({"name": definition["name"] + (f"_{channel}" if len(values)>1 else ""),
                        "default": float(scalar), "min": definition.get("min", -10000), "max": definition.get("max", 10000)})
            effect_id = 100000 + index
            copies[0]["effects"] = [{"id": effect_id, "effect": {"type": "customShader", "name": name,
                "wgsl": project_file(root, entry["implementation"]["path"]).read_text(encoding="utf-8"),
                "params": parameters, "textureInputs": [{"name": "to" if n == 0 else entry.get("texture_inputs", [{"name":"map"}])[-1]["name"],
                    "sourceLayerId": clone["id"]} for n, clone in enumerate(copies[1:])]}}]
            # Helper FX clock starts at the helper's own input window. Source
            # trim affects decoded content, never the animator clock.
            actions.append({"type": "setFxLayerEffectParamAnimator", "compositionId": composition["id"],
                "layerId": copies[0]["id"], "effectId": effect_id, "paramName": "progress", "dependencies": [],
                "animator": {"type":"jsScript","layerTimeJsCode":
                    f"return Math.max(0,Math.min(1,Math.round(input.time.seconds*{fps})/{max(1,item['duration_frames']-1)}));"}})
        elif name in ("native.fade", "native.transform", "native.text-reveal", "native.shape-reveal"):
            # Animate original for fades/reveals; helper copies would expose the unchanged original underneath.
            target = by_id[layer_ids[item["sources"][0]]]
            kind, source, at, length = source_item(plan, item["sources"][0])
            clock_start = start-at
            clock_end = math.floor(Fraction((item["start_frame"]+item["duration_frames"]-1)*1000,fps))-at
            pairs = {"opacity": (p["from_opacity"], p["to_opacity"])} if name == "native.fade" else {}
            if name == "native.transform":
                pairs = {prop: (p["from_"+prop], p["to_"+prop]) for prop in ("position", "scale", "rotation")}
                base = target["transform"]
                pairs["position"] = tuple([a+b for a,b in zip(base["position"],value)] for value in pairs["position"])
                pairs["scale"] = tuple([a*b/100 for a,b in zip(base["scale"],value)] for value in pairs["scale"])
                pairs["rotation"] = tuple(base["rotation"]+v for v in pairs["rotation"])
            if name in ("native.text-reveal", "native.shape-reveal"):
                position = target["transform"]["position"]
                pairs = {"opacity": (0, target["transform"].get("opacity", 100)),
                         "position": ([a+b for a,b in zip(position,p["offset"])], position)}
            for prop, pair in pairs.items():
                times_values = [(clock_start, pair[0]), (clock_end, pair[1])]
                original_value = target["transform"][prop]
                source_clock_origin = 0
                if clock_start > source_clock_origin:
                    times_values.insert(0, (clock_start-1, original_value))
                if end < at+length:
                    times_values.append((clock_start+end-start, original_value))
                if prop in ("position","scale"):
                    for channel,suffix in enumerate(("X","Y")):
                        actions.append(keyframes(composition["id"],target["id"],prop+suffix,
                            [(t,v[channel]) for t,v in times_values],label))
                else:
                    actions.append(keyframes(composition["id"], target["id"], prop,times_values, label))
            copies = []
        elif name in ("native.reframe", "native.overlay"):
            base = copies[0]["transform"]
            base.update(position=[a+b for a,b in zip(base["position"],p["position"])],
                scale=[a*b/100 for a,b in zip(base["scale"],p["scale"])], opacity=p.get("opacity",base.get("opacity",100)))
        elif name == "native.collage":
            cols = 2
            rows = math.ceil(len(copies)/2)
            cell_w = (width-2*p["margin"]-p["gap"])/cols
            cell_h = (height-2*p["margin"]-(rows-1)*p["gap"])/rows
            if min(cell_w,cell_h)<=0:
                raise ValueError("Margem ou espaçamento não cabe no canvas.")
            scale = min(cell_w/width,cell_h/height)*100
            for n,clone in enumerate(copies):
                base=clone["transform"]
                offset=[p["margin"]+(n%2)*(cell_w+p["gap"]),p["margin"]+(n//2)*(cell_h+p["gap"])]
                base.update(scale=[v*scale/100 for v in base["scale"]],position=[a*scale/100+b for a,b in zip(base["position"],offset)])
        elif name == "native.color":
            copies[0]["effects"] = [{"id":100000+index,"effect":{"type":"customShader","name":"FLOW independent color",
                "wgsl": (root/"resources/techniques/color.wgsl").read_text(encoding="utf-8"),
                "params":[{"name":d["name"],"default":p[d["name"]],"min":d["min"],"max":d["max"]} for d in entries[name]["parameters"]]}}]
        if copies and name != "native.overlay":
            # Replace the original visual only within this window. Leaving it
            # underneath would double premultiplied alpha for translucent media.
            # Opacity affects visual output; the original audio gain stays intact.
            for reference in item["sources"]:
                target=by_id[layer_ids[reference]]
                _,_,at,length=source_item(plan,reference)
                times_values=[(start-at,0),(end-at-1,0)]
                opacity=target["transform"].get("opacity",100)
                if start>at:
                    times_values.insert(0,(start-at-1,opacity))
                if end<at+length:
                    times_values.append((end-at,opacity))
                actions.append(keyframes(composition["id"],target["id"],"opacity",times_values,label+"-replace-"+reference.replace(":","-")))
        if copies:
            if name == "native.overlay":
                insert_at=0
            else:
                # A replacement belongs where its source was painted. Titles,
                # captions and unrelated foreground graphics keep their order.
                visible_refs=item["sources"][:2] if name.startswith("gl.") else item["sources"]
                source_ids={layer_ids[ref] for ref in visible_refs}
                insert_at=min(n for n,layer in enumerate(layers) if layer["id"] in source_ids)
            layers[insert_at:insert_at]=copies
    return actions
