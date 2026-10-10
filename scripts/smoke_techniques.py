"""Real portable-engine recipe checks; all media remains in a temporary directory."""
from __future__ import annotations
import argparse
import copy
import json
import math
from pathlib import Path
import shutil
import subprocess
import struct
import tempfile

from flow_files import ROOT, sha256, utc_now, write_json
from flow_techniques import compile_document
from tesseract_pipeline import Engine, playback, transform, probe


def decoded(path, width=96, height=54):
    result = subprocess.run([shutil.which("ffmpeg"), "-v", "error", "-i", str(path),
        "-vf", f"scale={width}:{height}", "-pix_fmt", "rgb24", "-f", "rawvideo", "-"],
        capture_output=True, check=True, timeout=90)
    size = width*height*3
    return [result.stdout[n:n+size] for n in range(0,len(result.stdout),size)]


def difference(a,b):
    if len(a)!=len(b) or not a:
        raise ValueError("Empty/mismatched pixel samples.")
    return sum(abs(x-y) for x,y in zip(a,b))/len(a)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--keep-temporary", action="store_true")
    parser.add_argument("--report", type=Path, default=ROOT/"reports/techniques-smoke.json")
    args = parser.parse_args()
    temporary = tempfile.TemporaryDirectory(prefix="flow-recipes-technical-")
    directory = Path(temporary.name)
    report = {"schema_version":1,"started_at":utc_now(),"generation_calls":0,"flow_credits_spent":0,
        "fixture_kind":"synthetic_temporary_only","playback_completed":False,"audio_listened":False,"cases":[]}
    report["recipe_files"] = [{"path":p,"sha256":sha256(ROOT/p)} for p in
        ("scripts/flow_techniques.py","resources/techniques/catalog.json","resources/techniques/color.wgsl")]
    preserved = [ROOT/"projects/exemplo-duas-cenas"/p for p in ("project.json","attempts.csv","review.csv")]
    before = {str(p):sha256(p) for p in preserved}
    try:
        engine = Engine(directory)
        source = directory/"moving.mp4"
        engine.call("--version")
        subprocess.run([shutil.which("ffmpeg"),"-v","error","-f","lavfi","-i",
            "testsrc2=s=1280x720:r=60:d=2", "-f","lavfi","-i","sine=frequency=440:sample_rate=48000:duration=2",
            "-c:v","libx264","-preset","ultrafast","-crf","10","-pix_fmt","yuv420p","-c:a","aac","-shortest",str(source)],
            check=True,capture_output=True,timeout=60)
        template = directory/"base.tsrct"
        engine.call("project","create","--project",template)
        engine.call("project","import-video","--project",template,"--file",source,"--asset-id","moving")
        wav=directory/"tone.wav"
        subprocess.run([shutil.which("ffmpeg"),"-v","error","-f","lavfi","-i",
            "sine=frequency=660:sample_rate=48000:duration=2","-c:a","pcm_s16le",str(wav)],check=True,capture_output=True)
        engine.call("project","import-asset","--project",template,"--file",wav,"--kind","audio","--asset-id","tone")
        font = json.loads(engine.call("project","import-font","--project",template,"--file","C:/Windows/Fonts/segoeui.ttf"))
        engine.call("project","checkout","--project",template,"--output",directory/"base.json")
        base = json.loads((directory/"base.json").read_text(encoding="utf-8"))
        base.update(dimensions={"width":1280,"height":720},duration=0.6)
        base["composition"]["layers"] = [{"type":"Video","id":1,"name":"SYNTHETIC ONLY",
            "blendMode":"normal","playback":playback(0,600,250),"sourceRange":{"start":250,"duration":600},
            "sourceIntrinsicDuration":2000,"volume":0.3,"transform":transform(),"source":{"assetId":"moving","fit":"contain"}}]
        base_plan = {"kind":"edit","delivery":{"width":1280,"height":720,"fps":24,"duration_ms":600},
            "clips":[{"at_ms":0,"in_ms":250,"out_ms":850}],
            "texts":[{"at_ms":0,"duration_ms":600}],"rectangles":[{"at_ms":0,"duration_ms":600}],
            "audio":[{"at_ms":50,"in_ms":250,"out_ms":800,"volume":0.3}]}
        references = {"clip:0":1,"clip:1":2,"text:0":3,"rectangle:0":4,"audio:0":5}
        baselines = {}

        def render_case(label, technique=None, fps=24, width=1280, height=720, graphics_id=None):
            doc = directory/(label+".tsrct")
            shutil.copyfile(template,doc)
            data, plan = copy.deepcopy(base),copy.deepcopy(base_plan)
            data["dimensions"] = {"width":width,"height":height}
            plan["delivery"].update(width=width,height=height,fps=fps)
            actions = []
            if technique and technique["id"] == "native.audio-gain":
                data["composition"]["layers"][0]["volume"]=0
                data["composition"]["layers"].append({"type":"Audio","id":5,"name":"explicit audio envelope",
                    "playback":playback(50,550,250),"sourceRange":{"start":250,"duration":550},"sourceIntrinsicDuration":2000,
                    "volume":0.3,"source":{"assetId":"tone"},"captionsEnabled":False})
            if technique and technique["id"]=="native.collage":
                second = copy.deepcopy(data["composition"]["layers"][0])
                second.update(id=2,name="second moving source")
                second["playback"] = playback(0,600,750)
                second["sourceRange"] = {"start":750,"duration":600}
                second["volume"] = 0
                data["composition"]["layers"].append(second)
                plan["clips"].append({"at_ms":0,"in_ms":750,"out_ms":1350})
            graphic = technique["id"] if technique else graphics_id
            if graphic in ("native.text-reveal","native.shape-reveal"):
                data["composition"]["layers"].insert(0,{"type":"Rect","id":4,"name":"shape",
                    "blendMode":"normal","activeRange":{"start":0,"duration":600},"transform":transform([80,100]),
                    "rect":{"size":[500,180],"fillColor":[0.9,0.2,0.6,1]}})
                if graphic=="native.text-reveal":
                    actions.append({"type":"createFxTextLayer","compositionId":data["composition"]["id"],"layerId":3,
                        "insertIndex":0,"name":"technical text","activeRange":{"start":0,"duration":600},"transform":transform([100,300]),
                        "sourceText":{"text":"Teste Ação 123","fontFamily":font["fontFamily"],"fontStyle":font["fontStyle"],
                            "fontSize":88,"fillColor":[1,1,1,1]}})
            editable = directory/(label+".json")
            write_json(editable,data)
            engine.call("project","commit","--project",doc,"--file",editable)
            if actions:
                actionfile=directory/(label+"-base-actions.json")
                write_json(actionfile,actions)
                engine.call("project","apply","--project",doc,"--actions",actionfile)
                engine.call("project","checkout","--project",doc,"--output",directory/(label+"-all.json"))
                data=json.loads((directory/(label+"-all.json")).read_text(encoding="utf-8"))
            if technique:
                plan["techniques"]=[technique]
                actions=compile_document(plan,data,references)
                compiled=directory/(label+"-compiled.json")
                write_json(compiled,data)
                engine.call("project","commit","--project",doc,"--file",compiled)
                if actions:
                    actionfile=directory/(label+"-actions.json")
                    write_json(actionfile,actions)
                    engine.call("project","apply","--project",doc,"--actions",actionfile)
            video=directory/(label+".mp4")
            engine.call("export","--project",doc,"--output",video,"--resolution","1080p","--fps",fps,timeout=300)
            stream=next(s for s in probe(video)["streams"] if s["codec_type"]=="video")
            if (stream["width"],stream["height"])!=(width,height):
                raise ValueError("Native canvas size changed.")
            frames=decoded(video)
            return video,frames

        for fps in (24,30,60):
            _,baselines[fps]=render_case(f"baseline-{fps}",fps=fps)
            for count in (1,2):
                technique={"id":"native.flash","sources":[],"start_frame":3,"duration_frames":count,"params":{}}
                video,frames=render_case(f"flash-{fps}-{count}",technique,fps)
                white=[n for n,f in enumerate(frames) if sum(f)/len(f)>250]
                if white!=list(range(3,3+count)):
                    raise ValueError(f"Flash frame mismatch {fps}/{count}: {white}")
                report["cases"].append({"id":"native.flash","fps":fps,"duration_frames":count,
                    "white_frame_indices":white,"video_sha256":sha256(video),"status":"passed"})
                print(f"PASS flash {fps} fps / {count} frames",flush=True)
        effects=[("native.fade",{},["clip:0"]),("native.transform",{"to_position":[150,80],"to_scale":[80,80]},["clip:0"]),
            ("native.reframe",{"position":[-100,-80],"scale":[140,140]},["clip:0"]),
            ("native.overlay",{"position":[250,160],"scale":[40,40]},["clip:0"]),
            ("native.collage",{},["clip:0","clip:1"]),
            ("native.color",{"saturation":0,"vignette":0.7},["clip:0"]),
            ("native.text-reveal",{},["text:0"]),("native.shape-reveal",{},["rectangle:0"])]
        for aspect,width,height in (("landscape",1280,720),("portrait",720,1280),("square",720,720)):
            baseline=baselines[24]
            if aspect!="landscape":
                _,baseline=render_case("baseline-"+aspect,width=width,height=height)
            for effect,params,sources in effects:
                technique={"id":effect,"sources":sources,"start_frame":3,"duration_frames":8,"params":params}
                label=effect.replace(".","-")+"-"+aspect
                video,frames=render_case(label,technique,width=width,height=height)
                comparison=baseline
                if effect in ("native.text-reveal","native.shape-reveal"):
                    _,comparison=render_case(label+"-baseline",width=width,height=height,graphics_id=effect)
                deltas=[difference(frames[n],comparison[n]) for n in (0,3,6,10,12)]
                if max(deltas[1:4])<1:
                    raise ValueError(f"Effect did not apply: {effect} {aspect} {deltas}")
                # H.264 prediction changes quantization after altered frames;
                # MAE < 1/255 is encoder residue, not a persistent recipe change.
                if max(deltas[0],deltas[-1])>1:
                    raise ValueError(f"Effect escaped its window: {effect} {aspect} {deltas}")
                report["cases"].append({"id":effect,"format":aspect,"dimensions":[width,height],
                    "sample_frames":[0,3,6,10,12],"baseline_mae":deltas,
                    "video_sha256":sha256(video),"status":"passed"})
                print(f"PASS {effect} {aspect}: {deltas}",flush=True)
        technique={"id":"native.audio-gain","sources":["audio:0"],"start_frame":3,"duration_frames":8,
            "params":{"from_gain":0,"to_gain":0.3}}
        video,_=render_case("audio-envelope",technique)
        pcm=subprocess.run([shutil.which("ffmpeg"),"-v","error","-i",str(video),"-map","0:a:0",
            "-ac","1","-ar","48000","-f","f32le","-"],capture_output=True,check=True).stdout
        samples=struct.unpack("<"+"f"*(len(pcm)//4),pcm)
        rms=[]
        for time in (0.075,0.13,0.27,0.4,0.52):
            window=samples[int(time*48000):int((time+0.02)*48000)]
            rms.append(math.sqrt(sum(v*v for v in window)/len(window)))
        # AAC block coding smears a sharp gain edge into nearby samples. Check
        # the measured envelope relative to the unchanged bed, not digital zero.
        if not (rms[1]<rms[2]<rms[3] and abs(rms[0]-rms[4])<0.002 and rms[1]<0.2*rms[0]):
            raise ValueError(f"Audio envelope did not follow explicit window: {rms}")
        report["cases"].append({"id":"native.audio-gain","rms_sample_times_seconds":[0.075,0.13,0.27,0.4,0.52],
            "rms":rms,"status":"passed","video_sha256":sha256(video)})
        print(f"PASS native.audio-gain {rms}",flush=True)
        for label,width,height in (("portrait",720,1280),("square",720,720)):
            technique={"id":"native.flash","sources":[],"start_frame":3,"duration_frames":1,"params":{}}
            video,frames=render_case(label,technique,24,width,height)
            report["cases"].append({"id":"native.flash","format":label,"dimensions":[width,height],
                "video_sha256":sha256(video),"status":"passed"})
        report["status"]="passed"
    except Exception as exc:
        report.update(status="failed",error=str(exc))
        print(str(exc),flush=True)
    finally:
        report["finished_at"]=utc_now()
        report["production_files_unchanged"]={str(p):sha256(p) for p in preserved}==before
        report["temporary_directory"]=str(directory) if args.keep_temporary else None
        archive = ROOT/"reports/techniques-smoke-runs"/(utc_now().replace(":","-")+".json")
        archive.parent.mkdir(parents=True,exist_ok=True)
        write_json(archive,report)
        write_json(args.report,report,replace=args.report.exists())
        if args.keep_temporary:
            temporary._finalizer.detach()
        else:
            temporary.cleanup()
    return 0 if report["status"]=="passed" and report["production_files_unchanged"] else 1


if __name__=="__main__":
    raise SystemExit(main())
