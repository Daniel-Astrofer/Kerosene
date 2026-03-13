#!/bin/bash
# ==============================================================================
# Kerosene - Remote Shard Deployment Script (Client-Side)
# ==============================================================================
# This script securely compiles the JVM binary, signs it mathematically,
# and pushes it through Tor SOCKS5 to the remote hidden service over SSH.
#
# Usage: ./deploy_shard.sh <onion_address> <private_key_path> <shard_name>
# Example: ./deploy_shard.sh xp4...onion ~/.ssh/admin_ed25519 ./kerosene
# ==============================================================================

set -e

ONION_ADDR=$1
PRIV_KEY=$2
PROJECT_DIR=$3

if [ -z "$ONION_ADDR" ] || [ -z "$PRIV_KEY" ] || [ -z "$PROJECT_DIR" ]; then
    echo "Usage: ./deploy_shard.sh <onion_address> <private_signing_key.pem> <project_dir>"
    echo "This key MUST NOT be your SSH key. It is the Code Signing Key."
    exit 1
fi

echo "[1/4] Starting Kerosene Gradle Build..."
cd "$PROJECT_DIR"
./gradlew clean bootJar -x test
cd -

JAR_PATH="$PROJECT_DIR/build/libs/kerosene-PRE-ALPHA.jar"

if [ ! -f "$JAR_PATH" ]; then
    echo "ERRO: JAR não encontrado em $JAR_PATH."
    exit 1
fi

echo "[2/4] Generating Cryptographic Signature..."
openssl dgst -sha256 -binary "$JAR_PATH" > /tmp/kerosene.hash
openssl pkeyutl -sign -in /tmp/kerosene.hash -inkey "$PRIV_KEY" -out /tmp/kerosene.sig
rm /tmp/kerosene.hash

echo "[3/4] Secure Transmit via SOCKS5 (Tor) to $ONION_ADDR..."
# Assume the Tor proxy is running locally on 9050.
# The SSH key for connection should be handling Auth independently.
scp -o "ProxyCommand=nc -X 5 -x 127.0.0.1:9050 %h %p" \
    "$JAR_PATH" /tmp/kerosene.sig \
    "admin@$ONION_ADDR:/tmp/"

echo "[4/4] Deployment pushed to remote /tmp. Awaiting Remote Gatekeeper Atomic Swap."
rm /tmp/kerosene.sig
echo "Limpeza local concluída. Deploy executado com sucesso."
