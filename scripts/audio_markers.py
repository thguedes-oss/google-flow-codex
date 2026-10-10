"""Extract local RMS energy candidates for human audio review; no generation or timeline edits."""
from __future__ import annotations

import argparse
import array
import math
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from flow_files import ROOT, identifier, project_file, project_root, read_json, sha256, utc_now, write_json
from tesseract_pipeline import validate_plan, integer

MAX_DURATION_MS = 8 * 60 * 60 * 1000
DECODE_TIMEOUT = 120


def parameters(sample_rate, hop_ms, sensitivity, min_distance_ms):
    if type(sample_rate) is not int or sample_rate not in (8000, 16000):
        raise ValueError('sample_rate exige 8000 ou 16000 Hz.')
    if type(hop_ms) is not int or not 10 <= hop_ms <= 20:
        raise ValueError('hop_ms exige inteiro de 10 a 20 ms.')
    if type(sensitivity) not in (int, float) or not math.isfinite(sensitivity) or sensitivity <= 0:
        raise ValueError('sensitivity exige número finito positivo (multiplicador da média RMS).')
    integer(min_distance_ms, 'min_distance_ms', positive=True)


def frame_rms(pcm: bytes) -> float:
    if len(pcm) % 2:
        raise ValueError('PCM truncado.')
    samples = array.array('h')
    samples.frombytes(pcm)
    if sys.byteorder != 'little':
        samples.byteswap()
    return math.sqrt(sum((v / 32768) ** 2 for v in samples) / len(samples)) if samples else 0.0


def rms_stream(stream, sample_rate: int, hop_ms: int) -> list[float]:
    parameters(sample_rate, hop_ms, 1, 1)
    size = sample_rate * hop_ms // 1000 * 2
    values = []
    for chunk in iter(lambda: stream.read(size), b''):
        if len(values) * hop_ms >= MAX_DURATION_MS:
            raise ValueError('Áudio excede limite de 8 horas.')
        values.append(frame_rms(chunk))
    return values


def rms_frames(pcm: bytes, sample_rate: int, hop_ms: int) -> list[float]:
    from io import BytesIO
    return rms_stream(BytesIO(pcm), sample_rate, hop_ms)


def energy_candidates(energies, *, hop_ms, sensitivity, min_distance_ms,
                      source_in_ms, source_out_ms, audio_at_ms):
    parameters(8000, hop_ms, sensitivity, min_distance_ms)
    for name, value in (('source_in_ms', source_in_ms), ('source_out_ms', source_out_ms), ('audio_at_ms', audio_at_ms)):
        integer(value, name)
    if source_out_ms <= source_in_ms or source_out_ms - source_in_ms > MAX_DURATION_MS:
        raise ValueError('Janela de origem inválida ou maior que 8 horas.')
    if any(type(e) not in (int, float) or not math.isfinite(e) or e < 0 for e in energies):
        raise ValueError('Energias inválidas.')
    if not energies:
        return []
    threshold = sum(energies) / len(energies) * sensitivity
    # Flat plateaus yield one candidate; silence yields none.
    candidates = [i for i, value in enumerate(energies) if value > 0 and value >= threshold
                  and (i == 0 or value > energies[i-1])
                  and (i == len(energies)-1 or value >= energies[i+1])]
    selected = []
    for i in sorted(candidates, key=lambda i: (-energies[i], i)):
        source_ms = source_in_ms + i * hop_ms + hop_ms // 2
        if source_ms >= source_out_ms:
            continue
        if all(abs(i-j) * hop_ms >= min_distance_ms for j in selected):
            selected.append(i)
    return [{'type': 'energy_peak_candidate', 'confirmed': False,
             'source_ms': source_in_ms + i * hop_ms + hop_ms // 2,
             'timeline_ms': audio_at_ms + i * hop_ms + hop_ms // 2,
             'rms': energies[i]} for i in sorted(selected)]


def extract(project: Path, plan_path: str, resource_id: str, output: str, *,
            sample_rate=8000, hop_ms=20, sensitivity=1.5, min_distance_ms=200, workspace=ROOT) -> dict:
    parameters(sample_rate, hop_ms, sensitivity, min_distance_ms)
    project = project_root(project, workspace)
    identifier(resource_id)
    plan_file = project_file(project, plan_path)
    plan_hash = sha256(plan_file)
    plan = read_json(plan_file)
    validate_plan(project, plan, workspace=workspace)
    matches = [r for r in plan.get('resources', []) if r.get('id') == resource_id and r.get('kind') == 'audio']
    layers = [(i, a) for i, a in enumerate(plan.get('audio', [])) if a.get('resource') == resource_id]
    if len(matches) != 1 or len(layers) != 1:
        raise ValueError('Selecione recurso de áudio com exatamente uma camada no plano; separe planos para múltiplos usos.')
    resource = matches[0]
    index, layer = layers[0]
    media = project_file(project, resource['path'])
    before = sha256(media)
    if before != resource['sha256']:
        raise ValueError('Áudio alterado antes da leitura.')
    start, end, at = layer['in_ms'], layer['out_ms'], layer['at_ms']
    if end-start > MAX_DURATION_MS:
        raise ValueError('Janela de áudio excede 8 horas.')
    target = project_file(project, output)
    allowed = (project / 'reports/postproduction/audio-markers').resolve()
    if not target.is_relative_to(allowed) or target.suffix.lower() != '.json' or target.exists():
        raise ValueError('Saída exige JSON novo em reports/postproduction/audio-markers/.')
    ffmpeg = shutil.which('ffmpeg')
    if not ffmpeg:
        raise ValueError('FFmpeg ausente; nenhuma instalação automática.')
    with tempfile.TemporaryDirectory(prefix='flow-audio-markers-') as temp:
        pcm = Path(temp) / 'selected.s16le'
        result = subprocess.run([ffmpeg, '-nostdin', '-v', 'error', '-xerror', '-i', str(media),
            '-ss', str(start / 1000), '-t', str((end-start) / 1000), '-map', '0:a:0', '-vn',
            '-ac', '1', '-ar', str(sample_rate), '-c:a', 'pcm_s16le', '-f', 's16le', str(pcm)],
            stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=DECODE_TIMEOUT, shell=False)
        if result.returncode or not pcm.exists():
            raise ValueError('FFmpeg não decodificou o áudio selecionado.')
        if pcm.stat().st_size > MAX_DURATION_MS * sample_rate * 2 // 1000:
            raise ValueError('PCM excede limite de 8 horas.')
        decoded_ms = pcm.stat().st_size * 1000 / (sample_rate * 2)
        if decoded_ms < end-start-1:
            raise ValueError('Janela selecionada ultrapassa o áudio decodificável.')
        with pcm.open('rb') as stream:
            energies = rms_stream(stream, sample_rate, hop_ms)
    markers = energy_candidates(energies, hop_ms=hop_ms, sensitivity=sensitivity,
        min_distance_ms=min_distance_ms, source_in_ms=start, source_out_ms=end, audio_at_ms=at)
    if sha256(media) != before or sha256(plan_file) != plan_hash:
        raise ValueError('Áudio ou plano alterado durante a extração; relatório não gravado.')
    # Recheck approvals and media hashes immediately before committing review evidence.
    validate_plan(project, read_json(plan_file), workspace=workspace)
    report = {'schema_version': 1, 'created_at': utc_now(), 'kind': 'audio_energy_candidates',
        'plan': plan_path, 'plan_sha256': plan_hash, 'resource': resource_id, 'audio_layer': index,
        'source': resource['path'], 'source_sha256': before, 'source_sha256_after': sha256(media),
        'source_in_ms': start, 'source_out_ms': end, 'audio_at_ms': at,
        'parameters': {'sample_rate': sample_rate, 'hop_ms': hop_ms, 'sensitivity': sensitivity,
                       'min_distance_ms': min_distance_ms, 'threshold': 'mean_rms_times_sensitivity'},
        'markers': markers, 'confirmed': False, 'timeline_modified': False,
        'limitations': 'Picos de energia são candidatos para audição humana; não comprovam batidas, tempo musical ou cortes.'}
    if report['source_sha256_after'] != before or sha256(plan_file) != plan_hash:
        raise ValueError('Fonte ou plano alterado na conferência final.')
    target.parent.mkdir(parents=True, exist_ok=True)
    write_json(target, report)
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('project', 'plan', 'resource', 'output'):
        parser.add_argument('--'+name, required=True, type=Path if name == 'project' else str)
    parser.add_argument('--sample-rate', type=int, default=8000)
    parser.add_argument('--hop-ms', type=int, default=20)
    parser.add_argument('--sensitivity', type=float, default=1.5)
    parser.add_argument('--min-distance-ms', type=int, default=200)
    args = vars(parser.parse_args())
    args['plan_path'] = args.pop('plan')
    args['resource_id'] = args.pop('resource')
    try:
        report = extract(**args)
    except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired) as exc:
        print(str(exc), file=sys.stderr)
        return 1
    print(f"{len(report['markers'])} candidatos de energia; confirmação humana pendente.")
    return 0

if __name__ == '__main__':
    sys.exit(main())
