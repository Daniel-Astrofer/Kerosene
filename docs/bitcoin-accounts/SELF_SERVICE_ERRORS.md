# Self-Service Errors

Use these user-facing messages:

- `USER_ACTION_REQUIRED`: "Precisamos de uma confirmação sua para continuar com segurança."
- `EXPIRED`: "Este link expirou. Você pode gerar um novo endereço de recebimento em poucos segundos."
- `EXPIRED_RECEIVED`: "Recebemos um pagamento após a expiração. Siga as etapas para concluir com segurança."
- `AUTO_HOLD`: "Recebemos o valor, mas ele está protegido automaticamente até a confirmação necessária."
- `REJECTED_TAMPERED`: "Não transmitimos essa transação porque ela não corresponde exatamente à intenção original."
- `REJECTED_POLICY`: "A taxa ou os outputs não seguem sua política de segurança. Revise antes de continuar."
- `FAILED_SAFE`: "Não conseguimos concluir com segurança agora. O estado foi preservado para nova tentativa."

Late mismatched payments and extra payments sent to one-time links must not disappear from the product. They are recorded with idempotency, placed in ledger auto-hold, and surfaced to the user with a self-service confirmation path.
