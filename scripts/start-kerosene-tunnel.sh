#!/usr/bin/env bash
set -Eeuo pipefail
trap '' HUP

ORIGINAL_PWD="$(pwd -P)"
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
  SCRIPT_DIR="$(cd -P -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
  LINK_TARGET="$(readlink -- "$SCRIPT_PATH")"
  if [[ "$LINK_TARGET" == /* ]]; then
    SCRIPT_PATH="$LINK_TARGET"
  else
    SCRIPT_PATH="$SCRIPT_DIR/$LINK_TARGET"
  fi
done
SCRIPT_DIR="$(cd -P -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
DEFAULT_ROOT="$(cd -P -- "$SCRIPT_DIR/.." && pwd)"

make_absolute_path() {
  local path="$1"
  if [[ "$path" == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$ORIGINAL_PWD" "$path"
  fi
}

ENV_FILE="${KEROSENE_TUNNEL_ENV_FILE:-$SCRIPT_DIR/.env.tunnel}"
ENV_FILE="$(make_absolute_path "$ENV_FILE")"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

ROOT="${KEROSENE_TUNNEL_ROOT:-$DEFAULT_ROOT}"
ROOT="$(make_absolute_path "$ROOT")"
if [[ ! -d "$ROOT" ]]; then
  printf 'Erro: raiz do projeto nao encontrada em %s\n' "$ROOT" >&2
  exit 1
fi
ROOT="$(cd -P -- "$ROOT" && pwd)"
TUNNEL_HOME="${KEROSENE_TUNNEL_HOME:-${HOME:-/home/omega}}"
TUNNEL_HOME="$(make_absolute_path "$TUNNEL_HOME")"
PROFILE="${KEROSENE_TUNNEL_PROFILE:-kerosene-readonly}"
SAMPLE="${KEROSENE_TUNNEL_SAMPLE:-sample_mcp_stdio_local}"
TUNNEL_ID="${KEROSENE_TUNNEL_ID:-tunnel_6a32fe90a87c819192510434922a01fb}"
MCP_COMMAND="${KEROSENE_TUNNEL_MCP_COMMAND:-$SCRIPT_DIR/kerosene-mcp}"
MCP_COMMAND="$(make_absolute_path "$MCP_COMMAND")"
HEALTH_ADDR_EXPLICIT=0
if [[ -n "${KEROSENE_TUNNEL_HEALTH_ADDR:-}" ]]; then
  HEALTH_ADDR_EXPLICIT=1
fi
HEALTH_LISTEN_ADDR="${KEROSENE_TUNNEL_HEALTH_ADDR:-127.0.0.1:18080}"
DOWNLOADS_DIR="${KEROSENE_TUNNEL_DOWNLOADS_DIR:-$TUNNEL_HOME/Downloads}"
DOWNLOADS_DIR="$(make_absolute_path "$DOWNLOADS_DIR")"
CONTROL_PLANE_BASE_URL="${KEROSENE_TUNNEL_CONTROL_PLANE_BASE_URL:-https://api.openai.com}"
CONTROL_PLANE_POLL_TIMEOUT="${KEROSENE_TUNNEL_CONTROL_PLANE_POLL_TIMEOUT:-90s}"
CONTROL_PLANE_MAX_INFLIGHT_REQUESTS="${KEROSENE_TUNNEL_CONTROL_PLANE_MAX_INFLIGHT_REQUESTS:-1}"
MCP_CONNECTION_MAX_TTL="${KEROSENE_TUNNEL_MCP_CONNECTION_MAX_TTL:-2h}"
MCP_MAX_CONCURRENT_REQUESTS="${KEROSENE_TUNNEL_MCP_MAX_CONCURRENT_REQUESTS:-1}"
SUPERVISE="${KEROSENE_TUNNEL_SUPERVISE:-1}"
RESTART_BACKOFF_SECONDS="${KEROSENE_TUNNEL_RESTART_BACKOFF_SECONDS:-5}"
RESTART_BACKOFF_MAX_SECONDS="${KEROSENE_TUNNEL_RESTART_BACKOFF_MAX_SECONDS:-120}"
LOG_DIR="${KEROSENE_TUNNEL_LOG_DIR:-$ROOT/logs}"
LOG_DIR="$(make_absolute_path "$LOG_DIR")"
SUPERVISOR_LOG_FILE="${KEROSENE_TUNNEL_SUPERVISOR_LOG_FILE:-$LOG_DIR/kerosene-tunnel-supervisor.log}"
SUPERVISOR_LOG_FILE="$(make_absolute_path "$SUPERVISOR_LOG_FILE")"
CLIENT_LOG_FILE="${KEROSENE_TUNNEL_CLIENT_LOG_FILE:-$LOG_DIR/kerosene-tunnel-client.ndjson}"
CLIENT_LOG_FILE="$(make_absolute_path "$CLIENT_LOG_FILE")"
SUPERVISOR_PID_FILE="${KEROSENE_TUNNEL_SUPERVISOR_PID_FILE:-$ROOT/tmp/kerosene-tunnel-supervisor.pid}"
SUPERVISOR_PID_FILE="$(make_absolute_path "$SUPERVISOR_PID_FILE")"
CLIENT_PID_FILE="${KEROSENE_TUNNEL_CLIENT_PID_FILE:-$ROOT/tmp/kerosene-tunnel-client.pid}"
CLIENT_PID_FILE="$(make_absolute_path "$CLIENT_PID_FILE")"

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

can_bind_tcp_addr() {
  local addr="$1"
  local host="${addr%:*}"
  local port="${addr##*:}"

  if [[ "$addr" != *:* || -z "$host" || ! "$port" =~ ^[0-9]+$ ]]; then
    return 2
  fi

  python3 - "$host" "$port" <<'PY'
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])

try:
    infos = socket.getaddrinfo(host, port, type=socket.SOCK_STREAM)
except OSError:
    sys.exit(1)

for family, socktype, proto, _canonname, sockaddr in infos:
    with socket.socket(family, socktype, proto) as sock:
        try:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            sock.bind(sockaddr)
        except OSError:
            continue
        sys.exit(0)

sys.exit(1)
PY
}

select_health_listen_addr() {
  local addr="$1"
  local host="${addr%:*}"
  local port="${addr##*:}"
  local candidate_port
  local candidate
  local max_port

  if [[ "$addr" != *:* || -z "$host" || ! "$port" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$addr"
    return 0
  fi

  if can_bind_tcp_addr "$addr"; then
    printf '%s\n' "$addr"
    return 0
  fi

  if [[ "$HEALTH_ADDR_EXPLICIT" == "1" ]]; then
    printf 'Erro: health listener %s ja esta em uso. Pare o processo conflitante ou defina KEROSENE_TUNNEL_HEALTH_ADDR.\n' "$addr" >&2
    return 1
  fi

  max_port="$(( port + 20 ))"
  if [[ "$max_port" -gt 65535 ]]; then
    max_port=65535
  fi

  candidate_port="$(( port + 1 ))"
  while [[ "$candidate_port" -le "$max_port" ]]; do
    candidate="$host:$candidate_port"
    if can_bind_tcp_addr "$candidate"; then
      printf '[tunnel] Health/UI padrao %s em uso; usando %s.\n' "$addr" "$candidate" >&2
      printf '%s\n' "$candidate"
      return 0
    fi
    candidate_port="$(( candidate_port + 1 ))"
  done

  printf 'Erro: nenhuma porta Health/UI livre encontrada entre %s e %s:%s.\n' "$addr" "$host" "$max_port" >&2
  return 1
}

cd "$ROOT"
TUNNEL_CLIENT="$(find_tunnel_client)"
if [[ -n "$TUNNEL_CLIENT" && "$TUNNEL_CLIENT" != /* ]]; then
  TUNNEL_CLIENT="$(make_absolute_path "$TUNNEL_CLIENT")"
fi
PROFILE_DIR="${TUNNEL_CLIENT_PROFILE_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/tunnel-client}"
PROFILE_DIR="$(make_absolute_path "$PROFILE_DIR")"
PROFILE_FILE="${KEROSENE_TUNNEL_PROFILE_FILE:-$PROFILE_DIR/$PROFILE.yaml}"
PROFILE_FILE="$(make_absolute_path "$PROFILE_FILE")"

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

HEALTH_LISTEN_ADDR="$(select_health_listen_addr "$HEALTH_LISTEN_ADDR")"
export KEROSENE_MCP_ROOT="$ROOT"
export KEROSENE_MCP_CODEX_FLEET_SCRIPT="${KEROSENE_MCP_CODEX_FLEET_SCRIPT:-$ROOT/AGENTS/codex-fleet-mcp}"
export KEROSENE_MCP_AGY_FLEET_SCRIPT="${KEROSENE_MCP_AGY_FLEET_SCRIPT:-$ROOT/AGENTS/agy-fleet-mcp}"

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
