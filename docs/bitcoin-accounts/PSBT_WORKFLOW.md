# PSBT Workflow

1. User selects cold wallet, destination, amount, and UTXOs.
2. Backend creates unsigned PSBT through Bitcoin Core watch-only wallet.
3. Backend stores hashes of destination outputs and selected inputs plus selected outpoints for lock release.
4. User signs externally.
5. Backend decodes signed PSBT and validates inputs, destination, amount, network, output policy, known change output, and fee ceiling.
6. Backend broadcasts only when validation passes and `broadcast=true`.

Rejected PSBTs use `REJECTED_TAMPERED` or `REJECTED_POLICY`.

Policy notes:

- Selected UTXOs are read with a pessimistic database lock before PSBT creation.
- Missing or zero fee data is rejected because the fee cannot be verified safely.
- Unknown change is rejected when the wallet xpub cannot prove the change address.
- Pending workflows expire automatically and move to `FAILED_SAFE`; selected locked UTXOs are returned to `UNSPENT`.
