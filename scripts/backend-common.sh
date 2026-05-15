#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "backend-common.sh is a helper. Source it from another script."
  exit 1
fi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$REPO_ROOT/backend/kerosene"
INFRA_DIR="$REPO_ROOT/backend/kerosene-infrastructure"
COMPOSE_FILE="$INFRA_DIR/docker-compose.local.yml"
ENV_FILE="$BACKEND_DIR/.env"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-kerosene-infrastructure}"

info() { echo "[backend] $*"; }
warn() { echo "[backend][warn] $*" >&2; }
fail() { echo "[backend][error] $*" >&2; exit 1; }

require_file() {
  local file="$1"
  [[ -f "$file" ]] || fail "Required file not found: $file"
}

require_docker() {
  command -v docker >/dev/null 2>&1 || fail "Docker CLI not found."
  docker info >/dev/null 2>&1 || fail "Docker is not running or is not accessible."
}

load_backend_env() {
  require_file "$ENV_FILE"
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
}

detect_compose() {
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose)
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(docker-compose)
  elif command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(podman compose)
  else
    fail "Docker Compose was not found. Install 'docker compose' or 'docker-compose'."
  fi
}

compose() {
  require_file "$COMPOSE_FILE"
  require_file "$ENV_FILE"
  detect_compose
  COMPOSE_PROJECT_NAME="$COMPOSE_PROJECT_NAME" "${COMPOSE_CMD[@]}" \
    --project-name "$COMPOSE_PROJECT_NAME" \
    --env-file "$ENV_FILE" \
    -f "$COMPOSE_FILE" \
    "$@"
}
