# CardGame Progress API

FastAPI backend that stores card-game player progress in PostgreSQL under the `cardgame` schema.

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `DATABASE_URL` | Yes | — | asyncpg-style DSN: `postgresql://user:pass@host:5432/dbname` |
| `PORT` | No | `8000` | Port uvicorn listens on |
| `CORS_ORIGINS` | No | `*` | Comma-separated allowed origins, e.g. `https://myapp.com,https://staging.myapp.com` |

## Running Locally

```bash
cd server
pip install -r requirements.txt
export DATABASE_URL=postgresql://coach:CHANGEME@localhost:5432/coach
uvicorn app.main:app --reload --port 8000
```

## Coolify Deploy Notes

1. Point Coolify at this directory (or the repo root with build context `server/`).
2. Build method: **Dockerfile** (uses `server/Dockerfile`).
3. Set environment variable `DATABASE_URL` to the internal Docker network DSN (e.g. `postgresql://coach:PASS@postgres:5432/coach`).
4. Expose port `8000`.
5. The `cardgame` schema and all tables are **auto-created on first boot** — no manual migration needed.
6. Place this service on the same Docker network as your existing Postgres container.

## API Endpoints

### Health Check

```bash
curl https://api.example.com/healthz
# {"status":"ok"}
```

### Create Player

```bash
curl -X POST https://api.example.com/v1/players \
  -H "Content-Type: application/json" \
  -d '{"display_name": "Alice"}'
# {"player_id":"<uuid>","token":"<raw-token>"}
```

Store the token securely — it is returned **only once**.

### Get Progress

```bash
curl https://api.example.com/v1/progress \
  -H "Authorization: Bearer <token>"
# {"data":{...},"crystals":42,"schema_version":1,"updated_at":"2024-01-01T00:00:00Z"}
```

### Save Progress

```bash
curl -X PUT https://api.example.com/v1/progress \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"data":{"kingdomLevel":3,"ownedCardIds":[1,2,3],"unlockedNodeIndex":5},"crystals":42,"schema_version":1}'
# {"data":{...},"crystals":42,"schema_version":1,"updated_at":"2024-01-01T00:00:00Z"}
```
