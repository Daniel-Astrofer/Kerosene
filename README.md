# Kerosene

Plataforma financeira Bitcoin em estado pre-alpha, com aplicativo Flutter, API Spring Boot, Vault de provisionamento de chaves, sidecar MPC em Go e infraestrutura Docker/Tor para shards regionais.

Esta documentacao reflete o estado real do repositorio inspecionado em 2026-04-07.

## Status do Projeto

| Area | Estado real no repositorio |
| --- | --- |
| Mobile | Flutter/Dart com app Android, iOS, web, Linux, macOS e Windows scaffolded. O build Android existente gera `app-release.apk` versao `1.0.0`. |
| Backend principal | Java 21, Spring Boot 3.3.2, Gradle, REST, WebSocket/STOMP, Spring Security, JPA, Redis, PostgreSQL, BitcoinJ e clientes de blockchain. |
| Vault | Servico Java 21/Maven/Spring Boot separado, porta interna `8090`, responsavel por armamento, atestacao e provisionamento de chave AES. |
| MPC sidecar | Servico Go 1.24/gRPC com `tss-lib`, porta `50051`. O sidecar implementa contratos `Keygen` e `Sign`; o cliente Java atual ainda possui retorno placeholder. |
| Infraestrutura | Docker Compose com shards IS/CH/SG, PostgreSQL, Redis, Tor hidden services, Vault e redes isoladas. |
| API | Endpoints documentados em [docs/API_REFERENCE.md](docs/API_REFERENCE.md), derivados dos controllers reais. |
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
| Blockchain | BitcoinJ, Pocket Network gateway, servicos de fee/onramp/payment link |
| Seguranca | JWT, TOTP, Passkey/WebAuthn-like Ed25519 flow, Argon2/pepper, filtros de rate limit, filtros de payload e Vault AES |
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
bash scripts/logs-local.sh
bash scripts/stop-local.sh
```

Compose local equivalente:

```bash
docker compose --project-name kerosene-infrastructure --env-file backend/kerosene/.env -f backend/kerosene-infrastructure/docker-compose.local.yml config
docker compose --project-name kerosene-infrastructure --env-file backend/kerosene/.env -f backend/kerosene-infrastructure/docker-compose.local.yml up -d --build
```

Topologia documentada:

| Componente | Papel |
| --- | --- |
| `kerosene-app-is`, `kerosene-app-ch`, `kerosene-app-sg` | Shards da API principal |
| `db-is`, `db-ch`, `db-sg` | PostgreSQL por shard |
| `redis-is`, `redis-ch`, `redis-sg` | Redis por shard |
| `mpc-sidecar-is`, `mpc-sidecar-ch`, `mpc-sidecar-sg` | Sidecars MPC Go/gRPC por shard |
| `kerosene-tor-is`, `kerosene-tor-ch`, `kerosene-tor-sg` | Hidden services Tor dos shards |
| `kerosene-vault` | Vault de chaves e atestacao |
| `kerosene-tor-vault` | Hidden service Tor do Vault |
| `net_db_*`, `net_vault`, `net_tor`, `net_mpc`, `tor_egress` | Redes Docker isoladas |

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

Referencia completa: [docs/API_REFERENCE.md](docs/API_REFERENCE.md).

## Validacao Executada

Checks executados nesta revisao da documentacao:

| Comando | Resultado |
| --- | --- |
| `git diff --cached --check -- README.md docs/... .gitignore` | OK, sem erros de whitespace no material documentacional staged. |
| `docker compose --project-name kerosene-infrastructure -f backend/kerosene-infrastructure/docker-compose.local.yml config` | OK no working tree local. A saida materializa variaveis de ambiente e nao deve ser publicada. |
| `./gradlew test` em `backend/kerosene` | Falhou com Java 25; o projeto esta configurado para Java 21. |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test` em `backend/kerosene` | Falhou em `:compileJava` com erros pre-existentes de contrato/modelo/dependencia. |

Principais bloqueios de compilacao observados no backend:

- Falta a dependencia `com.fasterxml.jackson.dataformat:jackson-dataformat-cbor` usada por `PasskeyService`.
- `PasskeyCredential` nao expoe `setDeviceName(String)`.
- `RedisServicer` nao expoe `getAndDeleteValue(String)`.
- `UserDataBase` nao expoe `getTestBalanceClaimed()` nem `setTestBalanceClaimed(boolean)`.
- `BlockchainClient`, `LedgerService`, `WalletEntity`, `WalletService` e `SignupState` estao desalinhados com chamadas usadas por servicos atuais.

## Notas Reais Antes de Publicar

- O APK atual ja existe, mas nao foi regenerado nesta execucao porque o working tree local esta com `frontend/pubspec.yaml`, `frontend/pubspec.lock` e `frontend/analysis_options.yaml` ausentes apesar de existirem no indice Git local.
- O comando `flutter --version` tentou escrever no cache do SDK em `/home/omega/flutter` e foi bloqueado pelo sandbox da sessao.
- O compose local atual foi validado com `docker compose config`; antes de publicar, garanta que a versao resolvida do arquivo esta staged, porque ha arquivos no repositorio com flag local `assume-unchanged`.
- O cliente Java `MpcSidecarClient` ainda retorna valores placeholder em `keygen` e `sign`, embora o sidecar Go exponha o contrato gRPC real.
- O endereco `bitcoin.deposit-address` em `application.properties` e um valor default de configuracao; substitua por endereco operacional real em producao.

## Documentacao

- [docs/README.md](docs/README.md) - indice tecnico.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - arquitetura real do sistema.
- [docs/INFRASTRUCTURE.md](docs/INFRASTRUCTURE.md) - infraestrutura Docker/Tor/DB/Redis/Vault.
- [docs/API_REFERENCE.md](docs/API_REFERENCE.md) - endpoints REST, WebSocket e Vault.
- [docs/APK.md](docs/APK.md) - metadados do APK, checksums e publicacao.
