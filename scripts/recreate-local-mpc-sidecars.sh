#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"

load_backend_env
require_docker

info "Recreating local MPC sidecars so tmpfs ownership changes take effect..."
compose up -d --force-recreate mpc-sidecar-is mpc-sidecar-ch mpc-sidecar-sg

info "Validating /mnt/mpc-shards write permissions inside mpc-sidecar-is..."
docker exec mpc-sidecar-is-local sh -lc '
  set -eu
  id
  ls -ld /mnt/mpc-shards /app/encrypted-shards
  touch /mnt/mpc-shards/.write-test
  touch /app/encrypted-shards/.write-test
  rm -f /mnt/mpc-shards/.write-test /app/encrypted-shards/.write-test
  echo "MPC sidecar RAM and persistent shard storage are writable."
'

info "Done. Retry wallet creation in the app."
