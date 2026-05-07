# Bitcoin Accounts API Contract

## Accounts

- `GET /bitcoin/accounts`
- `POST /bitcoin/accounts/internal-card`
- `POST /bitcoin/accounts/cold-wallet`

Cold wallet import accepts only public watch-only material: descriptor/xpub, fingerprint, derivation path, and script policy.

## Receive links

- `POST /bitcoin/accounts/{accountId}/receive-requests`
- `GET /bitcoin/receive/{publicCode}`
- `GET /bitcoin/receive-requests/{id}/status`
- `POST /bitcoin/receive-requests/{id}/hide`
- `POST /bitcoin/receive-requests/{id}/expire`
- `POST /bitcoin/receive-requests/{id}/user-action`

Public receive links never expose `user_id`.

## PSBT

- `POST /bitcoin/cold-wallets/{coldWalletId}/psbt`
- `GET /bitcoin/cold-wallets/{coldWalletId}/psbt`
- `GET /bitcoin/cold-wallets/{coldWalletId}/utxos`
- `POST /bitcoin/psbt/{workflowId}/signed`
- `GET /bitcoin/psbt/{workflowId}`

Broadcast is only allowed after signed PSBT validation against the original intent.

## Tax events

- `GET /bitcoin/tax-events`
- `GET /bitcoin/tax-events/export?format=csv|json`
- `POST /bitcoin/tax-events/{eventId}/classify`

Tax endpoints expose only temporary, redacted event views. Durable readable history belongs in encrypted mobile storage.
