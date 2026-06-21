#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="${KEROSENE_TUNNEL_ROOT:-/home/omega/Kerosene}"
TUNNEL_HOME="${KEROSENE_TUNNEL_HOME:-/home/omega}"
PROFILE="${KEROSENE_TUNNEL_PROFILE:-kerosene-readonly}"
SAMPLE="${KEROSENE_TUNNEL_SAMPLE:-sample_mcp_stdio_local}"
TUNNEL_ID="${KEROSENE_TUNNEL_ID:-tunnel_6a32fe90a87c819192510434922a01fb}"
MCP_COMMAND="${KEROSENE_TUNNEL_MCP_COMMAND:-$ROOT/scripts/kerosene-mcp}"
ENV_FILE="${KEROSENE_TUNNEL_ENV_FILE:-$ROOT/scripts/.env.tunnel}"
HEALTH_LISTEN_ADDR="${KEROSENE_TUNNEL_HEALTH_ADDR:-127.0.0.1:18080}"
DOWNLOADS_DIR="${KEROSENE_TUNNEL_DOWNLOADS_DIR:-/home/omega/Downloads}"
MCP_CONNECTION_MAX_TTL="${KEROSENE_TUNNEL_MCP_CONNECTION_MAX_TTL:-30m}"
MCP_MAX_CONCURRENT_REQUESTS="${KEROSENE_TUNNEL_MCP_MAX_CONCURRENT_REQUESTS:-1}"

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
printf '[tunnel] MCP connection TTL: %s\n' "$MCP_CONNECTION_MAX_TTL"
printf '[tunnel] MCP max concurrent requests: %s\n' "$MCP_MAX_CONCURRENT_REQUESTS"

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

printf '[tunnel] Validando configuracao...\n'
"$TUNNEL_CLIENT" doctor --profile "$PROFILE" --explain

printf '[tunnel] Iniciando tunnel. Use Ctrl+C para parar.\n'
exec "$TUNNEL_CLIENT" run \
  --profile "$PROFILE" \
  --mcp.connection-max-ttl "$MCP_CONNECTION_MAX_TTL" \
  --mcp.max-concurrent-requests "$MCP_MAX_CONCURRENT_REQUESTS"
