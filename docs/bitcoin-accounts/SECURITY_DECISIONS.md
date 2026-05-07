# Bitcoin Accounts Security Decisions

- Backend rejects seed, mnemonic, passphrase, xprv, WIF private keys, and raw private-key-like material in watch-only imports.
- Cold wallets always have `can_sign=false`.
- PSBT payloads are allowed up to 64KB only on PSBT routes; other JSON payloads keep the 2KB guard.
- Backend-readable movement data has a 24h TTL by default.
- User-readable transaction history belongs in encrypted mobile storage.
- Audit continuity is kept through hash-chain, payload hash, Merkle roots, commitments, and redacted audit metadata.
