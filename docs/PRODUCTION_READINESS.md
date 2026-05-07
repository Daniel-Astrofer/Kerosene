# Production Readiness

This document records the concrete gates required before Kerosene is treated as production-ready.

## Current Status

Kerosene is production-oriented but still pre-launch until the operational secrets, release artifacts, and live infrastructure values are configured and verified.

Implemented readiness controls:

- Android release builds require a real upload keystore unless `KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING=true` is set for local non-production builds.
- Android cleartext traffic is disabled globally, with a scoped localhost exception for the app-local Tor relay.
- Account activation no longer accepts manual TXID confirmation from the client. Activation is driven by the backend network-transfer monitor.
- Legacy deposit endpoints in the client now read `/transactions/network/transfers`.
- Backend `prod` profile validates schema, enables Flyway, refuses mocks, requires live Bitcoin RPC, Vault/Raft, MPC mTLS, LND, Tor health, and release attestation.
- `/v1/audit/siphon` fails closed unless `treasury.siphon.manual-settlement-enabled=true`; the `prod` safety check rejects that flag so simulated/manual fee collection cannot run in production.
- Vault runtime image runs as distroless nonroot, with only `IPC_LOCK` re-added in Compose and explicit memlock limits for off-heap key material.
- MPC sidecar runtime image runs as a nonroot `kerosene` user and exposes a Docker healthcheck against `/version`.
- Vault shard provision tokens are random 256-bit bearer tokens, single-use, in-memory only, and expire by `VAULT_PROVISION_TOKEN_TTL_MS`.
- CI runs backend tests/build/image, Vault build/image, Flutter analyze/tests/web build, Android release smoke build on PRs, Go sidecar tests/image, Docker Compose config validation, and OWASP dependency scan on non-PR builds.

## Required Before Launch

- Replace all `.env.example` placeholder values with real production values outside git.
- Configure `APP_CORS_ALLOWED_ORIGINS`, `WEBAUTHN_RP_ID`, and `WEBAUTHN_ORIGINS` with the exact public app hosts. Localhost and wildcard origins fail in `prod`.
- Provide `QUORUM_SHARD_URLS`, `BITCOIN_PLATFORM_MASTER_XPUB`, Bitcoin RPC credentials/ZMQ endpoints, LND TLS/macaroon material, Vault/Raft token material, and MPC mTLS files.
- Generate a release manifest and enable `RELEASE_ATTESTATION_REQUIRED=true` and `RELEASE_REMOTE_ATTESTATION_ENABLED=true`.
- Store Android signing secrets in CI as `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD`.
- Configure `NVD_API_KEY` in CI so dependency scanning is reliable and does not rely on anonymous NVD throttling.
- Confirm the production orchestrator preserves the Vault `IPC_LOCK`, `memlock`, `no-new-privileges`, nonroot user, and no host port binding constraints.
- Replace the manual `/v1/audit/siphon` settlement mode with a real treasury payout executor before enabling automated fee collection.
- Run a full staging launch against real Postgres, Redis, Vault/Raft, MPC sidecar, Bitcoin Core pruned node, and LND.

## Validation Commands

```bash
(cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test)
(cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew bootJar)
(cd backend/vault && mvn package)
(cd backend/mpc-sidecar && go test ./...)
(cd frontend && flutter analyze && flutter test)
(cd frontend && KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING=true flutter build apk --release)
./scripts/run-android-release-local.sh
(cd backend/kerosene && docker compose --env-file .env config --quiet)
docker build -t kerosene-api:validation ./backend/kerosene
docker build -t kerosene-vault:validation ./backend/vault
docker build -t kerosene-mpc-sidecar:validation ./backend/mpc-sidecar
podman build --format docker -t kerosene-mpc-sidecar:validation-docker-format ./backend/mpc-sidecar
podman run -d --name kerosene-mpc-healthcheck -e MPC_ALLOW_INSECURE_GRPC=true kerosene-mpc-sidecar:validation-docker-format
sleep 3
podman exec kerosene-mpc-healthcheck wget -q -O - http://127.0.0.1:8081/version
podman inspect kerosene-mpc-healthcheck --format 'state={{.State.Status}} health={{if .State.Healthcheck}}{{.State.Healthcheck.Status}}{{else}}n/a{{end}}'
podman rm -f kerosene-mpc-healthcheck
```

For a real release build, do not use `KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING`. Provide the upload keystore variables instead.
`./scripts/run-android-release-local.sh` is a convenience wrapper for `flutter run --release` on a local device with debug signing explicitly enabled.
The Compose validation requires a filled local `.env`; CI injects placeholder values only to validate syntax.
Run `./gradlew dependencyCheckAnalyze` only with `NVD_API_KEY` configured; anonymous NVD updates are too slow for a reliable production gate.
