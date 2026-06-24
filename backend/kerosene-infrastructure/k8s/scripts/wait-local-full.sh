#!/usr/bin/env bash
set -euo pipefail

KUBECTL="${KUBECTL:-kubectl}"
NS="${KEROSENE_NAMESPACE:-kerosene-local}"
TIMEOUT="${KEROSENE_WAIT_TIMEOUT:-300s}"

wait_for() {
  local kind="$1"
  local name="$2"
  echo "[*] Waiting for $kind/$name in $NS"
  "$KUBECTL" -n "$NS" rollout status "$kind/$name" --timeout="$TIMEOUT"
}

wait_for statefulset local-postgres
wait_for deployment local-redis
wait_for deployment local-vault
wait_for deployment local-bitcoin
wait_for deployment local-lnd-placeholder
wait_for statefulset mpc-sidecar
wait_for deployment server
wait_for deployment kfe-service
wait_for deployment web-page

echo "[*] Pods"
"$KUBECTL" -n "$NS" get pods -o wide

echo "[*] Services"
"$KUBECTL" -n "$NS" get svc

echo "[+] local-full workloads are ready or reported by rollout status as complete."
