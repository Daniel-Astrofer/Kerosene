#!/bin/bash
# ==============================================================================
# KEROSENE - mTLS Certificate Generator (Simulação para Lab)
# ==============================================================================
# Cria a Autoridade Certificadora Root e os certificados TLS pro PostgreSQL 
# rejeitar todas as conexões baseadas apenas em texto de senha.
# ==============================================================================

set -e

CERTS_DIR="./certs"
mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

echo "[1/4] Generating Root CA..."
openssl genrsa -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt \
    -subj "/C=CH/ST=Zurich/L=Zurich/O=Kerosene Network/CN=Kerosene Root CA"

echo "[2/4] Generating PostgreSQL Server Certificate..."
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
    -subj "/C=CH/ST=Zurich/L=Zurich/O=Kerosene Server/CN=kerosene_db"
openssl x509 -req -in server.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
    -out server.crt -days 3650 -sha256

echo "[3/4] Generating Client Certificate (Backend Java / api_system)..."
# IMPORTANTE: O Common Name (CN) DEVE ser o usuário do banco (api_system)
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr \
    -subj "/C=CH/ST=Zurich/L=Zurich/O=Kerosene App/CN=api_system"
openssl x509 -req -in client.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
    -out client.crt -days 3650 -sha256

# Ajustar permissões exigidas pelo PostgreSQL (Ele não inicia se o key file for público)
chmod 0600 server.key rootCA.key client.key

echo "[4/4] Conversion to PKCS8 for Java JDBC compatibility..."
openssl pkcs8 -topk8 -inform PEM -outform DER -in client.key -out client.key.der -nocrypt

echo "mTLS Certificates generated successfully in ./certs/"
echo "-> server.crt / server.key (Para montar no container Postgres)"
echo "-> client.crt / client.key.der (Para apontar no SPRING_DATASOURCE_URL)"
