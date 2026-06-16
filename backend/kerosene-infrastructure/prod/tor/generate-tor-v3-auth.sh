#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Kerosene Tor V3 Client Authorization Key Generator (OFFLINE CEREMONY)
# ═══════════════════════════════════════════════════════════════════════════════
# This script must be run on an offline, air-gapped machine (Amnesic OS like Tails).
# It generates the x25519 keypairs required for Tor V3 Client Authorization.
#
# Usage: ./generate-tor-v3-auth.sh <client_name>
# Example: ./generate-tor-v3-auth.sh kerosene-app-is

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <client_name>"
    exit 1
fi

CLIENT_NAME="$1"

if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 is required."
    exit 1
fi

if ! python3 -c "import nacl" &> /dev/null; then
    echo "ERROR: PyNaCl is required. Install with: pip3 install pynacl"
    exit 1
fi

echo "[*] Generating Ed25519/X25519 keypair for client: $CLIENT_NAME"

python3 - <<EOF
import base64
from nacl.public import PrivateKey

# Generate private key
priv_key = PrivateKey.generate()
# Derive public key
pub_key = priv_key.public_key

# Encode keys to base32 (without padding)
priv_b32 = base64.b32encode(bytes(priv_key)).decode('utf-8').replace('=', '')
pub_b32 = base64.b32encode(bytes(pub_key)).decode('utf-8').replace('=', '')

client_name = "${CLIENT_NAME}"

# Write the client side file (.auth_private)
with open(f"{client_name}.auth_private", "w") as f:
    f.write(f"{client_name}:descriptor:x25519:{priv_b32}\n")

# Write the hidden service side file (.auth)
with open(f"{client_name}.auth", "w") as f:
    f.write(f"descriptor:x25519:{pub_b32}\n")

print(f"[+] Successfully generated keys for {client_name}")
print(f"    Private file: {client_name}.auth_private (Distribute to Tor Client node)")
print(f"    Public file:  {client_name}.auth         (Place in Vault HiddenServiceDir/authorized_clients/)")
EOF

chmod 400 "${CLIENT_NAME}.auth_private"
chmod 400 "${CLIENT_NAME}.auth"

echo "[!] SECRETS GENERATED. Store ${CLIENT_NAME}.auth_private securely."
