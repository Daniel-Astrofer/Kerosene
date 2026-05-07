# Tax Engine

Tax events are local-first.

- Backend creates temporary tax events and commitments for settlement consistency.
- Temporary tax events are idempotent by `userId + eventType + sourceTxid`, where on-chain references should use `txid:vout` when available.
- Backend exports are temporary and redacted; txids are shortened to references.
- Users can classify events with self-service labels such as `SELF_TRANSFER`, `THIRD_PARTY_DEPOSIT`, `SPEND`, `FEE`, and `UNKNOWN`.
- Readable tax event data is purged/redacted after 24 hours.
- Mobile encrypted storage is the source of truth for readable tax history and CSV/JSON export.
- The app text must state: "Organizamos seus eventos para facilitar sua conferência. Este relatório não substitui orientação profissional."
