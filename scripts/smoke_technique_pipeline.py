"""Synthetic-only end-to-end proof: formal fixture reviews, GL windows, alpha and audio."""
from __future__ import annotations
import argparse
import copy
import json
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile

from flow_files import ROOT,sha256,utc_now,write_json
from flow_ledger import read_csv,write_csv
from flow_review import CRITERIA,close_review
from review_clip import review_clip
from tesseract_pipeline import prepare,render,Engine
from smoke_techniques import decoded,difference


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--keep-temporary",action="store_true")
    args=parser.parse_args()
    temporary=tempfile.TemporaryDirectory(prefix="flow-technique-integration-")
    workspace=Path(temporary.name)
    report={"schema_version":1,"started_at":utc_now(),"fixture_kind":"synthetic_temporary_only",
        "generation_calls":0,"flow_credits_spent":0,"audio_listened":False,"playback_completed":False}
    report["implementation_files"]=[{"path":p,"sha256":sha256(ROOT/p)} for p in
        ("scripts/tesseract_pipeline.py","scripts/flow_techniques.py","scripts/smoke_technique_pipeline.py")]
    paths=[ROOT/"projects/exemplo-duas-cenas"/name for name in ("project.json","attempts.csv","review.csv")]
    before={str(p):sha256(p) for p in paths}
    try:
        project=workspace/"projects/technical"
        shutil.copytree(ROOT/"projects/exemplo-duas-cenas",project)
        ffmpeg=shutil.which("ffmpeg")
        clips=[]
        for n,frequency in enumerate((440,880)):
            path=project/f"outputs/technical-{n}.mp4"
            subprocess.run([ffmpeg,"-v","error","-f","lavfi","-i","testsrc2=s=1280x720:r=24:d=2",
                "-f","lavfi","-i",f"sine=frequency={frequency}:sample_rate=48000:duration=2",
                "-vf",f"hue=h={n*120}","-c:v","libx264","-preset","ultrafast","-crf","12","-pix_fmt","yuv420p",
                "-c:a","aac","-shortest",str(path)],check=True,capture_output=True,timeout=60)
            aid=f"technical-{n}"
            fields,rows=read_csv(project/"attempts.csv")
            row=dict.fromkeys(fields,"")
            row.update(attempt_id=aid,scene_id=f"0{n+1}",status="completed",output_file=path.relative_to(project).as_posix(),
                expected_credits="0",charged_credits="0")
            write_csv(project/"attempts.csv",fields,rows+[row])
            evidence=review_clip(project,aid,workspace_root=workspace)
            close_review(project,aid,{"evidence_report":evidence.relative_to(project).as_posix(),"decision":"approved",
                "selected":True,"supersedes":None,"reviewer":"SYNTHETIC TEMPORARY TEST ONLY",
                "playback_completed":True,"audio_review":"reviewed","intent_review":"Synthetic contract fixture only",
                "criteria":[{"criterion":c,"severity":"0","timestamps":"0-2s","observation":"Synthetic contract fixture only"} for c in CRITERIA]},workspace=workspace)
            clips.append({"attempt_id":aid,"in_ms":500 if n==0 else 250,"out_ms":1500 if n==0 else 1000,
                "at_ms":0 if n==0 else 750,"volume":0.3 if n==0 else 0.2})
        plan={"schema_version":1,"kind":"edit","title":"Synthetic transition proof",
            "delivery":{"width":1280,"height":720,"duration_ms":1500,"fps":24,"resolution":"720p","audio_expected":True},
            "clips":clips,"rectangles":[{"name":"foreground graphic survives transition","position":[20,20],
                "size":[160,80],"color":[0.9,0.1,0.7,1],"at_ms":0,"duration_ms":1500}]}
        fixture_hashes={name:sha256(project/name) for name in ("project.json","attempts.csv","review.csv")}
        base_revision=prepare(project,plan,"baseline",workspace=workspace)
        base=render(project,"baseline",workspace=workspace)/"Video.mp4"
        incoming_plan=copy.deepcopy(plan)
        incoming_plan["clips"]=[clips[1]]
        prepare(project,incoming_plan,"incoming",workspace=workspace)
        incoming=render(project,"incoming",workspace=workspace)/"Video.mp4"
        effect_plan=copy.deepcopy(plan)
        effect_plan["techniques"]=[{"id":"gl.fade","sources":["clip:0","clip:1"],"start_frame":18,"duration_frames":6,"params":{}}]
        revision=prepare(project,effect_plan,"transition",workspace=workspace)
        video=render(project,"transition",workspace=workspace)/"Video.mp4"
        b,e,t=decoded(base),decoded(video),decoded(incoming)
        outside=[difference(b[n],e[n]) for n in (0,12,17,24,30,35)]
        endpoints=[difference(b[18],e[18]),difference(t[23],e[23])]
        midpoint=[difference(b[20],e[20]),difference(t[20],e[20])]
        # Corner foreground graphic remains above the effect, not underneath a
        # newly inserted full-frame helper. Sample inside its solid area.
        corner=(3*96+3)*3
        foreground_mae=difference(b[20][corner:corner+3],e[20][corner:corner+3])
        if foreground_mae>2:
            raise ValueError("Replacement transition covered the foreground graphic.")
        if max(outside)>2 or max(endpoints)>3 or min(midpoint)<5:
            raise ValueError(f"Window/clock/endpoint mismatch: {outside}, {endpoints}, {midpoint}")
        audio=[]
        for path in (base,video):
            audio.append(subprocess.run([ffmpeg,"-v","error","-i",str(path),"-map","0:a:0","-ac","1",
                "-ar","48000","-f","f32le","-"],capture_output=True,check=True).stdout)
        if audio[0]!=audio[1] or not audio[0]:
            raise ValueError("Transition duplicated, changed or lost original audio.")
        native=json.loads((revision/"techniques-editable.json").read_text(encoding="utf-8"))
        helper_volumes=[layer.get("volume") for layer in native["composition"]["layers"] if layer["name"].startswith("technique-") and layer["type"]=="Video"]
        if helper_volumes!=[0,0]:
            raise ValueError("Auxiliary source audio is not muted.")
        report.update(window_outside_mae=outside,endpoint_mae=endpoints,midpoint_distance_to_sources=midpoint,
            foreground_graphic_mae=foreground_mae,
            decoded_audio_byte_identical=True,helper_volumes=helper_volumes,
            frozen_technique_files=json.loads((revision/"revision.json").read_text())["technique_files"],
            video_sha256=sha256(video))
        # Transparent sources: hidden originals + consumed texture inputs must
        # preserve half alpha, rather than composite another copy underneath.
        images,resources=[],[]
        for n,color in enumerate(("red","blue")):
            path=project/f"assets/half-alpha-{n}.png"
            subprocess.run([ffmpeg,"-v","error","-f","lavfi","-i",f"color=c={color}@0.5:s=64x36,format=rgba",
                "-frames:v","1",str(path)],capture_output=True,check=True)
            resources.append({"id":f"image-{n}","kind":"image","path":path.relative_to(project).as_posix(),
                "sha256":sha256(path),"origin":"Synthetic temporary half-alpha fixture",
                "approval":{"approved":True,"reviewer":"SYNTHETIC TEMPORARY TEST ONLY","at":utc_now(),"evidence":"technical fixture"}})
            images.append({"resource":f"image-{n}","at_ms":0,"duration_ms":1000})
        alpha_plan={"schema_version":1,"kind":"animatic","title":"Synthetic alpha proof",
            "delivery":dict(plan["delivery"],duration_ms=1000,audio_expected=False),"resources":resources,"images":images,
            "techniques":[{"id":"gl.fade","sources":["image:0","image:1"],"start_frame":3,"duration_frames":12,"params":{}}]}
        alpha_revision=prepare(project,alpha_plan,"alpha",workspace=workspace)
        engine=Engine(workspace)
        png=workspace/"alpha.png"
        engine.call("preview","--project",alpha_revision/"Project.tsrct","--time",0.375,"--output",png)
        raw=subprocess.run([ffmpeg,"-v","error","-i",str(png),"-pix_fmt","rgba","-f","rawvideo","-"],capture_output=True,check=True).stdout
        alpha=list(raw[3::4])
        if min(alpha)<125 or max(alpha)>129:
            raise ValueError(f"Alpha duplicated/lost: {min(alpha)}, {max(alpha)}")
        color_plan=copy.deepcopy(alpha_plan)
        color_plan["images"]=images[:1]
        color_plan["resources"]=resources[:1]
        color_plan["techniques"]=[{"id":"native.color","sources":["image:0"],"start_frame":3,"duration_frames":12,
            "params":{"saturation":0}}]
        color_revision=prepare(project,color_plan,"color-alpha",workspace=workspace)
        color_png=workspace/"color-alpha.png"
        engine.call("preview","--project",color_revision/"Project.tsrct","--time",0.375,"--output",color_png)
        color_raw=subprocess.run([ffmpeg,"-v","error","-i",str(color_png),"-pix_fmt","rgba","-f","rawvideo","-"],capture_output=True,check=True).stdout
        if min(color_raw[3::4])<125 or max(color_raw[3::4])>129 or max(color_raw[:3])-min(color_raw[:3])>2:
            raise ValueError("Color treatment lost transparency or did not desaturate.")
        frozen={item["path"]:item for item in report["frozen_technique_files"]}
        frozen.update({item["path"]:item for item in json.loads((color_revision/"revision.json").read_text())["technique_files"]})
        report["frozen_technique_files"]=[frozen[key] for key in sorted(frozen)]
        report.update(alpha_min=min(alpha),alpha_max=max(alpha),alpha_preview_sha256=sha256(png),
            native_color_alpha_min=min(color_raw[3::4]),native_color_alpha_max=max(color_raw[3::4]),
            fixture_generation_records_unchanged={name:sha256(project/name) for name in fixture_hashes}==fixture_hashes,
            status="passed")
        report["temporary_previews"]=[str(png),str(revision/"Project.tsrct")]
        print(json.dumps({k:report[k] for k in ("status","window_outside_mae","endpoint_mae","decoded_audio_byte_identical","alpha_min","alpha_max")}),flush=True)
    except Exception as exc:
        report.update(status="failed",error=str(exc))
        print(str(exc),flush=True)
    finally:
        report["production_files_unchanged"]={str(p):sha256(p) for p in paths}==before
        report["finished_at"]=utc_now()
        report["temporary_directory"]=str(workspace) if args.keep_temporary else None
        path=ROOT/"reports/technique-pipeline-smoke.json"
        archive=ROOT/"reports/technique-pipeline-smoke-runs"/(utc_now().replace(":","-")+".json")
        archive.parent.mkdir(parents=True,exist_ok=True)
        write_json(archive,report)
        write_json(path,report,replace=path.exists())
        if args.keep_temporary:
            temporary._finalizer.detach()
        else:
            temporary.cleanup()
    return 0 if report["status"]=="passed" and report["production_files_unchanged"] else 1


if __name__=="__main__":
    raise SystemExit(main())
