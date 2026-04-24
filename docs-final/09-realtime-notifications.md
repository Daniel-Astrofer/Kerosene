# Kerosene - Realtime and Notifications

## Realtime Surface Summary

Kerosene currently uses Spring STOMP/WebSocket for two active realtime concerns:

- balance updates
- user notifications

There is also an internal-payment-request topic path in the backend, but the main frontend consumer currently focuses on balance and notification queues.

## STOMP Configuration

Backend broker configuration:

- simple broker prefixes: `/topic`, `/queue`
- application destination prefix: `/app`
- heartbeat: `10000 / 10000`

Registered endpoints:

- `/ws/balance` with SockJS
- `/ws/raw-balance` without SockJS
- `/ws/payment-request` with SockJS
- `/ws/raw-payment-request` without SockJS

Handshake behavior:

- allowed origins are inherited from the strict HTTP CORS allowlist
- handshake handler forces compatible STOMP protocol behavior when needed

## Authentication Model

HTTP upgrade on `/ws/**` is allowed through the HTTP security chain.

Actual session authorization happens during STOMP `CONNECT`:

- client must send native header `Authorization`
- `NativeHeaderStompTokenResolver` strips `Bearer `
- `ConnectAuthenticationStompMessageHandler` validates JWT and binds the user principal

If the header is missing or invalid:

- the STOMP connection is rejected

## Backend Balance Realtime

## Publisher chain

Balance publishing path:

1. ledger code produces `LedgerBalanceUpdate`
2. `WebSocketLedgerBalanceUpdateAdapter` forwards it
3. `BalanceEventPublisher` sends it to `/user/queue/balance`

Current balance event payload fields:

- `walletId`
- `walletName`
- `userId`
- `newBalance`
- `amount`
- `context`
- `timestamp`

## Frontend balance consumer

`BalanceWebSocketService` subscribes to:

- `/user/queue/balance`

`balance_websocket_provider.dart` then:

- invalidates transaction history providers
- invalidates deposit/external-transfer providers
- updates wallet balance in local state
- raises a synthetic received-transaction event when balance increases materially

This is used for instant in-app feedback even before a full refresh completes.

## Backend Notification Realtime

## Persistence and dispatch

Notification pipeline:

1. domain code calls `NotificationService`
2. `NotificationPersistenceService.persist(...)` stores `NotificationEntity`
3. the service publishes `NotificationPersistedEvent`
4. `NotificationDispatchAfterCommitListener` sends the payload to `/user/queue/notifications`

Critical property:

- dispatch happens after DB commit, not before

This avoids frontend seeing notifications for transactions that later roll back.

## Persisted notification model

`NotificationEntity` stores:

- numeric `id`
- `userId`
- `kind`
- `severity`
- `title`
- `body`
- optional `deeplink`
- optional `entityType`
- optional `entityId`
- `read`
- `createdAt`

## Wire payload model

`UserNotificationPayload.toMap()` emits:

- `id`
- `kind`
- `severity`
- `title`
- `body`
- `timestamp`
- `createdAt`
- optional `deeplink`
- optional `entityType`
- optional `entityId`
- optional `metadata`

`NotificationPersistenceService` overwrites the outgoing `id` with the persisted numeric DB id before publishing.

## Notification kinds

Canonical wire values:

- `system_info`
- `security_login_detected`
- `security_recovery_completed`
- `account_created`
- `transfer_received`
- `transfer_sent`
- `payment_request_created`
- `payment_request_paid`
- `deposit_detected`
- `deposit_confirmed`
- `payment_sent`
- `mining_started`
- `mining_completed`
- `mining_cancelled`

Notification severities:

- `info`
- `success`
- `warning`
- `error`

## Frontend notification consumers

## Live feed

`BalanceWebSocketService` also subscribes to:

- `/user/queue/notifications`

It parses the structured payload into `RealtimeNotificationEvent`, including:

- normalized id
- kind
- severity
- title/body
- timestamp
- deeplink
- entity type/id
- metadata

`balance_websocket_provider.dart` then:

- maps it to `SessionNotificationItem`
- appends it to the session feed
- refreshes wallet/payment-link/history providers
- optionally shows an in-app banner

## Persisted local feed

`session_notification_provider.dart`:

- persists up to `50` items per authenticated user
- deduplicates by `dedupeKey`
- syncs read state back to backend only when the id is numeric

This matches the fact that persisted backend notifications have numeric ids, while some fallback/local items may not.

## Notification inbox orchestrator

`notification_orchestrator.dart`:

- stores a local inbox in SharedPreferences
- attempts to merge backend `/notifications` data with local data
- marks notifications as read via `PUT /notifications/{id}/read`

This gives the app a persistent inbox even across sessions.

## Internal payment-request realtime

Backend also contains `PaymentRequestEventPublisher`, which pushes to:

- `/topic/payment-request/{linkId}`

Published transitions currently documented in code:

- payment request paid
- payment request expired

This path exists in backend, but the primary frontend websocket consumer shown in the repository is still centered on:

- `/user/queue/balance`
- `/user/queue/notifications`

## Mobile Versus Web Behavior

### Mobile

- initializes realtime bootstrap automatically after auth and app-PIN satisfaction
- consumes both balance and notification queues

### Web admin

- has screens that read notifications and audit data
- does not mount realtime bootstrap by default
- therefore does not automatically receive the live queue feed

This is a major operational difference.

## Canonical Corrections Versus Legacy Docs

Older docs described a thinner notification payload with mostly:

- title
- body
- timestamp

Current backend/frontend code supports a richer structured model with:

- kind
- severity
- deeplink
- entity references
- metadata

The structured model is the canonical one.

## Limitations

1. Web admin does not currently act as a first-class realtime operator console.

2. Notification infrastructure still supports `legacy(title, body)` payload generation in `NotificationService`, even though the structured payload is the canonical path.

3. There is no evidence in the inspected frontend of broad use of the payment-request topic channel.
