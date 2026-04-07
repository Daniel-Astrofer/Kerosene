# Documentacao Tecnica Kerosene

Esta pasta contem a documentacao real do repositorio para publicacao no GitHub.

Ela deve permanecer enxuta: mantenha aqui somente documentos canonicos, versionaveis e auditaveis. Logs diarios, checklists temporarios, dumps JSON de API, analises antigas e documentos com nomes/rotas divergentes devem ficar fora desta pasta ou ser consolidados nos arquivos abaixo.

| Documento | Conteudo |
| --- | --- |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Arquitetura por componente, fluxo de dados, seguranca e limites atuais. |
| [INFRASTRUCTURE.md](INFRASTRUCTURE.md) | Docker Compose, Tor hidden services, PostgreSQL, Redis, Vault, redes, volumes e scripts operacionais. |
| [API_REFERENCE.md](API_REFERENCE.md) | API REST, WebSocket/STOMP e API interna do Vault derivadas dos controllers reais. |
| [APK.md](APK.md) | Metadados, checksums e processo profissional de publicacao do APK. |

## Escopo

Esta documentacao foi montada a partir destes arquivos reais:

- `backend/kerosene/src/main/java/**`
- `backend/kerosene/src/main/resources/application*.properties`
- `backend/kerosene/docker-compose.yml`
- `backend/kerosene-infrastructure/docker-compose.local.yml`
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

Validacoes executadas durante a preparacao desta documentacao:

| Verificacao | Resultado |
| --- | --- |
| `git diff --cached --check` no README, docs e `.gitignore` | OK. |
| `docker compose -f backend/kerosene-infrastructure/docker-compose.local.yml config` | OK no working tree local. |
| `./gradlew test` com Java padrao da maquina | Falhou porque o Gradle recebeu Java 25, enquanto o projeto usa Java 21. |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test` | Falhou em `:compileJava` com erros pre-existentes no backend. |

Bloqueios de backend identificados: dependencia CBOR ausente, contratos divergentes em `PasskeyCredential`, `RedisServicer`, `UserDataBase`, `BlockchainClient`, `LedgerService`, `WalletEntity`, `WalletService` e `SignupState`.
