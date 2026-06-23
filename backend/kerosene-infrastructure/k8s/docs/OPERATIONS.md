# Kerosene Kubernetes Operations

This directory is the production-ready Kubernetes entrypoint for Kerosene's backend runtime.

## Deploy

Production must use immutable image tags or digests.

```bash
export KEROSENE_APP_IMAGE='registry.example.com/kerosene/kerosene-app@sha256:REPLACE'
export MPC_SIDECAR_IMAGE='registry.example.com/kerosene/mpc-sidecar@sha256:REPLACE'
export WEB_ADMIN_IMAGE='registry.example.com/kerosene/web-admin@sha256:REPLACE'
backend/kerosene-infrastructure/k8s/scripts/deploy.sh production --dry-run
backend/kerosene-infrastructure/k8s/scripts/deploy.sh production
```

## Reset stateless instances

```bash
backend/kerosene-infrastructure/k8s/scripts/reset-instance.sh kerosene-production kerosene-app rollout
backend/kerosene-infrastructure/k8s/scripts/reset-instance.sh kerosene-production kerosene-app pods
```

## Reset stateful instance without deleting data

```bash
backend/kerosene-infrastructure/k8s/scripts/reset-instance.sh kerosene-production mpc-sidecar one-pod
```

This deletes the Pod only. The PVC remains attached to the StatefulSet identity.

## Debug distroless containers

The Java backend image is distroless and intentionally has no shell. Use an ephemeral debug container:

```bash
backend/kerosene-infrastructure/k8s/scripts/debug-pod.sh kerosene-production kerosene-app --shell
```

For production, pin the debug image by digest:

```bash
DEBUG_IMAGE='nicolaka/netshoot@sha256:REPLACE' \
  backend/kerosene-infrastructure/k8s/scripts/debug-pod.sh kerosene-production kerosene-app --shell
```

## Logs and previous crash logs

```bash
backend/kerosene-infrastructure/k8s/scripts/debug-pod.sh kerosene-production kerosene-app --logs
kubectl -n kerosene-production logs deployment/kerosene-app -c kerosene-app --tail=300
kubectl -n kerosene-production logs <pod> -c kerosene-app --previous --tail=300
```

## Diagnostics bundle

```bash
backend/kerosene-infrastructure/k8s/scripts/collect-diagnostics.sh kerosene-production
```

The script redacts common secret-like values before writing files.

## Rollback

```bash
backend/kerosene-infrastructure/k8s/scripts/rollback.sh kerosene-production kerosene-app
backend/kerosene-infrastructure/k8s/scripts/rollback.sh kerosene-production kerosene-app 3
```

## Scale

Manual:

```bash
kubectl -n kerosene-production scale deployment/kerosene-app --replicas=6
```

Automatic:

The base includes an HPA for `kerosene-app` with production overlay limits of 3 to 12 replicas.

## Security assumptions

- Namespace uses restricted Pod Security in production.
- Service accounts do not automount Kubernetes API tokens.
- All Pods are isolated by default-deny NetworkPolicy.
- Egress is only opened to explicitly declared dependencies.
- Backend and web containers use read-only root filesystems.
- Secrets are referenced by contract and must be created outside Git.
- Production deploy refuses `replace-me` image tags.

## Stateful dependency contracts

`base/dependency-services/services.yaml` creates stable Service names for the existing stateful workloads in `backend/kerosene-infrastructure/prod/k8s`. This keeps the backend app deployable through the new Kustomize stack while Postgres, Redis, Vault, Bitcoin Core and LND are migrated to dedicated operator-backed manifests.

## Required external services before production Pods become Ready

The production overlay expects these Services/Secrets to exist or be deployed by their dedicated stack:

- `kerosene-db-headless` and `kerosene-db-secrets`
- `kerosene-redis-headless` and `kerosene-redis-secrets`
- `kerosene-vault-raft-headless`
- `bitcoin-core` and `kerosene-bitcoin-secrets`
- `kerosene-lnd-headless` and `kerosene-lnd-secrets`
- `kerosene-mpc-secrets`
- optionally `kerosene-mpc-tls` and `kerosene-release-manifest`
