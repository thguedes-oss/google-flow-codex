"""Rendered evidence must remain tied to the implementations it exercised."""
from pathlib import Path
import sys
import unittest
from unittest.mock import patch
from helpers import ROOT
sys.path.insert(0,str(ROOT/"scripts"))
import technique_coverage as coverage


class EvidenceTests(unittest.TestCase):
    def check_integration(self,mutate):
        read=coverage.read_json
        def fixture(path):
            data=read(path)
            if Path(path).name=="technique-pipeline-smoke.json":
                mutate(data)
            return data
        with patch.object(coverage,"read_json",side_effect=fixture):
            return coverage.audit()

    def test_current_evidence_passes_without_overriding_hashes(self):
        result=coverage.audit()
        self.assertTrue(result["passed"],result["errors"])

    def test_stale_compiler_or_shader_integration_evidence_is_rejected(self):
        def mutate(data):
            for item in data["frozen_technique_files"]:
                item["sha256"]="0"*64
        result=self.check_integration(mutate)
        self.assertFalse(result["passed"])
        self.assertTrue(any("integração de receitas/shaders" in error for error in result["errors"]),result["errors"])

    def test_missing_pipeline_implementation_fingerprint_is_rejected(self):
        result=self.check_integration(lambda data:data.pop("implementation_files",None))
        self.assertFalse(result["passed"])
        self.assertIn("Hashes obrigatórios ausentes: integração do pipeline.",result["errors"])


if __name__=="__main__":
    unittest.main()
