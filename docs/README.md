# Kerosene Documentation

Documentacao consolidada a partir dos `.md` existentes, controllers Spring, DTOs, configuracoes, scripts e app Flutter atuais.

## Documentos principais

| Documento | Conteudo |
| --- | --- |
| [API_REFERENCE.md](API_REFERENCE.md) | Referencia completa da API atual. Cada endpoint tem headers, path/query params, request body e response body independentes. |
| [INFRASTRUCTURE.md](INFRASTRUCTURE.md) | Infraestrutura atual por compose, scripts, profiles Spring, Vault, MPC, Tor, Bitcoin, Lightning, Redis e Postgres. |
| [APP.md](APP.md) | Documentacao do app Flutter: mobile, web admin, rotas, HTTP, Tor relay, auth, realtime e features. |
| [IMPLEMENTATION_NEXT_STEPS.md](IMPLEMENTATION_NEXT_STEPS.md) | Proximos passos de implementacao por prioridade. |
| [DOCUMENTATION_AUDIT.md](DOCUMENTATION_AUDIT.md) | Auditoria dos `.md` existentes e decisao de fonte canonica. |

## Limpeza aplicada

As documentacoes antigas e contraditorias foram removidas: `docs-final/**`, `backend/kerosene/*.md`, `backend/kerosene/docs/*.md`, docs antigas em `docs/` e a pasta `docs/bitcoin-accounts/`. A fonte canonica fica restrita aos documentos principais acima.

## Validacao recomendada

```bash
cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test
cd frontend && flutter analyze && flutter test
cd backend/mpc-sidecar && go test ./...
cd backend/vault && mvn package
```

A referencia de API foi reconciliada com os controllers atuais, mas ainda vale automatizar uma validacao CI que compare mappings Java com a documentacao.
