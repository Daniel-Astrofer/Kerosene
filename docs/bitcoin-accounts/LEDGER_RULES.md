# Bitcoin Accounts Ledger Rules

- Internal BTC Card balance is a Kerosene custodial obligation.
- Cold wallet balance is observed external balance and never becomes available ledger balance.
- Ledger buckets are separate: available, pending, locked, and auto-hold.
- Credit is idempotent by source key, including `txid:vout` for on-chain deposits.
- Debit reservation is idempotent by source key and moves funds from available to locked.
- `debitReserved()` finalizes only locked debit entries and removes the amount from the locked bucket.
- `reverseEntry()` can reverse pending/available/auto-hold credits and locked debits; finalized entries are not reversed by this path.
- `requireUserAction()` moves pending or available credits into auto-hold without making them spendable.
- Balance buckets must never become negative.
- Expired receive links remain monitored; late or anomalous one-time payments are represented in ledger `AUTO_HOLD` and resolved by self-service.
