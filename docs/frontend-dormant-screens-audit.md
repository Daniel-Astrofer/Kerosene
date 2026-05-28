# Frontend dormant screens audit

Data da auditoria: 2026-05-28

Escopo: telas citadas na estabilizacao do frontend como possivelmente sem
referencia real. Esta auditoria nao remove arquivos; ela classifica cada tela
antes de qualquer limpeza destrutiva.

Comandos usados:

```bash
grep -R "ReceivePaymentLinkScreen\|SovereigntyStatusScreen\|WithdrawReceiptScreen\|WithdrawScreen\|SendMethodScreen" -n frontend/lib frontend/test STORYBOOK_SCREEN_INVENTORY.md
grep -R "receive_payment_link_screen.dart\|sovereignty_status_screen.dart\|withdraw_receipt_screen.dart\|transactions/presentation/screens/withdraw_screen.dart\|home_screen_send_method.dart" -n frontend/lib frontend/test STORYBOOK_SCREEN_INVENTORY.md
grep -R "ReceivePaymentLinkScreen\|SovereigntyStatusScreen\|WithdrawReceiptScreen\|WithdrawScreen\|_SendMethodScreen" -n frontend/lib/storybook frontend/test
git ls-files frontend/lib/features/wallet/presentation/screens/receive_payment_link_screen.dart frontend/lib/features/security/presentation/screens/sovereignty_status_screen.dart frontend/lib/features/wallet/presentation/screens/withdraw_receipt_screen.dart frontend/lib/features/transactions/presentation/screens/withdraw_screen.dart frontend/lib/features/home/presentation/screens/home_screen_send_method.dart
```

## Resultado

| Tela | Arquivo | Existe | Rota/entrada real | Import em producao | Teste direto | Storybook real | Classificacao | Acao |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `_SendMethodScreen` | `frontend/lib/features/home/presentation/screens/home_screen_send_method.dart` | Sim | `HomeScreen._openSendActionsSheet` faz push direto | Sim, via `part` de `home_screen.dart` | Nao | Indireto pela story de `HomeScreen` | A. Usada em producao | Manter. Testar pelo fluxo da Home. |
| `ReceivePaymentLinkScreen` | `frontend/lib/features/wallet/presentation/screens/receive_payment_link_screen.dart` | Sim | Nao encontrada | Nao encontrado fora do proprio arquivo | Nao | Nao encontrada | B. Planejada, mas nao usada | Nao tratar como producao ate receber rota/entrada. Avaliar ligar ao fluxo de recebimento ou remover em commit proprio. |
| `SovereigntyStatusScreen` | `frontend/lib/features/security/presentation/screens/sovereignty_status_screen.dart` | Sim | Nao encontrada | Nao encontrado fora do proprio arquivo | Nao | Nao encontrada | B. Planejada, mas nao usada | Manter fora do fluxo principal ate haver decisao de produto e rota protegida. |
| `WithdrawScreen` | `frontend/lib/features/transactions/presentation/screens/withdraw_screen.dart` | Sim | Nao encontrada | Nao encontrado fora do proprio arquivo | Nao | Nao encontrada | B. Planejada, mas nao usada | Nao tratar como fluxo atual. Ligar explicitamente a envio externo ou remover em commit proprio. |
| `WithdrawReceiptScreen` | `frontend/lib/features/wallet/presentation/screens/withdraw_receipt_screen.dart` | Sim | Nao encontrada | Nao encontrado fora do proprio arquivo | Nao | Nao encontrada | C. Prototipo legado/dormente | Mover para Storybook/dev ou remover em commit proprio depois de validar que `PaymentConfirmationScreen` cobre o recibo atual. |

## Decisoes

- Nenhuma tela sem entrada real foi classificada como producao.
- `_SendMethodScreen` deixou de ser dormente: ela e privada, mas esta no fluxo
  real da Home.
- As telas planejadas/dormentes permanecem fora do fluxo principal. Para virar
  producao, precisam de rota ou push explicito, teste e inventario atualizado.
- Como os arquivos auditados ja tinham alteracoes pendentes no worktree, esta
  etapa nao removeu arquivos para nao sobrescrever trabalho existente.

## Proximos passos

- Etapa 5 deve atualizar `STORYBOOK_SCREEN_INVENTORY.md`, removendo entradas
  stale e marcando status como `production`, `dev_only`, `storybook_only`,
  `dormant` ou `deprecated`.
- Se uma tela for decidida como morta, remover em commit separado depois de
  confirmar que nao ha rota, import, teste ou storybook real.
