import hashlib
import json
import os.path
from typing import Any, Optional

from src.common.logs import create_logger

log = create_logger(__name__)


class Cached:
    path: str
    enabled: bool

    def __init__(self, path: str, enabled: bool = True):
        self.path = path
        self.enabled = enabled
        os.makedirs(self.path, exist_ok=True)

    def get(self, *key_components) -> Optional[str]:
        if not self.enabled:
            return None
        key = "-".join([str(k) for k in key_components]).encode("utf8")
        key_hash = hashlib.sha256(key).hexdigest()

        try:
            with open(os.path.join(self.path, key_hash + ".txt")) as file:
                data = file.read()
                log.debug("Get OK %s", key)
                return data

        except IOError:
            log.debug("Get NOT FOUND %s", key)
            return None

    def set(self, value: str, *key_components):
        if not self.enabled:
            return None
        key = "-".join([str(k) for k in key_components]).encode("utf8")
        key_hash = hashlib.sha256(key).hexdigest()
        log.debug("Set %s to %s bytes", key, len(value))
        with open(os.path.join(self.path, key_hash + ".txt"), "w") as file:
            file.write(value)
        return None

    def get_json(self, *key_components) -> Optional[Any]:
        raw = self.get(*key_components)
        if raw:
            return json.loads(raw)
        return None

    def set_json(self, value: Any, *key_components):
        self.set(json.dumps(value), *key_components)
