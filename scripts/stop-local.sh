#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"

REMOVE_VOLUMES=0
FRONTEND_DIR="$REPO_ROOT/frontend"
FRONTEND_PID_FILE="$FRONTEND_DIR/.dart_tool/kerosene-local-web.pid"

usage() {
  cat <<'EOF'
Usage: scripts/stop-local.sh [--volumes]

Options:
  --volumes   Also remove local PostgreSQL, Redis, Tor and MPC Docker volumes.
  -h, --help  Show this help.
EOF
}

stop_frontend() {
  local pid="" command_line=""
  if [[ ! -f "$FRONTEND_PID_FILE" ]]; then
    return
  fi

  pid="$(tr -d '[:space:]' < "$FRONTEND_PID_FILE" || true)"
  if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
    command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    if grep -Fq "$FRONTEND_DIR/build/web" <<<"$command_line"; then
      info "Stopping Flutter web frontend (pid $pid)."
      kill "$pid" 2>/dev/null || true
    else
      warn "Ignoring stale frontend PID $pid because it does not match the local web server."
    fi
  fi

  rm -f "$FRONTEND_PID_FILE"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --volumes) REMOVE_VOLUMES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1" ;;
  esac
  shift
done

stop_frontend

DOWN_ARGS=(down --remove-orphans)
if [[ "$REMOVE_VOLUMES" -eq 1 ]]; then
  DOWN_ARGS+=(--volumes)
fi

compose "${DOWN_ARGS[@]}"
