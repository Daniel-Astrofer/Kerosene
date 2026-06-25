#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"
# shellcheck source=scripts/flutter-common.sh
source "$SCRIPT_DIR/flutter-common.sh"

ARM_VAULT=1
BUILD=1
DETACH=1
RUN_MIGRATIONS=1
FORCE_MIGRATIONS=0
VERBOSE_MIGRATIONS=0
START_FRONTEND=0
FRONTEND_BUILD=1
COMPOSE_SERVICES=()
MASTER_KEY_WAIT_TIMEOUT_SECONDS=240
FRONTEND_DIR="$REPO_ROOT/frontend"
FRONTEND_BUILD_DIR="$FRONTEND_DIR/build/web"
BACKEND_WEB_ADMIN_BUILD_DIR="$BACKEND_DIR/web-admin-build"
FRONTEND_LOG_DIR="$FRONTEND_DIR/logs"
FRONTEND_BUILD_LOG_FILE="$FRONTEND_LOG_DIR/local-web-build.log"
FRONTEND_LOG_FILE="$FRONTEND_LOG_DIR/local-web-server.log"
FRONTEND_PID_FILE="$FRONTEND_DIR/.dart_tool/kerosene-local-web.pid"
FRONTEND_RUNTIME_CONFIG_FILE="$FRONTEND_BUILD_DIR/kerosene-runtime-config.json"
FRONTEND_WEB_PORT_EXPLICIT="${FRONTEND_WEB_PORT+x}"
FRONTEND_PUBLIC_URL_EXPLICIT="${FRONTEND_PUBLIC_URL+x}"
FRONTEND_WEB_HOST="${FRONTEND_WEB_HOST:-127.0.0.1}"
FRONTEND_WEB_PORT="${FRONTEND_WEB_PORT:-3000}"
FRONTEND_PUBLIC_URL="${FRONTEND_PUBLIC_URL:-http://localhost:${FRONTEND_WEB_PORT}}"
FRONTEND_API_URL="${FRONTEND_API_URL:-}"
FRONTEND_PASSKEY_RP_ID="${FRONTEND_PASSKEY_RP_ID:-kerosene-device}"
FRONTEND_PASSKEY_ORIGIN="${FRONTEND_PASSKEY_ORIGIN:-android:apk-key-hash:kerosene}"

usage() {
  cat <<'EOF'
Usage: scripts/start-local.sh [options] [compose-service...]

Options:
  --no-arm       Do not call scripts/arm-vault.sh after containers start.
  --no-build     Start without rebuilding Docker images or Flutter web.
  --frontend-server
                 Also start a separate localhost Flutter web server for dev.
                 Tor Browser access does not use this; the backend serves web.
  --no-frontend  Legacy no-op; web admin is served by the backend.
  --no-frontend-build
                 Serve the existing Flutter build/web output if present.
  --skip-migrations
                 Start containers without applying local database migrations.
  --force-migrations
                 Re-run all SQL migrations even if the local checksum cache says
                 they are already applied.
  --verbose-migrations
                 Print successful psql output while applying migrations.
  --foreground   Run docker compose in the foreground.
  -h, --help     Show this help.
EOF
}

maybe_enable_redis_overcommit() {
  if ! command -v sysctl >/dev/null 2>&1; then
    return
  fi

  local current
  current="$(sysctl -n vm.overcommit_memory 2>/dev/null || true)"
  if [[ "$current" == "1" ]]; then
    return
  fi

  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    info "Setting vm.overcommit_memory=1 to avoid Redis background-save warnings."
    sysctl -w vm.overcommit_memory=1 >/dev/null || warn "Failed to set vm.overcommit_memory=1 automatically."
  else
    warn "Host vm.overcommit_memory=${current:-unknown}. Redis will warn until you run: sudo sysctl -w vm.overcommit_memory=1"
  fi
}

service_has_master_key() {
  local service="$1"
  compose logs --no-color --tail 2000 "$service" 2>/dev/null | grep -Eq \
    "Master key securely locked in RAM\\.|SUCCESS: Master key provisioned on attempt" && return 0

  # In this local profile, VaultBootstrapCoordinator blocks startup until the
  # master key is provisioned. If noisy scheduled logs pushed the bootstrap
  # marker out of the tail window, a healthy app container is a safe fallback.
  service_is_healthy "$service"
}

prepare_backend_web_admin() {
  if [[ "$FRONTEND_BUILD" -ne 1 ]]; then
    if [[ ! -f "$BACKEND_WEB_ADMIN_BUILD_DIR/index.html" ]]; then
      warn "No embedded web admin build found at $BACKEND_WEB_ADMIN_BUILD_DIR/index.html."
      warn "Tor Browser will show backend status instead of the panel until you run scripts/build-web-admin-backend.sh."
    fi
    return
  fi

  "$SCRIPT_DIR/build-web-admin-backend.sh" --no-jar
}

service_is_healthy() {
  local service="$1"
  local container_id health
  container_id="$(compose ps -q "$service" 2>/dev/null | head -n 1 || true)"
  [[ -n "$container_id" ]] || return 1
  health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id" 2>/dev/null || true)"
  [[ "$health" == "healthy" ]]
}

print_container_health_summary() {
  local service="$1"
  local container_id status health_log
  container_id="$(compose ps -q "$service" 2>/dev/null | head -n 1 || true)"
  [[ -n "$container_id" ]] || return 0

  status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id" 2>/dev/null || true)"
  [[ -n "$status" ]] || status="unknown"
  warn "Health for ${service}: ${status}"

  health_log="$(docker inspect -f '{{if .State.Health}}{{range .State.Health.Log}}{{.End}} exit={{.ExitCode}} {{.Output}}{{end}}{{end}}' "$container_id" 2>/dev/null || true)"
  if [[ -n "$health_log" ]]; then
    printf '%s\n' "$health_log" | tail -n 12 >&2 || true
  fi
}

print_compose_start_diagnostics() {
  warn "docker compose failed during startup. Collecting local health diagnostics..."
  compose ps -a >&2 || true

  local service
  for service in \
    bitcoin-core lnd-neutrino lnd-bootstrap lnd-unlocker \
    vault-raft-1 vault-raft-2 vault-raft-3 vault-raft-bootstrap \
    server-wvo server-iw5 server-ltv \
    vanguards-wvo vanguards-iw5 vanguards-ltv \
    tor-wvo tor-iw5 tor-ltv \
    kerosene-vault mpc-sidecar-wvo mpc-sidecar-iw5 mpc-sidecar-ltv \
    db-wvo db-iw5 db-ltv redis-wvo redis-iw5 redis-ltv; do
    print_container_health_summary "$service"
  done

  warn "Recent logs from critical services:"
  compose logs --no-color --tail 80 \
    bitcoin-core lnd-neutrino lnd-bootstrap lnd-unlocker \
    vault-raft-1 vault-raft-2 vault-raft-3 vault-raft-bootstrap \
    server-wvo server-iw5 server-ltv \
    vanguards-wvo vanguards-iw5 vanguards-ltv \
    kerosene-vault mpc-sidecar-wvo mpc-sidecar-iw5 mpc-sidecar-ltv >&2 || true
}

refresh_vault_raft_bootstrap() {
  if [[ "${#COMPOSE_SERVICES[@]}" -gt 0 ]]; then
    return
  fi

  local bootstrap_container exit_file
  bootstrap_container="$(compose ps -a -q vault-raft-bootstrap 2>/dev/null | head -n 1 || true)"
  [[ -n "$bootstrap_container" ]] || return
  exit_file="$(mktemp "${TMPDIR:-/tmp}/kerosene-vault-raft-bootstrap.XXXXXX")"

  info "Refreshing Vault Raft bootstrap/unseal state..."
  compose start vault-raft-bootstrap >/dev/null || {
    warn "Could not start vault-raft-bootstrap. App startup may fail if Vault Raft is sealed."
    rm -f "$exit_file"
    return
  }

  if ! timeout 180s docker wait "$bootstrap_container" >"$exit_file" 2>/dev/null; then
    warn "Timed out waiting for vault-raft-bootstrap to complete."
    compose logs --no-color --tail 80 vault-raft-bootstrap >&2 || true
    rm -f "$exit_file"
    return
  fi

  local exit_code
  exit_code="$(tr -d '[:space:]' < "$exit_file" || true)"
  rm -f "$exit_file"
  if [[ "$exit_code" != "0" ]]; then
    warn "vault-raft-bootstrap exited with code ${exit_code:-unknown}."
    compose logs --no-color --tail 80 vault-raft-bootstrap >&2 || true
  fi
}

validate_local_runtime_env() {
  local missing=() var
  for var in BITCOIN_RPC_PASSWORD LND_WALLET_PASSWORD; do
    if [[ -z "${!var:-}" ]]; then
      missing+=("$var")
    fi
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    fail "Missing required local runtime variables after loading $ENV_FILE: ${missing[*]}"
  fi
}

read_onion_hostname() {
  local tor_service="$1"
  { compose exec -T "$tor_service" /bin/sh -lc 'cat /var/lib/tor/kerosene_service/hostname 2>/dev/null' 2>/dev/null || true; } \
    | tr -d '\r' \
    | tail -n 1
}

print_onion_addresses() {
  local vault_onion is_onion ch_onion sg_onion
  vault_onion="$(read_onion_hostname kerosene-tor-vault)"
  is_onion="$(read_onion_hostname tor-wvo)"
  ch_onion="$(read_onion_hostname tor-iw5)"
  sg_onion="$(read_onion_hostname tor-ltv)"

  info "Onion addresses:"
  info "  Vault: ${vault_onion:-unavailable}"
  info "  IS: ${is_onion:-unavailable}"
  info "  CH: ${ch_onion:-unavailable}"
  info "  SG: ${sg_onion:-unavailable}"
}

wait_for_master_keys_and_print_onions() {
  local deadline now
  deadline=$(( $(date +%s) + MASTER_KEY_WAIT_TIMEOUT_SECONDS ))

  info "Waiting for IS, CH, and SG shards to provision the master key..."
  while true; do
    if service_has_master_key server-wvo &&
       service_has_master_key server-iw5 &&
       service_has_master_key server-ltv; then
      info "All shards provisioned the master key."
      print_onion_addresses
      return 0
    fi

    now=$(date +%s)
    if (( now >= deadline )); then
      warn "Timed out waiting for all shards to provision the master key."
      print_onion_addresses
      return 1
    fi

    sleep 2
  done
}

frontend_pid_is_running() {
  local pid="$1"
  local command_line
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
  grep -Fq "$FRONTEND_BUILD_DIR" <<<"$command_line"
}

frontend_http_is_ready() {
  command -v curl >/dev/null 2>&1 || return 1
  curl -fsS "$FRONTEND_PUBLIC_URL" >/dev/null 2>&1
}

configure_frontend_runtime() {
  if [[ -z "$FRONTEND_API_URL" ]]; then
    FRONTEND_API_URL="http://localhost:${APP_WVO_PORT:-8080}"
  fi

  local web_admin_port="${WEB_ADMIN_PORT:-3000}"
  if [[ -z "$FRONTEND_WEB_PORT_EXPLICIT" &&
        -z "$FRONTEND_PUBLIC_URL_EXPLICIT" &&
        "$FRONTEND_WEB_PORT" =~ ^[0-9]+$ &&
        "$web_admin_port" =~ ^[0-9]+$ &&
        "$FRONTEND_WEB_PORT" == "$web_admin_port" ]]; then
    FRONTEND_WEB_PORT="$((web_admin_port + 1))"
    FRONTEND_PUBLIC_URL="http://localhost:${FRONTEND_WEB_PORT}"
    info "Frontend dev server port ${web_admin_port} is reserved by web-admin; using ${FRONTEND_WEB_PORT}."
  fi
}

write_frontend_runtime_config() {
  mkdir -p "$FRONTEND_BUILD_DIR"
  python3 - "$FRONTEND_RUNTIME_CONFIG_FILE" "$FRONTEND_API_URL" "$FRONTEND_PUBLIC_URL" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
api_url = sys.argv[2].rstrip("/")
frontend_url = sys.argv[3].rstrip("/")

payload = {
    "apiUrl": api_url,
    "frontendUrl": frontend_url,
    "source": "scripts/start-local.sh",
}
path.write_text(json.dumps(payload, separators=(",", ":")) + "\n", encoding="utf-8")
PY
  info "Wrote frontend runtime API config: $FRONTEND_RUNTIME_CONFIG_FILE -> $FRONTEND_API_URL"
}

start_frontend() {
  if [[ "$START_FRONTEND" -ne 1 ]]; then
    return
  fi

  configure_frontend_runtime

  if [[ "$DETACH" -ne 1 ]]; then
    warn "Foreground mode skips automatic Flutter web startup."
    return
  fi

  if [[ "${#COMPOSE_SERVICES[@]}" -gt 0 ]]; then
    warn "Specific compose services were requested; skipping automatic Flutter web startup."
    return
  fi

  if [[ ! -f "$FRONTEND_DIR/pubspec.yaml" ]]; then
    warn "Frontend pubspec not found at $FRONTEND_DIR/pubspec.yaml; backend is up, but frontend was not started."
    return
  fi

  local flutter_bin
  if ! flutter_bin="$(kerosene_resolve_flutter_bin "$FRONTEND_DIR")"; then
    warn "Flutter CLI not found for the non-root build user; backend is up, but frontend was not started."
    return
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    warn "python3 not found; backend is up, but frontend was not started."
    return
  fi

  local pid=""
  if [[ -f "$FRONTEND_PID_FILE" ]]; then
    pid="$(tr -d '[:space:]' < "$FRONTEND_PID_FILE" || true)"
    if frontend_pid_is_running "$pid"; then
      info "Flutter web frontend is already running at $FRONTEND_PUBLIC_URL (pid $pid)."
      return
    fi
    rm -f "$FRONTEND_PID_FILE"
  fi

  mkdir -p "$FRONTEND_LOG_DIR" "$(dirname "$FRONTEND_PID_FILE")"
  kerosene_chown_sudo_user "$FRONTEND_DIR/.dart_tool" "$FRONTEND_DIR/build" "$FRONTEND_LOG_DIR" "$(dirname "$FRONTEND_PID_FILE")"
  if [[ "$FRONTEND_BUILD" -eq 1 || ! -f "$FRONTEND_BUILD_DIR/index.html" ]]; then
    info "Building Flutter web frontend for $FRONTEND_PUBLIC_URL (API: $FRONTEND_API_URL)."
    (
      cd "$FRONTEND_DIR"
      FLUTTER_BUILD_ARGS=(web --release --csp --no-web-resources-cdn --target lib/web_main.dart)
      if [[ "${FLUTTER_BUILD_NO_PUB:-0}" == "1" ]]; then
        FLUTTER_BUILD_ARGS+=(--no-pub)
      fi
      kerosene_run_flutter "$flutter_bin" build "${FLUTTER_BUILD_ARGS[@]}" \
        --dart-define="WEB_API_URL=$FRONTEND_API_URL" \
        --dart-define="PASSKEY_RP_ID=$FRONTEND_PASSKEY_RP_ID" \
        --dart-define="PASSKEY_ORIGIN=$FRONTEND_PASSKEY_ORIGIN"
    ) > "$FRONTEND_BUILD_LOG_FILE" 2>&1 || {
      kerosene_chown_sudo_user "$FRONTEND_DIR/.dart_tool" "$FRONTEND_DIR/build" "$FRONTEND_LOG_DIR" "$(dirname "$FRONTEND_PID_FILE")"
      warn "Flutter web build failed. See $FRONTEND_BUILD_LOG_FILE"
      tail -n 80 "$FRONTEND_BUILD_LOG_FILE" >&2 || true
      return
    }
  else
    info "Using existing Flutter web build at $FRONTEND_BUILD_DIR."
  fi
  kerosene_chown_sudo_user "$FRONTEND_DIR/.dart_tool" "$FRONTEND_DIR/build" "$FRONTEND_LOG_DIR" "$(dirname "$FRONTEND_PID_FILE")"
  write_frontend_runtime_config

  info "Serving Flutter web frontend at $FRONTEND_PUBLIC_URL."
  if command -v setsid >/dev/null 2>&1; then
    (
      nohup setsid python3 -m http.server "$FRONTEND_WEB_PORT" \
        --bind "$FRONTEND_WEB_HOST" \
        --directory "$FRONTEND_BUILD_DIR" \
        > "$FRONTEND_LOG_FILE" 2>&1 < /dev/null &
      printf '%s\n' "$!" > "$FRONTEND_PID_FILE"
    )
  else
    (
      nohup python3 -m http.server "$FRONTEND_WEB_PORT" \
        --bind "$FRONTEND_WEB_HOST" \
        --directory "$FRONTEND_BUILD_DIR" \
        > "$FRONTEND_LOG_FILE" 2>&1 < /dev/null &
      printf '%s\n' "$!" > "$FRONTEND_PID_FILE"
    )
  fi

  pid="$(tr -d '[:space:]' < "$FRONTEND_PID_FILE" || true)"
  local deadline now
  deadline=$(( $(date +%s) + 90 ))
  while true; do
    if frontend_http_is_ready; then
      info "Flutter web frontend is ready at $FRONTEND_PUBLIC_URL"
      info "Frontend logs: $FRONTEND_LOG_FILE"
      return
    fi

    if ! frontend_pid_is_running "$pid"; then
      warn "Flutter web frontend exited during startup. See $FRONTEND_LOG_FILE"
      tail -n 40 "$FRONTEND_LOG_FILE" >&2 || true
      return
    fi

    now=$(date +%s)
    if (( now >= deadline )); then
      warn "Timed out waiting for Flutter web frontend. It may still be compiling. Logs: $FRONTEND_LOG_FILE"
      return
    fi

    sleep 2
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-arm) ARM_VAULT=0 ;;
    --no-build) BUILD=0; FRONTEND_BUILD=0 ;;
    --frontend-server) START_FRONTEND=1 ;;
    --no-frontend) START_FRONTEND=0 ;;
    --no-frontend-build) FRONTEND_BUILD=0 ;;
    --skip-migrations) RUN_MIGRATIONS=0 ;;
    --force-migrations) FORCE_MIGRATIONS=1 ;;
    --verbose-migrations) VERBOSE_MIGRATIONS=1 ;;
    --foreground) DETACH=0 ;;
    -h|--help) usage; exit 0 ;;
    *) COMPOSE_SERVICES+=("$1") ;;
  esac
  shift
done

"$INFRA_DIR/scripts/init-local.sh"
load_backend_env
validate_local_runtime_env
require_docker
maybe_enable_redis_overcommit
prepare_backend_web_admin

UP_ARGS=(up)
if [[ "$DETACH" -eq 1 ]]; then
  UP_ARGS+=(-d)
fi
if [[ "$BUILD" -eq 1 ]]; then
  UP_ARGS+=(--build)
fi

info "Starting local backend cluster with $COMPOSE_FILE"
if ! compose "${UP_ARGS[@]}" "${COMPOSE_SERVICES[@]}"; then
  print_compose_start_diagnostics
  exit 1
fi

if [[ "$DETACH" -eq 1 ]]; then
  refresh_vault_raft_bootstrap
fi

if [[ "$DETACH" -eq 1 && "$RUN_MIGRATIONS" -eq 1 ]]; then
  KEROSENE_FORCE_MIGRATIONS="$FORCE_MIGRATIONS" \
    KEROSENE_MIGRATION_VERBOSE="$VERBOSE_MIGRATIONS" \
    "$SCRIPT_DIR/migrate-local-db.sh"
elif [[ "$DETACH" -eq 1 ]]; then
  warn "Skipping local DB migrations by request. Run scripts/migrate-local-db.sh before testing schema changes."
else
  warn "Foreground mode skips automatic local DB migrations. Run scripts/migrate-local-db.sh in another terminal if you reuse persisted volumes."
fi

if [[ "$DETACH" -eq 1 && "$ARM_VAULT" -eq 1 ]]; then
  info "Waiting for Vault container before arming..."
  sleep 5
  "$SCRIPT_DIR/arm-vault.sh" || warn "Vault arming failed. Run scripts/arm-vault.sh manually after checking logs."
  wait_for_master_keys_and_print_onions || true
fi

start_frontend

info "Backend cluster command completed."
info "Logs: scripts/logs-local.sh -- use --raw for unfiltered Docker logs"
info "Stop: scripts/stop-local.sh"
