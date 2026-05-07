# Test Plan

## Backend

- Duplicate `txid:vout` does not duplicate credit.
- Pending credit becomes available after configured confirmations.
- Mempool detection moves the request to `MEMPOOL_SEEN`.
- Expired address payment becomes `EXPIRED_RECEIVED`.
- Late mismatched payment becomes `USER_ACTION_REQUIRED`.
- Late mismatched payment is credited into ledger `AUTO_HOLD`, not dropped.
- Extra payment on an already paid one-time link becomes `USER_ACTION_REQUIRED` with ledger `AUTO_HOLD`.
- Ledger reservation, final debit, self-service hold, reversal, and negative-bucket guards are unit tested.
- Cold wallet import rejects seed, mnemonic, passphrase, xprv, and private key.
- Receiving monitor parses matching outputs and calls the idempotent settlement path.
- Confirmation regression moves paid deposits into `AUTO_RESOLUTION_PENDING` and ledger `AUTO_HOLD`.
- Cold wallet monitor updates observed UTXOs without custodial ledger credit.
- PSBT with changed inputs, destination, unknown change, missing fee, or excessive fee is rejected.
- PSBT rejection or expiry unlocks selected UTXOs.
- Locked watch-only UTXOs are marked spent when they leave the observed UTXO set.
- Tax export uses redacted source references and self-service classifications.
- Retention job redacts readable receive/tax data when `purge_after` is due and uses the configured readable TTL when creating new temporary records.

## Frontend

- Internal account shows "Disponível para uso".
- Watch-only account shows "Saldo observado".
- Receive flow renders QR, address, BIP21 URI, expiry, and copy action.
- Import flow warns that Kerosene cannot sign and never receives secrets.
- PSBT flow copies unsigned PSBT, imports signed PSBT, validates, and broadcasts only after explicit action.
- Tax report persists events locally and exports CSV/JSON from encrypted mobile storage.
