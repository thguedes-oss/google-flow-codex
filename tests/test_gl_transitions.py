"""Static catalog integrity and typed-lowering contracts (no GPU or network)."""
import hashlib
import json
from pathlib import Path
import sys
import unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from port_gl_transitions import Parser, Generator, parameters

class GLTransitionsTests(unittest.TestCase):
    def setUp(self):
        self.catalog=json.loads((ROOT/'resources/gl-transitions/catalog.json').read_text(encoding='utf-8'))
    def test_inventory_and_attribution(self):
        self.assertEqual(self.catalog['schema_version'],1)
        effects=self.catalog['effects']; self.assertEqual(len(effects),125)
        self.assertEqual(len({x['id'] for x in effects}),125)
        for effect in effects:
            self.assertEqual(effect['id'],'gl.'+effect['name'])
            self.assertTrue(effect['license'])
            original=ROOT/'resources/gl-transitions/originals'/(effect['name']+'.glsl')
            self.assertEqual(hashlib.sha256(original.read_bytes()).hexdigest(),effect['source']['sha256'])
            self.assertEqual(effect['source']['commit'],'b2dfdcfbec079af4a05306d32b9366aa495c5155')
    def test_static_ports_and_packed_parameter_order(self):
        for effect in self.catalog['effects']:
            if 'implementation' not in effect:
                self.assertNotEqual(effect['status'],'enabled'); continue
            impl=effect['implementation']; shader=(ROOT/impl['path']).read_text()
            self.assertEqual(hashlib.sha256((ROOT/impl['path']).read_bytes()).hexdigest(),impl['sha256'])
            self.assertIn('progress: f32,\n  ratio: f32,',shader)
            for binding in range(effect.get('sources_max',2)+2): self.assertIn('@binding('+str(binding)+')',shader)
            self.assertIn('@location(0) tex_coords: vec2<f32>',shader)
            self.assertIn('textureSampleLevel',shader)
    def test_enabled_requires_matching_native_evidence(self):
        for effect in self.catalog['effects']:
            if effect['status']!='enabled': continue
            evidence=effect['evidence']
            self.assertEqual(evidence['implementation_sha256'],effect['implementation']['sha256'])
            report=json.loads((ROOT/evidence['report']).read_text())
            case=next(r for r in report['results'] if r['id']==evidence['case_id'])
            self.assertEqual(case['status'],'rendered')
            self.assertEqual(case['implementation_sha256'],effect['implementation']['sha256'])
            self.assertEqual({a['aspect'] for a in case['aspects']},{'landscape','portrait','square'})
            for aspect in case['aspects']:
                self.assertEqual(hashlib.sha256((ROOT/aspect['report']).read_bytes()).hexdigest(),aspect['report_sha256'])
    def lower(self,source):
        p=Parser(source); ast=p.program(); return Generator(ast,parameters(source),p.structs).generate()
    def test_scalar_vector_broadcast_and_mutable_arguments(self):
        shader=self.lower('vec4 transition(vec2 uv) { uv += 0.1; return getFromColor(uv); }')
        self.assertIn('var g_uv: vec2<f32> = a_uv;',shader)
        self.assertIn('g_uv += vec2<f32>(0.1);',shader)
    def test_chained_assignment_lowering(self):
        shader=self.lower('vec4 transition(vec2 uv) { float x,y; x = y = 0.2; return vec4(x+y); }')
        self.assertIn('g_y = 0.2;\ng_x = g_y;',shader)
    def test_float_loop_increment(self):
        shader=self.lower('vec4 transition(vec2 uv) { float v=0.; for(float i=0.;i<2.;i++){v+=i;} return vec4(v); }')
        self.assertIn('g_i += 1.0',shader)
    def test_extra_sampler_binding(self):
        shader=self.lower('uniform sampler2D luma; vec4 transition(vec2 uv){return texture2D(luma,uv);}')
        self.assertIn('@binding(2) var g_luma: texture_2d<f32>',shader)
        self.assertIn('@binding(3) var s_sampler',shader)
        self.assertIn('@binding(4) var<uniform> params',shader)

if __name__=='__main__': unittest.main()
