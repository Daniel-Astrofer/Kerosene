# Kerosene

Plataforma financeira Bitcoin em estado pre-alpha, com aplicativo Flutter, API Spring Boot, Vault de provisionamento de chaves, sidecar MPC em Go e infraestrutura Docker/Tor para shards regionais.

Esta documentacao reflete o estado real do repositorio inspecionado em 2026-04-29.

## Status do Projeto

| Area | Estado real no repositorio |
| --- | --- |
| Landing publica | Flutter web em `/`, com proposta de valor, taxas, seguranca, empresas, usuarios, blockchain monitoring e CTA para painel, download e status. |
| Painel web empresarial | Flutter web separado em `/admin`, protegido por autenticacao administrativa e alimentado por endpoints reais em `/api/admin/operations/*`. |
| Mobile | Flutter/Dart com app Android, iOS, web, Linux, macOS e Windows scaffolded. O fluxo web `/download` consome metadados reais em `/api/public/mobile-download`. |
| Backend principal | Java 21, Spring Boot 3.3.2, Gradle, REST, WebSocket/STOMP, Spring Security, JPA, Redis, PostgreSQL, BitcoinJ e clientes de blockchain. |
| Blockchain monitor | Monitoramento primario on-chain por Bitcoin Core mainnet pruned via RPC/ZMQ; Lightning por LND mainnet via gRPC. APIs publicas nao sao fonte primaria. |
| Vault | Vault Java legado para provisionamento e cluster HashiCorp Vault Raft com 3 nos para quorum, leader/followers e health de seal/unseal. |
| MPC sidecar | Servico Go 1.24/gRPC com `tss-lib`, porta `50051`, endpoint `/version`, runtime nao-root e healthcheck Docker. |
| Infraestrutura | Docker Compose com shards IS/CH/SG, PostgreSQL, Redis, Tor, MPC, Bitcoin Core pruned, LND, Vault Raft, web-admin e Prometheus em containers separados. |
| Release/attestation | Snapshots assinados em `scripts/release-snapshot.sh`; backend valida manifesto, hashes, digest de imagem e attestation em comunicacoes criticas. |
| API | Endpoints documentados em [docs/API_REFERENCE.md](docs/API_REFERENCE.md), com guia de consumo pela UI em [docs/FRONTEND_API_USAGE.md](docs/FRONTEND_API_USAGE.md). |
| APK | Artefato existente em `frontend/build/app/outputs/flutter-apk/app-release.apk`; veja [docs/APK.md](docs/APK.md). |

## Estrutura do Repositorio

```text
backend/
  kerosene/                   API principal Spring Boot, Dockerfile, compose e SQL init
  vault/                      Vault Spring Boot/Maven para atestacao e provisionamento
  mpc-sidecar/                Sidecar Go/gRPC para operacoes MPC
  kerosene-infrastructure/    Compose local e imagens de runtime
frontend/                    App Flutter/Dart e projetos Android/iOS/desktop/web
docs/                        Documentacao tecnica versionavel
scripts/                     Scripts operacionais locais para o backend
```

## Stack Tecnica

| Camada | Tecnologias |
| --- | --- |
| App | Flutter, Dart, Riverpod, Dio, Tor/Arti, passkeys, secure storage, NFC, QR, WebSocket |
| API | Java 21, Spring Boot, Spring Web, Spring Security, Spring Data JPA, Spring Data Redis, WebSocket/STOMP, Actuator |
| Dados | PostgreSQL 17, Redis 7 |
| Blockchain | Bitcoin Core mainnet pruned RPC/ZMQ, LND gRPC mainnet, BitcoinJ, fee/onramp/payment link; electrs apenas em perfil opcional de indexador de arquivo |
| Seguranca | JWT, TOTP, Passkey/WebAuthn-like Ed25519 flow, Argon2/pepper, filtros de rate limit/payload, Vault Raft e attestation de release |
| Infra | Docker Compose, Distroless Java 21, Debian Tor sidecar, redes internas, volumes Docker, `IPC_LOCK` |
| MPC | Go 1.24, gRPC, protobuf, `bnb-chain/tss-lib/v2` |

## APK Android

Artefato existente:

```text
frontend/build/app/outputs/flutter-apk/app-release.apk
```

Metadados reais do APK atual:

| Campo | Valor |
| --- | --- |
| Application ID | `com.teste.kersosene` |
| Version name | `1.0.0` |
| Version code | `1` |
| Variante | `release` |
| Tamanho | `51,369,097` bytes, aproximadamente `49M` |
| SHA-1 | `94a0ded8109812bdcafc82cdba9202ebe71c1f66` |
| SHA-256 | `80158a61b982eb4db95cd010d63ca3d5b52d3e2215c8d9df046a6609db960582` |

`frontend/build` fica corretamente ignorado pelo Git. Para publicar no GitHub, envie o APK como artefato em GitHub Releases e mantenha este README apenas com a referencia e checksums.

## Backend Principal

Servico: `backend/kerosene`

Comandos diretos do modulo:

```bash
cd backend/kerosene
./gradlew test
./gradlew bootRun
```

Variaveis obrigatorias ou usadas pelo backend:

```text
POSTGRES_USER
POSTGRES_PASSWORD
REDIS_PASSWORD
AES_SECRET
JWT_SECRET
PASSWORD_PEPPER
API_KEY
FOUNDER_TOTP_SECRET
HMAC_SECRET_KEY
WEBAUTHN_RP_ID
WEBAUTHN_RP_NAME
WEBAUTHN_ORIGINS
```

O arquivo `backend/kerosene/.env.example` agora lista as variaveis operacionais principais para o bootstrap local. Nao commite `.env`, certificados, chaves Tor, keystores ou `google-services.json`.

## Infraestrutura

Scripts locais recomendados:

```bash
bash scripts/init-local.sh
bash scripts/start-local.sh
bash scripts/logs-local.sh kerosene-app-is web-admin bitcoin-core vault-raft-1
bash scripts/backup-local-db.sh
bash scripts/stop-local.sh
```

Compose local equivalente:

```bash
docker compose --env-file backend/kerosene/.env -f docker-compose.yml config
docker compose --env-file backend/kerosene/.env -f docker-compose.yml up -d --build
```

`scripts/init-local.sh` cria/atualiza `backend/kerosene/.env` com segredos locais e gera configs Tor locais sem versionar segredos. `scripts/start-local.sh` valida Docker, prepara o bundle web, sobe a topologia local e aplica `backend/kerosene/src/main/resources/db/migration.sql` nos shards `db-is`, `db-ch` e `db-sg` quando o modo detached e usado.

Backups locais:

```bash
bash scripts/backup-local-db.sh
```

O backup e gravado em `backups/local-db/<timestamp>/`, fora do Git, contendo dumps PostgreSQL de `db-is`, `db-ch`, `db-sg`, snapshots Redis de `redis-is`, `redis-ch`, `redis-sg`, `MANIFEST.txt` e `SHA256SUMS`.

Topologia documentada:

| Componente | Papel |
| --- | --- |
| `kerosene-app-is`, `kerosene-app-ch`, `kerosene-app-sg` | Shards da API principal |
| `web-admin` | Nginx servindo landing, painel admin, download e status web |
| `bitcoin-core` / `bitcoin-pruned-node` | No local mainnet pruned via `bitcoin/bitcoin:27.1`, com RPC/ZMQ internos, egress P2P outbound e wallet descriptor para enderecos on-chain |
| `lnd-neutrino` | LND mainnet real para Lightning, usando o Bitcoin Core pruned local via RPC/ZMQ e gRPC interno |
| `lnd-bootstrap` | Inicializa/desbloqueia a wallet LND e disponibiliza TLS/macaroon para as apps |
| `bitcoin-indexer` | Indexador electrs opcional no profile `archive-indexer`; nao e iniciado no modo pruned padrao |
| `vault-raft-1`, `vault-raft-2`, `vault-raft-3` | Cluster HashiCorp Vault Raft |
| `vault-raft-bootstrap` | Inicializacao e unseal do cluster Raft local |
| `db-is`, `db-ch`, `db-sg` | PostgreSQL por shard |
| `redis-is`, `redis-ch`, `redis-sg` | Redis por shard |
| `mpc-sidecar-is`, `mpc-sidecar-ch`, `mpc-sidecar-sg` | Sidecars MPC Go/gRPC por shard |
| `kerosene-tor-is`, `kerosene-tor-ch`, `kerosene-tor-sg` | Hidden services Tor dos shards |
| `kerosene-vault` | Vault de chaves e atestacao |
| `kerosene-tor-vault` | Hidden service Tor do Vault |
| `prometheus` | Coleta basica de metricas/health |
| `net_db_*`, `net_vault`, `net_tor`, `net_mpc`, `tor_egress` | Redes Docker isoladas |

## Operacao de Release

Crie e valide snapshots antes de subir o stack:

```bash
bash scripts/release-snapshot.sh generate
bash scripts/release-snapshot.sh validate
```

O manifesto assinado contem commit Git, hash do codigo, hash das configs permitidas, digest esperado de imagem e SBOM quando `syft` estiver disponivel. Os servicos expõem a propria versao em `/system/release` ou `/version` e bloqueiam operacoes criticas quando o manifesto autorizado nao bate.

Detalhes completos estao em [docs/INFRASTRUCTURE.md](docs/INFRASTRUCTURE.md).

## API

Formato padrao de resposta da maioria dos endpoints:

```json
{
  "success": true,
  "message": "Mensagem operacional",
  "data": {},
  "timestamp": "2026-04-07T00:00:00"
}
```

Grupos principais:

| Grupo | Base path |
| --- | --- |
| Autenticacao | `/auth`, `/auth/passkey` |
| Carteiras | `/wallet` |
| Ledger interno | `/ledger` |
| Transacoes Bitcoin e payment links | `/transactions` |
| Voucher e onboarding | `/voucher` |
| Auditoria | `/v1/audit`, `/audit` |
| Soberania e status | `/sovereignty` |
| Economia e onramp | `/api/economy`, `/api/onramp` |
| Notificacoes | `/notifications` |
| WebSocket | `/ws/balance`, `/ws/raw-balance`, `/ws/payment-request`, `/ws/raw-payment-request` |
| Vault interno | `/v1/vault` |

Referencia completa: [docs/API_REFERENCE.md](docs/API_REFERENCE.md). Guia de telas, parametros e rotas preferenciais para o frontend: [docs/FRONTEND_API_USAGE.md](docs/FRONTEND_API_USAGE.md).

## Validacao Executada

Checks executados nesta revisao operacional em 2026-05-05:

| Comando | Resultado |
| --- | --- |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --no-daemon` em `backend/kerosene` | OK, 340 testes passaram e 1 ficou skipped. |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew bootJar --no-daemon` em `backend/kerosene` | OK, artefato Spring Boot gerado. |
| `flutter analyze` em `frontend` | OK, sem issues. |
| `flutter test` em `frontend` | OK, todos os testes passaram; integracoes reais `.onion` ficaram skipped por `RUN_REAL_ONION_TESTS`. |
| `flutter build web --release` em `frontend` | OK, bundle web gerado; ha aviso de incompatibilidade para build Wasm por dependencias `dart:html`/`dart:ffi`. |
| `KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING=true flutter build apk --release` em `frontend` | OK, APK de smoke gerado com assinatura debug permitida apenas para validacao local; warning local de NDK foi eliminado alinhando subprojetos ao NDK `28.2.13676358`. |
| `KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING=true flutter build appbundle --release` em `frontend` | OK, AAB de smoke gerado com assinatura debug permitida apenas para validacao local. |
| `flutter build linux --release` em `frontend` | OK apos regenerar artefatos Flutter que estavam com symlinks root-owned antigos. |
| `dart run tool/check_hardcoded_copy.dart` em `frontend` | OK, sem strings visiveis hardcoded detectadas nas areas verificadas. |
| `go test ./...` em `backend/mpc-sidecar` | OK. |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk mvn -B package` em `backend/vault` com Maven temporario | OK, 3 testes passaram e JAR Spring Boot gerado. |
| `bash scripts/release-snapshot.sh generate && bash scripts/release-snapshot.sh validate` | OK, snapshot local assinado e validado. |
| `docker compose --env-file backend/kerosene/.env -f docker-compose.yml config --quiet` | OK. |
| `podman build --format docker -t kerosene-api:validation-docker-format ./backend/kerosene` | OK, imagem da API validada com metadata Docker/Healthcheck. |
| `podman build --format docker -t kerosene-mpc-sidecar:validation-docker-format ./backend/mpc-sidecar` | OK, imagem do MPC sidecar validada com usuario nao-root e Healthcheck. |
| `podman build -t kerosene-vault:validation ./backend/vault` | OK. |
| Smoke runtime do `kerosene-mpc-sidecar:validation-docker-format` | OK, `/version` respondeu e o container ficou `healthy`. |

## Notas Reais Antes de Publicar

- O daemon Docker local continua parado em `/var/run/docker.sock`; as imagens foram validadas com Podman. Valide tambem no CI Docker real antes de release.
- Existem artefatos Flutter antigos renomeados como `*.root-owned-*` porque foram criados anteriormente por root e nao podem ser apagados sem sudo nesta sessao; eles estao ignorados pelo Git.
- O APK de smoke usa `KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING=true`; para release real, configure o upload keystore no CI e nao use essa flag.
- O build web padrao passa, mas build Wasm ainda exige remover ou isolar dependencias que importam `dart:html`/`dart:ffi`.
- `/v1/audit/siphon` falha fechado por padrao e o profile `prod` rejeita `treasury.siphon.manual-settlement-enabled=true`; ainda falta um executor real de payout para coleta automatica de taxas.
- O endereco `bitcoin.deposit-address` em `application.properties` e um valor default de configuracao; substitua por endereco operacional real em producao.

## Documentacao

- [docs/README.md](docs/README.md) - indice tecnico.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - arquitetura real do sistema.
- [docs/INFRASTRUCTURE.md](docs/INFRASTRUCTURE.md) - infraestrutura Docker/Tor/DB/Redis/Vault.
- [docs/PRODUCTION_OPERATIONS.md](docs/PRODUCTION_OPERATIONS.md) - landing, painel, blockchain monitor, Vault Raft, attestation e release snapshots.
- [docs/API_REFERENCE.md](docs/API_REFERENCE.md) - endpoints REST, WebSocket e Vault.
- [docs/FRONTEND_API_USAGE.md](docs/FRONTEND_API_USAGE.md) - quais endpoints cada tela do frontend deve usar e com quais parametros.
- [docs/APK.md](docs/APK.md) - metadados do APK, checksums e publicacao.
