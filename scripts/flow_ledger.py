"""CSV compatibility and exclusive local bookkeeping writes."""
from contextlib import contextmanager
import csv
import io
from pathlib import Path
from uuid import uuid4

from flow_files import project_file


def read_csv(path: Path) -> tuple[list[str], list[dict]]:
    with path.open(encoding="utf-8-sig", newline="") as stream:
        try:
            reader = csv.DictReader(stream, strict=True)
            if not reader.fieldnames or len(reader.fieldnames) != len(set(reader.fieldnames)):
                raise ValueError("Cabeçalho CSV ausente ou duplicado.")
            rows = list(reader)
        except csv.Error as exc:
            raise ValueError(f"CSV inválido: {exc}") from exc
        if any(None in row or any(value is None for value in row.values()) for row in rows):
            raise ValueError("Linha CSV possui quantidade de campos incorreta.")
        return reader.fieldnames, rows


def write_csv(path: Path, fields: list[str], rows: list[dict]) -> None:
    output = io.StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=fields, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    temporary = path.with_name(path.name + "." + uuid4().hex + ".tmp")
    try:
        temporary.write_text(output.getvalue(), encoding="utf-8", newline="")
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


@contextmanager
def record_lock(project: Path):
    path = project_file(project, "outputs/.records.lock")
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with path.open("x", encoding="utf-8") as stream:
            stream.write("Operação local em andamento. Se interrompida, reconciliar registros antes de remover este lock.\n")
    except FileExistsError as exc:
        raise ValueError("Há uma operação local em andamento ou interrompida; reconciliar outputs/.records.lock.") from exc
    try:
        yield
    finally:
        path.unlink(missing_ok=True)
