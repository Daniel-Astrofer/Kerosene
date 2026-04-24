# Features And States

Documento base para futuras implementacoes do app Kerosene.

Este arquivo complementa [API_REFERENCE.md](API_REFERENCE.md): aqui o foco nao e listar todos os contratos HTTP, e sim explicar quais features existem hoje, quais estados elas percorrem, como o backend/frontend as modelam e onde ainda ha lacunas.

Escopo desta leitura:

- backend `backend/kerosene/src/main/java/**`
- frontend `frontend/lib/**`
- documentacao canonica ja existente em `docs/`

Momento da analise: codigo atual em 2026-04-23.

## 1. Mapa rapido

| Area | Situacao atual | Superficie principal | Estados relevantes | Observacoes |
| --- | --- | --- | --- | --- |
| Onboarding e autenticacao | Implementado com pontos parciais | `/auth/**`, frontend `features/auth/**` | signup em Redis, pre-auth TOTP, autenticado, conta inativa/ativa | Signup so finaliza depois da passkey. |
| Passkey e seguranca transacional | Implementado e ajustado recentemente | `/auth/passkey/**`, `TransactionalAuthenticationService` | challenge requerido, passkey compativel/incompativel, replay rejeitado | Backend ja devolve erro estruturado com remediacao. |
| TOTP, backup codes e recovery | Implementado | `/auth/totp/**`, `/auth/backup-codes/**`, `/auth/recovery/**` | setup temporario, habilitado, desabilitado, recuperacao em andamento | Recovery gira fatores da conta. |
| Wallets e ledger | Implementado | `/wallet/**`, `/ledger/**` | wallet primaria, ledger pronto, saldo, historico | Muitas features assumem wallet primaria. |
| Transacoes internas | Implementado com inconsistencias de estados | `/ledger/transaction`, `/ledger/payment-request/**` | desafio de passkey, concluida, cancelada, expirada | Payment request usa Redis TTL e estados nao totalmente centralizados. |
| Transacoes externas e rede | Implementado em duas superficies | `/transactions/**` e `/transactions/network/**` | endereco emitido, pendente, confirmado, expirado, cancelado, concluido | Existe sobreposicao entre API "legada" e API "nova". |
| Payment links e onboarding financeiro | Implementado, mas com resquicios legados | `/transactions/payment-link/**` | `pending`, `paid`, `expired`, `completed`, `verifying_*` | Fluxo de ativacao por link esta parcialmente legado. |
| Onramp | Implementado | `/api/onramp/urls` | endereco dedicado emitido, transferencia monitorada | Depende de provedores externos. |
| Mineracao | Implementado | `/mining/**` | `ACTIVE`, `COMPLETED`, `CANCELLED` | Usa a mesma autenticacao transacional das saidas de wallet. |
| Notificacoes, soberania e status | Implementado | `/notifications/**`, `/sovereignty/**`, `/`, `/healthz` | notificacao criada/lida, status operacional | Serve como infraestrutura de apoio. |

## 2. Estados globais do app

### 2.1 Estados expostos no frontend de autenticacao

O frontend Flutter ja materializa estes estados em `frontend/lib/features/auth/presentation/state/auth_state.dart`:

| Estado | Significado |
| --- | --- |
| `AuthInitial` | Estado inicial antes de carregar sessao/token. |
| `AuthLoading` | Operacao de auth em andamento. |
| `AuthUnauthenticated` | Nenhuma sessao valida. |
| `AuthRequiresTotpSetup` | Signup iniciou e o app recebeu segredo TOTP, QR URI e backup codes. |
| `AuthTotpVerified` | Sessao de signup confirmou TOTP e segue para o proximo passo. |
| `AuthRequiresLoginTotp` | Login por passphrase aceito, mas ainda depende de TOTP ou backup code. |
| `AuthHardwareChallengeReceived` | Desafio de hardware recebido. Hoje e um estado pouco central na UX atual. |
| `AuthPasskeyChallengeReceived` | Desafio de passkey recebido e aguardando assinatura local. |
| `AuthPaymentRequired` | Fluxo do app entende que ainda existe etapa financeira pendente de onboarding/ativacao. |
| `AuthAuthenticated` | Usuario autenticado. |
| `AuthServerUnavailable` | O app tem contexto local, mas nao conseguiu falar com o backend. |
| `AuthError` | Erro funcional com `message`, `statusCode`, `errorCode` e `data`. |

### 2.2 Estados globais relevantes no backend

| Estado logico | Onde vive | Observacao |
| --- | --- | --- |
| `POW_CHALLENGE_READY` | Redis / fluxo curto | Necessario antes do signup. |
| `SIGNUP_SESSION_OPEN` | Redis `SignupState` | Usuario ainda nao foi persistido. |
| `PRE_AUTH_PENDING_2FA` | Redis `pre_auth:*` | Login aguardando TOTP ou backup code. TTL atual: 5 minutos. |
| `AUTHENTICATED` | JWT | Estado normal de sessao. |
| `ACCOUNT_INACTIVE` | Banco (`users.is_active=false`) | Pode autenticar, mas nao recebe fluxos inbound protegidos. |
| `ACCOUNT_ACTIVE` | Banco (`users.is_active=true`) | Inbound e criacao de links internos liberados. |
| `PRIMARY_WALLET_READY` | Banco | Criada automaticamente no fim do signup se nao existir wallet. |
| `LEDGER_READY` | Banco | Criado ou reparado no onboarding final. |

## 3. Onboarding, login e seguranca da conta

### 3.1 Signup e onboarding atual

Fluxo atual do backend:

1. `GET /auth/pow/challenge`
2. `POST /auth/signup`
3. Opcional: `POST /auth/signup/totp/verify`
4. `POST /auth/passkey/onboarding/start?sessionId=...`
5. `POST /auth/passkey/onboarding/finish?sessionId=...`

Comportamento real:

- `POST /auth/signup` valida username, passphrase, PoW e perfil de seguranca.
- Nesse ponto o backend gera `sessionId`, `otpUri`, `totpSecret` e `backupCodes`.
- O usuario ainda nao existe no banco nesse momento.
- O estado fica em Redis (`SignupState`).
- O cadastro so e finalizado quando a passkey do onboarding e validada em `finish`.
- `FinalizeSignupAccount` cria o usuario, garante a passkey, cria a wallet primaria `ACCOUNT 01` se necessario e garante ledger.

Estados do signup:

| Estado | Entrada | Saida |
| --- | --- | --- |
| `POW_READY` | challenge emitido | pode iniciar signup |
| `SIGNUP_SESSION_OPEN` | `/auth/signup` | pode configurar TOTP e registrar passkey |
| `TOTP_SETUP_AVAILABLE` | resposta do signup | usuario pode ativar TOTP antes de concluir conta |
| `TOTP_VERIFIED_OPTIONAL` | `/auth/signup/totp/verify` | sessao de signup atualizada |
| `PASSKEY_ONBOARDING_PENDING` | sessao aberta | aguardando prova de posse da passkey |
| `ACCOUNT_CREATED_INACTIVE` | `/auth/passkey/onboarding/finish` | usuario persistido, wallet e ledger prontos |
| `ACCOUNT_ACTIVE` | evento posterior de ativacao | inbound liberado |

Pontos importantes:

- A conta nasce `inactive`.
- A ativacao hoje nao depende mais de um `txid` enviado manualmente para um link de ativacao; ela acontece por mecanismos internos de deposito/monitoramento.
- `AccountActivationService.confirm(...)` hoje retorna erro explicito dizendo que deposito inicial deve ser feito dentro da plataforma.

Lacunas atuais:

- Nao existe caminho canonico para concluir signup sem passkey.
- O frontend ainda carrega estados de `payment required` e verificacao de ativacao que refletem um modelo de onboarding mais antigo.
- Existe resquicio de rotas/estados de ativacao por link, mas a confirmacao manual por `txid` foi descontinuada no servico.

### 3.2 Login por passphrase mais segundo fator

Fluxo atual:

1. `POST /auth/login`
2. Se usuario nao tem TOTP: JWT direto.
3. Se usuario tem TOTP: retorna `preAuthToken`.
4. `POST /auth/login/totp/verify` com TOTP ou backup code.
5. Backend gera JWT.

Estados:

| Estado | Descricao |
| --- | --- |
| `UNAUTHENTICATED` | sem sessao |
| `CREDENTIALS_VALIDATED` | passphrase aceita |
| `PRE_AUTH_PENDING_2FA` | backend emitiu `preAuthToken` |
| `AUTHENTICATED` | JWT emitido |
| `LOGIN_BLOCKED` | throttling, credencial invalida ou erro funcional |

Observacoes:

- O login principal continua sendo passphrase-first.
- O backend nao bloqueia login so porque a conta ainda esta `inactive`; o bloqueio ocorre em operacoes inbound especificas.
- O throttle de login vive no backend e protege tentativas repetidas.

### 3.3 Login por passkey

Fluxo atual:

1. `GET /auth/passkey/challenge?username=...`
2. `POST /auth/passkey/verify`

Comportamento real:

- O backend exige `credentialId` para lookup seguro da credencial.
- A assinatura e validada contra challenge guardado em Redis.
- O contador (`signatureCount`) precisa sempre avancar.
- O backend agora persiste o contador atualizado.
- Se a passkey estiver vinculada a outra origem/login, o backend retorna erro estruturado orientando a vincular outra.

Estados relevantes:

| Estado | Descricao |
| --- | --- |
| `PASSKEY_CHALLENGE_READY` | challenge emitido |
| `PASSKEY_ASSERTION_PENDING` | aguardando assinatura local |
| `PASSKEY_AUTHENTICATED` | JWT emitido |
| `PASSKEY_LINK_REQUIRED` | passkey existe, mas nao serve para o login atual |
| `PASSKEY_REPLAY_REJECTED` | contador do autenticador nao avancou |
| `PASSKEY_CREDENTIAL_NOT_FOUND` | `credentialId` nao pertence ao usuario |

### 3.4 Inventario de passkeys e compatibilidade por dispositivo

O backend ja suporta inventario da passkey por dispositivo:

- `GET /auth/passkey/devices`

Dados hoje persistidos por credencial:

- `deviceName`
- `credentialId`
- `relyingPartyId`
- `originHost`
- `signatureCount`

Estados de compatibilidade calculados pelo backend:

| Estado | Regra |
| --- | --- |
| `COMPATIBLE` | RP ID ou origem da credencial bate com o login atual |
| `INCOMPATIBLE` | metadados existem, mas nao batem com o login atual |
| `UNKNOWN` | credencial legada sem metadados suficientes |

Comportamento importante:

- Se o usuario tem TOTP ativo e nao possui passkey compativel com o login atual, o backend devolve remediacao para entrar com senha + TOTP e vincular uma nova passkey.
- O mesmo inventario e usado tanto no login por passkey quanto na autenticacao transacional.

### 3.5 Autenticacao transacional e modos de seguranca

Toda operacao sensivel reutiliza `TransactionalAuthenticationService`.

Fatores aceitos no request:

- `confirmationPassphrase`
- `totpCode`
- `passkeyAssertionJson`

Modos de seguranca hoje:

| Modo | Fatores exigidos na pratica |
| --- | --- |
| `STANDARD` | passkey compativel para transacao |
| `PASSKEY` | passkey compativel para transacao |
| `SHAMIR` | passphrase + TOTP + coassinatura da plataforma |
| `MULTISIG_2FA` com limiar 2 | passphrase + TOTP + coassinatura da plataforma |
| `MULTISIG_2FA` com limiar 3 | passphrase + TOTP + passkey compativel + coassinatura da plataforma |

Melhorias recentes ja presentes:

- Erros de passkey agora podem sair com `HttpStatus.PRECONDITION_REQUIRED` quando falta challenge.
- O backend tambem devolve `errorCode` e payload de acao recomendada.
- O marcador textual `PASSKEY_CHALLENGE_REQUIRED:<challenge>` ainda e mantido por compatibilidade com o frontend atual.

Lacunas atuais:

- O frontend ainda precisa migrar totalmente de parsing de mensagem para leitura do payload estruturado.
- O modo `STANDARD` semanticamente nao e "simples": ele ainda exige passkey para a operacao sensivel.

### 3.6 TOTP, backup codes, recovery e perfil de seguranca

Features implementadas:

- `POST /auth/totp/setup`
- `POST /auth/totp/verify`
- `DELETE /auth/totp`
- `GET /auth/backup-codes`
- `POST /auth/backup-codes/regenerate`
- `POST /auth/recovery/emergency/start`
- `POST /auth/recovery/emergency/finish`
- `GET /auth/security/profile`
- `PUT /auth/security/profile`
- `GET /auth/security-status`

Estados relevantes:

| Estado | Descricao |
| --- | --- |
| `TOTP_NOT_CONFIGURED` | usuario sem segredo TOTP ativo |
| `TOTP_SETUP_PENDING` | segredo temporario criado e aguardando validacao |
| `TOTP_ENABLED` | TOTP ativo e backup codes validos |
| `BACKUP_CODES_REGENERATED` | codigos antigos invalidados |
| `EMERGENCY_RECOVERY_IN_PROGRESS` | sessao temporaria de recuperacao |
| `SECURITY_PROFILE_UPDATED` | modo de seguranca alterado |

Regra importante:

- O backend agora impede ativar `PASSKEY` ou `MULTISIG_2FA` com 3 fatores se nao houver passkey utilizavel no login atual.

## 4. Wallets e ledger

### 4.1 Wallets

Superficie principal:

- `/wallet/create`
- `/wallet/all`
- `/wallet/find`
- `/wallet/update`
- `/wallet/delete`

Comportamento real:

- Um usuario pode ter varias wallets.
- O backend usa `findPrimaryWallet(userId)` em varios fluxos de deposito, payment link e onramp.
- No onboarding final, se o usuario nao tiver wallet, a primaria e criada automaticamente.

Estados relevantes:

| Estado | Descricao |
| --- | --- |
| `NO_WALLET` | usuario ainda sem wallet persistida |
| `PRIMARY_WALLET_READY` | wallet principal existe |
| `NETWORK_PROFILE_PARTIAL` | wallet existe, mas ainda sem endereco dedicado emitido |
| `NETWORK_PROFILE_READY` | wallet ja possui perfil de rede consultavel/emitido |
| `LEDGER_READY` | ledger associado existe |

Lacunas atuais:

- Nao existe um estado funcional bem definido para wallet arquivada/desabilitada.
- Varias features assumem wallet primaria, o que reduz clareza quando houver carteiras com papeis diferentes.

### 4.2 Ledger

Superficie principal:

- `POST /ledger/transaction`
- `GET /ledger/history`
- `GET /ledger/all`
- `GET /ledger/find`
- `GET /ledger/balance`

Comportamento real:

- O sender efetivo da transferencia interna e resolvido pelo backend a partir do usuario autenticado.
- Historico e saldos sao por wallet.
- Existe rate limit de 10 operacoes financeiras por usuario por minuto para transferencia interna e pagamento de request interna.

Estados relevantes:

| Estado | Descricao |
| --- | --- |
| `BALANCE_AVAILABLE` | saldo consultavel |
| `TX_ACCEPTED` | operacao entrou no orquestrador |
| `TX_CONFIRMED` | resposta sincrona do endpoint apos atualizar ledger |
| `HISTORY_PENDING` | historico interno pendente |
| `HISTORY_CONCLUDED` | historico interno concluido |
| `HISTORY_CANCELED` | historico interno cancelado |

## 5. Transacoes internas

### 5.1 Transferencia interna direta

Endpoint principal:

- `POST /ledger/transaction`

Entradas relevantes hoje:

- `sender`
- `receiver`
- `amount`
- `context`
- `idempotencyKey`
- `requestTimestamp`
- `totpCode`
- `passkeyAssertionJson`
- `confirmationPassphrase`

Observacoes:

- O backend aceita varios formatos de destino no DTO, mas a resolucao final e feita no servidor.
- O fluxo usa autenticacao transacional e pode devolver desafio de passkey.
- A resposta HTTP do endpoint tende a ser sincronica, com status funcional `confirmed` quando o ledger ja foi atualizado.

Estados praticos da transferencia interna:

| Estado | Como aparece hoje |
| --- | --- |
| `AUTH_REQUIRED` | faltou fator ou challenge |
| `PASSKEY_CHALLENGE_REQUIRED` | backend pede assinatura de passkey |
| `VALIDATION_FAILED` | saldo, ownership, destino ou 2FA invalidos |
| `LEDGER_UPDATED` | debitou/creditou com sucesso |
| `HISTORY_CONCLUDED` | historico persistido como concluido |

### 5.2 Payment request interno

Superficie principal:

- `POST /ledger/payment-request`
- `GET /ledger/payment-request/{linkId}`
- `POST /ledger/payment-request/{linkId}/pay`

Comportamento real:

- O request e salvo em Redis com TTL de 30 minutos.
- O recebedor da request precisa ser uma wallet do proprio criador.
- O criador precisa estar com inbound habilitado.
- Ninguem pode pagar a propria request.
- O pagamento reaproveita o mesmo orquestrador de transferencia interna.

Estados observados:

| Estado | Fonte atual |
| --- | --- |
| `PENDING` | estado inicial criado |
| `PAID` | pagamento concluido |
| `EXPIRED` | calculado em runtime quando `expiresAt` passou |
| `CANCELED` | citado no DTO/comentarios, mas nao ha endpoint publico de cancelamento hoje |

Inconsistencia importante:

- O contrato DTO ainda documenta `PENDING`, `PAID`, `CANCELED`.
- O runtime tambem usa `EXPIRED`.
- Nao existe um enum central unico para essa feature.

## 6. Transacoes externas, depositos, lightning, onramp e payment links

### 6.1 Superficie "legada" em `/transactions/*`

Rotas principais:

- `GET /transactions/deposit-address`
- `GET /transactions/estimate-fee`
- `POST /transactions/create-unsigned`
- `POST /transactions/broadcast`
- `GET /transactions/status`
- `POST /transactions/create-payment-link`
- `GET /transactions/payment-link/{linkId}`
- `POST /transactions/payment-link/{linkId}/confirm`
- `POST /transactions/payment-link/{linkId}/complete`
- `GET /transactions/payment-links`
- `POST /transactions/withdraw`

### 6.2 Superficie nova em `/transactions/network/*`

Rotas principais:

- `POST /transactions/network/onchain/address`
- `GET /transactions/network/wallet-profile`
- `POST /transactions/network/onchain/send`
- `POST /transactions/network/lightning/invoice`
- `POST /transactions/network/lightning/pay`
- `GET /transactions/network/transfers`
- `GET /transactions/network/transfers/{transferId}`
- `POST /transactions/network/transfers/{transferId}/cancel`

### 6.3 Depositos, enderecos e monitoramento

Comportamento real:

- Emissao de endereco on-chain dedicado cria registro de transferencia externa.
- O monitor de inbound acompanha depositos on-chain e invoices lightning.
- Quando o inbound liquida, o ledger pode ser creditado automaticamente.
- Esse mesmo fluxo pode ativar a conta do usuario.

Estados relevantes de deposito/transferencia:

| Estado | Uso atual |
| --- | --- |
| `PENDING` | endereco emitido ou transferencia aguardando settle |
| `COMPLETED` | credito efetivado |
| `CANCELLED` | transferencia cancelada |
| `EXPIRED` | invoice/transferencia expirou |
| `CONFIRMED` | status de monitoramento de blockchain |
| `FAILED` | falha de broadcast/confirmacao monitorada |

Observacao:

- As entidades de pagamentos externos ainda usam `String` para varios estados, nao um enum central do dominio.

### 6.4 Payment links

Estados hoje usados por payment links:

| Estado | Significado |
| --- | --- |
| `pending` | link criado e aguardando pagamento |
| `paid` | pagamento identificado |
| `expired` | link expirou |
| `completed` | fluxo normal finalizado |
| `verifying_onboarding` | pago e aguardando finalizacao de onboarding |
| `verifying_activation` | pago e aguardando confirmacao de ativacao |

Comportamento real:

- Payment links normais alocam endereco dedicado e creditam a wallet primaria.
- Existem payment links associados a onboarding e ativacao.
- A confirmacao de pagamento coloca o link em observacao.
- A etapa `complete` fecha o fluxo do link normal.

Lacunas atuais:

- O dominio de payment link ainda carrega estados de ativacao/onboarding que convivem com um modelo novo de ativacao interna.
- Ha sobreposicao funcional entre `/transactions/*` e `/transactions/network/*`.
- Falta decidir qual superficie sera a API canonica de longo prazo.

### 6.5 Onramp

Superficie principal:

- `GET /api/onramp/urls`

Comportamento real:

- O backend gera URLs de provedores externos com endereco dedicado monitorado.
- O credito final depende do mesmo pipeline de monitoramento inbound.

## 7. Mineracao

Superficie principal:

- `GET /mining/rigs`
- `POST /mining/allocations`
- `GET /mining/allocations`
- `GET /mining/allocations/{allocationId}`
- `POST /mining/allocations/{allocationId}/cancel`

Comportamento real:

- O usuario escolhe rig, duracao e wallet.
- O backend autentica a operacao com o mesmo servico transacional.
- O custo e debitado do ledger.
- O rig tem hashrate reservado.
- Na liquidacao, o rendimento projetado e creditado.
- No cancelamento, ha calculo de valor minerado mais eventual reembolso.

Estados atuais:

| Estado | Significado |
| --- | --- |
| `ACTIVE` | locacao aberta e hashrate reservado |
| `COMPLETED` | liquidacao final executada |
| `CANCELLED` | locacao encerrada antes do fim |

Lacunas atuais:

- Nao ha estados intermediarios mais ricos como `SETTLING`, `FAILED_SETTLEMENT` ou `PAUSED`.
- A UX futura pode precisar distinguir "em execucao" de "aguardando creditacao".

## 8. Notificacoes, soberania e status operacional

Features existentes:

- notificacoes de eventos financeiros e de conta
- status publico do backend em `/` e `/healthz`
- status de soberania em `/sovereignty/status` e `/sovereignty/ping`
- dados de economia em `/api/economy/status` e `/api/economy/btc-price`

Papel dessas features:

- Nao sao o nucleo do produto, mas sustentam UX, observabilidade e confianca operacional.
- Devem ser consideradas em qualquer feature nova que mova dinheiro, altere estado da conta ou dependa de infraestrutura soberana.

## 9. Gaps e inconsistencias que precisam ser resolvidos

Prioridades recomendadas para as proximas implementacoes:

1. Unificar o modelo canonico de onboarding e ativacao.
   Hoje coexistem `payment required`, `verifying_activation` e `AccountActivationService.confirm()` descontinuado.

2. Consolidar estados em enums/contratos centrais.
   Payment request interno, payment link, transferencias externas e historicos ainda espalham `String` em varios pontos.

3. Fechar a migracao do frontend para erros estruturados de passkey.
   O backend ja entrega `errorCode` e payload de remediacao; o cliente ainda precisa deixar de depender de parsing textual.

4. Escolher uma unica superficie para transacoes externas.
   `/transactions/*` e `/transactions/network/*` convivem hoje com sobreposicao parcial.

5. Tornar explicito o papel de `STANDARD`.
   O nome sugere experiencia simples, mas na pratica exige passkey para operacoes sensiveis.

6. Formalizar estados de wallet e lifecycle de requests.
   Hoje faltam estados publicos para arquivar wallet, cancelar internal request e diferenciar expirado de removido.

## 10. Direcao recomendada para futuras features

Para novas implementacoes, este documento assume como direcao alvo:

- um state machine unico para onboarding/login/ativacao
- erros estruturados como contrato principal entre backend e frontend
- enums centralizados para todos os estados financeiros
- uma API canonica unica para pagamentos externos
- inventario de passkeys tratado como parte do perfil de seguranca da conta, nao como detalhe isolado

Enquanto isso nao for consolidado, qualquer nova feature deve declarar explicitamente:

- qual estado de conta ela exige (`inactive` ou `active`)
- qual fator transacional ela exige
- se depende de wallet primaria ou de wallet explicitamente escolhida
- qual estado final sera refletido no frontend
