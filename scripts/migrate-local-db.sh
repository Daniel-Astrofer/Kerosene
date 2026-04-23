#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"

MIGRATION_FILE="$BACKEND_DIR/src/main/resources/db/migration.sql"
DB_WAIT_TIMEOUT_SECONDS=90
DB_SERVICES=("$@")

usage() {
  cat <<'EOF'
Usage: scripts/migrate-local-db.sh [db-service...]

Applies backend/kerosene/src/main/resources/db/migration.sql to running local
PostgreSQL services. If no services are provided, it targets db-is, db-ch, db-sg.
EOF
}

if [[ ${#DB_SERVICES[@]} -eq 0 ]]; then
  DB_SERVICES=(db-is db-ch db-sg)
fi

if [[ "${DB_SERVICES[0]}" == "-h" || "${DB_SERVICES[0]}" == "--help" ]]; then
  usage
  exit 0
fi

require_file "$MIGRATION_FILE"
require_docker

service_is_running() {
  local service="$1"
  compose ps --services --status running | grep -Fxq "$service"
}

wait_for_db_service() {
  local service="$1"
  local deadline now
  deadline=$(( $(date +%s) + DB_WAIT_TIMEOUT_SECONDS ))

  while true; do
    if compose exec -T "$service" sh -lc \
      'PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "${POSTGRES_DB:-kerosene}" -tAc "SELECT 1"' \
      >/dev/null 2>&1; then
      return 0
    fi

    now=$(date +%s)
    if (( now >= deadline )); then
      return 1
    fi

    sleep 2
  done
}

apply_migration() {
  local service="$1"
  info "Applying schema migration to $service..."
  compose exec -T "$service" sh -lc \
    'PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "${POSTGRES_DB:-kerosene}" -f -' \
    < "$MIGRATION_FILE"
}

for service in "${DB_SERVICES[@]}"; do
  if ! service_is_running "$service"; then
    warn "Skipping $service because it is not running."
    continue
  fi

  info "Waiting for $service to accept connections..."
  wait_for_db_service "$service" || fail "Timed out waiting for $service to become ready."
  apply_migration "$service"
done

info "Local database migrations completed."
