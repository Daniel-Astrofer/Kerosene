# Bitcoin Accounts Domain States

## Account

`ACTIVE`, `FROZEN`, `EXPIRED`, `REPLACED`, `SAFETY_LOCKED`, `USER_ACTION_REQUIRED`.

## Receive request

`ACTIVE`, `EXPIRED`, `MEMPOOL_SEEN`, `CONFIRMING`, `PAID`, `EXPIRED_RECEIVED`, `AUTO_RESOLUTION_PENDING`, `USER_ACTION_REQUIRED`, `HIDDEN`, `FAILED_SAFE`.

No manual review state is allowed. Every abnormal state must resolve through automatic network confirmation, policy block, failed-safe retry, or user self-service action.

## PSBT

`DRAFT`, `UNSIGNED_CREATED`, `WAITING_EXTERNAL_SIGNATURE`, `SIGNED_SUBMITTED`, `VALIDATED`, `REJECTED_TAMPERED`, `REJECTED_POLICY`, `BROADCASTED`, `CONFIRMED`, `FAILED_SAFE`.
