#!/usr/bin/env bash
set -Eeuo pipefail
trap '' HUP

ROOT="${KEROSENE_TUNNEL_ROOT:-/home/omega/Kerosene}"
TUNNEL_HOME="${KEROSENE_TUNNEL_HOME:-/home/omega}"
PROFILE="${KEROSENE_TUNNEL_PROFILE:-kerosene-readonly}"
SAMPLE="${KEROSENE_TUNNEL_SAMPLE:-sample_mcp_stdio_local}"
TUNNEL_ID="${KEROSENE_TUNNEL_ID:-tunnel_6a32fe90a87c819192510434922a01fb}"
MCP_COMMAND="${KEROSENE_TUNNEL_MCP_COMMAND:-$ROOT/scripts/kerosene-mcp}"
ENV_FILE="${KEROSENE_TUNNEL_ENV_FILE:-$ROOT/scripts/.env.tunnel}"
HEALTH_LISTEN_ADDR="${KEROSENE_TUNNEL_HEALTH_ADDR:-127.0.0.1:18080}"
DOWNLOADS_DIR="${KEROSENE_TUNNEL_DOWNLOADS_DIR:-/home/omega/Downloads}"
CONTROL_PLANE_BASE_URL="${KEROSENE_TUNNEL_CONTROL_PLANE_BASE_URL:-https://api.openai.com}"
CONTROL_PLANE_POLL_TIMEOUT="${KEROSENE_TUNNEL_CONTROL_PLANE_POLL_TIMEOUT:-90s}"
CONTROL_PLANE_MAX_INFLIGHT_REQUESTS="${KEROSENE_TUNNEL_CONTROL_PLANE_MAX_INFLIGHT_REQUESTS:-1}"
MCP_CONNECTION_MAX_TTL="${KEROSENE_TUNNEL_MCP_CONNECTION_MAX_TTL:-2h}"
MCP_MAX_CONCURRENT_REQUESTS="${KEROSENE_TUNNEL_MCP_MAX_CONCURRENT_REQUESTS:-1}"
SUPERVISE="${KEROSENE_TUNNEL_SUPERVISE:-1}"
RESTART_BACKOFF_SECONDS="${KEROSENE_TUNNEL_RESTART_BACKOFF_SECONDS:-5}"
RESTART_BACKOFF_MAX_SECONDS="${KEROSENE_TUNNEL_RESTART_BACKOFF_MAX_SECONDS:-120}"
LOG_DIR="${KEROSENE_TUNNEL_LOG_DIR:-$ROOT/logs}"
SUPERVISOR_LOG_FILE="${KEROSENE_TUNNEL_SUPERVISOR_LOG_FILE:-$LOG_DIR/kerosene-tunnel-supervisor.log}"
CLIENT_LOG_FILE="${KEROSENE_TUNNEL_CLIENT_LOG_FILE:-$LOG_DIR/kerosene-tunnel-client.ndjson}"
SUPERVISOR_PID_FILE="${KEROSENE_TUNNEL_SUPERVISOR_PID_FILE:-$ROOT/tmp/kerosene-tunnel-supervisor.pid}"
CLIENT_PID_FILE="${KEROSENE_TUNNEL_CLIENT_PID_FILE:-$ROOT/tmp/kerosene-tunnel-client.pid}"

export HOME="$TUNNEL_HOME"

find_tunnel_client() {
  local candidate

  if [[ -n "${KEROSENE_TUNNEL_CLIENT:-}" ]]; then
    printf '%s\n' "$KEROSENE_TUNNEL_CLIENT"
    return 0
  fi

  candidate="$DOWNLOADS_DIR/tunnel-client-v0.0.9--context-conduit-topaz-all/bin/linux_amd64/tunnel-client"
  if [[ -f "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  candidate="$(find "$DOWNLOADS_DIR" -path '*/bin/linux_amd64/tunnel-client' -type f -print -quit 2>/dev/null || true)"
  if [[ -n "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  candidate="$ROOT/tunnel-client"
  if [[ -f "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  command -v tunnel-client 2>/dev/null || true
}

cd "$ROOT"
TUNNEL_CLIENT="$(find_tunnel_client)"
PROFILE_DIR="${TUNNEL_CLIENT_PROFILE_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/tunnel-client}"
PROFILE_FILE="${KEROSENE_TUNNEL_PROFILE_FILE:-$PROFILE_DIR/$PROFILE.yaml}"

log() {
  printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$SUPERVISOR_LOG_FILE"
}

write_runtime_profile() {
  mkdir -p "$PROFILE_DIR" "$LOG_DIR" "$(dirname "$SUPERVISOR_PID_FILE")" "$(dirname "$CLIENT_PID_FILE")"
  cat > "$PROFILE_FILE" <<YAML
config_version: 1
control_plane:
  base_url: "$CONTROL_PLANE_BASE_URL"
  tunnel_id: "$TUNNEL_ID"
  api_key: "env:CONTROL_PLANE_API_KEY"
  poll_timeout: "$CONTROL_PLANE_POLL_TIMEOUT"
  max_inflight_requests: $CONTROL_PLANE_MAX_INFLIGHT_REQUESTS
health:
  listen_addr: "$HEALTH_LISTEN_ADDR"
admin_ui:
  open_browser: false
log:
  level: info
  format: json
  file: "$CLIENT_LOG_FILE"
process:
  pid_file: "$CLIENT_PID_FILE"
mcp:
  connection_max_ttl: "$MCP_CONNECTION_MAX_TTL"
  max_concurrent_requests: $MCP_MAX_CONCURRENT_REQUESTS
  commands:
    - channel: main
      command: "$MCP_COMMAND"
YAML
}

run_tunnel_client() {
  "$TUNNEL_CLIENT" run \
    --profile "$PROFILE" \
    --control-plane.poll-timeout "$CONTROL_PLANE_POLL_TIMEOUT" \
    --control-plane.max-inflight "$CONTROL_PLANE_MAX_INFLIGHT_REQUESTS" \
    --mcp.connection-max-ttl "$MCP_CONNECTION_MAX_TTL" \
    --mcp.max-concurrent-requests "$MCP_MAX_CONCURRENT_REQUESTS"
}

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

if [[ -z "${CONTROL_PLANE_API_KEY:-}" ]]; then
  printf 'Erro: CONTROL_PLANE_API_KEY nao definido. Configure em %s ou exporte antes de executar.\n' "$ENV_FILE" >&2
  exit 1
fi

if [[ -z "$TUNNEL_CLIENT" ]]; then
  printf 'Erro: tunnel-client nao encontrado em %s nem no projeto/PATH.\n' "$DOWNLOADS_DIR" >&2
  exit 1
fi

if [[ ! -x "$TUNNEL_CLIENT" ]]; then
  printf 'Erro: tunnel-client encontrado, mas sem permissao de execucao em %s\n' "$TUNNEL_CLIENT" >&2
  exit 1
fi

if [[ ! -x "$MCP_COMMAND" ]]; then
  printf 'Erro: comando MCP nao encontrado ou sem permissao de execucao em %s\n' "$MCP_COMMAND" >&2
  exit 1
fi

printf '[tunnel] Projeto: %s\n' "$ROOT"
printf '[tunnel] Home: %s\n' "$HOME"
printf '[tunnel] Profile: %s\n' "$PROFILE"
printf '[tunnel] Tunnel ID: %s\n' "$TUNNEL_ID"
printf '[tunnel] Tunnel client: %s\n' "$TUNNEL_CLIENT"
printf '[tunnel] MCP command: %s\n' "$MCP_COMMAND"
printf '[tunnel] Health/UI: http://%s\n' "$HEALTH_LISTEN_ADDR"
printf '[tunnel] Control plane poll timeout: %s\n' "$CONTROL_PLANE_POLL_TIMEOUT"
printf '[tunnel] Control plane max in-flight: %s\n' "$CONTROL_PLANE_MAX_INFLIGHT_REQUESTS"
printf '[tunnel] MCP connection TTL: %s\n' "$MCP_CONNECTION_MAX_TTL"
printf '[tunnel] MCP max concurrent requests: %s\n' "$MCP_MAX_CONCURRENT_REQUESTS"
printf '[tunnel] Supervisor log: %s\n' "$SUPERVISOR_LOG_FILE"
printf '[tunnel] Client log: %s\n' "$CLIENT_LOG_FILE"

export MCP_CONNECTION_MAX_TTL
export MCP_MAX_CONCURRENT_REQUESTS

printf '[tunnel] Inicializando profile...\n'
"$TUNNEL_CLIENT" init \
  --force \
  --sample "$SAMPLE" \
  --profile "$PROFILE" \
  --tunnel-id "$TUNNEL_ID" \
  --health-listen-addr "$HEALTH_LISTEN_ADDR" \
  --mcp-command "$MCP_COMMAND"

printf '[tunnel] Aplicando ajustes persistentes no profile...\n'
write_runtime_profile

printf '[tunnel] Validando configuracao...\n'
"$TUNNEL_CLIENT" doctor --profile "$PROFILE" --explain

if [[ "$SUPERVISE" != "1" && "$SUPERVISE" != "true" && "$SUPERVISE" != "yes" ]]; then
  printf '[tunnel] Iniciando tunnel em modo one-shot. Use Ctrl+C para parar.\n'
  run_tunnel_client
  exit "$?"
fi

child_pid=""
stop_supervisor() {
  log "[tunnel] Encerrando supervisor."
  if [[ -n "$child_pid" ]] && kill -0 "$child_pid" 2>/dev/null; then
    kill "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi
  rm -f "$SUPERVISOR_PID_FILE"
}
trap stop_supervisor EXIT
trap 'exit 0' INT TERM

printf '%s\n' "$$" > "$SUPERVISOR_PID_FILE"
log "[tunnel] Supervisor iniciado para profile=$PROFILE."

backoff="$RESTART_BACKOFF_SECONDS"
while true; do
  started_at="$(date +%s)"
  log "[tunnel] Iniciando tunnel-client: ttl=$MCP_CONNECTION_MAX_TTL, poll=$CONTROL_PLANE_POLL_TIMEOUT, max_concurrent=$MCP_MAX_CONCURRENT_REQUESTS."
  set +e
  run_tunnel_client >> "$SUPERVISOR_LOG_FILE" 2>&1 &
  child_pid="$!"
  wait "$child_pid"
  status="$?"
  child_pid=""
  set -e

  duration="$(( $(date +%s) - started_at ))"
  log "[tunnel] tunnel-client saiu com status=$status depois de ${duration}s."
  if [[ "$duration" -ge 300 ]]; then
    backoff="$RESTART_BACKOFF_SECONDS"
  fi
  log "[tunnel] Reiniciando em ${backoff}s."
  sleep "$backoff"
  if [[ "$backoff" -lt "$RESTART_BACKOFF_MAX_SECONDS" ]]; then
    backoff="$(( backoff * 2 ))"
    if [[ "$backoff" -gt "$RESTART_BACKOFF_MAX_SECONDS" ]]; then
      backoff="$RESTART_BACKOFF_MAX_SECONDS"
    fi
  fi
done
