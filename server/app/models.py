from __future__ import annotations
from datetime import datetime
from typing import Any
from uuid import UUID
from pydantic import BaseModel


class CreatePlayerRequest(BaseModel):
    display_name: str | None = None


class CreatePlayerResponse(BaseModel):
    player_id: UUID
    token: str


class ProgressResponse(BaseModel):
    data: dict[str, Any]
    crystals: int
    schema_version: int
    updated_at: datetime


class UpsertProgressRequest(BaseModel):
    data: dict[str, Any]
    crystals: int
    schema_version: int


class HealthResponse(BaseModel):
    status: str
