# Kerosene - Frontend

## Frontend Scope

The repository contains two distinct Flutter runtimes:

- mobile app bootstrap in `frontend/lib/bootstrap/mobile_bootstrap.dart`
- web admin bootstrap in `frontend/lib/bootstrap/web_bootstrap.dart`

They share domain code, API clients and parts of the presentation layer, but they do not share the same network/bootstrap behavior.

## Mobile Runtime

## Startup sequence

Mobile initialization performs:

1. local notifications init
2. background service init
3. audio service init
4. Tor bootstrap through `TorService`
5. local relay startup to the current onion host
6. `AppConfig.apiUrl` rewrite to `http://127.0.0.1:<relayPort>`
7. app launch with realtime bootstrap wrapper

If Tor starts successfully, all mobile API traffic is redirected through the local relay to the selected onion host.

## App shell behavior

Mobile `MyApp`:

- chooses theme and locale from providers
- wraps the app in `_AppRealtimeBootstrap`
- routes authenticated users through `AppEntryPinGate`
- shows `HomeLoadingScreen` after auth, not the home screen directly

Realtime bootstrap is only activated when:

- auth state is `AuthAuthenticated`
- app PIN is either disabled or already satisfied

At that point the app starts the balance/notification WebSocket provider.

## Web Runtime

## API URL resolution

The web admin resolves API URL in this order:

1. compile-time `WEB_API_URL`
2. compile-time `WEB_ONION_GATEWAY`
3. current browser origin if already on `.onion`
4. `Uri.base.origin`

The resolved URL is written to:

- `AppConfig.apiUrl`
- `AppConfig.activeNodeUrl`

This matters for passkey relying-party alignment.

## Important difference from mobile

The web app:

- does not start Tor
- does not start a local relay
- does not mount `_AppRealtimeBootstrap`
- does not automatically subscribe to the live balance/notification WebSocket service

The admin console is therefore currently a polling-style consumer for most operational data.

## Frontend State Model

The auth state machine in `auth_state.dart` currently includes:

- `AuthInitial`
- `AuthLoading`
- `AuthAuthenticated`
- `AuthUnauthenticated`
- `AuthError`
- `AuthRequiresTotpSetup`
- `AuthRequiresLoginTotp`
- `AuthTotpVerified`
- `AuthHardwareChallengeReceived`
- `AuthPasskeyChallengeReceived`
- `AuthHardwareVerified`
- `AuthPaymentRequired`
- `AuthServerUnavailable`

Important reality:

- `AuthPaymentRequired` still exists and is actively used by the frontend
- the backend onboarding path no longer requires this state to activate an account

This is one of the largest frontend/backend divergences in the repository.

## Networking Layer

## API config

`AppConfig` centralizes endpoint constants and runtime host selection.

Important valid constants:

- auth endpoints
- wallet endpoints
- ledger endpoints
- transaction and network-transfer endpoints
- treasury, sovereignty and audit endpoints

Important stale constants still present:

- `/transactions/confirm-deposit`
- `/transactions/deposits`
- `/transactions/deposit-balance`
- `/notifications/send`
- `/notifications/register-token`

These paths do not represent the current backend surface.

## Interceptors and token handling

The frontend networking layer includes:

- token injection
- automatic device-hash propagation on many routes
- `ApiResponse` unwrapping

Important caveat:

- `ApiResponseInterceptor` only declares `/audit` as a raw-response path
- backend also returns raw responses from `/notifications`, `/treasury/overview`, `/sovereignty/*`, `/v1/audit/*`, `/`, `/healthz`

Current app code works because many individual call sites already parse raw maps/lists directly, but the contract is not globally uniform.

## Device hash usage

`X-Device-Hash` is actively sent by the frontend to:

- app PIN endpoints
- account-security profile endpoints
- WebSocket connect headers
- some authenticated profile/session reads

This is correct for the current backend, despite stale comments in `AppConfig`.

## Auth and onboarding implementation details

### Signup flow in frontend

Current Flutter signup flow still models:

- signup start
- optional TOTP verification
- passkey onboarding
- possible activation deposit state

But backend truth is:

- passkey onboarding finish already finalizes an active user

### Legacy activation calls still present

`AuthController` and `AuthRemoteDataSource` still call:

- `getActivationStatus()`
- `createActivationDepositLink()`
- `confirmActivationPayment(...)`
- `mockConfirmOnboarding(...)`

`mockConfirmOnboarding(...)` already logs that no backend endpoint exists.

## Realtime and notifications in frontend

Mobile live subscriptions:

- `/user/queue/balance`
- `/user/queue/notifications`

On incoming balance updates, frontend code:

- refreshes wallet and transaction providers
- emits a synthetic "received transaction" UI event when balance increases

On incoming notifications, frontend code:

- creates a `SessionNotificationItem`
- updates local feed state
- refreshes payment links, history and wallet data
- optionally shows an in-app banner

The local notification inbox is also persisted in SharedPreferences.

## Web Admin Surface

The admin console routes to the following modules:

- `dashboard`
- `transactions`
- `lightning`
- `onchain`
- `checks`
- `paymentLinks`
- `analytics`
- `volatility`
- `companies`
- `audit`
- `notifications`
- `settings`

Current state of the admin surface:

- it consumes live API data for many dashboards
- it does not bootstrap realtime WebSockets by default
- its settings screen is explicitly marked as a placeholder

## Known Frontend/Backend Divergences

1. Activation deposit flow remains modeled in Flutter but is no longer canonical in backend.

2. Removed deposit endpoints are still called by:
   - `transaction_remote_datasource.dart`
   - `admin_data_service.dart`

3. `security_remote_datasource.dart` calls:
   - `POST /sovereignty/reattest`
   - `POST /sovereignty/telemetry`
   without adding the required `X-Admin-Token`.
   The backend route is currently `GET /sovereignty/telemetry`, so the client also has an HTTP method mismatch there.

4. Web admin notifications screen exists, but the web shell does not subscribe to the live notification queue by default.

## Android Build Facts

Confirmed from current Android config:

- namespace/application id: `com.teste.kersosene`
- compile SDK: `36`
- target SDK: `36`
- version code: `1`
- version name: `1.0.0`
- release build currently signs with the debug signing config
- manifest sets `android:usesCleartextTraffic="true"`

Declared permissions include:

- `INTERNET`
- `CAMERA`
- `NFC`
- `WAKE_LOCK`
- `FOREGROUND_SERVICE`
- `RECEIVE_BOOT_COMPLETED`
- `POST_NOTIFICATIONS`
- `USE_BIOMETRIC`
- `FOREGROUND_SERVICE_DATA_SYNC`

## Frontend Guidance

For future work, the frontend should treat the following as canonical:

- onboarding success occurs at passkey onboarding finish
- payment links are the current external receive primitive
- notifications are structured objects, not just `title/body/timestamp`
- mobile and web must be documented separately because their trust and network models differ materially
