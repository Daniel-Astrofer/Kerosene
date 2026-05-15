#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"

REMOVE_VOLUMES=0

usage() {
  cat <<'EOF'
Usage: scripts/stop-local.sh [--volumes]

Options:
  --volumes   Also remove local PostgreSQL, Redis, Tor and MPC Docker volumes.
  -h, --help  Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --volumes) REMOVE_VOLUMES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1" ;;
  esac
  shift
done

DOWN_ARGS=(down --remove-orphans)
if [[ "$REMOVE_VOLUMES" -eq 1 ]]; then
  DOWN_ARGS+=(--volumes)
fi

compose "${DOWN_ARGS[@]}"
