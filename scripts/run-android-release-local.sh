#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FRONTEND_DIR="${REPO_ROOT}/frontend"

cd "${FRONTEND_DIR}"

export KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING="${KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING:-true}"

echo "Running local Android release with debug signing enabled."
echo "This is for local non-production device testing only."

exec flutter run --release "$@"
