"""Energy candidates are review aids, never confirmed beats or automatic cuts."""
import array
import importlib
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))

class AudioMarkerTests(unittest.TestCase):
    def module(self):
        return importlib.import_module('audio_markers')

    def test_impulses_and_timeline_mapping(self):
        m = self.module()
        samples = [0] * 8000
        for at in (800, 2400, 4000):
            samples[at:at+80] = [16000] * 80
        energies = m.rms_frames(array.array('h', samples).tobytes(), 8000, 10)
        peaks = m.energy_candidates(energies, hop_ms=10, sensitivity=1.5, min_distance_ms=100,
                                    source_in_ms=200, source_out_ms=800, audio_at_ms=3000)
        self.assertEqual([p['source_ms'] for p in peaks], [305, 505, 705])
        self.assertEqual([p['timeline_ms'] for p in peaks], [3105, 3305, 3505])
        self.assertTrue(all(p['confirmed'] is False and p['type']=='energy_peak_candidate' for p in peaks))

    def test_silence_and_invalid_parameters(self):
        m = self.module()
        self.assertEqual(m.energy_candidates([0]*20, hop_ms=20, sensitivity=2, min_distance_ms=100,
                                             source_in_ms=0, source_out_ms=400, audio_at_ms=0), [])
        for sensitivity in (float('nan'), float('inf'), 0, -1, True):
            with self.assertRaises(ValueError):
                m.parameters(8000, 10, sensitivity, 100)
        for rate, hop, distance in ((44100, 10, 100), (8000, 9, 100), (8000, 10, -1)):
            with self.assertRaises(ValueError): m.parameters(rate, hop, 2, distance)

    def test_distance_boundaries_and_invalid_window(self):
        m = self.module()
        peaks = m.energy_candidates([1,0,1,0,0,1], hop_ms=10, sensitivity=0.5, min_distance_ms=30,
                                    source_in_ms=100, source_out_ms=160, audio_at_ms=0)
        self.assertEqual([p['source_ms'] for p in peaks], [105, 155])
        with self.assertRaises(ValueError):
            m.energy_candidates([1], hop_ms=10, sensitivity=2, min_distance_ms=30,
                                source_in_ms=20, source_out_ms=10, audio_at_ms=0)



class AudioExtractionTests(unittest.TestCase):
    def setUp(self):
        import tempfile, wave, json, hashlib
        self.temp = tempfile.TemporaryDirectory(prefix='flow-audio-tests-')
        self.addCleanup(self.temp.cleanup)
        self.workspace = Path(self.temp.name)
        self.project = self.workspace/'projects/example'
        self.project.mkdir(parents=True)
        self.media = self.project/'audio.wav'
        samples = [0]*16000
        for at in (3200,6400,9600,12800): samples[at:at+160] = [16000]*160
        with wave.open(str(self.media), 'wb') as audio:
            audio.setnchannels(1); audio.setsampwidth(2); audio.setframerate(8000)
            audio.writeframes(array.array('h', samples).tobytes())
        self.digest = hashlib.sha256(self.media.read_bytes()).hexdigest()
        self.plan = {'schema_version':1, 'kind':'animatic', 'title':'Synthetic fixture',
            'delivery':{'width':1280,'height':720,'resolution':'720p','duration_ms':3000,
                        'fps':30,'audio_expected':True},
            'resources':[{'id':'track','kind':'audio','path':'audio.wav','sha256':self.digest,
                          'origin':'synthetic temporary test',
                          'approval':{'approved':True,'reviewer':'Test fixture','at':'2026-10-10','evidence':'fixture only'}}],
            'rectangles':[{'at_ms':0,'duration_ms':3000,'position':[0,0],'size':[100,100],'color':[0,0,0,1]}],
            'audio':[{'resource':'track','at_ms':1000,'in_ms':200,'out_ms':1800}]}
        self.plan_file = self.project/'postproduction.json'
        self.save()

    def save(self):
        import json
        self.plan_file.write_text(json.dumps(self.plan),encoding='utf-8')

    def run_extract(self, output='reports/postproduction/audio-markers/test-v1.json'):
        import audio_markers
        return audio_markers.extract(self.project,'postproduction.json','track', output,
                                     workspace=self.workspace,hop_ms=10,min_distance_ms=200)

    @unittest.skipUnless(__import__('shutil').which('ffmpeg') and __import__('shutil').which('ffprobe'), 'FFmpeg required')
    def test_real_decode_hash_mapping_and_no_overwrite(self):
        report=self.run_extract()
        self.assertEqual(report['source_sha256'],self.digest)
        self.assertEqual(report['source_sha256_after'],self.digest)
        self.assertTrue(report['markers'])
        for point in report['markers']:
            self.assertEqual(point['timeline_ms'],1000+point['source_ms']-200)
            self.assertGreaterEqual(point['source_ms'],200)
            self.assertLess(point['source_ms'],1800)
        with self.assertRaises(ValueError): self.run_extract()
        with self.assertRaises(ValueError): self.run_extract('project.json')
        with self.assertRaises(ValueError): self.run_extract('../outside.json')

    def test_unapproved_changed_hash_offsource_and_plan_bounds(self):
        import copy
        original=copy.deepcopy(self.plan)
        for mutate in (
            lambda p: p['resources'][0]['approval'].update(approved=False),
            lambda p: p['resources'][0].update(sha256='0'*64),
            lambda p: p['audio'][0].update(out_ms=4000),
            lambda p: p['audio'][0].update(at_ms=2500),
        ):
            self.plan=copy.deepcopy(original); mutate(self.plan); self.save()
            with self.assertRaises(ValueError): self.run_extract()

    @unittest.skipUnless(__import__('shutil').which('ffmpeg') and __import__('shutil').which('ffprobe'), 'FFmpeg required')
    def test_hash_change_during_decode_blocks_evidence(self):
        import audio_markers
        from unittest.mock import patch
        real=audio_markers.rms_stream
        def changed(*args,**kwargs):
            value=real(*args,**kwargs)
            with self.media.open('ab') as stream: stream.write(b'changed')
            return value
        with patch.object(audio_markers,'rms_stream',side_effect=changed):
            with self.assertRaises(ValueError): self.run_extract()
        self.assertFalse((self.project/'reports').exists())

