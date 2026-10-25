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
   overwriting `frontend/vite.config.ts` with the Docker-ready version):

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
- `frontend/Dockerfile` + `frontend/.dockerignore` — Vite dev server (Node 20)
- `frontend/vite.config.ts` — proxy target made configurable via `VITE_PROXY_TARGET`, plus a `/static` proxy for the pricing bundle

## Notes

- **npm registry**: the upstream `package-lock.json` pins some packages to
  Databricks' internal npm mirror. The frontend Dockerfile rewrites those URLs
  to the public registry at build time (lockfile integrity hashes still match).
- **PostgreSQL runs with SSL** (self-signed cert) because the backend hardcodes
  `sslmode=require`, matching production Lakebase behavior.
- **AI chat** needs a Databricks workspace (`DATABRICKS_HOST` +
  `CLAUDE_MODEL_ENDPOINT`) and will not work locally; all other features
  (estimates, calculator, pricing, Excel export) are fully functional.
- **Local auth** is simulated with `LOCAL_DEV_EMAIL=dev@lakemeter.local`
  (set in `docker-compose.yml`).
- Data persists in Docker volumes. Reset everything with
  `docker compose down -v`.
