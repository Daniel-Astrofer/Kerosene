# Frontend Notification System

## 1. Escopo atual

O frontend hoje nao tem um unico "sistema de notificacao". Ele tem cinco trilhas paralelas:

1. Notificacao realtime vinda do backend por WebSocket em `/user/queue/notifications`.
2. Atualizacao de saldo por WebSocket em `/user/queue/balance`, que dispara UIs de recebimento.
3. Notificacao local do sistema operacional via `flutter_local_notifications`.
4. Feedback transacional em snackbar via `AppNotice` e `SnackbarHelper`.
5. Dialogs e overlays de erro/sucesso reutilizando `AppNotificationSurface`.

Na pratica, a base visual esta relativamente concentrada, mas o contrato de dados e o roteamento nao estao.

## 2. Onde o sistema e inicializado

### Mobile app

- `frontend/lib/bootstrap/mobile_bootstrap.dart`
  - Inicializa `core/services/notification_service.dart`.
  - Inicializa `background_service_mobile.dart`.
  - Registra `SnackbarHelper.navigatorKey` e `SnackbarHelper.scaffoldMessengerKey` no `MaterialApp`.
  - Ativa o bootstrap realtime com `_AppRealtimeBootstrap`, que observa `balanceWebSocketServiceProvider` quando o usuario esta autenticado.

### Login / restauracao de sessao

- `frontend/lib/features/auth/controller/auth_controller.dart`
  - Em restauracao de sessao (`_checkAuthStatus`) e em `verifyLoginTotp`, chama `features/notifications/application/notification_service.dart`.
  - Essa `NotificationService` de feature hoje e praticamente no-op: ela apenas faz `debugPrint('Local notifications only now.')`.
  - O mesmo controller sincroniza o background service conforme a preferencia `backgroundAlertsEnabled`.

### Web admin

- `frontend/lib/bootstrap/web_bootstrap.dart`
  - Nao inicializa notificacao local.
  - Nao monta `_AppRealtimeBootstrap`.
  - Portanto o painel web nao participa do fluxo realtime do app mobile.

## 3. Infraestrutura de transporte

### 3.1 Canal realtime de notificacoes

- Arquivo: `frontend/lib/core/services/balance_websocket_service.dart`
- Destino STOMP: `/user/queue/notifications`
- Payload esperado:
  - `title`
  - `body`
  - `timestamp`

Observacoes:

- O backend envia apenas `title`, `body` e `timestamp`.
- Nao existe `id`, `kind`, `severity`, `action`, `deeplink`, `entityId`, `read`, `source` ou `dedupeKey`.
- O frontend apenas renderiza texto cru. Ele nao sabe semanticamente qual evento recebeu.

### 3.2 Canal realtime de saldo

- Arquivo: `frontend/lib/core/services/balance_websocket_service.dart`
- Destino STOMP: `/user/queue/balance`
- Payload consumido:
  - `walletId`
  - `walletName`
  - `userId`
  - `newBalance`
  - `amount`
  - `context`
  - `timestamp`
  - `sender` ou aliases (`from`, `fromAddress`)
  - `receiver` ou aliases (`to`, `toAddress`)

Esse canal nao e "notificacao" no nome, mas ele gera experiencia de notificacao quando detecta entrada positiva de saldo.

### 3.3 Notificacao local do SO

- Arquivo: `frontend/lib/core/services/notification_service.dart`
- Plugin: `flutter_local_notifications`
- Canal Android criado:
  - id: `kerosene_updates`
  - nome: `Kerosene Alerts`

Mostra:

- `title`
- `body`
- Android: `BigTextStyleInformation`, `subText: Kerosene`, `Importance.max`, `Priority.high`
- iOS: `presentAlert`, `presentBadge`, `presentSound`, `presentBanner`, `presentList`

## 4. Fluxos reais de disparo

## 4.1 Evento `/user/queue/notifications`

Arquivo principal:

- `frontend/lib/features/wallet/presentation/providers/balance_websocket_provider.dart`

Quando chega um evento em `onNotification`, o frontend faz 6 coisas:

1. Converte o payload em `SessionNotificationItem`.
2. Gera um `id` local baseado em `timestamp-title-body`.
3. Adiciona o item ao `sessionNotificationFeedProvider`.
4. Invalida providers de `paymentLinks`, historico e depositos.
5. Faz `walletProvider.refresh()`.
6. Mostra um snackbar visual de push com `SnackbarHelper.showPushNotification(...)`.

### Derivacoes de UI desse mesmo evento

Em foreground, o mesmo evento gera 2 superficies visiveis:

1. `PushNotificationCard` em snackbar flutuante.
2. Item persistido em memoria na `SessionNotificationSidebar`.

Em background mobile, o mesmo evento gera mais 1 superficie:

3. Notificacao local do SO em `background_service_mobile.dart`.

### Dados mostrados em cada derivacao

#### A. Snackbar de push

- Componente: `PushNotificationCard`
- Conteudo:
  - `title`
  - `message` = `body`
  - `footerLabel` = `Agora` / `Now`
- Icone fixo: notificacao
- Tempo de exibicao: 4s
- Politica: `hideCurrentSnackBar()` antes de mostrar a proxima

#### B. Sidebar de sessao

- Componente: `SessionNotificationSidebar`
- Conteudo por item:
  - `title`
  - `body`
  - `footerLabel` relativo ao tempo (`Agora`, `x min`, horario, `dd/MM`)
- Estado adicional:
  - contador de alertas
  - botao `Limpar`
  - estado vazio
- Persistencia:
  - apenas memoria
  - limite de 30 itens
  - sem `read/unread`
  - sem persistencia entre sessoes

#### C. Notificacao local do SO

- Componente: notificacao nativa do Android/iOS
- Conteudo:
  - `title`
  - `body`
- Sem CTA de dominio
- Sem deep link
- Sem marcacao de lida

## 4.2 Evento `/user/queue/balance` com aumento de saldo

Arquivo principal:

- `frontend/lib/features/wallet/presentation/providers/balance_websocket_provider.dart`

Quando chega `onBalanceUpdate`, o provider:

1. Calcula delta entre saldo antigo e novo.
2. Invalida historicos e listas relacionadas se houve mudanca relevante.
3. Se o valor recebido for positivo, tenta resolver remetente (`sender`) ou extrair endereco do `context`.
4. Dispara `receivedTxEventProvider`.
5. Atualiza o saldo da carteira no estado local.

### Derivacoes de UI desse mesmo evento

Ha 2 derivacoes diretas e 1 indireta:

1. `TransactionSuccessDialog` quando `HomeScreen` esta ouvindo `receivedTxEventProvider`.
2. `_TxPopupWidget` via `txPopupProvider.show(...)`.
3. `LatestTxPopup` pode aparecer depois, quando o historico recarregado passa a ter uma nova transacao no topo.

### Dados mostrados

#### A. `TransactionSuccessDialog`

- Tipo: `TransactionType.receive`
- Dados:
  - valor formatado na moeda selecionada
  - valor BTC secundario, quando a moeda principal nao e BTC
  - contraparte (`sender`), quando existe
- Tempo:
  - auto close em 2.5s

#### B. `_TxPopupWidget`

- Dados:
  - `label = Recebido`
  - `address = sender abreviado`
  - `amount = valor formatado`
  - `time = agora`
- Tempo:
  - auto hide em 4s

#### C. `LatestTxPopup`

- Dados:
  - tipo da transacao
  - valor na moeda selecionada
  - valor BTC secundario
  - data
  - status
- Comportamento:
  - toca no card abre `TxDetailOverlay`

Observacao importante:

- Esse fluxo de recebimento nao usa o feed de notificacao.
- Ele depende de um listener montado em `HomeScreen`.
- Ou seja: a UX de recebimento esta acoplada a um screen especifico, nao a um centro global de notificacoes.

## 4.3 Evento de ativacao de monitoramento em segundo plano

Arquivo principal:

- `frontend/lib/features/settings/presentation/screens/settings_screen.dart`

Quando o usuario ativa `backgroundAlertsEnabled`, o frontend:

1. Abre um bottom sheet de consentimento.
2. Pede permissao de notificacao com `NotificationService().requestPermissions()`.
3. Persiste a preferencia em `SharedPreferences`.
4. Inicia `FlutterBackgroundService`.
5. Mostra `AppNotice` de sucesso ou erro.

### Derivacoes de UI

1. Bottom sheet de consentimento.
2. Prompt de permissao do SO.
3. `AppNotice` informando ativacao/desativacao.
4. No Android, notificacao persistente do foreground service.

## 5. Inventario de superficies de UI

## 5.1 Base visual central

Arquivo base:

- `frontend/lib/core/presentation/widgets/app_notification_surface.dart`

Essa e a superficie visual comum. Ela suporta:

- `title`
- `message`
- `tone`
- `onClose`
- `actions`
- `footerLabel`
- `leadingIcon`

### Tons suportados

1. `neutral`
2. `success`
3. `error`
4. `info`
5. `warning`

## 5.2 Derivacoes diretas de `AppNotificationSurface`

Hoje existem 6 derivacoes diretas:

1. `AppNotice` snackbar generico
2. `PushNotificationCard`
3. `SessionNotificationSidebar` estado vazio
4. `CustomErrorDialog`
5. `AnimatedErrorPopup`
6. `KeroErrorDialog`

## 5.3 Superficies adjacentes com linguagem visual propria

Essas nao reutilizam diretamente `AppNotificationSurface`, mas cumprem papel de notificacao/feedback:

1. `TransactionSuccessDialog`
2. `LatestTxPopup`
3. `_TxPopupWidget`
4. `TxDetailOverlay`

## 6. Quantidade de pontos de disparo hoje

### `SnackbarHelper`

Chamadas mapeadas em `frontend/lib`:

- `showError`: 28
- `showSuccess`: 16
- `showInfo`: 1
- `showWarning`: 4
- `showPushNotification`: 1

Total: 50 call sites

### `AppNotice`

Chamadas mapeadas em `frontend/lib`:

- `showError`: 16
- `showSuccess`: 16
- `showInfo`: 7
- `showWarning`: 18

Total: 57 call sites

Leitura pratica:

- Existem pelo menos 107 pontos de disparo de feedback visual espalhados no app.
- Eles nao passam por um modelo unico de notificacao.
- Parte usa `context`, parte usa chave global do `ScaffoldMessenger`.

## 7. Eventos de dominio que hoje chegam ao frontend

Os eventos abaixo sao emitidos pelo backend para `/user/queue/notifications` e hoje chegam ao frontend apenas como texto livre:

### Autenticacao e seguranca

1. `Acesso Detectado`
2. `Conta criada`
3. `Account Created!`
4. `Emergency recovery completed`

### Transferencias internas e links de pagamento

1. `Transferencia Recebida`
2. `Transferencia Enviada`
3. `Solicitacao de Pagamento Gerada`
4. `Solicitacao de Pagamento Liquidada`

### Blockchain, deposito e pagamentos externos

1. `Transacao Transmitida`
2. `Recurso Recebido`
3. `Deposito Identificado`
4. `Deposito Confirmado`
5. `Deposito confirmado`
6. `Transferencia Confirmada`
7. `Pagamento Lightning enviado`
8. `Pagamento on-chain enviado`

### Mining

1. `Locacao de hashpower iniciada`
2. `Locacao de hashpower concluida`
3. `Locacao de hashpower cancelada`

### Manual / administrativo

1. `POST /notifications/send`

Observacao critica:

- O frontend nao diferencia nenhum desses eventos por tipo.
- Todos caem na mesma UI neutra de push/feed, independentemente de severidade, importancia ou necessidade de acao.

## 8. Problemas arquiteturais atuais

## 8.1 Contrato de dados fraco

O payload de notificacao so tem:

- `title`
- `body`
- `timestamp`

Isso impede:

- deep link seguro
- CTA contextual
- agrupamento por tipo
- read/unread
- deduplicacao confiavel
- telemetria por categoria
- priorizacao visual coerente

## 8.2 Dois `NotificationService` com o mesmo nome e papeis diferentes

Hoje existem:

1. `core/services/notification_service.dart`
2. `features/notifications/application/notification_service.dart`

O primeiro controla notificacao local real.
O segundo deveria representar a feature, mas hoje e um stub/no-op.

Isso induz confusao de ownership.

## 8.3 Fluxo realtime e inbox nao sao globais

- O feed existe em provider global.
- Mas a UI consumidora visivel esta essencialmente em `HomeScreen` e `DepositsScreen`.
- Nao existe uma inbox/central de notificacoes acessivel de qualquer lugar.

## 8.4 Politica de exibicao nao e centralizada

- `AppNotice` usa `context`.
- `SnackbarHelper` usa chave global.
- Push em foreground usa snackbar flutuante.
- Push em background usa notificacao do SO.
- Recebimento usa dialog + popup proprio.

Ou seja: o tipo de UI depende mais de onde o codigo foi escrito do que do tipo semantico do evento.

## 8.5 Feedback sobrepoe feedback

`AppNotice` e `SnackbarHelper.showPushNotification` chamam `hideCurrentSnackBar()` antes de exibir o proximo item.

Consequencia:

- nao existe fila visivel
- o ultimo evento vence
- eventos rapidos podem ser "engolidos" visualmente

## 8.6 Duplicacao e legado

- Existe `core/widgets/custom_error_dialog.dart` com `AnimatedErrorPopup`.
- Existe `core/presentation/widgets/custom_error_dialog.dart` com `AppNotificationSurface`.
- So a versao em `core/presentation/widgets` esta conectada aos fluxos atuais de auth.

Isso aumenta a fragmentacao.

## 8.7 Tela de configuracao de notificacao desconectada

- `features/profile/presentation/screens/notification_settings_screen.dart` usa estado mock local.
- Ela nao persiste nada.
- Ela nao esta integrada ao fluxo real.
- O ajuste real de notificacoes esta em `features/settings/presentation/screens/settings_screen.dart`, mas so cobre `backgroundAlertsEnabled`.

## 9. O que padronizar

## 9.1 Criar um modelo unico de notificacao

Sugestao de contrato:

- `id`
- `kind`
- `channel`
- `severity`
- `title`
- `body`
- `shortBody`
- `createdAt`
- `readAt`
- `dedupeKey`
- `deeplink`
- `actions`
- `entityType`
- `entityId`
- `metadata`
- `deliveryPolicy`

### `kind` minimo recomendado

1. `security_login_detected`
2. `security_recovery_completed`
3. `account_created`
4. `transfer_received`
5. `transfer_sent`
6. `deposit_detected`
7. `deposit_confirmed`
8. `payment_request_created`
9. `payment_request_paid`
10. `mining_started`
11. `mining_completed`
12. `mining_cancelled`
13. `external_payment_sent`
14. `system_info`
15. `system_warning`

## 9.2 Separar "notificacao de dominio" de "feedback de UI"

Padrao sugerido:

- Dominio:
  - eventos do backend
  - recebimento de saldo
  - eventos de seguranca
- Feedback de UI:
  - formulario invalido
  - copiar endereco
  - salvar configuracao
  - erro de submit

Hoje esses dois mundos usam componentes parecidos, mas nao o mesmo pipeline.

## 9.3 Criar um orquestrador unico

Sugestao:

- `NotificationOrchestrator`

Responsabilidades:

1. Receber eventos de WebSocket.
2. Traduzir payload cru em `AppNotification`.
3. Aplicar dedupe.
4. Persistir inbox local.
5. Decidir a superficie correta:
   - inbox
   - banner/snackbar
   - dialog
   - OS notification
6. Marcar telemetria de exibicao e clique.

## 9.4 Definir uma matriz clara de exibicao

Exemplo:

- `security_*`
  - foreground: banner destacado
  - background: OS notification
  - inbox: sim
  - CTA: abrir seguranca/sessoes

- `deposit_confirmed`
  - foreground: banner + inbox
  - background: OS notification
  - CTA: abrir carteira / historico

- `payment_request_paid`
  - foreground: banner + inbox
  - background: OS notification
  - CTA: abrir link liquidado

- `copy_success` e afins
  - foreground: toast curto
  - inbox: nao
  - background: nao

## 9.5 Unificar settings

Substituir os estados fragmentados por uma unica fonte de verdade, por exemplo:

- `pushEnabled`
- `backgroundMonitoringEnabled`
- `securityAlertsEnabled`
- `transactionAlertsEnabled`
- `marketingAlertsEnabled`

E remover a tela mock ou conecta-la ao estado real.

## 10. Plano recomendado de implementacao

## Fase 1. Consolidacao tecnica

1. Escolher um unico `NotificationService` de ownership.
2. Remover ou renomear o service stub da feature.
3. Introduzir entidade `AppNotification`.
4. Introduzir `NotificationOrchestrator`.
5. Centralizar os adapters de WebSocket para passar pelo orquestrador.

## Fase 2. Contrato de payload

1. Evoluir o payload do backend para incluir `id`, `kind`, `severity`, `deeplink`, `metadata`.
2. Manter compatibilidade com `title/body/timestamp` durante migracao.
3. Fazer o frontend parar de inferir semantica por texto.

## Fase 3. Inbox real

1. Persistir notificacoes localmente.
2. Adicionar `read/unread`.
3. Criar uma tela/rota de central de notificacoes.
4. Fazer a sidebar ser apenas uma view dessa mesma fonte de verdade.

## Fase 4. Politica de UX

1. Definir quais eventos viram toast.
2. Definir quais viram banner persistente.
3. Definir quais viram dialog.
4. Definir quais viram OS notification.
5. Padronizar copy, iconografia, severidade e CTA por `kind`.

## Fase 5. Migracao gradual de call sites

1. Parar de disparar `AppNotice` e `SnackbarHelper` diretamente em eventos de dominio.
2. Deixar `AppNotice` apenas para feedback efemero de UI.
3. Migrar recebimento de saldo para o mesmo pipeline semantico do centro de notificacoes.

## 11. Decisoes que valem ser tomadas antes de implementar

1. A inbox deve ser somente de eventos do backend ou tambem incluir feedback local importante?
2. Eventos de recebimento de saldo devem virar notificacao de dominio formal ou continuar como popup especial?
3. O app web tambem precisa consumir notificacoes realtime, ou isso fica restrito ao app mobile?
4. O historico de notificacoes precisa sobreviver logout/login no mesmo aparelho?
5. Quais eventos exigem CTA obrigatoria?

## 12. Resumo executivo

Hoje o frontend ja possui uma base visual reutilizavel, mas nao possui um sistema unificado de notificacao.

O que existe de fato e:

- 1 canal realtime de notificacoes por texto livre
- 1 canal realtime de saldo que tambem vira notificacao
- 1 feed em memoria de sessao
- 1 camada de notificacao local do SO
- 107 call sites de feedback visual espalhados
- varias superficies visuais concorrentes

Se o objetivo e padronizar UI e "permitir elas serem consumidas devidamente", o proximo passo correto nao e redesenhar cards primeiro.

O passo correto e:

1. definir contrato semantico
2. centralizar orquestracao
3. separar notificacao de dominio de feedback de UI
4. so depois unificar a apresentacao
