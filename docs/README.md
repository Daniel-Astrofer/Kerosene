# Documentacao Tecnica Kerosene

Esta pasta contem a documentacao real do repositorio para publicacao no GitHub.

Ela deve permanecer enxuta: mantenha aqui somente documentos canonicos, versionaveis e auditaveis. Logs diarios, checklists temporarios, dumps JSON de API, analises antigas e documentos com nomes/rotas divergentes devem ficar fora desta pasta ou ser consolidados nos arquivos abaixo.

| Documento | Conteudo |
| --- | --- |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Arquitetura por componente, fluxo de dados, seguranca e limites atuais. |
| [INFRASTRUCTURE.md](INFRASTRUCTURE.md) | Docker Compose, Tor hidden services, PostgreSQL, Redis, Vault, redes, volumes e scripts operacionais. |
| [PRODUCTION_OPERATIONS.md](PRODUCTION_OPERATIONS.md) | Landing web, painel empresarial, Bitcoin Core pruned, LND, Vault Raft, release snapshots e attestation. |
| [PRODUCTION_READINESS.md](PRODUCTION_READINESS.md) | Gates de prontidao para producao, validacoes obrigatorias e pendencias operacionais antes do lancamento. |
| [API_REFERENCE.md](API_REFERENCE.md) | API REST, WebSocket/STOMP e API interna do Vault derivadas dos controllers reais. |
| [FRONTEND_API_USAGE.md](FRONTEND_API_USAGE.md) | Guia de consumo da API pela UI, com endpoints por tela, parametros e rotas a evitar. |
| [FEATURES_AND_STATES.md](FEATURES_AND_STATES.md) | Mapa funcional do app, estados expostos ao frontend, implementacao atual e gaps para proximas iteracoes. |
| [APK.md](APK.md) | Metadados, checksums e processo profissional de publicacao do APK. |

## Escopo

Esta documentacao foi montada a partir destes arquivos reais:

- `backend/kerosene/src/main/java/**`
- `backend/kerosene/src/main/resources/application*.properties`
- `frontend/lib/features/landing/**`
- `frontend/lib/features/web_admin/**`
- `backend/kerosene/docker-compose.yml`
- `backend/kerosene-infrastructure/docker-compose.local.yml`
- `backend/kerosene-infrastructure/bitcoin/**`
- `backend/kerosene-infrastructure/vault/raft/**`
- `scripts/release-snapshot.sh`
- `backend/kerosene-infrastructure/scripts/init-local.sh`
- `backend/vault/src/main/java/**`
- `backend/mpc-sidecar/**`
- `scripts/*.sh`
- `frontend/lib/**`
- `frontend/android/app/build.gradle.kts`
- `frontend/build/app/outputs/apk/release/output-metadata.json`

## Observacoes de Publicacao

- Nao versionar `frontend/build/**`; publique o APK em GitHub Releases.
- Nao versionar `.env`, certificados, chaves Tor, keystores, `.jks`, `.p12`, `.pfx`, `google-services.json` ou service accounts.
- Use `bash scripts/start-local.sh` para subir o backend local canonico.
- Antes de publicar, rode `docker compose --project-name kerosene-infrastructure --env-file backend/kerosene/.env -f backend/kerosene-infrastructure/docker-compose.local.yml config` para validar o compose local sem exibir a saida em canais publicos, pois o comando materializa variaveis de ambiente.
- O README raiz referencia somente documentacao e checksums; valores sensiveis devem ficar fora do repositorio.

## Validacao Real

Validacoes executadas neste passe de revisao da documentacao da API:

| Verificacao | Resultado |
| --- | --- |
| Cobertura mecanica entre `@RestController` e `docs/API_REFERENCE.md` | OK apos documentar tambem `/transactions/network/*` e `/mining/*`. |
| Revisao manual de contratos DTO/controller/service | OK apos alinhar retorno real de login, formato de `login/totp/verify`, corpo de `ledger/payment-request/{linkId}/pay`, estados de payment links/onboarding, pagamentos externos e alugueis de mineracao. |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew compileJava` | OK. |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.auth.application.orchestrator.recovery.EmergencyRecoveryUseCaseTest --tests source.auth.dto.AccountSecurityProfileDTOTest` | OK. |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.transactions.service.ExternalPaymentsServiceTest --tests source.mining.service.MiningServiceTest` | OK. |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.wallet.service.WalletCardProfileServiceTest --tests source.wallet.orchestrator.WalletUseCaseTest --tests source.transactions.service.ExternalPaymentsServiceTest` | OK. |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.transactions.application.paymentlink.PaymentLinkConfirmerTest --tests source.transactions.infra.paymentlink.PaymentLinkWalletCreditAdapterTest` | OK. |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.transactions.service.PaymentLinkServiceRedisTest` | Falhou no ambiente de revisao por indisponibilidade de Redis (`RedisConnectionFailureException`); testes foram atualizados, mas nao houve execucao completa aqui. |

Observacao: este passe validou especificamente a referencia da API contra o backend atual, incluindo cartoes de wallet, taxa dinamica de deposito/saque e o breakdown `gross/depositFee/net` dos payment links. Nao houve reexecucao das verificacoes de infraestrutura desta pasta.
