#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Kerosene Production Kubernetes Deployment Script
# ═══════════════════════════════════════════════════════════════════════════════
# This script creates the production namespace and applies all critical 
# infrastructure components in the correct order.

set -euo pipefail

NAMESPACE="kerosene-production"

echo "[*] Checking cluster connection..."
kubectl cluster-info

echo "[*] Creating production namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 1. Apply Databases (Postgres & Redis HA)
echo "[*] Deploying Highly Available Databases..."
kubectl apply -f postgres-patroni.yaml
kubectl apply -f redis-sentinel.yaml

# 2. Apply Vault Raft Cluster
echo "[*] Deploying Vault Raft Cluster..."
kubectl apply -f vault-raft.yaml

# 3. Apply Bitcoin Core and Lightning Network
echo "[*] Deploying Bitcoin Core Full Node..."
kubectl apply -f bitcoin.yaml
echo "[*] Deploying Lightning Network Daemon (LND)..."
kubectl apply -f lnd.yaml

# 4. Apply Kerosene Application
echo "[*] Deploying Kerosene Application..."
kubectl apply -f server.yaml

echo "[+] Deployment manifests submitted."
echo "[!] IMPORTANT: Pods will remain Pending if LUKS storage classes or Secrets are missing."
echo "    Ensure 'kerosene-db-secrets', 'kerosene-redis-secrets', and 'kerosene-lnd-secrets' are created."
