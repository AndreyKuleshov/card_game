from __future__ import annotations
import os
import secrets
import uuid
from contextlib import asynccontextmanager
from typing import Any

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

from .auth import current_player, hash_token
from .db import close_pool, get_pool, init_pool
from .models import (
    CreatePlayerRequest,
    CreatePlayerResponse,
    HealthResponse,
    ProgressResponse,
    UpsertProgressRequest,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    dsn = os.environ["DATABASE_URL"]
    await init_pool(dsn)
    yield
    await close_pool()


app = FastAPI(title="CardGame Progress API", version="1.0.0", lifespan=lifespan)

cors_origins_raw = os.environ.get("CORS_ORIGINS", "*")
cors_origins = [o.strip() for o in cors_origins_raw.split(",")] if cors_origins_raw != "*" else ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/healthz", response_model=HealthResponse)
async def healthz():
    try:
        pool = get_pool()
        async with pool.acquire() as conn:
            await conn.execute("SELECT 1")
        return HealthResponse(status="ok")
    except Exception:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Database unavailable")


@app.post("/v1/players", response_model=CreatePlayerResponse, status_code=201)
async def create_player(body: CreatePlayerRequest):
    player_id = uuid.uuid4()
    token = secrets.token_urlsafe(32)
    token_hash = hash_token(token)
    pool = get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            "INSERT INTO cardgame.players (id, token_hash, display_name) VALUES ($1, $2, $3)",
            player_id,
            token_hash,
            body.display_name,
        )
    return CreatePlayerResponse(player_id=player_id, token=token)


@app.get("/v1/progress", response_model=ProgressResponse)
async def get_progress(player: dict = Depends(current_player)):
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT data, crystals, schema_version, updated_at FROM cardgame.player_progress WHERE player_id = $1",
            uuid.UUID(player["player_id"]),
        )
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No progress found")
    import json
    return ProgressResponse(
        data=json.loads(row["data"]) if isinstance(row["data"], str) else row["data"],
        crystals=row["crystals"],
        schema_version=row["schema_version"],
        updated_at=row["updated_at"],
    )


@app.put("/v1/progress", response_model=ProgressResponse)
async def upsert_progress(body: UpsertProgressRequest, player: dict = Depends(current_player)):
    import json
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            INSERT INTO cardgame.player_progress (player_id, data, crystals, schema_version, updated_at)
            VALUES ($1, $2::jsonb, $3, $4, now())
            ON CONFLICT (player_id) DO UPDATE
            SET data = EXCLUDED.data,
                crystals = EXCLUDED.crystals,
                schema_version = EXCLUDED.schema_version,
                updated_at = now()
            RETURNING data, crystals, schema_version, updated_at
            """,
            uuid.UUID(player["player_id"]),
            json.dumps(body.data),
            body.crystals,
            body.schema_version,
        )
    return ProgressResponse(
        data=json.loads(row["data"]) if isinstance(row["data"], str) else row["data"],
        crystals=row["crystals"],
        schema_version=row["schema_version"],
        updated_at=row["updated_at"],
    )
