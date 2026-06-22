from __future__ import annotations
import asyncpg

MIGRATION_SQL = """
CREATE SCHEMA IF NOT EXISTS cardgame;

CREATE TABLE IF NOT EXISTS cardgame.players (
    id uuid PRIMARY KEY,
    token_hash text NOT NULL UNIQUE,
    display_name text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cardgame.player_progress (
    player_id uuid PRIMARY KEY REFERENCES cardgame.players(id) ON DELETE CASCADE,
    data jsonb NOT NULL,
    crystals int NOT NULL DEFAULT 0,
    schema_version int NOT NULL DEFAULT 1,
    updated_at timestamptz NOT NULL DEFAULT now()
);
"""

_pool: asyncpg.Pool | None = None


async def init_pool(dsn: str) -> None:
    global _pool
    _pool = await asyncpg.create_pool(dsn=dsn, min_size=2, max_size=10)
    async with _pool.acquire() as conn:
        await conn.execute(MIGRATION_SQL)


async def close_pool() -> None:
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None


def get_pool() -> asyncpg.Pool:
    if _pool is None:
        raise RuntimeError("Database pool is not initialized")
    return _pool
