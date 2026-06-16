# Kerosene Documentation

Documentacao consolidada a partir dos `.md` existentes, controllers Spring, DTOs, configuracoes, scripts e app Flutter atuais.

## Documentos principais

| Documento | Conteudo |
| --- | --- |
| [API_REFERENCE.md](API_REFERENCE.md) | Referencia completa da API atual. Cada endpoint tem headers, path/query params, request body e response body independentes. |
| [INFRASTRUCTURE.md](INFRASTRUCTURE.md) | Infraestrutura atual por compose, scripts, profiles Spring, Vault, MPC, Tor, Bitcoin, Lightning, Redis e Postgres. |
| [APP.md](APP.md) | Documentacao do app Flutter: mobile, web admin, rotas, HTTP, Tor relay, auth, realtime e features. |
| [FRONTEND_DESIGN_SYSTEM.md](FRONTEND_DESIGN_SYSTEM.md) | Sistema visual e convencoes de UI do frontend. |
| [REPOSITORY_ORGANIZATION.md](REPOSITORY_ORGANIZATION.md) | Politica de estrutura de diretorios, caches, builds e adapters. |

## Limpeza aplicada

As documentacoes antigas e contraditorias devem permanecer fora da raiz operacional. A fonte canonica fica restrita aos documentos principais acima e aos relatórios tecnicos atuais mantidos em `docs/`.

## Validacao recomendada

```bash
cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test
cd frontend && flutter analyze && flutter test
cd backend/mpc-sidecar && go test ./...
cd backend/vault && mvn package
```

A referencia de API foi reconciliada com os controllers atuais, mas ainda vale automatizar uma validacao CI que compare mappings Java com a documentacao.
