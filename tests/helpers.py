"""Only synthetic technical fixtures, never production references or approvals."""
import json
from pathlib import Path
import shutil
import struct
import tempfile
import zlib

ROOT = Path(__file__).resolve().parents[1]


def technical_direction():
    return {"purpose": "Temporary continuity contract only",
            "action_result": "Turn toward the window and return, keeping hands still",
            "camera_intent": "Static medium shot to inspect hands and face",
            "graphics_intent": "No graphics planned"}


def png(path: Path, color=(30, 60, 90)) -> Path:
    def chunk(name, payload):
        data = name + payload
        return struct.pack(">I", len(payload)) + data + struct.pack(">I", zlib.crc32(data) & 0xffffffff)
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = b"".join(b"\0" + bytes(color) * 16 for _ in range(16))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 16, 16, 8, 2, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))
    return path


class WorkspaceFixture:
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="flow-base-test-")
        self.addCleanup(self.temp.cleanup)
        self.workspace = Path(self.temp.name)
        self.project = self.workspace / "projects" / "vídeo teste"
        shutil.copytree(ROOT / "projects/exemplo-duas-cenas", self.project)
        shutil.copytree(ROOT / "library", self.workspace / "library", ignore=shutil.ignore_patterns("assets"))
        self.data = json.loads((self.project / "project.json").read_text(encoding="utf-8"))

    def save(self):
        (self.project / "project.json").write_text(json.dumps(self.data), encoding="utf-8")
