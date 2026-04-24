# Kerosene - Infrastructure

## Canonical Local Runtime

The canonical local cluster definition is:

- `backend/kerosene-infrastructure/docker-compose.local.yml`

It is explicitly marked local-only and simulates the production topology on one machine.

The older `backend/kerosene/docker-compose.yml` still exists, but it is not the best reference for current day-to-day local execution.

## Service Topology

## Vault plane

- `kerosene-vault`
- `kerosene-tor-vault`
- `kerosene-vault-arm`

## Iceland shard

- `db-is`
- `redis-is`
- `mpc-sidecar-is`
- `kerosene-tor-is`
- `shard-identity-init-is`
- `kerosene-app-is`
- `kerosene-vanguards-is`

## Switzerland shard

- `db-ch`
- `redis-ch`
- `mpc-sidecar-ch`
- `kerosene-tor-ch`
- `shard-identity-init-ch`
- `kerosene-app-ch`
- `kerosene-vanguards-ch`

## Singapore shard

- `db-sg`
- `redis-sg`
- `mpc-sidecar-sg`
- `kerosene-tor-sg`
- `shard-identity-init-sg`
- `kerosene-app-sg`
- `kerosene-vanguards-sg`

## Host Port Exposure

| Host port | Service |
| --- | --- |
| `8080` | `kerosene-app-is-local` |
| `8081` | `kerosene-app-ch-local` |
| `8082` | `kerosene-app-sg-local` |

Vault is not exposed directly on a host port in the local compose.

## Networks

Current named networks:

- `net_ingress`
- `net_vault`
- `net_db_is`
- `net_db_ch`
- `net_db_sg`
- `net_mpc`
- `net_tor`
- `tor_egress`

Important properties:

- `net_vault` is internal with subnet `172.24.0.0/24`
- `net_tor` is internal with subnet `10.241.0.0/24`
- regional DB networks are internal
- only Tor daemons are attached to `tor_egress`

## Volumes

Persistent volumes declared in compose include:

- `pg_data_is`, `pg_data_ch`, `pg_data_sg`
- `redis_data_is`, `redis_data_ch`, `redis_data_sg`
- `mpc_shards_is`, `mpc_shards_ch`, `mpc_shards_sg`
- `tor_socks_is`, `tor_socks_ch`, `tor_socks_sg`
- `tor_data_is`, `tor_data_ch`, `tor_data_sg`
- `tor_control_is`, `tor_control_ch`, `tor_control_sg`
- `vanguards_state_is`, `vanguards_state_ch`, `vanguards_state_sg`
- `shard_identity_is`, `shard_identity_ch`, `shard_identity_sg`
- `tor_keys_vault`, `tor_keys_is`, `tor_keys_ch`, `tor_keys_sg`

## Container Hardening Signals

Examples already present in compose:

- `cap_drop: [ALL]` for app and vanguards containers
- `cap_add: [IPC_LOCK]` for app and Vault where needed
- `no-new-privileges:true`
- tmpfs mounts for `/tmp` and `/opt/kerosene`
- read-only vanguards runtime plus isolated `network_mode: none`

## Tor Runtime

`init-local.sh` rewrites Tor configs on each init.

Example shard Tor config generated:

- `SocksPort unix:/var/run/tor/socks/tor.sock WorldWritable`
- `ControlSocket /var/run/tor/control/control`
- `CookieAuthentication 1`
- `HiddenServicePort 80 <shard-ip>:8080`

Vault Tor config maps:

- hidden-service port `80` -> `172.24.0.10:8090`

`vanguards.conf` uses:

- control socket at `/var/run/tor/control/control`
- state file `/var/lib/vanguards/vanguards.state`

## Startup Scripts

## `scripts/start-local.sh`

Primary orchestration script behavior:

1. validate Docker availability
2. warn about Redis overcommit if host kernel is not configured
3. call infrastructure `init-local.sh`
4. compose up, usually detached and with build
5. run `scripts/migrate-local-db.sh`
6. arm Vault unless `--no-arm`
7. wait for all shards to provision the master key
8. print onion hostnames

## `backend/kerosene-infrastructure/scripts/init-local.sh`

Responsibilities:

- validate required `.env`
- generate certificates if missing
- regenerate `torrc-is`, `torrc-ch`, `torrc-sg`, `torrc-vault`

Required `.env` variables validated:

- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `JWT_SECRET`
- `PASSWORD_PEPPER`
- `FOUNDER_TOTP_SECRET`
- `AES_SECRET`

## `scripts/arm-vault.sh`

Behavior:

- loads backend `.env`
- reads `AES_SECRET`
- connects over the Docker Vault network
- submits approvals for `director-1` and `director-2`
- sends `X-Director-Id` and `X-Director-Signature`
- posts `{"master_key":"<AES_SECRET>"}` to Vault

This matches the 2-of-3 quorum model in `VaultController`.

## Runtime Environment

Important app-container environment in local compose includes:

- `SPRING_PROFILES_ACTIVE=docker`
- `VAULT_ENABLED=true`
- `VAULT_URL=http://kerosene-vault:8090`
- `VAULT_ONION_FILE=/vault-onion/hostname`
- `VAULT_BOOTSTRAP_STARTUP_TIMEOUT_MS=180000`
- `MPC_SIDECAR_TLS_ENABLED=false`
- `AUDIT_SOLVENCY_ENFORCED=false`
- `BITCOIN_NETWORK=testnet`

## Operational Interpretation

The local compose is:

- comprehensive enough to reason about service boundaries
- not identical to a real multi-host deployment
- appropriate as the canonical repository runtime for development and documentation

It should not be described as a full proof of production readiness by itself.

## Infrastructure Caveats

1. The cluster simulates geographic shards on one machine.

2. MPC sidecars start and expose gRPC, but threshold operations are not wired.

3. Vault attestation logic is simulated.

4. The compose topology is stronger than a simple single-node dev environment, but still materially simpler than a true bare-metal multi-host deployment.
