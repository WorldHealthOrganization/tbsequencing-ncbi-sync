from typing import Any, Optional

import boto3
import psycopg
from psycopg.abc import Query, Params

from src.common.logs import create_logger
from src.db.database import Connection

log = create_logger(__name__)


class TestConnection(Connection):
    # pylint: disable=too-many-arguments
    def __init__(self, host: str, port: str, name: str, user: str, password: str = "RDS", autocommit: bool = True):
        super(TestConnection, self).__init__(host, port, name, user, password, False)

    def commit(self):
        pass

    def close(self):
        pass
