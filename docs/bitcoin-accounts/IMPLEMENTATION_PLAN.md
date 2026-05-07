# Bitcoin Accounts Implementation Plan

## Phase delivered

- Added backend Bitcoin Accounts domain for internal custodial cards, rotating receive requests, watch-only cold wallets, PSBT workflows, temporary tax events, and audit events.
- Added authenticated `/bitcoin/*` APIs plus public `/bitcoin/receive/{publicCode}`.
- Added Flutter Bitcoin Accounts screen on the mobile `/card` route.
- Wired ZMQ raw transaction detection and the scheduled receiving monitor into `ReceivingRequestService.observeOnchainPayment`.
- Added a watch-only cold wallet monitor that updates observed address balances and UTXOs without touching custodial ledger availability.
- Added PSBT UTXO/workflow APIs, PSBT expiry/unlock behavior, fee/network/output policy checks, and Flutter PSBT flow.
- Added temporary tax event APIs plus encrypted mobile local-first tax report export.
- Set readable backend transaction retention to 24 hours by default.

## Next phases

- Add full regtest integration tests for deposit, expiry, reorg, PSBT validation, and purge.
- Expand legacy admin/history hardening outside the Bitcoin Accounts module.
