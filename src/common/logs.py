import logging
import sys

loggers_registry: set[str] = set()

formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(formatter)

global_level = logging.INFO


def set_global_debug(value: bool):
    global global_level

    if value:
        global_level = logging.DEBUG
    else:
        global_level = logging.INFO

    for name in loggers_registry:
        logging.getLogger(name).setLevel(global_level)


def create_logger(name: str):
    loggers_registry.add(name)

    logger = logging.getLogger(name)
    logger.setLevel(global_level)
    logger.addHandler(handler)
    return logger
