# Lakemeter — Local Docker Setup

Docker-based local development setup for [Lakemeter](https://github.com/databrickslabs/lakemeter-oss),
an open-source Databricks workload cost estimation tool.

This repo contains **only the Docker additions** needed to run the app locally.
The application source code lives in the upstream repository:

**Base code:** <https://github.com/databrickslabs/lakemeter-oss.git>

## Setup

1. Clone the base repository:

   ```bash
   git clone https://github.com/databrickslabs/lakemeter-oss.git
   ```

2. Copy everything from this repo into the cloned repo
   (merges into the existing `backend/` and `frontend/` directories,
   overwriting `frontend/vite.config.ts`, `backend/app/services/ai_client.py`
   and `backend/app/routes/chat.py` with the Docker/OpenAI-ready versions):

   ```bash
   cp -a lakemeter-oss-local/backend lakemeter-oss/
   cp -a lakemeter-oss-local/frontend lakemeter-oss/
   cp lakemeter-oss-local/docker-compose.yml lakemeter-oss/
   ```

3. Start the stack:

   ```bash
   cd lakemeter-oss
   docker compose up -d --build
   ```

The first start takes a few minutes (pip/npm installs) and bootstraps the
database schema plus pricing data automatically.

## URLs

| Service | URL |
|---|---|
| Frontend (Vite dev server, hot reload) | http://localhost:5173 |
| Backend API | http://localhost:8000 |
| API docs (Swagger) | http://localhost:8000/api/docs |
| PostgreSQL (SSL enabled) | localhost:5433 |

## What's included

- `docker-compose.yml` — `certgen` (self-signed cert), `db` (postgres:16 with SSL), `backend`, `frontend`
- `backend/Dockerfile` + `backend/.dockerignore` — FastAPI backend (Python 3.12)
- `backend/app/services/ai_client.py` + `backend/app/routes/chat.py` — refactored chat backend supporting OpenAI-compatible APIs (see AI chat below)
- `frontend/Dockerfile` + `frontend/.dockerignore` — Vite dev server (Node 20)
- `frontend/vite.config.ts` — proxy target made configurable via `VITE_PROXY_TARGET`, plus a `/static` proxy for the pricing bundle

## AI chat (OpenAI-compatible)

The AI assistant works locally with any OpenAI-compatible API (OpenAI,
Ollama, vLLM, LM Studio, etc.) — no Databricks workspace needed.

Set these environment variables when starting the stack (via a `.env` file
next to `docker-compose.yml` or in your shell):

| Variable | Example | Description |
|---|---|---|
| `OPENAI_BASE_URL` | `https://api.openai.com/v1` | API base URL (include `/v1`); e.g. `http://localhost:11434/v1` for Ollama |
| `OPENAI_API_KEY` | `sk-...` | API key; can be any value for keyless local servers |
| `OPENAI_MODEL` | `gpt-4o-mini` | Model name (default: `gpt-4o-mini`) |

```bash
OPENAI_BASE_URL=https://api.openai.com/v1 \
OPENAI_API_KEY=sk-... \
OPENAI_MODEL=gpt-4o-mini \
docker compose up -d --build backend
```

When `OPENAI_BASE_URL` / `OPENAI_API_KEY` are left unset, the backend keeps
the original Databricks FMAPI mode (`DATABRICKS_HOST` + `CLAUDE_MODEL_ENDPOINT`).

## Notes

- **npm registry**: the upstream `package-lock.json` pins some packages to
  Databricks' internal npm mirror. The frontend Dockerfile rewrites those URLs
  to the public registry at build time (lockfile integrity hashes still match).
- **PostgreSQL runs with SSL** (self-signed cert) because the backend hardcodes
  `sslmode=require`, matching production Lakebase behavior.
- **Local auth** is simulated with `LOCAL_DEV_EMAIL=dev@lakemeter.local`
  (set in `docker-compose.yml`).
- Data persists in Docker volumes. Reset everything with
  `docker compose down -v`.
