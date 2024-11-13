from typing import Any, Optional

import boto3
import psycopg
from psycopg.abc import Query, Params

from src.common.logs import create_logger

log = create_logger(__name__)


def execute_many_with_return(
    cursor: psycopg.Cursor[tuple[Any, ...]], query: str, params: list[tuple[Any, ...]]
) -> list[tuple[Any, ...]]:
    if len(params) == 0:
        return []

    cursor.executemany(query, params, returning=True)

    results = []
    has_result: Optional[bool] = True
    while has_result:
        row = cursor.fetchone()
        assert row
        results.append(row)

        has_result = cursor.nextset()
    assert len(results) == len(params)
    return results


class LoggingCursor(psycopg.ClientCursor):
    psycopg_log = create_logger(__name__ + '+psycopg')

    def execute(
        self: "LoggingCursor",
        query: Query,
        params: Optional[Params] = None,
        *,
        prepare: Optional[bool] = None,
        binary: Optional[bool] = None,
    ) -> "LoggingCursor":
        """
        Execute a query or command to the database.
        """
        self.psycopg_log.debug(self.mogrify(query, params))

        try:
            super(LoggingCursor, self).execute(query, params, prepare=prepare, binary=binary)
        except Exception as e:
            self.psycopg_log.error("%s: %s", e, self.mogrify(query, params))
            raise
        return self


class Connection:
    autocommit: bool
    host: str
    port: int
    name: str
    user: str
    password: str

    conn: Optional[psycopg.Connection[tuple[Any, ...]]] = None

    # pylint: disable=too-many-arguments
    def __init__(self, host: str, port: int, name: str, user: str, password: str = "RDS", autocommit: bool = True):
        self.host = host
        self.port = port
        self.name = name
        self.user = user
        self.password = password
        self.autocommit = autocommit

    def ensure_password_resolution(self):
        if self.password == "RDS":
            log.debug("Detected the AWS RDS, recreating the token...")
            rds_client = boto3.client("rds")
            self.password = rds_client.generate_db_auth_token(
                DBHostname=self.host, Port=self.port, DBUsername=self.user
            )
            log.debug("Generated token %s", self.password)

    def reconnect(self):
        self.ensure_password_resolution()
        log.debug(
            "Connecting to"
            f" host={self.host} port={self.port} dbname={self.name} user={self.user}"
        )
        self.conn = psycopg.connect(
            f"host={self.host} port={self.port} dbname={self.name} user={self.user} password={self.password}",
            autocommit=self.autocommit,
        )
        self.conn.cursor_factory = LoggingCursor

    def cursor(self) -> psycopg.Cursor[tuple[Any, ...]]:
        if self.conn is None:
            self.reconnect()
        assert self.conn
        curr = self.conn.cursor()
        return curr

    def commit(self):
        if self.conn:
            self.conn.commit()

    def close(self):
        if self.conn:
            self.conn.close()
