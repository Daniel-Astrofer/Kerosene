#!/bin/bash
# ==============================================================================
# Kerosene - Remote Shard Gatekeeper (Server-Side watchdog)
# ==============================================================================
# Runs inside the Shard (e.g., via cron or systemd path monitor).
# Watches /tmp for incoming 'kerosene*.jar' and its signature.
# Validates against the pre-provisioned Admin Public Key.
# Swaps it into production atomically if valid.
# ==============================================================================

WATCH_DIR="/tmp"
PROD_DIR="/opt/kerosene"
PUB_KEY="/etc/kerosene/admin_pub.pem"
SERVICE_NAME="kerosene-shard"

# Check if new files arrived
if [ ! -f "$WATCH_DIR/kerosene.sig" ]; then
    exit 0 # Nothing to do
fi

# Find the JAR (It might be named kerosene-PRE-ALPHA.jar)
JAR_FILE=$(ls $WATCH_DIR/*.jar 2>/dev/null | head -n 1)

if [ -z "$JAR_FILE" ]; then
    echo "[Gatekeeper] Signature found but no JAR file. Cleaning up."
    rm -f "$WATCH_DIR"/kerosene.sig
    exit 1
fi

echo "[Gatekeeper] New deployment payload detected. Initiating Cryptographic Verification."

# Verify Signature
openssl pkeyutl -verify -pubin -inkey "$PUB_KEY" \
    -sigfile "$WATCH_DIR/kerosene.sig" \
    -in <(openssl dgst -sha256 -binary "$JAR_FILE")

if [ $? -eq 0 ]; then
    echo "[Gatekeeper] [SUCCESS] Signature Validated. Binary originates from Trusted Admin."
    echo "[Gatekeeper] Performing Atomic Swap."
    
    # Backup old
    if [ -f "$PROD_DIR/app.jar" ]; then
        mv "$PROD_DIR/app.jar" "$PROD_DIR/app.jar.bak"
    fi

    # Swap
    mv "$JAR_FILE" "$PROD_DIR/app.jar"
    
    # Cleanup signature
    rm -f "$WATCH_DIR/kerosene.sig"
    
    echo "[Gatekeeper] Restarting Kerosene Service..."
    systemctl restart "$SERVICE_NAME"
    echo "[Gatekeeper] Deployment Completed and Service Restarted."

else
    echo "[Gatekeeper] [ALARM] CRITICAL BREACH. INVALID SIGNATURE DETECTED."
    echo "[Gatekeeper] The binary fails cryptographic checks! Deleting malicious payload."
    rm -f "$JAR_FILE" "$WATCH_DIR/kerosene.sig"
    
    # Optional: Send alarm to Admin via Matrix or Webhook
    # curl -X POST -H 'Content-type: application/json' --data '{"text":"[SHARD ALARM] Invalid JAR signature deployed to /tmp"}' https://matrix.org/...
    
    exit 1
fi
