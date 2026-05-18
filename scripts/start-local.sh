#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"

ARM_VAULT=1
BUILD=1
DETACH=1
INIT=1
LITE=0
REGION="is"
PARALLEL_LIMIT="${COMPOSE_PARALLEL_LIMIT:-2}"
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
FRONTEND_WEB_HOST="${FRONTEND_WEB_HOST:-127.0.0.1}"
FRONTEND_WEB_PORT="${FRONTEND_WEB_PORT:-3000}"
FRONTEND_PUBLIC_URL="${FRONTEND_PUBLIC_URL:-http://localhost:${FRONTEND_WEB_PORT}}"
FRONTEND_API_URL="${FRONTEND_API_URL:-http://localhost:8080}"
FRONTEND_PASSKEY_RP_ID="${FRONTEND_PASSKEY_RP_ID:-kerosene-device}"
FRONTEND_PASSKEY_ORIGIN="${FRONTEND_PASSKEY_ORIGIN:-android:apk-key-hash:kerosene}"

usage() {
  cat <<'EOF'
Usage: scripts/start-local.sh [options] [compose-service...]

Options:
  --lite         Start only Vault plus one app shard for faster local testing.
  --region R     Region for --lite: is, ch, or sg. Default: is.
  --no-init      Skip local bootstrap file regeneration.
  --no-arm       Do not call scripts/arm-vault.sh after containers start.
  --no-build     Start without rebuilding Docker images or Flutter web.
  --parallel N   Limit Docker Compose build/start parallelism. Default: 2.
  --frontend-server
                 Also start a separate localhost Flutter web server for dev.
                 Tor Browser access does not use this; the backend serves web.
  --no-frontend  Legacy no-op; web admin is served by the backend.
  --no-frontend-build
                 Serve the existing Flutter build/web output if present.
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

configure_lite_services() {
  if [[ "$LITE" -ne 1 || "${#COMPOSE_SERVICES[@]}" -gt 0 ]]; then
    return
  fi

  COMPOSE_SERVICES=(
    kerosene-vault
    kerosene-tor-vault
    kerosene-vault-arm
    vault-raft-data-init
    vault-raft-1
    vault-raft-2
    vault-raft-3
    vault-raft-bootstrap
    "db-$REGION"
    "redis-$REGION"
    "mpc-sidecar-$REGION"
    "shard-identity-init-$REGION"
    "kerosene-app-$REGION"
    "kerosene-tor-$REGION"
  )
}

repair_stale_local_networks() {
  local net_vault="${COMPOSE_PROJECT_NAME}_net_vault"
  local subnets labels

  if ! docker network inspect "$net_vault" >/dev/null 2>&1; then
    return
  fi

  labels="$(docker network inspect -f '{{index .Labels "com.docker.compose.project"}} {{index .Labels "com.docker.compose.network"}}' "$net_vault" 2>/dev/null || true)"
  [[ "$labels" == "$COMPOSE_PROJECT_NAME net_vault" ]] || return

  subnets="$(docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}} {{end}}' "$net_vault" 2>/dev/null || true)"
  if grep -qw '10.242.0.0/24' <<<"$subnets"; then
    return
  fi

  warn "$net_vault exists with subnet '${subnets:-unknown}', but this compose file requires 10.242.0.0/24."
  warn "Stopping the local compose stack so Docker can recreate the network without deleting volumes."
  compose down --remove-orphans >/dev/null || warn "Could not stop stale compose stack before network repair."
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

  if [[ -x "$SCRIPT_DIR/build-web-admin-backend.sh" ]]; then
    "$SCRIPT_DIR/build-web-admin-backend.sh" --no-jar
    return
  fi

  if [[ -f "$BACKEND_WEB_ADMIN_BUILD_DIR/index.html" ]]; then
    warn "scripts/build-web-admin-backend.sh is missing; using existing embedded web admin build."
    return
  fi

  warn "scripts/build-web-admin-backend.sh is missing and no embedded web admin build exists."
  warn "Continuing backend startup without rebuilding the web admin."
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
    kerosene-app-is kerosene-app-ch kerosene-app-sg \
    kerosene-vanguards-is kerosene-vanguards-ch kerosene-vanguards-sg \
    kerosene-tor-is kerosene-tor-ch kerosene-tor-sg \
    kerosene-vault mpc-sidecar-is mpc-sidecar-ch mpc-sidecar-sg \
    db-is db-ch db-sg redis-is redis-ch redis-sg; do
    print_container_health_summary "$service"
  done

  warn "Recent logs from critical services:"
  compose logs --no-color --tail 80 \
    kerosene-app-is kerosene-app-ch kerosene-app-sg \
    kerosene-vanguards-is kerosene-vanguards-ch kerosene-vanguards-sg \
    kerosene-vault mpc-sidecar-is mpc-sidecar-ch mpc-sidecar-sg >&2 || true
}

refresh_vault_raft_bootstrap() {
  if [[ "${#COMPOSE_SERVICES[@]}" -gt 0 ]]; then
    return
  fi

  local bootstrap_container
  bootstrap_container="$(compose ps -a -q vault-raft-bootstrap 2>/dev/null | head -n 1 || true)"
  [[ -n "$bootstrap_container" ]] || return

  info "Refreshing Vault Raft bootstrap/unseal state..."
  compose start vault-raft-bootstrap >/dev/null || {
    warn "Could not start vault-raft-bootstrap. App startup may fail if Vault Raft is sealed."
    return
  }

  if ! timeout 180s docker wait "$bootstrap_container" >/tmp/kerosene-vault-raft-bootstrap.exit 2>/dev/null; then
    warn "Timed out waiting for vault-raft-bootstrap to complete."
    compose logs --no-color --tail 80 vault-raft-bootstrap >&2 || true
    return
  fi

  local exit_code
  exit_code="$(tr -d '[:space:]' < /tmp/kerosene-vault-raft-bootstrap.exit || true)"
  if [[ "$exit_code" != "0" ]]; then
    warn "vault-raft-bootstrap exited with code ${exit_code:-unknown}."
    compose logs --no-color --tail 80 vault-raft-bootstrap >&2 || true
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
  is_onion="$(read_onion_hostname kerosene-tor-is)"
  ch_onion="$(read_onion_hostname kerosene-tor-ch)"
  sg_onion="$(read_onion_hostname kerosene-tor-sg)"

  info "Onion addresses:"
  info "  Vault: ${vault_onion:-unavailable}"
  info "  IS: ${is_onion:-unavailable}"
  info "  CH: ${ch_onion:-unavailable}"
  info "  SG: ${sg_onion:-unavailable}"
}

wait_for_master_keys_and_print_onions() {
  local deadline now
  deadline=$(( $(date +%s) + MASTER_KEY_WAIT_TIMEOUT_SECONDS ))

  if [[ "$LITE" -eq 1 ]]; then
    local service="kerosene-app-$REGION"
    info "Waiting for ${REGION^^} shard to provision the master key..."
    while true; do
      if service_has_master_key "$service"; then
        info "${REGION^^} shard provisioned the master key."
        print_onion_addresses
        return 0
      fi

      now=$(date +%s)
      if (( now >= deadline )); then
        warn "Timed out waiting for ${REGION^^} shard to provision the master key."
        print_onion_addresses
        return 1
      fi

      sleep 2
    done
  fi

  info "Waiting for IS, CH, and SG shards to provision the master key..."
  while true; do
    if service_has_master_key kerosene-app-is &&
       service_has_master_key kerosene-app-ch &&
       service_has_master_key kerosene-app-sg; then
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

start_frontend() {
  if [[ "$START_FRONTEND" -ne 1 ]]; then
    return
  fi

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

  if ! command -v flutter >/dev/null 2>&1; then
    warn "Flutter CLI not found; backend is up, but frontend was not started."
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
  if [[ "$FRONTEND_BUILD" -eq 1 || ! -f "$FRONTEND_BUILD_DIR/index.html" ]]; then
    info "Building Flutter web frontend for $FRONTEND_PUBLIC_URL (API: $FRONTEND_API_URL)."
    (
      cd "$FRONTEND_DIR"
      FLUTTER_BUILD_ARGS=(web --release --csp --no-web-resources-cdn)
      if [[ "${FLUTTER_BUILD_NO_PUB:-0}" == "1" ]]; then
        FLUTTER_BUILD_ARGS+=(--no-pub)
      fi
      flutter build "${FLUTTER_BUILD_ARGS[@]}" \
        --dart-define="WEB_API_URL=$FRONTEND_API_URL" \
        --dart-define="PASSKEY_RP_ID=$FRONTEND_PASSKEY_RP_ID" \
        --dart-define="PASSKEY_ORIGIN=$FRONTEND_PASSKEY_ORIGIN"
    ) > "$FRONTEND_BUILD_LOG_FILE" 2>&1 || {
      warn "Flutter web build failed. See $FRONTEND_BUILD_LOG_FILE"
      tail -n 80 "$FRONTEND_BUILD_LOG_FILE" >&2 || true
      return
    }
  else
    info "Using existing Flutter web build at $FRONTEND_BUILD_DIR."
  fi

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
    --lite) LITE=1 ;;
    --region)
      shift
      [[ $# -gt 0 ]] || fail "--region requires one of: is, ch, sg"
      REGION="${1,,}"
      ;;
    --region=*) REGION="${1#*=}"; REGION="${REGION,,}" ;;
    --no-init) INIT=0 ;;
    --no-arm) ARM_VAULT=0 ;;
    --no-build) BUILD=0; FRONTEND_BUILD=0 ;;
    --parallel)
      shift
      [[ $# -gt 0 ]] || fail "--parallel requires a positive integer"
      PARALLEL_LIMIT="$1"
      ;;
    --parallel=*) PARALLEL_LIMIT="${1#*=}" ;;
    --frontend-server) START_FRONTEND=1 ;;
    --no-frontend) START_FRONTEND=0 ;;
    --no-frontend-build) FRONTEND_BUILD=0 ;;
    --foreground) DETACH=0 ;;
    -h|--help) usage; exit 0 ;;
    *) COMPOSE_SERVICES+=("$1") ;;
  esac
  shift
done

[[ "$REGION" =~ ^(is|ch|sg)$ ]] || fail "--region must be one of: is, ch, sg"
[[ "$PARALLEL_LIMIT" =~ ^[1-9][0-9]*$ ]] || fail "--parallel must be a positive integer"
configure_lite_services

if [[ "$INIT" -eq 1 ]]; then
  "$INFRA_DIR/scripts/init-local.sh"
else
  info "Skipping local bootstrap regeneration (--no-init)."
fi
require_docker
maybe_enable_redis_overcommit
prepare_backend_web_admin
repair_stale_local_networks

UP_ARGS=(up)
if [[ "$DETACH" -eq 1 ]]; then
  UP_ARGS+=(-d)
fi
if [[ "$BUILD" -eq 1 ]]; then
  UP_ARGS+=(--build)
fi

export COMPOSE_PARALLEL_LIMIT="$PARALLEL_LIMIT"
export DOCKER_BUILDKIT="${DOCKER_BUILDKIT:-1}"

info "Starting local backend cluster with $COMPOSE_FILE"
if [[ "$LITE" -eq 1 ]]; then
  info "Lite mode enabled for region ${REGION^^}: ${COMPOSE_SERVICES[*]}"
fi
info "Docker Compose parallel limit: $COMPOSE_PARALLEL_LIMIT"
if ! compose "${UP_ARGS[@]}" "${COMPOSE_SERVICES[@]}"; then
  print_compose_start_diagnostics
  exit 1
fi

if [[ "$DETACH" -eq 1 ]]; then
  if [[ "$LITE" -eq 1 ]]; then
    info "Lite mode skips full-cluster Vault Raft refresh."
  else
    refresh_vault_raft_bootstrap
  fi
fi

if [[ "$DETACH" -eq 1 ]]; then
  if [[ -x "$SCRIPT_DIR/migrate-local-db.sh" ]]; then
    if [[ "$LITE" -eq 1 ]]; then
      "$SCRIPT_DIR/migrate-local-db.sh" "db-$REGION"
    else
      "$SCRIPT_DIR/migrate-local-db.sh"
    fi
  else
    warn "scripts/migrate-local-db.sh is missing; skipping automatic local DB migrations."
  fi
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
info "Logs: scripts/logs-local.sh"
info "Stop: scripts/stop-local.sh"
