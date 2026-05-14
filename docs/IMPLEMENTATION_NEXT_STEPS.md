# Implementation Next Steps

Esta lista vem da leitura dos `.md`, controllers, configs, scripts e frontend atuais.

## Prioridade 0 - Corrigir inconsistencias que quebram confiabilidade

1. Renumerar uma das migracoes `V10__*.sql`; existem duas versoes `V10`, o que pode quebrar Flyway em producao.
2. Limpar constantes frontend sem controller atual: `/notifications/send`, `/transactions/confirm-deposit`, `/transactions/deposits`, `/transactions/deposit-balance`, `/transactions/deposit`.
3. Decidir se `/v1/audit/stats` deve ser publico ou JWT. O comentario do controller fala em transparencia publica, mas `Security.java` exige autenticacao para `/v1/audit/**`.
4. Revisar `X-Device-Hash`: o frontend injeta em mobile e varios controllers aceitam; comentario em `AppConfig` diz que foi removido. O contrato precisa ser unificado.
5. Remover ou arquivar `web-admin-build.stale-*` e artefatos gerados versionados se nao forem necessarios.

## Prioridade 1 - API e contratos financeiros

1. Escrever testes de contrato para todos os endpoints financeiros: ledger, payment links, `/payments/*`, network transfers, Bitcoin accounts, PSBT e treasury.
2. Padronizar erros para evitar concorrencia entre `GlobalExceptionHandler` e `RestResponseErrors` legado.
3. Validar idempotencia por rota: `Idempotency-Key` header, `idempotencyKey` no body e Redis precisam de regra unica.
4. Documentar e testar limites de payload PSBT vs limite padrao de 2KB.
5. Formalizar status machines de `PaymentIntent`, `ExternalTransfer`, `PaymentLink`, `ReceivingRequest`, `PsbtWorkflow` e `TreasuryPayout`.

## Prioridade 2 - Infraestrutura e operacao

1. Rodar `bash scripts/start-local.sh` em ambiente limpo e atualizar docs se algum servico divergir.
2. Validar health de `kerosene-app-is/ch/sg`, Vault, Vault Raft, Bitcoin Core, LND, MPC e Prometheus.
3. Criar checklist de secrets obrigatorios por perfil (`default`, `docker`, `prod`).
4. Separar claramente docs de local, staging e producao para evitar usar compose endurecido como caminho de dev simples.
5. Adicionar runbook de restore de Postgres/Redis e rotacao de Tor keys sem vazar segredo.

## Prioridade 3 - App Flutter

1. Padronizar camada de repositories/services para todas as features; hoje algumas chamadas usam services diretos e outras providers/domain repositories.
2. Cobrir `/payments/*` no frontend se o novo dominio for o caminho principal para pagamentos externos.
3. Unificar notificacoes: inbox, WebSocket, local notifications e UI feedback ainda estao parcialmente fragmentados.
4. Revisar fluxo de Tor relay mobile e web admin gateway, especialmente Host override, passkey RP ID e origem WebAuthn.
5. Atualizar Storybook/mocks para refletir contratos novos de Bitcoin accounts, payments e admin devices.

## Prioridade 4 - Seguranca

1. Revisar todos os endpoints publicos em `Security.java` e confirmar que cada um realmente pode ser publico.
2. Validar `BTCPAY-SIG` obrigatorio no webhook conforme `BtcPayWebhookService`; o controller aceita header opcional, mas o service rejeita ausencia.
3. Exigir segredo real para `security.admin.attestation-token`, `FOUNDER_TOTP_SECRET`, `X-Hardware-Signature` e flows de treasury antes de qualquer ambiente com dinheiro real.
4. Revisar logs para garantir que txid completo, endereco, passphrase, passkey credential e recovery codes nao vazem.
5. Adicionar teste para CORS sem wildcard e para rejeicao de content-type/payload acima do limite.

## Prioridade 5 - Documentacao continua

1. Manter `docs/API_REFERENCE.md` como fonte gerada/verificada a partir de controllers.
2. Manter a limpeza aplicada: evitar novas copias paralelas em `backend/kerosene/docs`, `docs-final` ou documentos Hydra.
3. Criar changelog de contrato da API quando endpoints mudarem.
4. Adicionar validacao CI que compara controllers com a matriz de endpoints documentada.
