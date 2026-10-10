"""Reference integrity must detect missing files, edited bytes and changed Git checkouts."""
import hashlib
import copy
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from source_integrity import check_supplements


class SupplementTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="flow-source-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "vendor/example"
        self.source.mkdir(parents=True)
        (self.source / "LICENSE").write_bytes(b"technical license fixture\n")
        self.record = {"id": "example", "directory": "vendor/example", "type": "snapshot", "commit": "a" * 40,
                       "files": [{"path": "LICENSE", "sha256": hashlib.sha256(b"technical license fixture\n").hexdigest()}]}

    def check(self):
        return check_supplements(self.root, [self.record])[0]

    def test_pinned_snapshot_passes_and_modified_bytes_fail(self):
        self.assertTrue(self.check()["passed"])
        (self.source / "LICENSE").write_bytes(b"changed")
        self.assertFalse(self.check()["passed"])

    def duplicate_fixture(self):
        import json
        self.inventory = self.root / "config/source-inventories/example.json"
        self.inventory.parent.mkdir(parents=True, exist_ok=True)
        self.inventory.write_text(json.dumps({"files": [
            {"path": "a", "sha256": "a"*64, "destination": "workflow/tecnicas.md"},
            {"path": "b", "sha256": "a"*64, "destination": "workflow/tecnicas.md"}]}), encoding="utf-8")
        self.record["inventory"] = {"path": "config/source-inventories/example.json",
                                     "sha256": hashlib.sha256(self.inventory.read_bytes()).hexdigest()}
        self.duplicates = self.inventory.with_name("duplicates.json")
        group = {"sha256": "a"*64, "origins": [{"source_id": "example", "path": p,
            "destination": "workflow/tecnicas.md"} for p in ("a", "b")]}
        self.duplicates.write_text(json.dumps({"schema_version": 1, "groups": [group]}), encoding="utf-8")
        return {"supplements": [self.record], "duplicate_inventory": {
            "path": "config/source-inventories/duplicates.json",
            "sha256": hashlib.sha256(self.duplicates.read_bytes()).hexdigest()}}

    def test_duplicate_groups_hash_and_legacy_optional(self):
        from source_integrity import check_duplicate_inventory
        lock = self.duplicate_fixture()
        self.assertTrue(check_duplicate_inventory(self.root, lock)["passed"])
        self.duplicates.write_bytes(b"{}")
        self.assertFalse(check_duplicate_inventory(self.root, lock)["passed"])
        self.assertIsNone(check_duplicate_inventory(self.root, {"supplements": [self.record]}))

    def test_duplicate_groups_omission_and_extra_fail_even_with_new_hash(self):
        import json
        from source_integrity import check_duplicate_inventory
        lock = self.duplicate_fixture()
        original = json.loads(self.duplicates.read_text(encoding="utf-8"))
        for data in ({"schema_version": 1, "groups": []},
                     {"schema_version": 1, "groups": [dict(original["groups"][0], origins=[])]},
                     {"schema_version": 1, "groups": original["groups"]*2}):
            self.duplicates.write_text(json.dumps(data), encoding="utf-8")
            lock["duplicate_inventory"]["sha256"] = hashlib.sha256(self.duplicates.read_bytes()).hexdigest()
            self.assertFalse(check_duplicate_inventory(self.root, lock)["passed"])

    def test_missing_files_and_path_escapes_fail(self):
        for path in ("missing", "../outside"):
            self.record["files"][0]["path"] = path
            self.assertFalse(self.check()["passed"])
        self.record["directory"] = "../escape"
        self.assertFalse(self.check()["passed"])

    def test_empty_supplement_list_fails(self):
        self.assertFalse(check_supplements(self.root, [])[0]["passed"])

    def test_inventory_hash_coverage_and_metadata(self):
        import json
        inventory = self.root / "config/source-inventories/example.json"
        inventory.parent.mkdir(parents=True)
        data = {"source_id": "example", "commit": self.record["commit"], "files": [dict(
            self.record["files"][0], category="license", observed_license="fixture",
            applicability="consulta", destination="workflow/tecnicas.md", reason="Fixture only")]}
        def save():
            inventory.write_text(json.dumps(data), encoding="utf-8")
            self.record["inventory"]["sha256"] = hashlib.sha256(inventory.read_bytes()).hexdigest()
        self.record["inventory"] = {"path": "config/source-inventories/example.json", "sha256": ""}
        save()
        self.assertTrue(self.check()["passed"])
        inventory.write_text("{}", encoding="utf-8")
        self.assertFalse(self.check()["passed"])
        save()
        (self.source / "extra.txt").write_text("extra", encoding="utf-8")
        self.assertFalse(self.check()["passed"])
        (self.source / "extra.txt").unlink()
        data["files"] = []
        save()
        self.assertFalse(self.check()["passed"])

    def test_inventory_rejects_duplicate_and_missing_metadata(self):
        import json
        inventory = self.root / "config/source-inventories/example.json"
        inventory.parent.mkdir(parents=True)
        entry = dict(self.record["files"][0], category="license", observed_license="fixture",
                     applicability="consulta", destination="workflow/tecnicas.md", reason="Fixture only")
        self.record["inventory"] = {"path": "config/source-inventories/example.json", "sha256": ""}
        for entries in ([entry, entry], [dict(entry, reason=" ")],
                        [dict(entry, path="../outside")], [dict(entry, sha256="0" * 64)]):
            with self.subTest(entries=entries):
                inventory.write_text(json.dumps({"source_id": "example", "commit": self.record["commit"],
                                                "files": entries}), encoding="utf-8")
                self.record["inventory"]["sha256"] = hashlib.sha256(inventory.read_bytes()).hexdigest()
                self.assertFalse(self.check()["passed"])

    def web_record(self):
        record = copy.deepcopy(self.record)
        record.pop("commit")
        record.update(type="web-snapshot", url="https://example.invalid/wiki/", verified_on="2026-10-08",
                      attribution="Synthetic source only", license="unspecified",
                      rights_note="No explicit text license identified")
        record["files"][0]["source_url"] = "https://example.invalid/wiki/start.md"
        self.record = record

    def test_web_snapshot_without_commit_checks_real_bytes_and_missing_files(self):
        self.web_record()
        self.assertTrue(self.check()["passed"], self.check()["errors"])
        (self.source / "LICENSE").write_bytes(b"edited source")
        self.assertFalse(self.check()["passed"])
        (self.source / "LICENSE").unlink()
        self.assertFalse(self.check()["passed"])

    def test_web_snapshot_requires_provenance_and_contained_paths(self):
        self.web_record()
        self.assertTrue(self.check()["passed"], self.check()["errors"])
        original = copy.deepcopy(self.record)
        for key, value in (("verified_on", "2026-02-30"), ("verified_on", "20261008"),
                           ("url", "file:///local"), ("attribution", "   "),
                           ("license", "   "), ("rights_note", "   ")):
            with self.subTest(key=key, value=value):
                self.record = copy.deepcopy(original)
                self.record[key] = value
                self.assertFalse(self.check()["passed"])
        for key, value in (("path", "../outside"), ("path", str(self.source / "LICENSE")),
                           ("source_url", "https://user:secret@example.invalid/wiki/start.md"),
                           ("source_url", "not a URL"), ("sha256", "bad")):
            with self.subTest(key=key, value=value):
                self.record = copy.deepcopy(original)
                self.record["files"][0][key] = value
                self.assertFalse(self.check()["passed"])
        self.record = copy.deepcopy(original)
        self.record["directory"] = "../escape"
        self.assertFalse(self.check()["passed"])

    def test_git_pin_and_clean_checkout_are_required(self):
        def git(*args):
            return subprocess.run(["git", "-C", str(self.source), *args], check=True, capture_output=True,
                                  text=True, encoding="utf-8").stdout.strip()

        git("init", "--quiet")
        git("config", "core.autocrlf", "false")
        git("add", "LICENSE")
        git("-c", "user.name=FLOW technical test", "-c", "user.email=fixture@example.invalid", "-c", "commit.gpgsign=false",
            "commit", "--quiet", "-m", "technical fixture")
        self.record.update(type="git", commit=git("rev-parse", "HEAD"))
        self.assertTrue(self.check()["passed"])
        self.record["commit"] = "0" * 40
        self.assertFalse(self.check()["passed"])
        self.record["commit"] = git("rev-parse", "HEAD")
        (self.source / "untracked.txt").write_text("unreviewed file", encoding="utf-8")
        self.assertFalse(self.check()["passed"])


if __name__ == "__main__":
    unittest.main()
