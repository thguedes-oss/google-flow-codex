"""Review declarations must carry real text; no media or production approvals."""
import copy
import sys
import unittest

from helpers import ROOT, technical_direction
sys.path.insert(0, str(ROOT / "scripts"))
from flow_review import CRITERIA, validate_spec


class ReviewDeclarationTests(unittest.TestCase):
    def setUp(self):
        self.report = {"metadata": {"streams": []}}
        self.spec = {"reviewer": "SYNTHETIC TEST ONLY", "decision": "approved", "selected": False,
                     "playback_completed": True, "audio_review": "not_applicable",
                     "audio_reason": "Temporary silent fixture",
                     "criteria": [{"criterion": key, "severity": "0", "timestamps": "0-1s",
                                   "observation": "Temporary test declaration only"} for key in CRITERIA]}

    def test_mandatory_review_strings_reject_whitespace_and_non_text(self):
        for field in ("reviewer", "audio_reason", "observation", "timestamps"):
            for value in ("   ", "\t\n", 1, ["text"]):
                with self.subTest(field=field, value=value):
                    spec = copy.deepcopy(self.spec)
                    if field in ("observation", "timestamps"):
                        spec["criteria"][0][field] = value
                    else:
                        spec[field] = value
                    with self.assertRaises(ValueError):
                        validate_spec(spec, self.report)

    def test_direction_requires_intent_review_for_approval_and_rejection(self):
        self.report["expected_direction"] = technical_direction()
        for decision in ("approved", "rejected"):
            for value in (None, "   ", 1):
                with self.subTest(decision=decision, value=value), self.assertRaises(ValueError):
                    validate_spec(dict(self.spec, decision=decision, intent_review=value), self.report)
        validate_spec(dict(self.spec, intent_review="Human observation of the intended result"), self.report)

    def test_old_evidence_does_not_require_intent_review(self):
        validate_spec(self.spec, self.report)
        validate_spec(self.spec, dict(self.report, expected_direction=None))


if __name__ == "__main__":
    unittest.main()
