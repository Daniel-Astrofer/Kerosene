# Frontend/backend UI audit

Data da auditoria: 2026-05-29

Escopo: controllers Spring em `backend/kerosene/src/main/java/source`,
rotas Flutter em `frontend/lib/bootstrap`, inventario Storybook, textos/branding
em `frontend/lib` e design system documentado em `docs/FRONTEND_DESIGN_SYSTEM.md`.

## Lacunas de tela vs backend

| Backend/contrato | Estado no frontend | Acao |
| --- | --- | --- |
| `/auth/recovery/emergency/start` e `/finish` | Tela publica e service dedicados implementados no P1. | Manter testes de widget/contrato e validar em ambiente com passkey local. |
| `/bitcoin/cold-wallets/{id}/utxos`, `/psbt`, `/bitcoin/psbt/{id}`, `/bitcoin/tax-events` | Implementado dentro de `BitcoinAccountsScreen`: painel de UTXOs, criacao de PSBT, copia/envio de PSBT assinada, tax events, classificacao e export JSON/CSV. Service, modelos, providers e mocks Storybook acompanham os contratos. | Validar em ambiente com Bitcoin Core/RPC real e carteira externa. |
| `/auth/backup-codes`, `/auth/totp`, `/auth/passkey/devices` | Implementado em `SecuritySettingsScreen`: status de seguranca, TOTP setup/verify/disable, backup codes status/regenerate, inventario de passkeys por dispositivo, registro de novo dispositivo, app PIN e bloqueio/revogacao de passkeys por `deviceInstallId`. | Validar em dispositivo real com passkey local e TOTP ativo. |
| `/voucher/**` | README cita endpoints, mas nao ha controller atual no backend. | Tratar como doc stale, nao criar tela ate existir controller. |

## Registro de implementacao

- 2026-05-29 / P2 Bitcoin Advanced: integrado em
  `BitcoinAccountsScreen` com UTXOs monitorados, PSBT workflows, criacao de
  unsigned PSBT, copia/envio de signed PSBT, tax events, classificacao e export
  JSON/CSV. Contratos atualizados em models, service, providers, testes e
  Storybook.
- 2026-05-29 / P2 Account Security: completado inventario mobile de
  credenciais com `/auth/security/profile`, `/auth/security-status`,
  `/auth/backup-codes`, `/auth/totp` e `/auth/passkey/devices`; a lista de
  dispositivos autenticados agora tambem consegue bloquear/revogar passkeys via
  `/auth/passkey/devices/{deviceInstallId}/block|revoke`, com textos das acoes
  em l10n e mocks Storybook incluindo dispositivos ativos/bloqueados.
- 2026-05-29 / P2 continuo l10n recorte 1: removidos hardcodes visiveis de
  `Receive requests` em `BitcoinAccountsScreen`; ARB e localizations en/pt/es
  sincronizados para titulo, estados de erro/offline/vazio, valor flexivel e
  expiracao.
- 2026-05-29 / P2 continuo l10n recorte 2A: concluido em `features/payments`.
  `payment_intent_flow_screen.dart`, `payment_intent_widgets.dart` e
  `payment_intent_provider.dart` agora usam chaves l10n para textos visiveis,
  labels de trilho/taxa/status e mensagens de validacao; o provider emite erro
  tipado e a tela traduz via `context.tr`.
- 2026-05-29 / P2 continuo l10n recorte 2B: concluido em
  `deposits_screen.dart` e `withdraw_screen.dart`. O fluxo de recebimento,
  gateway de provedores, extrato financeiro e envio externo agora usam chaves
  l10n para textos visiveis, labels de review/taxa/tempo e mensagens
  contextuais; nomes de provedores, rotas, regex e constantes de API ficaram
  como valores tecnicos.
- 2026-05-29 / P2 continuo l10n recorte 2C: em andamento em
  `bitcoin_accounts_screen.dart`, sem tocar no 2B; foco nos literais visiveis
  restantes de Bitcoin Advanced, PSBT, UTXO e relatorios fiscais. Primeira
  passada migrada para l10n no painel advanced, sheets de PSBT e bloco fiscal;
  ainda revisar fluxos de criacao/configuracao de contas no mesmo arquivo.
- 2026-05-29 / P2 continuo l10n recorte 2D: em andamento em `web_admin/**`,
  sem tocar nos recortes 2B/2C; primeira passada migrou o login
  administrativo, o indicador de conexao onion e o retry comum do painel web
  para l10n; segunda passada migrou labels do shell/topbar e rotas da sidebar,
  e terceira passada migrou `settings`, `monitoring`, `companies`/
  infrastructure e `payment_links` para l10n com templates tipados de metricas,
  erros, tabelas e estados vazios.
- Proxima fase: continuar o recorte 2D nas telas restantes de `web_admin/**`
  (`dashboard`, `analytics`, `audit`, `checks`, `lightning`, `onchain`,
  `transactions`, `volatility` e `authenticated_devices`) sem sobrepor os
  recortes 2B/2C; depois disso, normalizar radius/assets conforme o design
  system em alteracao separada.

## Incoerencias de UI e texto

- O app ainda tem strings hardcoded em telas de producao, especialmente
  residuos em `bitcoin_accounts_screen.dart` e `web_admin/**`, ambos ja em
  andamento por outros agentes. Os recortes de `features/payments`,
  `deposits_screen.dart` e `withdraw_screen.dart` ja foram migrados para l10n.
  Isso contraria o design system, que exige `context.tr`.
- Ha raios de borda acima de 8px em muitas surfaces/cards mobile
  (`statement_transaction_card.dart`, `bitcoin_accounts_screen.dart`,
  `sovereignty_status_screen.dart`, `landing`, widgets auth). O design system
  atual documenta cards em 8px salvo padrao local explicitamente estabelecido.
- A pasta `frontend/assets/fonts` ainda contem fontes fora da lista permitida
  (`HubotSans`, `Lato`, `SF Pro`, `SpaceGrotesk`). A busca nao encontrou uso
  direto dessas familias em `frontend/lib`, mas os assets permanecem incoerentes
  com o contrato.
- Branding antigo critico nao apareceu em `frontend/lib` para `Hydra`,
  `hydra_logo`, `Kerosene Bank`, `package:teste`, `com.teste` ou
  `com.example.teste`. Permanecem apenas comentarios/termos genericos de
  template em arquivos de plataforma.
- O inventario Storybook agora inclui `Bitcoin/Advanced`, alem de admin,
  payments e receive requests.

## Ordem recomendada

1. P2 continuo: migrar strings hardcoded de telas financeiras para l10n e
   normalizar radius/assets do design system em commits separados.
2. P2 QA: validar Bitcoin Advanced e Account Security em ambiente real com
   Bitcoin Core/RPC, carteira externa, passkey local e TOTP ativo.
