#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"

ARM_VAULT=1
BUILD=1
DETACH=1
COMPOSE_SERVICES=()

usage() {
  cat <<'EOF'
Usage: scripts/start-local.sh [options] [compose-service...]

Options:
  --no-arm       Do not call scripts/arm-vault.sh after containers start.
  --no-build     Start without rebuilding Docker images.
  --foreground   Run docker compose in the foreground.
  -h, --help     Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-arm) ARM_VAULT=0 ;;
    --no-build) BUILD=0 ;;
    --foreground) DETACH=0 ;;
    -h|--help) usage; exit 0 ;;
    *) COMPOSE_SERVICES+=("$1") ;;
  esac
  shift
done

require_docker
"$INFRA_DIR/scripts/init-local.sh"

UP_ARGS=(up)
if [[ "$DETACH" -eq 1 ]]; then
  UP_ARGS+=(-d)
fi
if [[ "$BUILD" -eq 1 ]]; then
  UP_ARGS+=(--build)
fi

info "Starting local backend cluster with $COMPOSE_FILE"
compose "${UP_ARGS[@]}" "${COMPOSE_SERVICES[@]}"

if [[ "$DETACH" -eq 1 && "$ARM_VAULT" -eq 1 ]]; then
  info "Waiting for Vault container before arming..."
  sleep 5
  "$SCRIPT_DIR/arm-vault.sh" || warn "Vault arming failed. Run scripts/arm-vault.sh manually after checking logs."
fi

info "Backend cluster command completed."
info "Logs: scripts/logs-local.sh"
info "Stop: scripts/stop-local.sh"
