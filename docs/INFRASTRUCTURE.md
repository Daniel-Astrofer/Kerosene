# Infraestrutura Real do Kerosene

Documento baseado nos arquivos Docker, compose, propriedades Spring e scripts existentes em 2026-04-29.

## Arquivos Relevantes

| Arquivo | Papel |
| --- | --- |
| `backend/kerosene-infrastructure/docker-compose.local.yml` | Compose local para simular Vault e shards IS/CH/SG no mesmo host. |
| `backend/kerosene/docker-compose.yml` | Compose de topologia distribuida antiga/producao, com mTLS e sidecars MPC definidos. |
| `backend/kerosene-infrastructure/images/app/Dockerfile` | Build do backend principal em Java 21 com runtime Distroless. |
| `backend/kerosene-infrastructure/images/vault/Dockerfile` | Build do Vault Maven/Java 21 com runtime Distroless. |
| `backend/kerosene/tor/Dockerfile` | Imagem Tor baseada em Debian Bookworm Slim. |
| `backend/kerosene/tor/vanguards/Dockerfile` | Imagem sidecar do addon oficial Tor Vanguards para os shards. |
| `backend/mpc-sidecar/Dockerfile` | Build Go/gRPC do sidecar MPC. |
| `backend/kerosene-infrastructure/scripts/init-local.sh` | Bootstrap local: valida `.env`, tenta gerar certificados e reescreve `torrc`. |
| `scripts/start-local.sh` | Wrapper local canonico para inicializar o backend via compose. |
| `scripts/arm-vault.sh` | Arma o Vault local usando `AES_SECRET` do `.env` e quorom de dois diretores de desenvolvimento. |
| `backend/kerosene/deploy/init-iptables.sh` | Regras host-level de egress guard por iptables. |

## Compose Local Recomendado

O compose local atual usa o layout real `backend/*`:

```bash
bash scripts/init-local.sh
docker compose up -d --build
docker compose logs -f kerosene-app-is web-admin bitcoin-core vault-raft-1
docker compose down
```

Comando compose equivalente:

```bash
docker compose --env-file backend/kerosene/.env -f docker-compose.yml config
docker compose --env-file backend/kerosene/.env -f docker-compose.yml up -d --build
```

Servicos definidos:

| Servico | Funcao |
| --- | --- |
| `web-admin` | Nginx servindo `frontend/build/web`: landing em `/`, painel admin em `/admin`, download e status. |
| `bitcoin-core` / `bitcoin-pruned-node` | No Bitcoin mainnet pruned com RPC, ZMQ e wallet descriptor. |
| `lnd-neutrino` | LND mainnet real via Bitcoin Core pruned local para Lightning. |
| `lnd-bootstrap` | Inicializa/desbloqueia a wallet LND e prepara TLS/macaroon. |
| `bitcoin-indexer` | electrs opcional no profile `archive-indexer`; nao sobe no modo pruned padrao. |
| `vault-raft-1`, `vault-raft-2`, `vault-raft-3` | HashiCorp Vault com integrated storage/Raft. |
| `vault-raft-bootstrap` | Inicializacao, join e unseal do cluster Raft local. |
| `prometheus` | Observabilidade basica dos servicos locais. |
| `kerosene-vault` | Vault local sem port binding de host. |
| `kerosene-tor-vault` | Hidden service Tor do Vault. |
| `db-is`, `db-ch`, `db-sg` | PostgreSQL 17 Alpine por shard, `REQUIRE_MTLS=false` no local. |
| `redis-is`, `redis-ch`, `redis-sg` | Redis 7 Alpine por shard com `--requirepass`. |
| `mpc-sidecar-is`, `mpc-sidecar-ch`, `mpc-sidecar-sg` | Sidecars Go/gRPC usados por `MPC_SIDECAR_HOST`. |
| `kerosene-app-is`, `kerosene-app-ch`, `kerosene-app-sg` | API principal por regiao. |
| `kerosene-tor-is`, `kerosene-tor-ch`, `kerosene-tor-sg` | Hidden services Tor dos shards. |
| `kerosene-vanguards-is`, `kerosene-vanguards-ch`, `kerosene-vanguards-sg` | Addon Vanguards preso ao `ControlSocket` do Tor por shard. |

Redes definidas:

| Rede | Tipo | Observacao |
| --- | --- | --- |
| `net_vault` | bridge internal | Sem egress direto; Vault isolado. |
| `net_db_is`, `net_db_ch`, `net_db_sg` | bridge internal | Banco e Redis por shard. |
| `net_mpc` | bridge internal | Declarada para sidecar MPC. |
| `net_bitcoin` | bridge internal | Bitcoin Core pruned, indexador opcional e apps. |
| `net_tor` | bridge internal | Comunicacao app/Tor. |
| `tor_egress` | bridge | Apenas daemons Tor devem ter saida. |

Volumes definidos:

```text
pg_data_is, pg_data_ch, pg_data_sg
redis_data_is, redis_data_ch, redis_data_sg
mpc_shards_is, mpc_shards_ch, mpc_shards_sg
tor_socks_is, tor_socks_ch, tor_socks_sg
tor_data_is, tor_data_ch, tor_data_sg
tor_control_is, tor_control_ch, tor_control_sg
vanguards_state_is, vanguards_state_ch, vanguards_state_sg
tor_keys_vault, tor_keys_is, tor_keys_ch, tor_keys_sg
shard_identity_is, shard_identity_ch, shard_identity_sg
bitcoin_core_data, bitcoin_indexer_data
vault_raft_1_data, vault_raft_2_data, vault_raft_3_data, vault_raft_bootstrap
prometheus_data
```

Observacao operacional: o compose local define os sidecars `mpc-sidecar-is`, `mpc-sidecar-ch` e `mpc-sidecar-sg` no `net_mpc`. O compose `backend/kerosene/docker-compose.yml` permanece como topologia distribuida antiga/producao e ainda deve ser revisado antes de producao para garantir build contexts consistentes com o layout `backend/*`.

## Topologia de Runtime

```mermaid
flowchart TB
  subgraph IS[Shard IS]
    AppIS[kerosene-app-is] --> DbIS[(db-is)]
    AppIS --> RedisIS[(redis-is)]
    AppIS --> MpcIS[mpc-sidecar-is]
    TorIS[kerosene-tor-is] --> AppIS
    VgIS[kerosene-vanguards-is] --> TorIS
  end

  subgraph CH[Shard CH]
    AppCH[kerosene-app-ch] --> DbCH[(db-ch)]
    AppCH --> RedisCH[(redis-ch)]
    AppCH --> MpcCH[mpc-sidecar-ch]
    TorCH[kerosene-tor-ch] --> AppCH
    VgCH[kerosene-vanguards-ch] --> TorCH
  end

  subgraph SG[Shard SG]
    AppSG[kerosene-app-sg] --> DbSG[(db-sg)]
    AppSG --> RedisSG[(redis-sg)]
    AppSG --> MpcSG[mpc-sidecar-sg]
    TorSG[kerosene-tor-sg] --> AppSG
    VgSG[kerosene-vanguards-sg] --> TorSG
  end

  TorVault[kerosene-tor-vault] --> Vault[kerosene-vault]
  Web[web-admin] --> AppIS
  Web --> AppCH
  Web --> AppSG
  AppIS --> Bitcoin[bitcoin-core]
  AppCH --> Bitcoin
  AppSG --> Bitcoin
  AppIS --> Lnd[lnd-bitcoind]
  AppCH --> Lnd
  AppSG --> Lnd
  Bitcoin -. archive-indexer .-> Electrs[bitcoin-indexer opcional]
  AppIS --> VaultRaft[vault-raft quorum]
  AppCH --> VaultRaft
  AppSG --> VaultRaft
  Prom[prometheus] --> AppIS
  Prom --> AppCH
  Prom --> AppSG
  AppIS --> TorVault
  AppCH --> TorVault
  AppSG --> TorVault
```

## Bitcoin Core Pruned, LND e Indexador Opcional

Arquivos:

- `backend/kerosene-infrastructure/bitcoin/bitcoind-entrypoint.sh`
- `backend/kerosene-infrastructure/bitcoin/bitcoind-healthcheck.sh`
- `backend/kerosene-infrastructure/scripts/lnd-entrypoint.sh`
- `backend/kerosene-infrastructure/scripts/lnd-bootstrap.sh`

O servico Compose continua chamado `bitcoin-core` para compatibilidade interna, mas o container e a rede expõem `bitcoin-pruned-node`. Ele usa a imagem oficial `bitcoin/bitcoin:27.1` e executa `bitcoind` em modo pruned real: `BITCOIN_CHAIN=mainnet`, `prune=${BITCOIN_PRUNE_MB:-5500}`, `txindex=0`, RPC local, ZMQ para blocos/transacoes e volume `bitcoin_core_data`. O container fica na `net_bitcoin` para RPC/ZMQ internos e tambem na rede de egress para conexoes P2P outbound da mainnet, sem publicar RPC no host. O healthcheck falha se `getblockchaininfo` nao reportar `pruned=true` e `chain=main`. Ele carrega ou cria o wallet descriptor `BITCOIN_RPC_WALLET`, usado para enderecos on-chain reais via `getnewaddress`.

O servico Compose ainda se chama `lnd-neutrino` para compatibilidade, mas o container roda LND mainnet com `--bitcoin.active --bitcoin.node=bitcoind`, conectado ao `bitcoin-pruned-node` por RPC/ZMQ. A rede expõe o alias interno `lnd-bitcoind`, usado pelo backend e pelo bootstrap com verificacao TLS. `lnd-bootstrap` inicializa ou desbloqueia a wallet e disponibiliza `tls.cert` e `admin.macaroon` em `lnd_data`; as apps montam esse volume somente leitura e acessam LND por gRPC.

`bitcoin-indexer`/electrs fica no profile `archive-indexer`. Ele nao e fonte primaria no modo pruned, porque indexadores de arquivo exigem historico/txindex que conflitam com a politica padrao de poda.

O backend usa `bitcoin.rpc.*`, `bitcoin.rpc.zmq.*`, `lightning.lnd.*` e, opcionalmente, `bitcoin.indexer.*`. Se `bitcoin.rpc.required=true`, readiness e painel marcam falha quando o RPC local nao responde. Se `bitcoin.rpc.pruned-required=true`, o monitor blockchain marca falha quando o RPC responder de um no sem poda. Se LND estiver indisponivel, `/api/admin/operations/lightning` retorna `DOWN` e operacoes Lightning reais falham fechadas.

## Vault Raft

Arquivos:

- `backend/kerosene-infrastructure/vault/raft/vault-raft-1.hcl`
- `backend/kerosene-infrastructure/vault/raft/vault-raft-2.hcl`
- `backend/kerosene-infrastructure/vault/raft/vault-raft-3.hcl`
- `backend/kerosene-infrastructure/vault/raft/bootstrap-raft.sh`

O bootstrap inicializa o cluster, junta os followers ao leader, faz unseal dos tres nos e persiste token/unseal keys em volume Docker local. As apps montam somente leitura esse volume para health checks. Valores gerados sao operacionais e nao devem ser publicados.

## Release Snapshot e Identidade

Arquivo:

- `scripts/release-snapshot.sh`

Comandos:

```bash
bash scripts/release-snapshot.sh generate
bash scripts/release-snapshot.sh validate
```

O script calcula commit Git, hash do codigo, hash das configs permitidas, digest de manifesto, assinatura Ed25519 e SBOM opcional via `syft`. O diretorio `release/` permanece ignorado porque contem chave privada local e artefatos gerados.

Cada app recebe `RELEASE_*` por ambiente e monta `/release` como somente leitura. O backend publica `/system/release`; o sidecar MPC publica `/version`.

## Backend App Image

Dockerfile: `backend/kerosene-infrastructure/images/app/Dockerfile`

Caracteristicas:

- Stage builder com `eclipse-temurin:21-jdk`.
- Build Gradle `./gradlew bootJar --no-daemon -x test`.
- Runtime `gcr.io/distroless/java21-debian12:nonroot`.
- Usuario `65532:65532`.
- `EXPOSE 8080` apenas interno.
- Entrypoint Java com `UseContainerSupport`, `MaxRAMPercentage=75.0` e `java.security.egd`.

Hardening no compose:

- `cap_drop: [ALL]`.
- `cap_add: [IPC_LOCK]`.
- `security_opt: no-new-privileges:true`.
- `tmpfs` para `/tmp` e `/opt/kerosene`.

## Vault Image

Dockerfile: `backend/kerosene-infrastructure/images/vault/Dockerfile`

Caracteristicas:

- Stage builder com `maven:3.9.6-eclipse-temurin-21-jammy`.
- `mvn clean package -DskipTests`.
- Runtime `gcr.io/distroless/java21-debian12:nonroot`.
- Sem port binding de host no compose local.
- `server.port=8090` em `backend/vault/src/main/resources/application.properties`.

## Tor Sidecars

Arquivos:

- `backend/kerosene/tor/Dockerfile`.
- `backend/kerosene/tor/entrypoint.sh`.
- `backend/kerosene/tor/torrc-is`.
- `backend/kerosene/tor/torrc-ch`.
- `backend/kerosene/tor/torrc-sg`.
- `backend/kerosene/tor/torrc-vault`.
- `backend/kerosene/tor/vanguards/Dockerfile`.
- `backend/kerosene/tor/vanguards/entrypoint.sh`.
- `backend/kerosene/tor/vanguards/vanguards.conf`.

Configuracao real dos shards:

```text
SocksPort unix:/var/run/tor/socks/tor.sock WorldWritable
ControlSocket /var/run/tor/control/control
CookieAuthentication 1
CookieAuthFile /var/run/tor/control/control_auth_cookie
HiddenServicePort 80 kerosene-app-<region>-local:8080
```

Configuracao real do Vault:

```text
SocksPort 0
HiddenServicePort 80 kerosene-vault-local:8090
```

O entrypoint:

- Verifica o hash do binario Tor se `EXPECTED_TOR_HASH` estiver definida.
- Cria usuario `kerosene` com UID/GID `65532`.
- Ajusta permissoes de `/var/run/tor/socks`, `/var/run/tor/control` e `/var/lib/tor/kerosene_service`.
- Inicia `tor -f /etc/tor/torrc`.

## Tor Vanguards

Os shards IS, CH e SG executam um sidecar `vanguards` separado do processo Tor.

Decisao de desenho:

- o addon nao compartilha rede com nenhum outro servico; ele roda com `network_mode: none`;
- o acoplamento com Tor acontece apenas por volume do `ControlSocket` e cookie;
- o estado operacional fica em volume dedicado `vanguards_state_<region>`;
- o backend principal monta esse estado como somente leitura para publicar health via Actuator.

Volumes por shard:

| Volume | Escritor | Leitor | Papel |
| --- | --- | --- | --- |
| `tor_data_<region>` | Tor | Vanguards | `DataDirectory` com consenso e caches necessarios para o addon. |
| `tor_control_<region>` | Tor | Vanguards | `ControlSocket` e `control_auth_cookie`. |
| `vanguards_state_<region>` | Vanguards | App | `vanguards.state` usado para health e auditoria operacional. |

Healthchecks reais:

- Tor: `test -f /tmp/tor-ready`
- Vanguards: `test -f /tmp/vanguards-ready`

Subida:

1. `kerosene-tor-<region>` sobe e conclui bootstrap.
2. `kerosene-vanguards-<region>` autentica no `ControlSocket`.
3. O addon escreve `vanguards.state` e permanece supervisionando guard layers, bandguards e rendguard.

Observacao: o Vault continua com hidden service Tor isolado, mas sem sidecar `vanguards` nesta implementacao. O requisito aplicado aqui foi exatamente nos 3 shards regionais.

## Banco de Dados

Configuracao local de app:

- `application.properties`: `jdbc:postgresql://localhost:5432/kerosene`.
- `application-docker.properties`: `jdbc:postgresql://db:5432/kerosene`, mas o compose sobrescreve com `SPRING_DATASOURCE_URL` por shard.
- `ddl-auto=update`.
- `spring.sql.init.mode=always` no profile docker usando `classpath:db/migration.sql`.

Schemas:

- `auth`.
- `financial`.

Inicializacao:

- `backend/kerosene/docker-entrypoint-initdb.d/init.sql`.
- `backend/kerosene/docker-entrypoint-initdb.d/99-init-ssl.sh`.
- `backend/kerosene/src/main/resources/db/migration.sql`.

No compose local, `REQUIRE_MTLS=false`, entao o `pg_hba.conf` permite `scram-sha-256`. No compose distribuido antigo, os bancos usam SSL e certificados em `backend/kerosene/certs`.

## Redis

Configuracao:

- Local default: `127.0.0.1:6379`.
- Docker: host por shard via `SPRING_DATA_REDIS_HOST`.
- Senha por `REDIS_PASSWORD`.
- Comando real: `redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes`.

Uso no codigo:

- Rate limit.
- Signup state.
- Payment links.
- Internal payment requests.
- Economy status.

## Variaveis de Ambiente

Nunca commitar valores reais. Lista de nomes usados:

```text
POSTGRES_USER
POSTGRES_PASSWORD
REDIS_PASSWORD
AES_SECRET
JWT_SECRET
PASSWORD_PEPPER
FOUNDER_TOTP_SECRET
HMAC_SECRET_KEY
WEBAUTHN_RP_ID
WEBAUTHN_RP_NAME
WEBAUTHN_ORIGINS
BITCOIN_NETWORK
BITCOIN_CHAIN
BITCOIN_PRUNE_MB
BITCOIN_P2P_PORT
BITCOIN_RPC_ENABLED
BITCOIN_RPC_REQUIRED
BITCOIN_RPC_PRUNED_REQUIRED
BITCOIN_RPC_USER
BITCOIN_RPC_PASSWORD
BITCOIN_RPC_URL
BITCOIN_RPC_WALLET
BITCOIN_WALLET_PASSPHRASE
BITCOIN_ZMQ_ENABLED
BITCOIN_ZMQ_RAWTX
BITCOIN_ZMQ_HASHBLOCK
BITCOIN_INDEXER_BASE_URL
BITCOIN_ESPLORA_ENABLED
BITCOIN_FEE_RECOMMENDATION_URL
BITCOIN_PLATFORM_MASTER_XPUB
BITCOIN_HOT_WALLET_ADDRESS
BITCOIN_HOT_WALLET_XPUB
BITCOIN_HOT_WALLET_XPUB_SCAN_RANGE
TRANSACTIONS_BITCOIN_CORE_WALLET_ADDRESS_ENABLED
LIGHTNING_LND_ENABLED
LIGHTNING_LND_HOST
LIGHTNING_LND_PORT
LIGHTNING_LND_REST_PORT
LIGHTNING_LND_TLS_ENABLED
LIGHTNING_LND_TLS_CERT_PATH
LIGHTNING_LND_MACAROON
LIGHTNING_LND_MACAROON_PATH
LIGHTNING_LND_PROVIDER_NAME
LIGHTNING_LND_BOOTSTRAP_TIMEOUT_SECONDS
LND_WALLET_PASSWORD
EXPECTED_TOR_HASH
REGION
MPC_SIDECAR_HOST
VAULT_ENABLED
VAULT_ONION_FILE
VAULT_PROXY_PATH
CUSTODY_PROVIDER_NAME
CUSTODY_BASE_URL
CUSTODY_API_KEY
CUSTODY_MOCK_MODE
CUSTODY_ONCHAIN_ADDRESS_PATH
CUSTODY_LIGHTNING_INVOICE_PATH
CUSTODY_ONCHAIN_SEND_PATH
CUSTODY_LIGHTNING_PAY_PATH
TOR_HEALTH_VANGUARDS_STATE_FILE
VAULT_RAFT_REQUIRED
VAULT_RAFT_ADDR
VAULT_RAFT_TOKEN_FILE
RELEASE_MANIFEST_PATH
RELEASE_MANIFEST_SIGNATURE_PATH
RELEASE_MANIFEST_PUBLIC_KEY
RELEASE_ATTESTATION_REQUIRED
RELEASE_ATTESTATION_REMOTE_ENABLED
RELEASE_ATTESTATION_SECRET
MOBILE_ANDROID_DOWNLOAD_URL
MOBILE_IOS_DOWNLOAD_URL
MOBILE_APP_VERSION
MOBILE_ANDROID_SHA256
MOBILE_IOS_SHA256
```

Variaveis com defaults no codigo:

- `bitcoin.deposit-address`.
- `bitcoin.min-confirmations`.
- `bitcoin.payment-link-expiration-minutes`.
- `bitcoin.mock-mode`.
- `bitcoin.rpc.*`.
- `bitcoin.rpc.zmq.*`.
- `bitcoin.esplora.enabled`.
- `bitcoin.esplora.base-url`.
- `bitcoin.fee-recommendation.url`.
- `bitcoin.platform.master-xpub`.
- `bitcoin.hot-wallet.address`.
- `bitcoin.hot-wallet.xpub`.
- `bitcoin.hot-wallet.xpub-scan-range`.
- `audit.merkle.interval-ms`.
- `blockchain.monitor.interval.min`.
- `blockchain.monitor.interval.max`.
- `onramp.moonpay.url`.
- `onramp.banxa.url`.
- `onramp.bipa.url`.
- `bitcoin.network`.
- `bitcoin.derivation.salt`.
- `transactions.external.fee-rate`.
- `transactions.local-address-provider-name`.
- `lightning.default-max-routing-fee-sats`.
- `custody.provider-name`.
- `custody.onchain-address-path`.
- `custody.lightning-invoice-path`.
- `custody.onchain-send-path`.
- `custody.lightning-pay-path`.
- `bitcoin.rpc.required`.
- `vault.raft.required`.
- `release.attestation.required`.
- `release.attestation.remote.enabled`.
- `mobile.release.version`.

Configuracao nova de custodia/pagamentos externos:

- `transactions.external.fee-rate`: taxa percentual aplicada em saidas externas; default real `0.009` (0.9%).
- `lightning.default-max-routing-fee-sats`: reserva default de fee Lightning; default real `60` sats.
- `custody.*`: define o adapter HTTP para provider externo de carteira/custodia. O nome default configurado no backend e `BCX`.
- No compose padrao, enderecos on-chain Kerosene usam `BitcoinCoreRpcClient.getNewAddress` contra o wallet `BITCOIN_RPC_WALLET`.
- XPUB BIP84 (`bitcoin.platform.master-xpub`) continua disponivel para self-custody/watch-only. O fallback local deterministico exige `TRANSACTIONS_LOCAL_DERIVED_ADDRESS_FALLBACK_ENABLED=true` e fica desativado por padrao.
- Lightning usa LND gRPC real para invoices, pagamentos e monitoramento; nao ha mock habilitado no profile Docker.

## Validacao Antes de Deploy

Checklist minimo:

```bash
bash scripts/init-local.sh
bash scripts/release-snapshot.sh generate
docker compose --env-file backend/kerosene/.env -f docker-compose.yml config
docker compose --env-file backend/kerosene/.env -f docker-compose.yml up -d --build
docker compose --env-file backend/kerosene/.env -f docker-compose.yml down
cd backend/kerosene
./gradlew test
./gradlew dependencyCheckAnalyze
```

Cuidados:

- `docker compose config` imprime variaveis resolvidas; nao publique a saida se estiver usando `.env` real.
- Confirme se os sidecars MPC estao definidos no compose usado em producao.
- Confirme se os build contexts apontam para `backend/vault` e `backend/mpc-sidecar` no layout atual.
- Confirme se `bitcoin.platform.master-xpub` ou `bitcoin.hot-wallet.xpub` estao configurados para a emissao dos enderecos custodiais on-chain.
- Confirme se `WEBAUTHN_RP_ID` e `WEBAUTHN_ORIGINS` batem com o dominio/onion acessado pelo app.
- Confirme se o manifesto assinado foi gerado para o commit e as imagens publicadas.
- Confirme se o cluster Vault Raft tem leader, followers votantes e seal status saudavel antes de promover release.
