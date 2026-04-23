#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"

ARM_VAULT=1
BUILD=1
DETACH=1
COMPOSE_SERVICES=()
MASTER_KEY_WAIT_TIMEOUT_SECONDS=240

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
  compose logs --no-color --tail 200 "$service" 2>/dev/null | grep -Eq \
    "Master key securely locked in RAM\\.|SUCCESS: Master key provisioned on attempt"
}

read_onion_hostname() {
  local tor_service="$1"
  compose exec -T "$tor_service" /bin/sh -lc 'cat /var/lib/tor/kerosene_service/hostname 2>/dev/null' 2>/dev/null | tr -d '\r' | tail -n 1
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
maybe_enable_redis_overcommit
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

if [[ "$DETACH" -eq 1 ]]; then
  "$SCRIPT_DIR/migrate-local-db.sh"
else
  warn "Foreground mode skips automatic local DB migrations. Run scripts/migrate-local-db.sh in another terminal if you reuse persisted volumes."
fi

if [[ "$DETACH" -eq 1 && "$ARM_VAULT" -eq 1 ]]; then
  info "Waiting for Vault container before arming..."
  sleep 5
  "$SCRIPT_DIR/arm-vault.sh" || warn "Vault arming failed. Run scripts/arm-vault.sh manually after checking logs."
  wait_for_master_keys_and_print_onions || true
fi

info "Backend cluster command completed."
info "Logs: scripts/logs-local.sh"
info "Stop: scripts/stop-local.sh"
