#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# init-local.sh — Bootstrap Kerosene local dev environment
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/../backend/kerosene"
CERTS_DIR="$BACKEND_DIR/certs"

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GREEN}[init]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── 1. Validate .env ──────────────────────────────────────────────────────────
ENV_FILE="$BACKEND_DIR/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  error ".env not found at $ENV_FILE. Copy .env.example and fill in values."
fi

source "$ENV_FILE"
REQUIRED_VARS=(POSTGRES_USER POSTGRES_PASSWORD REDIS_PASSWORD JWT_SECRET FOUNDER_TOTP_SECRET)
for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then error "Missing required variable: $var"; fi
done
info "Environment variables validated. ✓"

# ── 2. TLS certificates ───────────────────────────────────────────────────────
if [[ ! -f "$CERTS_DIR/rootCA.crt" ]]; then
  bash "$ROOT_DIR/../cert-generator.sh" || warn "Cert generator failed, check if it exists."
fi

# ── 3. Tor Configs (Force LF Line Endings) ──────────────────────────────────
fix_torrc() {
  local file=$1
  local service_name=$2
  info "Generating $file..."
  # Use printf to ensure no \r and strict format
  printf "SocksPort unix:/var/run/tor/socks/tor.sock WorldWritable\nHiddenServiceDir /var/lib/tor/kerosene_service/\nHiddenServiceVersion 3\nHiddenServicePort 80 %s:8080\nLog notice stdout\nDataDirectory /var/lib/tor\nNumCPUs 1\n" "$service_name" > "$file"
}

fix_torrc "$BACKEND_DIR/tor/torrc-is" "kerosene-app-is-local"
fix_torrc "$BACKEND_DIR/tor/torrc-ch" "kerosene-app-ch-local"
fix_torrc "$BACKEND_DIR/tor/torrc-sg" "kerosene-app-sg-local"

info "Generating $BACKEND_DIR/tor/torrc-vault..."
printf "SocksPort 0\nHiddenServiceDir /var/lib/tor/kerosene_service/\nHiddenServiceVersion 3\nHiddenServicePort 80 kerosene-vault-local:8090\nLog notice stdout\nDataDirectory /var/lib/tor\nNumCPUs 1\n" > "$BACKEND_DIR/tor/torrc-vault"

info "Initialization complete."
echo "  docker compose --env-file backend/kerosene/.env -f kerosene-infrastructure/docker-compose.local.yml up --build"
