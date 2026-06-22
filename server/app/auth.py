from __future__ import annotations
import hashlib
from fastapi import Header, HTTPException, status
from .db import get_pool


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


async def current_player(authorization: str = Header(...)) -> dict:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authorization header")
    token = authorization[len("Bearer "):]
    token_hash = hash_token(token)
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, display_name FROM cardgame.players WHERE token_hash = $1",
            token_hash,
        )
    if row is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    return {"player_id": str(row["id"]), "display_name": row["display_name"]}
