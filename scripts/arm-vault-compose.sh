#!/bin/sh
set -eu

VAULT_URL="${VAULT_URL:-http://kerosene-vault:8090/v1/vault/arm}"
MASTER_KEY="${AES_SECRET:-}"
MAX_WAIT_SECONDS="${VAULT_ARM_MAX_WAIT_SECONDS:-120}"

if [ -z "$MASTER_KEY" ]; then
  echo "[vault-arm][error] AES_SECRET is required." >&2
  exit 1
fi

wait_deadline=$(( $(date +%s) + MAX_WAIT_SECONDS ))

submit_approval() {
  director="$1"
  signature="SIGNATURE_${director}_LOCAL_DEV"

  response="$(curl \
    --silent \
    --show-error \
    --write-out '\n%{http_code}' \
    --request POST "$VAULT_URL" \
    --header "X-Director-Id: $director" \
    --header "X-Director-Signature: $signature" \
    --header "Content-Type: application/json" \
    --data "{\"master_key\":\"$MASTER_KEY\"}")"

  http_code="$(printf '%s' "$response" | tail -n 1)"
  body="$(printf '%s' "$response" | sed '$d')"

  if echo "$body" | grep -Fqi "already armed"; then
    echo "$body"
    return 0
  fi

  case "$http_code" in
    2*)
      echo "$body"
      return 0
      ;;
    *)
      echo "$body" >&2
      return 1
      ;;
  esac
}

VAULT_BASE_URL="${VAULT_URL%/v1/vault/arm}"

until curl --silent --show-error --output /dev/null \
  --connect-timeout 2 "$VAULT_BASE_URL"
do
  if [ "$(date +%s)" -ge "$wait_deadline" ]; then
    echo "[vault-arm][error] Vault did not become reachable within ${MAX_WAIT_SECONDS}s." >&2
    exit 1
  fi

  sleep 2
done

for director in director-1 director-2
do
  echo "[vault-arm] submitting quorum approval from ${director}..."
  submit_approval "$director"
done

echo "[vault-arm] vault is armed."
