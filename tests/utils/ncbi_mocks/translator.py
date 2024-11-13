from typing import Any


def translate(s: str, mapping: dict[str, Any]):
    for k, v in mapping.items():
        s = s.replace("{" + k + "}", v)
    return s