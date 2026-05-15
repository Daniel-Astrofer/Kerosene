#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"

load_backend_env
require_docker

VAULT_URL="${VAULT_URL:-http://kerosene-vault-local:8090/v1/vault/arm}"
VAULT_NETWORK="${VAULT_NETWORK:-${COMPOSE_PROJECT_NAME}_net_vault}"
MASTER_KEY="${AES_SECRET:-}"

if [[ -z "$MASTER_KEY" ]]; then
  fail "AES_SECRET is missing in $ENV_FILE."
fi

echo "[vault] Arming vault through Docker network: $VAULT_NETWORK"

for director in director-1 director-2; do
  echo "[vault] Submitting quorum approval from $director..."
  docker run --rm --network "$VAULT_NETWORK" curlimages/curl:8.10.1 \
    --fail-with-body \
    --silent \
    --show-error \
    --request POST "$VAULT_URL" \
    --header "X-Director-Id: $director" \
    --header "X-Director-Signature: SIGNATURE_${director}_LOCAL_DEV" \
    --header "Content-Type: application/json" \
    --data "{\"master_key\":\"$MASTER_KEY\"}"
  echo
done

echo "[vault] Quorum submitted. If the second response says the vault is ARMED, the vault is ready."
