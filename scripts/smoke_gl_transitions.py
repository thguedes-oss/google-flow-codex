"""Explicit native GL shader smoke; all synthetic media lives in temporary directories.
No production approval, generation calls, network requests or Flow credits.
"""
from __future__ import annotations
import argparse, copy, json, shutil, subprocess, tempfile, math
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from flow_files import ROOT, sha256, utc_now
from tesseract_pipeline import Engine, transform, playback

def write(path,obj): path.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def runtime_parameters(entry,progress=0,ratio=16/9):
    out=[{'name':'progress','min':0,'max':1,'default':progress},{'name':'ratio','min':0.1,'max':10,'default':ratio}]
    for p in entry['parameters']:
        values=p['default'] if isinstance(p['default'],list) else [p['default']]
        for i,v in enumerate(values):
            out.append({'name':p['name']+('_'+'xyzw'[i] if len(values)>1 else ''),'default':float(v),'min':p.get('min',min(-100,float(v)*2)),'max':p.get('max',max(100,float(v)*2))})
    return out

def raw(path,time=None):
    cmd=['ffmpeg','-nostdin','-v','error']
    if time is not None: cmd+=['-ss',str(time)]
    cmd+=['-i',str(path),'-frames:v','1','-pix_fmt','rgba','-f','rawvideo','-']
    return subprocess.run(cmd,check=True,capture_output=True).stdout

def rgb(pixels): return bytes(v for i,v in enumerate(pixels) if i%4!=3)
def mae(a,b): return sum(abs(x-y) for x,y in zip(a,b))/len(a) if len(a)==len(b) and a else 1e9

def setup(workspace):
    engine=Engine(workspace); doc=workspace/'base.tsrct'
    engine.call('project','create','--project',doc)
    for i,freq in enumerate((440,880)):
        src=workspace/f'source-{i}.mp4'
        filt='testsrc2=s=320x180:r=24:d=3'+(',hflip,hue=h=100' if i else '')
        subprocess.run(['ffmpeg','-nostdin','-v','error','-f','lavfi','-i',filt,'-f','lavfi','-i',f'sine=frequency={freq}:sample_rate=48000:duration=3','-c:v','libx264','-preset','ultrafast','-crf','10','-pix_fmt','yuv420p','-c:a','aac','-shortest',str(src)],check=True)
        engine.call('project','import-video','--project',doc,'--file',src,'--asset-id',f'source-{i}')
    editable=workspace/'base.json'; engine.call('project','checkout','--project',doc,'--output',editable)
    data=json.loads(editable.read_text()); data['dimensions']={'width':320,'height':180}; data['duration']=1.1
    layers=[]
    for i,offset in enumerate((500,250)):
        layers.append({'type':'Video','id':i+1,'name':f'SYNTHETIC source {i}','blendMode':'normal','playback':playback(0,1100,offset),'sourceRange':{'start':offset,'duration':1100},'sourceIntrinsicDuration':3000,'volume':1,'transform':transform(),'source':{'assetId':f'source-{i}','fit':'contain'}})
    data['composition']['layers']=layers; write(editable,data); engine.call('project','commit','--project',doc,'--file',editable)
    # Native baselines isolate shader output from decoder/color conversion differences.
    baselines={}
    for i in range(2):
        one=copy.deepcopy(data); one['composition']['layers']=[one['composition']['layers'][i]]
        write(editable,one); engine.call('project','commit','--project',doc,'--file',editable)
        for time in (0,0.5,1):
            image=workspace/f'baseline-{i}-{time}.png'; engine.call('preview','--project',doc,'--time',time,'--output',image)
            baselines[i,time]=raw(image)
    write(editable,data); engine.call('project','commit','--project',doc,'--file',editable)
    return engine,doc,data,baselines

def filmstrip(engine,doc,path,width,height):
    engine.call('filmstrip','--project',doc,'--timestamps-ms',0,250,500,750,1000,'--tile-width',width,'--tile-height',height,'--items-per-row',5,'--output',path)
    log=engine.directory/'logs'/f'{engine.counter:03d}-filmstrip'/'stderr.txt'
    stderr=log.read_text()
    if 'failed validation' in stderr or 'Shader' in stderr: raise ValueError(stderr)
    pixels=raw(path); stride=width*5*4; images=[]
    if len(pixels)!=stride*height: raise ValueError('Native filmstrip dimensions differ from requested canvas.')
    for i in range(5):
        # Exclude filmstrip labels, which are overlaid by the CLI and not shader output.
        images.append(b''.join(pixels[y*stride+(i*width+20)*4:y*stride+((i+1)*width-20)*4] for y in range(30,height-24)))
    return images

def run_entry(engine,base,data,entry,workspace,baselines):
    folder=workspace/entry['name']; folder.mkdir(exist_ok=True); doc=folder/'shader.tsrct'; shutil.copyfile(base,doc)
    current=copy.deepcopy(data); effect={'type':'customShader','name':entry['id'],'description':'GL Transitions static port; temporary native verification','wgsl':(ROOT/entry['implementation']['path']).read_text(),'params':runtime_parameters(entry,ratio=data['dimensions']['width']/data['dimensions']['height']),'textureInputs':[{'name':p['name'],'sourceLayerId':i+2} for i,p in enumerate(entry.get('texture_inputs',[{'name':'to'}]))]}
    if entry.get('sources_max',2)==2: current['composition']['layers']=current['composition']['layers'][:2]
    current['composition']['layers'][0]['effects']=[{'id':10,'effect':effect}]
    editable=folder/'editable.json'; write(editable,current); engine.call('project','commit','--project',doc,'--file',editable)
    actions=[{'type':'setFxLayerEffectParamAnimator','compositionId':current['composition']['id'],'layerId':1,'effectId':10,'paramName':'progress','animator':{'type':'jsScript','layerTimeJsCode':'return Math.max(0,Math.min(1,input.time.seconds));'},'dependencies':[]}]
    actionfile=folder/'actions.json'; write(actionfile,actions); engine.call('project','apply','--project',doc,'--actions',actionfile)
    frames=[]; target=folder/'filmstrip.png'
    width=current['dimensions']['width']; height=current['dimensions']['height']
    samples=filmstrip(engine,doc,target,width,height)
    for index,time in enumerate((0,0.25,0.5,0.75,1)):
        pixels=samples[index]; fromdiff=mae(pixels,baselines[0,time]); todiff=mae(pixels,baselines[1,time])
        frames.append({'time':time,'filmstrip_cell':index,'mae_from':fromdiff,'mae_to':todiff,'mae_from_rgb':mae(rgb(pixels),rgb(baselines[0,time])),'mae_to_rgb':mae(rgb(pixels),rgb(baselines[1,time])),'alpha_mae_from':mae(pixels[3::4],baselines[0,time][3::4]),'alpha_mae_to':mae(pixels[3::4],baselines[1,time][3::4]),'rgb_mean':sum(v for n,v in enumerate(pixels) if n%4!=3)/(len(pixels)*.75),'alpha_min':min(pixels[3::4]),'alpha_max':max(pixels[3::4]),'transparent_rgb_nonzero':sum(any(pixels[i:i+3]) for i in range(0,len(pixels),4) if pixels[i+3]==0)})
    if any(f['transparent_rgb_nonzero'] for f in frames): raise ValueError('Nonzero RGB in fully transparent output pixels.')
    if all(f['mae_from']<0.1 for f in frames[1:]): raise ValueError('Pass-through detected across transition; shader/input binding unproved.')
    if all(f['rgb_mean']<0.1 for f in frames): raise ValueError('Black output across transition.')
    return {'id':entry['id'],'implementation_sha256':entry['implementation']['sha256'],'status':'rendered','frames':frames,'document':str(doc),'document_sha256':sha256(doc),'filmstrip':str(target),'filmstrip_sha256':sha256(target),'orientation_and_aspect_endpoint_mae':[frames[0]['mae_from_rgb'],frames[-1]['mae_to_rgb']], 'dimensions':current['dimensions'], 'intermediate_black_detected':any(f['rgb_mean']<0.1 for f in frames[1:-1])}

def refresh_metrics(path):
    report=json.loads(path.read_text()); workspace=Path(report['temporary_directory'])
    width,height=next((r['dimensions']['width'],r['dimensions']['height']) for r in report['results'] if r['status']=='rendered')
    def cells(path):
        pixels=raw(path); stride=width*5*4
        return [b''.join(pixels[y*stride+(i*width+20)*4:y*stride+((i+1)*width-20)*4] for y in range(30,height-24)) for i in range(5)]
    baselines=[cells(workspace/f'baseline-{i}.png') for i in range(2)]
    for case in report['results']:
        if case['status']!='rendered': continue
        if 'mae_from_rgb' in case['frames'][0]: continue
        for index,(pixels,frame) in enumerate(zip(cells(Path(case['filmstrip'])),case['frames'])):
            frame.update(mae_from_rgb=mae(rgb(pixels),rgb(baselines[0][index])),mae_to_rgb=mae(rgb(pixels),rgb(baselines[1][index])),alpha_mae_from=mae(pixels[3::4],baselines[0][index][3::4]),alpha_mae_to=mae(pixels[3::4],baselines[1][index][3::4]))
        case['orientation_and_aspect_endpoint_mae']=[case['frames'][0]['mae_from_rgb'],case['frames'][-1]['mae_to_rgb']]
    report['baseline_files']=[{'path':str(workspace/f'baseline-{i}.png'),'sha256':sha256(workspace/f'baseline-{i}.png')} for i in range(2)]
    for case in report['results']:
        if case['status']=='rendered': case['document_sha256']=sha256(Path(case['document']))
    report['metric_note']='Endpoint orientation/aspect uses RGB MAE. Alpha is reported separately because some original shaders explicitly force opaque output. This does not claim preservation of input transparency.'
    write(path,report)

def publish_catalog():
    catalogpath=ROOT/'resources/gl-transitions/catalog.json'
    catalog=json.loads(catalogpath.read_text()); reports={}
    dimensions={'landscape':{'width':320,'height':180},'portrait':{'width':180,'height':320},'square':{'width':240,'height':240}}
    for aspect in dimensions:
        path=ROOT/f'reports/gl-transitions-{aspect}.json'
        report=json.loads(path.read_text())
        if report.get('counts')!={'rendered':125,'incomplete':0,'unsupported':0}: raise ValueError(f'Aspect report incomplete: {aspect}')
        for baseline in report['baseline_files']:
            if sha256(Path(baseline['path']))!=baseline['sha256']: raise ValueError('Altered baseline evidence.')
        reports[aspect]=(path,{r['id']:r for r in report['results']})
    aggregate={'schema_version':1,'engine':'0.3.1','verified_at':utc_now(),'synthetic_only':True,'flow_credits':0,'production_approval':False,'results':[]}
    for entry in catalog['effects']:
        cases=[]
        for aspect,(path,byid) in reports.items():
            case=byid[entry['id']]
            if case['implementation_sha256']!=entry['implementation']['sha256'] or sha256(ROOT/entry['implementation']['path'])!=entry['implementation']['sha256']: raise ValueError('Stale shader evidence: '+entry['id'])
            if case['dimensions']!=dimensions[aspect]: raise ValueError('Wrong tested aspect.')
            if any(f['transparent_rgb_nonzero'] for f in case['frames']): raise ValueError('Alpha check failed.')
            if max(case['orientation_and_aspect_endpoint_mae'])>(8 if entry['name'] in ('AdvancedMosaic','tangentMotionBlur') else 2): raise ValueError('Endpoint fidelity review needed: '+entry['id']+' '+aspect)
            if sha256(Path(case['filmstrip']))!=case['filmstrip_sha256']: raise ValueError('Altered native evidence image.')
            if sha256(Path(case['document']))!=case['document_sha256']: raise ValueError('Altered native evidence document.')
            cases.append({'aspect':aspect,'report':path.relative_to(ROOT).as_posix(),'report_sha256':sha256(path),'filmstrip_sha256':case['filmstrip_sha256'],'endpoint_mae':case['orientation_and_aspect_endpoint_mae'],'intermediate_black_detected':case['intermediate_black_detected']})
        aggregate['results'].append({'id':entry['id'],'status':'rendered','implementation_sha256':entry['implementation']['sha256'],'source_sha256':entry['source']['sha256'],'aspects':cases,'pixel_checks':{'compiled':True,'non_passthrough':True,'endpoint_orientation_aspect':True,'transparent_rgb_zero':True}})
    target=ROOT/'reports/gl-transitions-smoke.json'; write(target,aggregate)
    for entry in catalog['effects']:
        entry['status']='enabled'; entry.pop('reason',None); entry.pop('verification',None)
        entry['evidence']={'report':target.relative_to(ROOT).as_posix(),'case_id':entry['id'],'implementation_sha256':entry['implementation']['sha256']}
    write(catalogpath,catalog)
    print(json.dumps({'enabled':len(catalog['effects']),'report':str(target)}))

def main():
    ap=argparse.ArgumentParser(description=__doc__); ap.add_argument('--only',nargs='*'); ap.add_argument('--refresh-metrics',type=Path); ap.add_argument('--publish-catalog',action='store_true',help='Publish only when all three complete aspect reports match every static shader hash.'); ap.add_argument('--report',type=Path,default=ROOT/'reports/gl-transitions-smoke.json'); ap.add_argument('--workspace',type=Path); ap.add_argument('--aspect', choices=['landscape','portrait','square'],default='landscape'); args=ap.parse_args()
    if args.refresh_metrics: refresh_metrics(args.refresh_metrics); return 0
    if args.publish_catalog: publish_catalog(); return 0
    workspace=args.workspace or Path(tempfile.mkdtemp(prefix='flow-gl-transitions-'))
    catalogpath=ROOT/'resources/gl-transitions/catalog.json'; catalog=json.loads(catalogpath.read_text()); report={'schema_version':1,'engine':'0.3.1','started_at':utc_now(),'temporary_directory':str(workspace),'synthetic_only':True,'flow_credits':0,'playback_completed':False,'audio_listened':False,'results':[]}
    if args.workspace:
        engine=Engine(workspace); engine.counter=len(list((workspace/'logs').glob('*'))); base=workspace/'base.tsrct'; data=json.loads((workspace/'base.json').read_text()); baselines={}
    else: engine,base,data,baselines=setup(workspace)
    # Reuse packaged assets but prepare an isolated aspect fixture and native baselines.
    runspace=workspace/(args.aspect+'-'+utc_now().replace(':','').replace('.',''))
    runspace.mkdir(); original=base; base=runspace/'base.tsrct'; shutil.copyfile(original,base)
    engine=Engine(runspace); workspace=runspace; report['temporary_directory']=str(workspace)
    width,height={'landscape':(320,180),'portrait':(180,320),'square':(240,240)}[args.aspect]
    data['dimensions']={'width':width,'height':height}
    third=workspace/'map.png'
    subprocess.run(['ffmpeg','-nostdin','-v','error','-f','lavfi','-i','nullsrc=s=320x180,geq=lum=16+220*X/W:cb=128:cr=128','-frames:v','1',str(third)],check=True)
    engine.call('project','import-asset','--project',base,'--file',third,'--kind','image','--asset-id','map')
    resourcecheck=workspace/'imported.json'; engine.call('project','checkout','--project',base,'--output',resourcecheck)
    imported=json.loads(resourcecheck.read_text()); imported['dimensions']=data['dimensions']; imported['duration']=data['duration']; imported['composition']=copy.deepcopy(data['composition']); data=imported
    data['composition']['layers'].append({'type':'Image','id':3,'name':'SYNTHETIC extra grayscale map','blendMode':'normal','activeRange':{'start':0,'duration':1100},'transform':transform(),'source':{'assetId':'map','fit':'contain'}})
    editable=workspace/'base.json'; baselines={}
    for i in range(2):
        one=copy.deepcopy(data); one['composition']['layers']=[one['composition']['layers'][i]]
        write(editable,one); engine.call('project','commit','--project',base,'--file',editable)
        images=filmstrip(engine,base,workspace/f'baseline-{i}.png',width,height)
        baselines.update({(i,t):pixels for t,pixels in zip((0,0.25,0.5,0.75,1),images)})
    write(editable,data); engine.call('project','commit','--project',base,'--file',editable)
    report['baseline_files']=[{'path':str(workspace/f'baseline-{i}.png'),'sha256':sha256(workspace/f'baseline-{i}.png')} for i in range(2)]
    report['metric_note']='Endpoint orientation/aspect uses RGB MAE; alpha is measured separately. Original shaders that explicitly force opacity retain that behavior.'
    entries=[e for e in catalog['effects'] if not args.only or e['name'] in args.only]
    def worker(entry):
        if 'implementation' not in entry: return {'id':entry['id'],'status':entry['status'],'reason':entry['reason']}
        folder=workspace/entry['name']; folder.mkdir(exist_ok=True)
        local=copy.copy(engine); local.directory=folder; local.counter=len(list((folder/'logs').glob('*'))) if (folder/'logs').exists() else 0
        try: return run_entry(local,base,data,entry,workspace,baselines)
        except Exception as exc: return {'id':entry['id'],'status':'incomplete','error':str(exc)}
    with ThreadPoolExecutor(max_workers=4) as pool:
        jobs={pool.submit(worker,e):e for e in entries}
        for future in as_completed(jobs):
            entry=jobs[future]; result=future.result()
            report['results'].append(result); write(args.report,report)
            print(entry['id'],result['status'],str(result.get('error',''))[:100],flush=True)
    report['finished_at']=utc_now(); report['counts']={s:sum(r['status']==s for r in report['results']) for s in ('rendered','incomplete','unsupported')}; write(args.report,report)
    print(json.dumps({'workspace':str(workspace),'counts':report['counts']})); return 0 if not report['counts']['incomplete'] else 1
if __name__=='__main__': raise SystemExit(main())
