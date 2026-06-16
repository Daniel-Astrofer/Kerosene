#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/status-local.sh [options]

Animated local Kerosene operations dashboard. It renders Docker health and
sanitized application request events without changing the structured audit logs.

Options:
  --once             Render one snapshot and exit.
  --no-color         Disable ANSI colors.
  --tail N           Number of recent application log lines to seed the feed.
  --interval SECONDS Dashboard refresh interval. Default: 1.0.
  --all-logs         Follow all compose services instead of only app services.
  --self-test        Run dashboard parser/sanitizer tests.
  -h, --help         Show this help.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
  esac
done

command -v python3 >/dev/null 2>&1 || fail "python3 is required for the local dashboard."

if [[ "${1:-}" != "--self-test" ]]; then
  require_docker
fi

detect_compose

COMPOSE_FILES=("$COMPOSE_FILE")
if [[ "${KEROSENE_COMPOSE_RESOURCE_LIMITS:-1}" != "0" ]]; then
  COMPOSE_FILES+=("$COMPOSE_LIMITS_FILE")
fi

PY_ARGS=(
  "$SCRIPT_DIR/status_dashboard.py"
  --compose-command "${COMPOSE_CMD[*]}"
  --project-name "$COMPOSE_PROJECT_NAME"
  --env-file "$ENV_FILE"
)

for compose_file in "${COMPOSE_FILES[@]}"; do
  PY_ARGS+=(--compose-file "$compose_file")
done

exec python3 "${PY_ARGS[@]}" "$@"
