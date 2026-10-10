"""Run the unchanged upstream suite, resolving Git Bash explicitly on Windows."""
from pathlib import Path
import os
import runpy
import shutil
import subprocess
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
original_run = subprocess.run


def run_with_git_bash(command, *args, **kwargs):
    # Windows subprocess searches System32 before PATH for bash.exe; that is WSL.
    # Only change executable resolution. The original scripts/arguments still run.
    if os.name == "nt" and isinstance(command, list) and command and command[0] == "bash":
        git = shutil.which("git")
        bash = Path(git).resolve().parents[1] / "bin" / "bash.exe" if git else None
        if not bash or not bash.is_file():
            raise RuntimeError("Git Bash não encontrado junto ao Git instalado.")
        command = [str(bash), *command[1:]]
    return original_run(command, *args, **kwargs)


if __name__ == "__main__":
    print("Executor local: mesma suíte upstream; Git Bash explícito no Windows.", flush=True)
    with patch("subprocess.run", run_with_git_bash):
        runpy.run_path(str(ROOT / "vendor/google-flow-scripting-skill/tests/run_tests.py"), run_name="__main__")
