"""Read review intent without changing plans, approving media or accessing services."""
from pathlib import Path

from flow_files import nonempty_text, nonnegative_number, read_json

DIRECTION_FIELDS = ("purpose", "action_result", "camera_intent", "graphics_intent")
CRITERIA = ("face", "hair", "wardrobe", "set", "lighting", "prop", "hands", "action", "physics", "text", "audio", "handoff")


def validate_direction(direction: dict) -> None:
    if not isinstance(direction, dict) or not all(
            nonempty_text(direction.get(key)) for key in DIRECTION_FIELDS):
        raise ValueError("direction exige purpose, action_result, camera_intent e graphics_intent como textos não vazios.")


def validate_moments(moments: list) -> None:
    if not isinstance(moments, list):
        raise ValueError("moments precisa ser uma lista.")
    for index, moment in enumerate(moments):
        if (not isinstance(moment, dict) or not nonnegative_number(moment.get("seconds"))
                or not nonempty_text(moment.get("expected"))):
            raise ValueError(f"Momento {index}: exige objeto, seconds finito não negativo e expected textual não vazio.")
        if "criterion" in moment and moment["criterion"] not in CRITERIA:
            raise ValueError(f"Momento {index}: criterion desconhecido.")


def load_review_plan(path: Path) -> dict:
    plan = read_json(path)
    if plan.get("schema_version") != 1 or not isinstance(plan.get("moments"), list):
        raise ValueError("Plano de revisão exige schema_version=1 e lista moments.")
    if "direction" in plan:
        validate_direction(plan["direction"])
    validate_moments(plan["moments"])
    return plan
