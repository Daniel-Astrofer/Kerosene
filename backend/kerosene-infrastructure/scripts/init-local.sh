#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# init-local.sh — Bootstrap Kerosene local dev environment
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$INFRA_DIR/../.." && pwd)"
BACKEND_DIR="$REPO_ROOT/backend/kerosene"
BACKEND_DEPLOY_DIR="$BACKEND_DIR/deploy"
TOR_DIR="$BACKEND_DEPLOY_DIR/tor"
CERTS_DIR="$BACKEND_DEPLOY_DIR/local/certs"
ENV_FILE="$BACKEND_DIR/.env"

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GREEN}[init]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

require_openssl() {
  command -v openssl >/dev/null 2>&1 || error "openssl is required to generate local secrets."
}

rand_b64() {
  local bytes="$1"
  openssl rand -base64 "$bytes" | tr -d '\n'
}

rand_hex() {
  local bytes="$1"
  openssl rand -hex "$bytes" | tr -d '\n'
}

rand_base32() {
  local out=""
  while [[ "${#out}" -lt 32 ]]; do
    out+=$(openssl rand -base64 64 | tr -dc 'A-Z2-7')
  done
  printf '%s' "${out:0:32}"
}

env_value() {
  local key="$1"
  local line line_key line_value found=1
  if [[ ! -f "$ENV_FILE" ]]; then
    return 1
  fi
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# || "$line" != *=* ]] && continue
    line_key="${line%%=*}"
    line_value="${line#*=}"
    if [[ "$line_key" == "$key" ]]; then
      printf '%s\n' "$line_value"
      found=0
    fi
  done < "$ENV_FILE"
  return "$found"
}

env_key_exists() {
  local key="$1"
  local line line_key
  [[ -f "$ENV_FILE" ]] || return 1
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# || "$line" != *=* ]] && continue
    line_key="${line%%=*}"
    if [[ "$line_key" == "$key" ]]; then
      return 0
    fi
  done < "$ENV_FILE"
  return 1
}

set_env_value() {
  local key="$1"
  local value="$2"
  local tmp line line_key
  tmp="$(mktemp)"
  if [[ -f "$ENV_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == *=* ]]; then
        line_key="${line%%=*}"
        [[ "$line_key" == "$key" ]] && continue
      fi
      printf '%s\n' "$line" >> "$tmp"
    done < "$ENV_FILE"
  fi
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$ENV_FILE"
}

load_env_file() {
  local line key value first last
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || error "Invalid .env line: ${line%%=*}"

    key="${line%%=*}"
    value="${line#*=}"
    if [[ "${#value}" -ge 2 ]]; then
      first="${value:0:1}"
      last="${value: -1}"
      if { [[ "$first" == "'" ]] && [[ "$last" == "'" ]]; } ||
         { [[ "$first" == '"' ]] && [[ "$last" == '"' ]]; }; then
        value="${value:1:${#value}-2}"
      fi
    fi
    export "$key=$value"
  done < "$ENV_FILE"
}

ensure_env_value() {
  local key="$1"
  local value="$2"
  local current
  current="$(env_value "$key")"
  if [[ -z "$current" || "$current" == CHANGE_ME* ]]; then
    set_env_value "$key" "$value"
    return 0
  fi
  return 1
}

ensure_optional_env_value() {
  local key="$1"
  local value="$2"
  local current
  if ! env_key_exists "$key"; then
    set_env_value "$key" "$value"
    return 0
  fi

  current="$(env_value "$key")"
  if [[ "$current" == CHANGE_ME* ]]; then
    set_env_value "$key" "$value"
    return 0
  fi

  return 1
}

ensure_env_csv_contains() {
  local key="$1"
  local required="$2"
  local current entry
  current="$(env_value "$key")"
  if [[ -z "$current" || "$current" == CHANGE_ME* ]]; then
    set_env_value "$key" "$required"
    return 0
  fi

  IFS=',' read -ra entries <<<"$current"
  for entry in "${entries[@]}"; do
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    if [[ "$entry" == "$required" ]]; then
      return 1
    fi
  done

  set_env_value "$key" "${current},${required}"
  return 0
}

director_secret() {
  local director="$1"
  local secrets="$2"
  local entry entry_director entry_secret
  IFS=',' read -ra entries <<<"$secrets"
  for entry in "${entries[@]}"; do
    entry_director="${entry%%:*}"
    entry_secret="${entry#*:}"
    if [[ "$entry_director" == "$director" && "$entry_secret" != "$entry" ]]; then
      printf '%s' "$entry_secret"
      return 0
    fi
  done
  return 1
}

hmac_signature() {
  local director="$1"
  local secret_b64="$2"
  local master_key_b64="$3"
  local secret_hex digest
  secret_hex="$(printf '%s' "$secret_b64" | base64 --decode | od -An -tx1 | tr -d ' \n')"
  digest="$(printf 'vault-arm:v1:%s:%s' "$director" "$master_key_b64" \
    | openssl dgst -sha256 -mac HMAC -macopt "hexkey:${secret_hex}" -binary \
    | base64 | tr -d '\n')"
  printf 'v1:%s' "$digest"
}

ensure_local_env() {
  require_openssl

  if [[ ! -f "$ENV_FILE" ]]; then
    info "Creating local .env with generated secrets."
    {
      printf '# Kerosene local environment generated by backend/kerosene-infrastructure/scripts/init-local.sh\n'
      printf '# Do not commit this file.\n'
    } > "$ENV_FILE"
    chmod 600 "$ENV_FILE" 2>/dev/null || true
  fi

  local changed=0
  ensure_env_value POSTGRES_USER "api_system" && changed=1 || true
  ensure_env_value API_KEY "$(rand_hex 32)" && changed=1 || true
  ensure_env_value POSTGRES_PASSWORD "$(rand_b64 36)" && changed=1 || true
  ensure_env_value REDIS_PASSWORD "$(rand_b64 36)" && changed=1 || true
  ensure_env_value JWT_SECRET "$(rand_b64 64)" && changed=1 || true
  ensure_env_value PASSWORD_PEPPER "$(rand_b64 64)" && changed=1 || true
  ensure_env_value HMAC_SECRET_KEY "$(rand_b64 64)" && changed=1 || true
  ensure_env_value AES_SECRET "$(rand_b64 32)" && changed=1 || true
  ensure_env_value SHARD_SECRET_KEY_IS "$(rand_hex 32)" && changed=1 || true
  ensure_env_value SHARD_SECRET_KEY_CH "$(rand_hex 32)" && changed=1 || true
  ensure_env_value SHARD_SECRET_KEY_SG "$(rand_hex 32)" && changed=1 || true
  ensure_env_value FOUNDER_TOTP_SECRET "$(rand_base32)" && changed=1 || true
  ensure_env_value LND_WALLET_PASSWORD "$(rand_b64 32)" && changed=1 || true
  ensure_env_value MPC_MASTER_KEY_B64 "$(rand_b64 32)" && changed=1 || true
  ensure_env_value VAULT_CLUSTER_ATTESTATION_SECRET "$(rand_b64 32)" && changed=1 || true
  ensure_env_value BITCOIN_RPC_PASSWORD "$(rand_b64 32)" && changed=1 || true
  ensure_env_value RELEASE_ATTESTATION_SECRET "$(rand_b64 32)" && changed=1 || true

  ensure_env_value VAULT_REQUIRED_APPROVALS "2" && changed=1 || true
  ensure_env_value VAULT_ARM_DIRECTORS "director-1,director-2" && changed=1 || true

  local director_secrets
  director_secrets="$(env_value VAULT_DIRECTOR_HMAC_SECRETS || true)"
  if [[ -z "$director_secrets" || "$director_secrets" == CHANGE_ME* ]] ||
     ! director_secret director-1 "$director_secrets" >/dev/null ||
     ! director_secret director-2 "$director_secrets" >/dev/null; then
    director_secrets="director-1:$(rand_b64 32),director-2:$(rand_b64 32),director-3:$(rand_b64 32)"
    set_env_value VAULT_DIRECTOR_HMAC_SECRETS "$director_secrets"
    changed=1
  fi

  local aes_secret director_1_secret director_2_secret director_3_secret
  aes_secret="$(env_value AES_SECRET)"
  director_1_secret="$(director_secret director-1 "$director_secrets")"
  director_2_secret="$(director_secret director-2 "$director_secrets")"
  director_3_secret="$(director_secret director-3 "$director_secrets" || true)"
  set_env_value DIRECTOR_1_ARM_SIGNATURE "$(hmac_signature director-1 "$director_1_secret" "$aes_secret")"
  set_env_value DIRECTOR_2_ARM_SIGNATURE "$(hmac_signature director-2 "$director_2_secret" "$aes_secret")"
  if [[ -n "$director_3_secret" ]]; then
    set_env_value DIRECTOR_3_ARM_SIGNATURE "$(hmac_signature director-3 "$director_3_secret" "$aes_secret")"
  fi

  ensure_env_value APP_CORS_ALLOWED_ORIGINS "http://localhost:3000,http://localhost:8080,http://localhost:8081,http://localhost:8082" && changed=1 || true
  webauthn_rp_id="$(env_value WEBAUTHN_RP_ID || true)"
  if [[ -z "$webauthn_rp_id" || "$webauthn_rp_id" == CHANGE_ME* || "$webauthn_rp_id" == "localhost" ]]; then
    set_env_value WEBAUTHN_RP_ID "kerosene-device"
    changed=1
  fi
  ensure_env_value WEBAUTHN_RP_NAME "Kerosene Local" && changed=1 || true
  ensure_env_value WEBAUTHN_ORIGINS "http://localhost:3000,http://localhost:8080,http://localhost:8081,http://localhost:8082" && changed=1 || true
  ensure_env_csv_contains WEBAUTHN_ORIGINS "android:apk-key-hash:kerosene" && changed=1 || true
  ensure_env_value WEB_ADMIN_PORT "3000" && changed=1 || true
  ensure_env_value PROMETHEUS_PORT "19090" && changed=1 || true

  ensure_env_value BITCOIN_NETWORK "mainnet" && changed=1 || true
  ensure_env_value BITCOIN_CHAIN "mainnet" && changed=1 || true
  ensure_env_value BITCOIN_CORE_IMAGE "bitcoin/bitcoin:27.1" && changed=1 || true
  if [[ "$(env_value BITCOIN_CORE_IMAGE || true)" == ruimarinho/bitcoin-core* ]]; then
    set_env_value BITCOIN_CORE_IMAGE "bitcoin/bitcoin:27.1"
    changed=1
  fi
  if [[ "$(env_value BITCOIN_NETWORK || true)" == "testnet" ]]; then
    set_env_value BITCOIN_NETWORK "mainnet"
    changed=1
  fi
  if [[ "$(env_value BITCOIN_CHAIN || true)" == "regtest" ]]; then
    set_env_value BITCOIN_CHAIN "mainnet"
    changed=1
  fi
  ensure_env_value BITCOIN_PRUNE_MB "5500" && changed=1 || true
  ensure_env_value BITCOIN_MAX_MEMPOOL_MB "300" && changed=1 || true
  ensure_env_value BITCOIN_DBCACHE_MB "1024" && changed=1 || true
  ensure_env_value BITCOIN_P2P_PORT "8333" && changed=1 || true
  ensure_env_value BITCOIN_RPC_ENABLED "true" && changed=1 || true
  ensure_env_value BITCOIN_RPC_REQUIRED "true" && changed=1 || true
  ensure_env_value BITCOIN_RPC_PRUNED_REQUIRED "true" && changed=1 || true
  ensure_env_value BITCOIN_RPC_USER "kerosene" && changed=1 || true
  ensure_env_value BITCOIN_RPC_URL "http://bitcoin-pruned-node:8332" && changed=1 || true
  ensure_env_value BITCOIN_RPC_WALLET "kerosene" && changed=1 || true
  ensure_optional_env_value BITCOIN_WALLET_PASSPHRASE "" && changed=1 || true
  ensure_env_value BITCOIN_ZMQ_ENABLED "true" && changed=1 || true
  ensure_env_value BITCOIN_ZMQ_RAWTX "tcp://bitcoin-pruned-node:28332" && changed=1 || true
  ensure_env_value BITCOIN_ZMQ_HASHBLOCK "tcp://bitcoin-pruned-node:28333" && changed=1 || true
  ensure_env_value BITCOIN_ZMQ_RAWBLOCK "tcp://bitcoin-pruned-node:28334" && changed=1 || true
  if [[ "$(env_value BITCOIN_RPC_URL || true)" == "http://bitcoin-core:8332" ]]; then
    set_env_value BITCOIN_RPC_URL "http://bitcoin-pruned-node:8332"
    changed=1
  fi
  if [[ "$(env_value BITCOIN_ZMQ_RAWTX || true)" == "tcp://bitcoin-core:28332" ]]; then
    set_env_value BITCOIN_ZMQ_RAWTX "tcp://bitcoin-pruned-node:28332"
    changed=1
  fi
  if [[ "$(env_value BITCOIN_ZMQ_HASHBLOCK || true)" == "tcp://bitcoin-core:28333" ]]; then
    set_env_value BITCOIN_ZMQ_HASHBLOCK "tcp://bitcoin-pruned-node:28333"
    changed=1
  fi
  if [[ "$(env_value BITCOIN_ZMQ_RAWBLOCK || true)" == "tcp://bitcoin-core:28334" ]]; then
    set_env_value BITCOIN_ZMQ_RAWBLOCK "tcp://bitcoin-pruned-node:28334"
    changed=1
  fi
  ensure_env_value BITCOIN_ESPLORA_ENABLED "false" && changed=1 || true
  ensure_optional_env_value BITCOIN_INDEXER_BASE_URL "" && changed=1 || true
  ensure_optional_env_value BITCOIN_FEE_RECOMMENDATION_URL "" && changed=1 || true
  if [[ "$(env_value BITCOIN_INDEXER_BASE_URL || true)" == "http://bitcoin-indexer:3002" ]]; then
    set_env_value BITCOIN_INDEXER_BASE_URL ""
    changed=1
  fi
  ensure_env_value VAULT_RAFT_ENABLED "true" && changed=1 || true
  ensure_env_value VAULT_RAFT_REQUIRED "true" && changed=1 || true
  ensure_env_value VAULT_RAFT_EXPECTED_SERVERS "3" && changed=1 || true
  local current_raft_url
  current_raft_url="$(env_value VAULT_RAFT_URL || true)"
  if [[ "$current_raft_url" == http://vault-raft-1:* ]]; then
    set_env_value VAULT_RAFT_URL "https://vault-raft-1:8200"
    changed=1
  fi
  ensure_env_value VAULT_RAFT_URL "https://vault-raft-1:8200" && changed=1 || true
  ensure_env_value VAULT_RAFT_TOKEN_FILE "/vault-raft/app-health-token" && changed=1 || true
  if [[ "$(env_value VAULT_RAFT_TOKEN_FILE || true)" == "/vault-raft/root-token" ]]; then
    set_env_value VAULT_RAFT_TOKEN_FILE "/vault-raft/app-health-token"
    changed=1
  fi
  ensure_env_value RELEASE_ATTESTATION_REQUIRED "false" && changed=1 || true
  ensure_env_value RELEASE_REMOTE_ATTESTATION_ENABLED "false" && changed=1 || true
  ensure_env_value RELEASE_MANIFEST_PATH "/release/release-manifest.json" && changed=1 || true
  ensure_env_value RELEASE_MANIFEST_SIGNATURE_PATH "/release/release-manifest.json.sig" && changed=1 || true
  ensure_env_value RELEASE_MANIFEST_PUBLIC_KEY_PATH "/release/release-public-key.der.b64" && changed=1 || true
  ensure_env_value GIT_COMMIT "unknown" && changed=1 || true
  ensure_env_value BUILD_TIME "unknown" && changed=1 || true
  ensure_env_value IMAGE_DIGEST "unknown" && changed=1 || true
  ensure_env_value CODE_HASH "unknown" && changed=1 || true
  ensure_env_value CONFIG_HASH "unknown" && changed=1 || true
  ensure_env_value MOBILE_RELEASE_VERSION "1.0.0" && changed=1 || true
  ensure_env_value MOBILE_RELEASE_BUILD_NUMBER "1" && changed=1 || true
  ensure_env_value MOBILE_ANDROID_SHA256 "80158a61b982eb4db95cd010d63ca3d5b52d3e2215c8d9df046a6609db960582" && changed=1 || true
  ensure_env_value LIGHTNING_LND_IMAGE "lightninglabs/lnd:v0.20.1-beta" && changed=1 || true
  ensure_env_value LIGHTNING_LND_ENABLED "true" && changed=1 || true
  ensure_env_value LIGHTNING_LND_HOST "lnd-bitcoind" && changed=1 || true
  if [[ "$(env_value LIGHTNING_LND_HOST || true)" == "lnd-neutrino" ]]; then
    set_env_value LIGHTNING_LND_HOST "lnd-bitcoind"
    changed=1
  fi
  ensure_env_value LIGHTNING_LND_BITCOIN_NODE "bitcoind" && changed=1 || true
  ensure_env_value LIGHTNING_LND_PORT "10009" && changed=1 || true
  ensure_env_value LIGHTNING_LND_REST_PORT "8080" && changed=1 || true
  ensure_env_value LIGHTNING_LND_TLS_ENABLED "true" && changed=1 || true
  ensure_env_value LIGHTNING_LND_TLS_SERVER_NAME "lnd-bitcoind" && changed=1 || true
  if [[ "$(env_value LIGHTNING_LND_TLS_SERVER_NAME || true)" == "localhost" ]]; then
    set_env_value LIGHTNING_LND_TLS_SERVER_NAME "lnd-bitcoind"
    changed=1
  fi
  ensure_env_value LIGHTNING_LND_TLS_EXTRA_DOMAINS "lnd-bitcoind,lnd-neutrino,localhost" && changed=1 || true
  ensure_env_value LIGHTNING_LND_TLS_EXTRA_IPS "127.0.0.1" && changed=1 || true
  ensure_env_value LIGHTNING_LND_TLS_CERT_PATH "/lnd/tls.cert" && changed=1 || true
  ensure_env_value LIGHTNING_LND_MACAROON_PATH "/lnd/data/chain/bitcoin/mainnet/admin.macaroon" && changed=1 || true
  if [[ "$(env_value LIGHTNING_LND_MACAROON_PATH || true)" == "/lnd/data/chain/bitcoin/testnet/admin.macaroon" ]]; then
    set_env_value LIGHTNING_LND_MACAROON_PATH "/lnd/data/chain/bitcoin/mainnet/admin.macaroon"
    changed=1
  fi
  ensure_env_value LIGHTNING_LND_PROVIDER_NAME "LND_BITCOIND_PRUNED" && changed=1 || true
  if [[ "$(env_value LIGHTNING_LND_PROVIDER_NAME || true)" == "LND_NEUTRINO" ]]; then
    set_env_value LIGHTNING_LND_PROVIDER_NAME "LND_BITCOIND_PRUNED"
    changed=1
  fi
  ensure_env_value LIGHTNING_LND_ALIAS "kerosene-lnd-bitcoind-local" && changed=1 || true
  if [[ "$(env_value LIGHTNING_LND_ALIAS || true)" == "kerosene-neutrino-local" ]]; then
    set_env_value LIGHTNING_LND_ALIAS "kerosene-lnd-bitcoind-local"
    changed=1
  fi
  local lnd_color
  lnd_color="$(env_value LIGHTNING_LND_COLOR || true)"
  if [[ -z "$lnd_color" || "$lnd_color" == CHANGE_ME* || "$lnd_color" == \#* ]]; then
    set_env_value LIGHTNING_LND_COLOR "'#D1495B'"
    changed=1
  fi
  ensure_env_value LIGHTNING_LND_BOOTSTRAP_TIMEOUT_SECONDS "180" && changed=1 || true

  ensure_optional_env_value QUORUM_SHARD_URLS "" && changed=1 || true
  ensure_optional_env_value BITCOIN_PLATFORM_MASTER_XPUB "" && changed=1 || true
  ensure_env_value TRANSACTIONS_LOCAL_DERIVED_ADDRESS_FALLBACK_ENABLED "false" && changed=1 || true
  if [[ "$(env_value TRANSACTIONS_LOCAL_DERIVED_ADDRESS_FALLBACK_ENABLED || true)" == "true" ]]; then
    set_env_value TRANSACTIONS_LOCAL_DERIVED_ADDRESS_FALLBACK_ENABLED "false"
    changed=1
  fi
  ensure_env_value TRANSACTIONS_BITCOIN_CORE_WALLET_ADDRESS_ENABLED "true" && changed=1 || true

  if [[ "$changed" -eq 1 ]]; then
    info "Local .env generated/updated with missing secrets. Existing non-empty values were preserved."
  else
    info "Local .env already has required secrets."
  fi
}

restore_invoking_user_ownership() {
  if [[ "${EUID:-$(id -u)}" -ne 0 || -z "${SUDO_UID:-}" || -z "${SUDO_GID:-}" || "${SUDO_UID}" == "0" ]]; then
    return
  fi

  chown "$SUDO_UID:$SUDO_GID" "$ENV_FILE" 2>/dev/null || true
  chown "$SUDO_UID:$SUDO_GID" \
    "$TOR_DIR/torrc-is" \
    "$TOR_DIR/torrc-ch" \
    "$TOR_DIR/torrc-sg" \
    "$TOR_DIR/torrc-vault" 2>/dev/null || true
}

# ── 1. Validate .env ──────────────────────────────────────────────────────────
ensure_local_env

load_env_file

REQUIRED_VARS=(
  POSTGRES_USER
  API_KEY
  POSTGRES_PASSWORD
  REDIS_PASSWORD
  JWT_SECRET
  PASSWORD_PEPPER
  FOUNDER_TOTP_SECRET
  AES_SECRET
  HMAC_SECRET_KEY
  SHARD_SECRET_KEY_IS
  SHARD_SECRET_KEY_CH
  SHARD_SECRET_KEY_SG
  LND_WALLET_PASSWORD
  MPC_MASTER_KEY_B64
  VAULT_CLUSTER_ATTESTATION_SECRET
  BITCOIN_RPC_PASSWORD
  RELEASE_ATTESTATION_SECRET
  VAULT_DIRECTOR_HMAC_SECRETS
  DIRECTOR_1_ARM_SIGNATURE
  DIRECTOR_2_ARM_SIGNATURE
)
for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then error "Missing required variable: $var"; fi
done
info "Environment variables validated. ✓"

# ── 2. TLS certificates ───────────────────────────────────────────────────────
if [[ ! -f "$CERTS_DIR/rootCA.crt" ]]; then
  CERTS_DIR="$CERTS_DIR" bash "$BACKEND_DEPLOY_DIR/host/cert-generator.sh" || warn "Cert generator failed, check if it exists."
fi

# ── 2b. Vault Raft TLS certificates ──────────────────────────────────────────
VAULT_RAFT_CERTS_DIR="$INFRA_DIR/vault/raft/certs"
if [[ ! -f "$VAULT_RAFT_CERTS_DIR/ca.pem" ]]; then
  require_openssl
  mkdir -p "$VAULT_RAFT_CERTS_DIR"
  openssl req -x509 -new -nodes -days 3650 \
    -subj "/CN=Vault Raft Local CA" \
    -keyout "$VAULT_RAFT_CERTS_DIR/ca-key.pem" \
    -out "$VAULT_RAFT_CERTS_DIR/ca.pem"
  for node in vault-raft-1 vault-raft-2 vault-raft-3; do
    cat > "$VAULT_RAFT_CERTS_DIR/$node.ext" << EXTEOF
subjectAltName = DNS:$node, DNS:localhost, IP:127.0.0.1
EXTEOF
    openssl genrsa -out "$VAULT_RAFT_CERTS_DIR/$node-key.pem" 2048
    openssl req -new -key "$VAULT_RAFT_CERTS_DIR/$node-key.pem" \
      -subj "/CN=$node" \
      -out "$VAULT_RAFT_CERTS_DIR/$node.csr"
    openssl x509 -req -days 3650 \
      -in "$VAULT_RAFT_CERTS_DIR/$node.csr" \
      -CA "$VAULT_RAFT_CERTS_DIR/ca.pem" \
      -CAkey "$VAULT_RAFT_CERTS_DIR/ca-key.pem" \
      -CAcreateserial \
      -extfile "$VAULT_RAFT_CERTS_DIR/$node.ext" \
      -out "$VAULT_RAFT_CERTS_DIR/$node.pem"
    rm -f "$VAULT_RAFT_CERTS_DIR/$node.csr" "$VAULT_RAFT_CERTS_DIR/$node.ext"
  done
  chmod 600 "$VAULT_RAFT_CERTS_DIR/ca-key.pem" "$VAULT_RAFT_CERTS_DIR"/*-key.pem
  chmod 644 "$VAULT_RAFT_CERTS_DIR/ca.pem" "$VAULT_RAFT_CERTS_DIR"/*.pem
  info "Vault Raft TLS certs generated in $VAULT_RAFT_CERTS_DIR"
fi

# ── 3. Tor Configs (Force LF Line Endings) ──────────────────────────────────
fix_torrc() {
  local file=$1
  local app_service=$2
  info "Generating $file..."
  # Use printf to ensure no \r and strict format
  printf "User kerosene\nSocksPort unix:/var/run/tor/socks/tor.sock WorldWritable\nControlSocket /var/run/tor/control/control\nControlSocketsGroupWritable 1\nCookieAuthentication 1\nCookieAuthFile /var/run/tor/control/control_auth_cookie\nCookieAuthFileGroupReadable 1\nHiddenServiceDir /var/lib/tor/kerosene_service/\nHiddenServiceVersion 3\nHiddenServicePort 80 %s:8080\nLog notice stdout\nDataDirectory /var/lib/tor\nNumCPUs 1\n" "$app_service" > "$file"
}

fix_torrc "$TOR_DIR/torrc-is" "10.241.0.10"
fix_torrc "$TOR_DIR/torrc-ch" "10.241.0.11"
fix_torrc "$TOR_DIR/torrc-sg" "10.241.0.12"

info "Generating $TOR_DIR/torrc-vault..."
printf "User kerosene\nSocksPort 0\nHiddenServiceDir /var/lib/tor/kerosene_service/\nHiddenServiceVersion 3\nHiddenServicePort 80 10.242.0.10:8090\nLog notice stdout\nDataDirectory /var/lib/tor\nNumCPUs 1\n" > "$TOR_DIR/torrc-vault"

restore_invoking_user_ownership

info "Initialization complete."
echo "  bash scripts/start-local.sh"
