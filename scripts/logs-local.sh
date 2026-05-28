#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"

RAW=0
FOLLOW=1
FILTER_ONLY=0
TAIL="${KEROSENE_LOG_TAIL:-180}"
SERVICES=()

usage() {
  cat <<'EOF'
Usage: scripts/logs-local.sh [options] [compose-service...]

Shows local backend logs with noisy sync/healthcheck lines filtered by default.

Options:
  --raw             Show unfiltered docker compose logs.
  --no-follow       Print the current tail and exit.
  --tail N          Number of recent lines per service to read first.
  --filter-only     Read stdin and apply the local noise filter. Useful for tests.
  -h, --help        Show this help.

Set KEROSENE_LOG_TAIL=N to change the default tail.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --raw|--include-noisy)
      RAW=1
      ;;
    --no-follow)
      FOLLOW=0
      ;;
    --tail)
      shift
      [[ $# -gt 0 ]] || fail "--tail requires a number."
      TAIL="$1"
      ;;
    --filter-only)
      FILTER_ONLY=1
      FOLLOW=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      SERVICES+=("$1")
      ;;
  esac
  shift
done

case "$TAIL" in
  ''|*[!0-9]*)
    fail "--tail must be numeric."
    ;;
esac

LOG_ARGS=(logs --no-color --tail "$TAIL")
if [[ "$FOLLOW" -eq 1 ]]; then
  LOG_ARGS+=(-f)
fi

FILTER_PROGRAM='
  /bitcoin-pruned-node-local[[:space:]]+\| .* UpdateTip: new best=/ { next }
  /kerosene-web-admin-local[[:space:]]+\| .*"GET \/ HTTP\/1\.1" 200 .*"Wget"/ { next }
  /kerosene_db_.*_local[[:space:]]+\| .* LOG:[[:space:]]+checkpoint (starting|complete):/ { next }
  /Successfully deleted 0 expired ephemeral ledger transaction history records\./ { next }
  /Starting cleanup of ephemeral ledger transaction history older than/ { next }
  /Vault is already armed\./ { next }
  /Vault Raft bootstrap complete/ { next }
  /Success! Uploaded policy: kerosene-raft-health/ { next }
  /Waiting for Tor control socket at \/var\/run\/tor\/control\/control/ { next }
  /Tor control socket authenticated\. Starting Vanguards/ { next }
  /Vanguards [0-9.]+ connected to Tor/ { next }
  /Redis is starting/ { next }
  /Redis version=/ { next }
  /Configuration loaded/ { next }
  /Increased maximum number of open files/ { next }
  /monotonic clock:/ { next }
  /Running mode=standalone, port=6379/ { next }
  /Ready to accept connections tcp/ { next }
  { print; fflush() }
'

if [[ "$FILTER_ONLY" -eq 1 ]]; then
  awk "$FILTER_PROGRAM"
  exit 0
fi

if [[ "$RAW" -eq 1 ]]; then
  compose "${LOG_ARGS[@]}" "${SERVICES[@]}"
  exit 0
fi

compose "${LOG_ARGS[@]}" "${SERVICES[@]}" | awk "$FILTER_PROGRAM"
