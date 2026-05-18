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

submit_approval() {
  local director="$1"
  local response status body

  response="$(docker run --rm --network "$VAULT_NETWORK" curlimages/curl:8.10.1 \
    --silent \
    --show-error \
    --write-out $'\n%{http_code}' \
    --request POST "$VAULT_URL" \
    --header "X-Director-Id: $director" \
    --header "X-Director-Signature: SIGNATURE_${director}_LOCAL_DEV" \
    --header "Content-Type: application/json" \
    --data "{\"master_key\":\"$MASTER_KEY\"}")"
  status="$(tail -n 1 <<<"$response")"
  body="$(sed '$d' <<<"$response")"
  [[ -n "$body" ]] && printf '%s\n' "$body"

  if [[ "$status" =~ ^2[0-9][0-9]$ ]]; then
    return 0
  fi
  if [[ "$status" == "400" && "$body" == *"already armed"* ]]; then
    return 0
  fi

  echo "[vault][error] Vault arm request for $director failed with HTTP $status." >&2
  return 1
}

for director in director-1 director-2; do
  echo "[vault] Submitting quorum approval from $director..."
  submit_approval "$director"
  echo
done

echo "[vault] Quorum submitted. If the second response says the vault is ARMED, the vault is ready."
