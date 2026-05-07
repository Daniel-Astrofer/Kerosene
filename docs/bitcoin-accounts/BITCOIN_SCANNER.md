# Bitcoin Scanner Contract

The scanner should call:

```text
ReceivingRequestService.observeOnchainPayment(address, txid, vout, amountSats, confirmations)
```

Required behavior:

- Detect mempool and block confirmations.
- Continue monitoring expired addresses.
- Use `txid:vout` idempotency.
- Handle reorg by not double-crediting and by moving unresolved settlement into `FAILED_SAFE` or `AUTO_RESOLUTION_PENDING`.
- If a paid receive request regresses below minimum confirmations, the request moves to `AUTO_RESOLUTION_PENDING` and the ledger entry moves from available to `AUTO_HOLD`.
- Never create manual review queues.

Implemented entry points:

- `BlockchainZmqListenerService` forwards raw transaction outputs to Bitcoin Accounts when ZMQ is enabled.
- `BitcoinReceivingMonitorService` polls monitored receive addresses and reconciles confirmations through the same idempotent service method.
- `ColdWalletMonitorService` scans watch-only addresses, updates observed balances/UTXOs, and records temporary tax events for observed external movement. It never creates custodial ledger availability.
