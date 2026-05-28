#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FRONTEND_DIR="${REPO_ROOT}/frontend"

cd "${FRONTEND_DIR}"

export KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING="${KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING:-true}"
PASSKEY_RP_ID="${PASSKEY_RP_ID:-${FRONTEND_PASSKEY_RP_ID:-kerosene-device}}"
PASSKEY_ORIGIN="${PASSKEY_ORIGIN:-${FRONTEND_PASSKEY_ORIGIN:-android:apk-key-hash:kerosene}}"

echo "Running local Android release with debug signing enabled."
echo "This is for local non-production device testing only."
echo "Passkey RP ID: ${PASSKEY_RP_ID}"

exec flutter run --release \
  --dart-define="PASSKEY_RP_ID=${PASSKEY_RP_ID}" \
  --dart-define="PASSKEY_ORIGIN=${PASSKEY_ORIGIN}" \
  "$@"
