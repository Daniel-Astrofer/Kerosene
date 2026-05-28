# Infrastructure

Esta documentacao reflete o codigo atual, scripts e arquivos de configuracao do repositorio. Ela substitui leituras antigas chamadas Hydra por uma visao Kerosene baseada nos arquivos atuais.

## Fontes analisadas

- `docker-compose.yml`: compose raiz que inclui `backend/kerosene-infrastructure/docker-compose.local.yml` e carrega `backend/kerosene/.env`.
- `backend/kerosene-infrastructure/docker-compose.local.yml`: topologia local completa com shards, Bitcoin Core, indexer, Vault Raft, Prometheus e web admin.
- `backend/kerosene/docker-compose.yml`: topologia distribuida/producao com shards regionais, Tor, Vanguards, Vault e LND.
- `backend/kerosene/src/main/resources/application.properties`, `application-docker.properties`, `application-prod.properties`.
- `scripts/start-local.sh`, `stop-local.sh`, `logs-local.sh`, `init-local.sh`, `arm-vault.sh`, `build-web-admin-backend.sh`, `release-snapshot.sh`.
- `backend/mpc-sidecar`, `backend/vault` e migracoes SQL em `backend/kerosene/src/main/resources/db/migration`.

## Topologia local canonica

O comando canonico e:

```bash
bash scripts/start-local.sh
```

Esse script usa o compose raiz, prepara o build web Flutter para ser servido pelo backend, sobe a infraestrutura local, arma o Vault quando habilitado, aguarda provisionamento de master key nos shards e imprime enderecos onion quando disponiveis.

Servicos principais em `backend/kerosene-infrastructure/docker-compose.local.yml`:

| Grupo | Servicos | Funcao |
| --- | --- | --- |
| App shards | `kerosene-app-is`, `kerosene-app-ch`, `kerosene-app-sg` | Tres instancias Spring Boot com perfis `docker,prod`, cada uma ligada a Postgres/Redis regionais. |
| Bancos | `db-is`, `db-ch`, `db-sg` | PostgreSQL 17 com volumes separados por shard. |
| Cache | `redis-is`, `redis-ch`, `redis-sg` | Redis 7 com senha e AOF. |
| MPC | `mpc-sidecar-is`, `mpc-sidecar-ch`, `mpc-sidecar-sg` | Go gRPC sidecar para assinatura/MPC com TLS. |
| Tor | `kerosene-tor-is`, `kerosene-tor-ch`, `kerosene-tor-sg`, `kerosene-tor-vault` | Hidden services e egress controlado. |
| Vanguards | `kerosene-vanguards-is`, `kerosene-vanguards-ch`, `kerosene-vanguards-sg` | Hardening Tor. |
| Vault | `kerosene-vault`, `kerosene-vault-arm`, `vault-raft-1..3`, `vault-raft-bootstrap` | Cofre Java e quorum/health de Vault Raft. |
| Bitcoin | `bitcoin-core`, `bitcoin-indexer` | Bitcoin Core pruned e indexador opcional para deposits/PSBT. |
| Lightning | `lnd-neutrino`, `lnd-bootstrap` | LND para invoices e pagamentos Lightning. |
| Operacao | `web-admin`, `prometheus` | Painel web/admin e metricas. |

## Topologia distribuida

`backend/kerosene/docker-compose.yml` modela o deployment endurecido:

- Um Vault central sem `ports`, acessivel via `kerosene-tor-vault`.
- Tres shards regionais `IS`, `CH` e `SG` com redes separadas de DB, Tor e MPC.
- PostgreSQL com SSL, Redis com senha, sidecar MPC com mTLS e volumes separados de shards.
- Apps com `cap_drop: ALL`, `IPC_LOCK`, `no-new-privileges`, tmpfs e identidade persistente por shard.
- Tor hidden service por shard e Vanguards por shard.

## Backend Spring

O backend principal fica em `backend/kerosene` e roda Java 21/Spring Boot.

Configuracoes importantes:

| Area | Config atual |
| --- | --- |
| Banco | `spring.jpa.hibernate.ddl-auto=validate`; schema por Flyway/migracoes SQL. |
| Redis | host local no perfil default; service DNS no perfil docker. |
| Flyway | default desligado; `application-prod.properties` liga por `FLYWAY_ENABLED=true`. |
| HTTP | `server.address=0.0.0.0`; porta docker `8080`. |
| CORS | origins explicitas via `APP_CORS_ALLOWED_ORIGINS`; wildcard causa falha de boot. |
| Payload | limite padrao `2KB`; PSBT `64KB`; content type estrito. |
| Auth | JWT stateless, method security e filtros `ParanoidSecurityFilter`, `RateLimitFilter`, `JwtAuthenticationFilter`. |
| Passkey/WebAuthn | `WEBAUTHN_RP_ID` default local/docker `kerosene-device`; prod exige valor explicito. |
| Observabilidade | Actuator health/info/metrics/prometheus, health groups de liveness/readiness. |

## Banco e migracoes

Arquivos atuais:

- `db/migration.sql` legado/manual.
- `db/migration/V1__baseline_schema.sql` ate `V10__notification_device_tokens.sql`.
- Ha duas migracoes `V10` (`V10__lightning_invoice_inbound_guards.sql` e `V10__notification_device_tokens.sql`), o que deve ser corrigido antes de Flyway prod, porque versoes duplicadas podem quebrar validacao.

Dados persistidos incluem usuarios, passkeys, wallets, ledger, transfers externos, payment intents, payment links, Bitcoin accounts, cold wallets, PSBT workflows, tax events, audit events, treasury config/payouts e notificacoes/device tokens.

## Redis

Usos observados:

- Rate limit por rota e identidade.
- Signup state, recovery state e passkey challenge.
- Idempotencia/replay financeiro.
- Circuit breakers e sinais efemeros.
- Eventos temporarios de ledger/history conforme servicos atuais.

Redis e dependencia critica para auth, rate limit e fluxos financeiros; health de readiness inclui Redis.

## Bitcoin e Lightning

O codigo atual suporta:

- Bitcoin Core RPC opcional no default, obrigatorio em prod/docker endurecido.
- ZMQ `rawtx` e `hashblock` quando habilitado.
- Esplora/indexer opcional para consulta.
- Hot wallet address/xpub e platform master xpub.
- LND com TLS e macaroon para invoice/pagamento Lightning.
- Quorum PSBT com signers configuraveis por URL/API key/id.

Em producao, `application-prod.properties` fecha mock/fallback: `bitcoin.mock-mode=false`, `transactions.local-derived-address-fallback-enabled=false`, `voucher.mock.accept-any-txid=false`.

## Vault e MPC

`backend/vault` e um servico Java separado empacotado por Maven. Ele e armado por diretores via HMAC e usado para material sensivel/master key.

`backend/mpc-sidecar` e um servico Go gRPC com proto em `proto/mpc.proto`; no compose roda em modo `HARDWARE_ENCLAVE`, exige master key e TLS. O backend fala com ele via `mpc.sidecar.*`.

## Jobs e workers agendados

| Area | Jobs |
| --- | --- |
| Preco | `TickerService` a cada 5 min. |
| Ledger/audit | Merkle audit, cleanup de history, reconciliation audit, shadow balance audit. |
| Seguranca | time drift, remote attestation, sovereignty heartbeat. |
| Transactions | liquidity monitor, inbound transfer monitor, pending tx monitor, account activation monitor, financial reconciliation, provider outbox worker. |
| Treasury | financial integrity, treasury payout worker. |
| Bitcoin accounts | retention, receive monitor, cold wallet monitor, PSBT expiry. |
| Payments | external execution worker e reconciliation service. |

## Health e operacao

Endpoints publicos:

- `GET /healthz`
- `GET /health/live`
- `GET /health/ready`
- `GET /system/release`
- Actuator `/actuator/health/**` quando habilitado.

Comandos:

```bash
bash scripts/start-local.sh
bash scripts/logs-local.sh
bash scripts/stop-local.sh
cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test
cd backend/mpc-sidecar && go test ./...
cd backend/vault && mvn package
```

## Segredos e arquivos proibidos

Nunca versionar `.env`, certificados, keystores, Tor keys, macaroons LND, service accounts, secrets de diretores, master keys, dumps de banco ou `frontend/build/**`.

A arvore atual contem varios `web-admin-build.stale-*`; eles devem ser tratados como artefatos antigos, nao como fonte de verdade.
