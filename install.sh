#!/usr/bin/env bash
#
# Lakemeter local Docker setup installer.
#
# Clones the upstream Lakemeter repository (if needed), overlays this
# repo's Docker additions, and starts the stack with docker compose.
#
set -euo pipefail

BASE_REPO_URL="https://github.com/databrickslabs/lakemeter-oss.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET=""
SKIP_CLONE=false
NO_START=false
NO_BUILD=false

usage() {
  cat <<EOF
Usage: $0 [options]

Installs and starts Lakemeter locally with Docker.

Options:
  --target DIR     Directory for the Lakemeter source repo
                   (default: $SCRIPT_DIR/../lakemeter-oss)
  --skip-clone     Do not clone the base repository if DIR is missing
  --no-build       Skip image builds (use existing images)
  --no-start       Only prepare files; do not start the stack
  -h, --help       Show this help

Steps:
  1. Clone $BASE_REPO_URL into DIR when it does not exist
  2. Copy backend/, frontend/, docker-compose.yml and .env.example from
     this repo into DIR (overwriting the Docker/OpenAI-ready files)
  3. Create DIR/.env from .env.example if missing
  4. Run 'docker compose up -d --build' in DIR
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --skip-clone) SKIP_CLONE=true; shift ;;
    --no-build) NO_BUILD=true; shift ;;
    --no-start) NO_START=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

TARGET="${TARGET:-$SCRIPT_DIR/../lakemeter-oss}"
TARGET="$(realpath -m "$TARGET")"

if [[ "$TARGET" == "$SCRIPT_DIR" ]]; then
  echo "ERROR: --target must not be the installer repo itself" >&2
  exit 1
fi

# --- 1. Clone the base repository if needed ---
if [[ ! -d "$TARGET" ]]; then
  if $SKIP_CLONE; then
    echo "ERROR: $TARGET does not exist and --skip-clone was given" >&2
    exit 1
  fi
  echo "Cloning $BASE_REPO_URL into $TARGET ..."
  git clone --depth 1 "$BASE_REPO_URL" "$TARGET"
elif [[ -d "$TARGET/.git" ]]; then
  echo "Using existing checkout: $TARGET"
else
  echo "Using existing directory (not a git repo): $TARGET"
fi

# --- 2. Prerequisites ---
command -v docker >/dev/null 2>&1 || { echo "ERROR: docker is not installed" >&2; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "ERROR: docker compose is not available" >&2; exit 1; }

# --- 3. Overlay the Docker additions ---
echo "Copying Docker additions into $TARGET ..."
cp -a "$SCRIPT_DIR/backend" "$TARGET/"
cp -a "$SCRIPT_DIR/frontend" "$TARGET/"
cp "$SCRIPT_DIR/docker-compose.yml" "$TARGET/"
if [[ -f "$SCRIPT_DIR/.env.example" ]]; then
  cp "$SCRIPT_DIR/.env.example" "$TARGET/"
fi

# --- 4. Create .env if missing ---
if [[ ! -f "$TARGET/.env" ]] && [[ -f "$TARGET/.env.example" ]]; then
  cp "$TARGET/.env.example" "$TARGET/.env"
  echo "Created $TARGET/.env from .env.example."
  echo "Edit it to configure the AI chat backend (OPENAI_BASE_URL / OPENAI_API_KEY / OPENAI_MODEL)."
fi

# --- 5. Start the stack ---
if $NO_START; then
  echo "Skipping stack start (--no-start)."
  echo "Run: cd $TARGET && docker compose up -d --build"
  exit 0
fi

echo "Starting the stack (first start builds images and bootstraps the database)..."
cd "$TARGET"
if $NO_BUILD; then
  docker compose up -d
else
  docker compose up -d --build
fi

# --- 6. Wait for the backend ---
echo "Waiting for the backend to become healthy..."
for _ in $(seq 1 90); do
  if curl -fsS http://localhost:8000/health >/dev/null 2>&1; then
    echo
    echo "Lakemeter is running:"
    echo "  Frontend:  http://localhost:5173"
    echo "  API:       http://localhost:8000"
    echo "  API docs:  http://localhost:8000/api/docs"
    exit 0
  fi
  sleep 2
done

echo "WARNING: backend did not become healthy within 3 minutes." >&2
echo "Check logs with: cd $TARGET && docker compose logs backend" >&2
exit 1
