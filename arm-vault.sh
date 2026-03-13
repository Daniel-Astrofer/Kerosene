#!/bin/bash

# KEROSENE - Vault Arming Utility (Lab Quorum - Bash Version)
# ------------------------------------------------------------------------------

PROJ_NAME="kerosene"
NET_NAME="kerosene_net_vault"
VAULT_URL="http://kerosene-vault:8090/v1/vault/arm"
MASTER_KEY="PhfLUTzM/N8FPNofkH9a+5HpXdAEhZu+kR9ZpjNJ7XQ=" # Coincident with .env AES_SECRET (32 bytes)

echo -e "\n\033[0;36m[1/3] Checking Docker connectivity...\033[0m"
if ! docker info > /dev/null 2>&1; then
    echo -e "\033[0;31mError: Docker is not running or not accessible from WSL. Please start Docker Desktop and enable WSL integration.\033[0m"
    exit 1
fi

echo -e "\033[0;33m[2/3] Director 1: Submitting signature...\033[0m"
docker run --rm --network "$NET_NAME" alpine sh -c "apk add --no-cache curl > /dev/null && curl -s -X POST $VAULT_URL -H 'X-Director-Id: director-1' -H 'X-Director-Signature: SIGNATURE_DIRECTOR_1_LAB' -H 'Content-Type: application/json' -d '{\"master_key\": \"$MASTER_KEY\"}'"

echo -e "\n\033[0;33m[3/3] Director 2: Submitting signature (Quorum Reached)...\033[0m"
docker run --rm --network "$NET_NAME" alpine sh -c "apk add --no-cache curl > /dev/null && curl -s -X POST $VAULT_URL -H 'X-Director-Id: director-2' -H 'X-Director-Signature: SIGNATURE_DIRECTOR_2_LAB' -H 'Content-Type: application/json' -d '{\"master_key\": \"$MASTER_KEY\"}'"

echo -e "\n\033[0;32m[SUCCESS] If 'Vault is ARMED' appeared above, the system is ready.\033[0m"
echo -e "The vault is now locked in RAM and ready to provision Shards.\n"
