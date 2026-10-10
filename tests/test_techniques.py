"""Contract tests for explicit frame-based post-production recipes."""
import copy
from pathlib import Path
import sys
import unittest

from helpers import ROOT
sys.path.insert(0, str(ROOT / "scripts"))
import flow_techniques as techniques


class TechniqueTests(unittest.TestCase):
    def setUp(self):
        self.plan = {"kind": "animatic", "delivery": {"width": 1280, "height": 720,
            "duration_ms": 2000, "fps": 24}, "images": [{"at_ms": 0, "duration_ms": 2000}],
            "techniques": [{"id": "native.flash", "sources": [], "start_frame": 7,
                            "duration_frames": 1, "params": {}}]}

    def validate(self):
        return techniques.validate(self.plan)

    def test_old_plans_need_no_catalog_or_new_fields(self):
        self.assertEqual(techniques.validate({"kind": "design"}), [])

    def test_frame_window_contains_exact_sampled_frames(self):
        for fps in (24, 30, 60):
            for start in range(fps):
                for duration in (1, 2):
                    a, b = techniques.frame_window(start, duration, fps)
                    visible = [n for n in range(2 * fps) if a <= n * 1000 / fps < b]
                    self.assertEqual(visible, list(range(start, start + duration)))

    def test_unknown_technique_param_source_and_interval_rejected(self):
        for changes in ({"id": "unknown"}, {"params": {"bogus": 2}}, {"sources": ["clip:9"]},
                        {"duration_frames": 0}, {"start_frame": True}, {"start_frame": 48}):
            plan = copy.deepcopy(self.plan)
            plan["techniques"][0].update(changes)
            with self.assertRaises(ValueError):
                techniques.validate(plan)

    def test_source_interval_is_never_extended(self):
        self.plan["images"][0].update(at_ms=500, duration_ms=500)
        self.plan["techniques"][0].update(id="native.fade", sources=["image:0"],
                                         start_frame=0, duration_frames=24)
        with self.assertRaisesRegex(ValueError, "selecionado"):
            self.validate()

    def test_parameter_types_and_non_finite_values_rejected(self):
        for color in ([1, 1], [True, 1, 1, 1], [float("nan"), 1, 1, 1], [2, 1, 1, 1]):
            self.plan["techniques"][0]["params"] = {"color": color}
            with self.assertRaises(ValueError):
                self.validate()

    def test_recipe_and_catalog_are_frozen(self):
        frozen = self.validate()
        self.assertTrue(frozen)
        self.assertTrue(all(len(item["sha256"]) == 64 for item in frozen))
        self.assertIn("scripts/flow_techniques.py", [item["path"] for item in frozen])

    def test_ambiguous_multiple_animations_are_rejected(self):
        fade = dict(id="native.fade", sources=["image:0"], start_frame=0, duration_frames=24, params={})
        self.plan["techniques"] = [fade, dict(fade)]
        with self.assertRaisesRegex(ValueError, "sobrep"):
            self.validate()

    def test_video_effect_clock_is_independent_of_source_trim(self):
        plan = {"kind":"edit","delivery":{"fps":24,"width":1280,"height":720,"duration_ms":1000},
            "clips":[{"at_ms":0,"in_ms":500,"out_ms":1500}],
            "techniques":[{"id":"native.fade","sources":["clip:0"],"start_frame":3,"duration_frames":8,"params":{}}]}
        data = {"composition":{"id":"main","layers":[{"id":1,"type":"Video",
            "transform":{"position":[0,0],"scale":[100,100],"rotation":0,"opacity":100}}]}}
        actions = techniques.compile_document(plan,data,{"clip:0":1})
        self.assertEqual(actions[0]["keyframes"][1]["layerTime"],125)
        self.assertEqual(actions[0]["keyframes"][-1]["layerTime"],458)

    def test_collage_scales_the_fitted_image_instead_of_raw_pixels(self):
        self.plan["images"] *= 2
        self.plan["techniques"]=[{"id":"native.collage","sources":["image:0","image:1"],
            "start_frame":0,"duration_frames":24,"params":{"margin":0,"gap":0}}]
        layers=[{"id":n,"type":"Image","activeRange":{"start":0,"duration":2000},
            "transform":{"position":[0,0],"scale":[4000,4000],"opacity":100,"rotation":0}} for n in (1,2)]
        data={"composition":{"id":"main","layers":layers}}
        techniques.compile_document(self.plan,data,{"image:0":1,"image:1":2})
        self.assertEqual(data["composition"]["layers"][0]["transform"]["scale"],[2000,2000])

    def test_animated_recipe_needs_two_distinct_frames(self):
        self.plan["techniques"][0].update(id="native.fade",sources=["image:0"])
        with self.assertRaisesRegex(ValueError,"dois frames"):
            self.validate()

    def test_audio_envelope_uses_original_layer_without_helper(self):
        plan={"kind":"edit","delivery":{"fps":24,"width":1280,"height":720,"duration_ms":1000},
            "audio":[{"at_ms":0,"in_ms":200,"out_ms":1200,"volume":0.3}],
            "techniques":[{"id":"native.audio-gain","sources":["audio:0"],"start_frame":3,"duration_frames":8,
                "params":{"from_gain":0.05,"to_gain":0.2}}]}
        data={"composition":{"id":"main","layers":[{"id":1,"type":"Audio","volume":0.3}]}}
        actions=techniques.compile_document(plan,data,{"audio:0":1})
        self.assertEqual(len(data["composition"]["layers"]),1)
        self.assertEqual(actions[0]["property"]["propertyType"],"volume")
        self.assertEqual(actions[0]["keyframes"][-1]["value"]["value"],0.3)

    def test_animation_clock_starts_at_owning_layer_not_composition(self):
        plan={"kind":"edit","delivery":{"fps":24,"width":1280,"height":720,"duration_ms":2000},
            "clips":[{"at_ms":500,"in_ms":500,"out_ms":1500}],
            "techniques":[{"id":"native.fade","sources":["clip:0"],"start_frame":18,"duration_frames":6,"params":{}}]}
        data={"composition":{"id":"main","layers":[{"id":1,"type":"Video",
            "transform":{"position":[0,0],"scale":[100,100],"rotation":0,"opacity":100}}]}}
        actions=techniques.compile_document(plan,data,{"clip:0":1})
        self.assertEqual(actions[0]["keyframes"][1]["layerTime"],250)

    def test_replacement_effect_preserves_foreground_graphics(self):
        self.plan["techniques"]=[{"id":"native.color","sources":["image:0"],"start_frame":3,"duration_frames":8,"params":{}}]
        data={"composition":{"id":"main","layers":[{"id":2,"name":"foreground caption","type":"Text"},
            {"id":1,"type":"Image","transform":{"position":[0,0],"scale":[100,100],"opacity":100}}]}}
        techniques.compile_document(self.plan,data,{"image:0":1})
        self.assertEqual(data["composition"]["layers"][0]["id"],2)


if __name__ == "__main__":
    unittest.main()
