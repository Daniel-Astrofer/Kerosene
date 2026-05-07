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

db_accepts_target_credentials() {
  local service="$1"
  compose exec -T "$service" sh -lc \
    'PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "${POSTGRES_DB:-kerosene}" -tAc "SELECT 1"' \
    >/dev/null 2>&1
}

wait_for_db_service() {
  local service="$1"
  local deadline now
  deadline=$(( $(date +%s) + DB_WAIT_TIMEOUT_SECONDS ))

  while true; do
    if db_accepts_target_credentials "$service"; then
      return 0
    fi

    now=$(date +%s)
    if (( now >= deadline )); then
      return 1
    fi

    sleep 2
  done
}

set_temporary_local_trust() {
  local service="$1"
  compose exec -T -u root "$service" sh -lc '
    set -eu
    backup="/tmp/pg_hba.conf.kerosene-local-repair"
    cp "$PGDATA/pg_hba.conf" "$backup"
    {
      printf "%s\n" "local all all trust"
      printf "%s\n" "host all all 0.0.0.0/0 scram-sha-256"
    } > "$PGDATA/pg_hba.conf"
    chown postgres:postgres "$PGDATA/pg_hba.conf"
    kill -HUP 1
  '
}

restore_pg_hba() {
  local service="$1"
  compose exec -T -u root "$service" sh -lc '
    set -eu
    backup="/tmp/pg_hba.conf.kerosene-local-repair"
    if [ -f "$backup" ]; then
      cp "$backup" "$PGDATA/pg_hba.conf"
      chown postgres:postgres "$PGDATA/pg_hba.conf"
      rm -f "$backup"
      kill -HUP 1
    fi
  ' >/dev/null 2>&1 || true
}

discover_repair_users() {
  local service="$1"
  {
    printf '%s\n' postgres kerosene_admin api_system
    compose exec -T -u root "$service" sh -lc \
      'grep -aEo "[A-Za-z_][A-Za-z0-9_]{2,}" "$PGDATA/global/1260" 2>/dev/null | grep -Ev "^(pg_|SCRAM$|SHA$)" | sort -u' \
      2>/dev/null || true
  } | awk 'NF && !seen[$0]++'
}

can_connect_as_repair_user() {
  local service="$1"
  local candidate="$2"
  compose exec -T -u postgres -e KEROSENE_DB_REPAIR_USER="$candidate" "$service" sh -lc \
    'psql -v ON_ERROR_STOP=1 -U "$KEROSENE_DB_REPAIR_USER" -d postgres -tAc "SELECT 1"' \
    >/dev/null 2>&1
}

repair_db_credentials_if_needed() {
  local service="$1"
  local repair_user=""
  local candidate

  if db_accepts_target_credentials "$service"; then
    return 0
  fi

  warn "$service is running, but the configured POSTGRES_USER cannot authenticate. Attempting local role repair for persisted volumes."
  set_temporary_local_trust "$service"

  for candidate in $(discover_repair_users "$service"); do
    if can_connect_as_repair_user "$service" "$candidate"; then
      repair_user="$candidate"
      break
    fi
  done

  if [[ -z "$repair_user" ]]; then
    restore_pg_hba "$service"
    fail "Could not find an existing local PostgreSQL superuser in $service for role repair."
  fi

  if ! compose exec -T -u postgres -e KEROSENE_DB_REPAIR_USER="$repair_user" "$service" sh -lc '
    set -eu
    target_user="${POSTGRES_USER:-}"
    target_db="${POSTGRES_DB:-kerosene}"
    case "$target_user" in ""|*[!A-Za-z0-9_]*)
      echo "Invalid POSTGRES_USER for local repair." >&2
      exit 1
      ;;
    esac
    case "$target_db" in ""|*[!A-Za-z0-9_]*)
      echo "Invalid POSTGRES_DB for local repair." >&2
      exit 1
      ;;
    esac

    password_sql=$(printf "%s" "${POSTGRES_PASSWORD:-}" | sed "s/'\''/'\'''\''/g")
    psql -v ON_ERROR_STOP=1 -U "$KEROSENE_DB_REPAIR_USER" -d postgres -c "DO \$\$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '\''${target_user}'\'') THEN ALTER ROLE ${target_user} WITH LOGIN SUPERUSER PASSWORD '\''${password_sql}'\''; ELSE CREATE ROLE ${target_user} WITH LOGIN SUPERUSER PASSWORD '\''${password_sql}'\''; END IF; END \$\$;" >/dev/null
    if ! psql -v ON_ERROR_STOP=1 -U "$KEROSENE_DB_REPAIR_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '\''${target_db}'\''" | grep -qx 1; then
      psql -v ON_ERROR_STOP=1 -U "$KEROSENE_DB_REPAIR_USER" -d postgres -c "CREATE DATABASE ${target_db} OWNER ${target_user}" >/dev/null
    fi
    psql -v ON_ERROR_STOP=1 -U "$KEROSENE_DB_REPAIR_USER" -d postgres -c "ALTER DATABASE ${target_db} OWNER TO ${target_user}" >/dev/null
    psql -v ON_ERROR_STOP=1 -U "$KEROSENE_DB_REPAIR_USER" -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${target_db} TO ${target_user}" >/dev/null
  '; then
    restore_pg_hba "$service"
    fail "Failed to repair PostgreSQL role for $service."
  fi

  restore_pg_hba "$service"
  db_accepts_target_credentials "$service" || fail "PostgreSQL role repair completed, but $service still rejects configured credentials."
  info "Repaired local PostgreSQL role for $service."
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
  repair_db_credentials_if_needed "$service"
  wait_for_db_service "$service" || fail "Timed out waiting for $service to become ready."
  apply_migration "$service"
done

info "Local database migrations completed."
