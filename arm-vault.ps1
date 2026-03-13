# KEROSENE - Vault Arming Utility (Lab Quorum)
# ------------------------------------------------------------------------------
# This script arms the vault by simulating two independent director approvals
# with a shared master key.
# ------------------------------------------------------------------------------

$PROJ_NAME = "kerosene"
$NET_NAME = "${PROJ_NAME}_net_vault"
$VAULT_URL = "http://kerosene-vault:8090/v1/vault/arm"
$MASTER_KEY = "PhfLUTzM/N8FPNofkH9a+5HpXdAEhZu+kR9ZpjNJ7XQ=" # Coincident with .env AES_SECRET (32 bytes)

Write-Host "`n[1/3] Checking Docker connectivity..." -ForegroundColor Cyan
if (!(docker info 2>$null)) {
    Write-Error "Docker is not running. Please start Docker Desktop first."
    exit 1
}

Write-Host "[2/3] Director 1: Submitting signature..." -ForegroundColor Yellow
docker run --rm --network $NET_NAME alpine sh -c "apk add --no-cache curl > /dev/null && curl -s -X POST $VAULT_URL -H 'X-Director-Id: director-1' -H 'X-Director-Signature: SIGNATURE_DIRECTOR_1_LAB' -H 'Content-Type: application/json' -d '{\`"master_key\`": \`"$MASTER_KEY\`"}'"

Write-Host "`n"
Write-Host "[3/3] Director 2: Submitting signature (Quorum Reached)..." -ForegroundColor Yellow
docker run --rm --network $NET_NAME alpine sh -c "apk add --no-cache curl > /dev/null && curl -s -X POST $VAULT_URL -H 'X-Director-Id: director-2' -H 'X-Director-Signature: SIGNATURE_DIRECTOR_2_LAB' -H 'Content-Type: application/json' -d '{\`"master_key\`": \`"$MASTER_KEY\`"}'"

Write-Host "`n[SUCCESS] If 'Vault is ARMED' appeared above, the system is ready." -ForegroundColor Green
Write-Host "The vault is now locked in RAM and ready to provision Shards.`n"
