# Operacao de Producao Kerosene

Este documento descreve a evolucao produtiva implementada para landing publica, painel empresarial, blockchain monitor, Vault Raft, Docker isolado e snapshots de release.

## Web Publica e Painel

O Flutter web agora entrega quatro rotas principais:

```text
/          landing publica
/admin     painel empresarial autenticado
/download  download mobile e integridade
/status    status publico dos servicos
```

A landing explica proposta de valor, taxas, seguranca, uso por empresas/usuarios, blockchain monitoring e download do app. O painel admin consome apenas endpoints reais em `/api/admin/operations/*`: status dos servicos, Bitcoin Core, Vault Raft, release attestation, metricas essenciais e logs saneados.

## Download Mobile

`GET /api/public/mobile-download` retorna links Android/iOS, versao, changelog e hashes SHA-256/assinatura quando configurados por ambiente. Use:

```text
MOBILE_ANDROID_DOWNLOAD_URL
MOBILE_IOS_DOWNLOAD_URL
MOBILE_APP_VERSION
MOBILE_ANDROID_SHA256
MOBILE_IOS_SHA256
```

Nao publique APK/IPA sem checksum e assinatura verificavel.

## Blockchain e Lightning Monitor

Fonte primaria on-chain: Bitcoin Core local mainnet pruned via RPC/ZMQ. Fonte primaria Lightning: LND mainnet via gRPC. O compose sobe:

```text
bitcoin-core       mainnet pruned, RPC/ZMQ, wallet descriptor
lnd-neutrino       LND mainnet real via Bitcoin Core pruned local
lnd-bootstrap      init/unlock da wallet LND
bitcoin-indexer    electrs opcional no profile archive-indexer
```

O painel le `GET /api/admin/operations/blockchain` para altura, hash do bloco, dificuldade, `pruned`, `pruneHeight`, mempool, estimativas de taxa via Bitcoin Core, sincronizacao, transacoes relevantes e confirmacoes. Enderecos on-chain reais sao emitidos pelo wallet `BITCOIN_RPC_WALLET` com `getnewaddress`.

O painel le `GET /api/admin/operations/lightning` para pubkey, alias, versao, sync chain/graph, altura, peers, canais e saldos local/remoto/wallet do LND. Invoices, pagamentos e streams usam gRPC real (`SubscribeTransactions` e `SubscribeInvoices`). Se Bitcoin Core ou LND estiver offline, o status do provedor fica `DOWN`; API publica so pode aparecer como fallback explicito e marcado.

## Vault Raft Quorum

O cluster Vault produtivo local usa tres containers HashiCorp Vault:

```text
vault-raft-1  leader elegivel
vault-raft-2  follower votante
vault-raft-3  follower votante
```

`vault-raft-bootstrap` inicializa, junta peers e faz unseal. O backend valida `/v1/sys/health`, `/v1/sys/leader` e `/v1/sys/storage/raft/configuration`. Com `VAULT_RAFT_REQUIRED=true`, a API bloqueia startup se nao houver quorum, leader ou todos os nos estiverem sealed.

## Containers e Isolamento

O stack raiz usa:

```bash
bash scripts/init-local.sh
bash scripts/release-snapshot.sh generate
docker compose up -d --build
```

Servicos ficam separados por responsabilidade: web-admin, tres apps Spring, tres bancos, tres Redis, tres sidecars MPC, Tor/Vanguards, Vault Java legado, Vault Raft, Bitcoin Core pruned, LND, indexador opcional e Prometheus. Redes internas separam banco, MPC, Vault, Bitcoin e Tor; volumes nomeados persistem dados.

## Release Snapshot

Gere e valide snapshots:

```bash
bash scripts/release-snapshot.sh generate
bash scripts/release-snapshot.sh validate
```

O manifesto assinado inclui commit SHA, build time, hash do codigo, hash das configs permitidas, digest esperado de imagem, manifesto e SBOM opcional. `release/` fica ignorado por conter chaves/artefatos locais.

## Attestation Interno

`ReleaseManifestService` valida assinatura Ed25519 e compara runtime contra o manifesto autorizado. `ReleaseAttestationFilter` protege caminhos criticos com digest autorizado, timestamp anti-replay, prova HMAC do payload e identidade mTLS quando configurada. Hash/digest divergente bloqueia a operacao e registra alerta.

## Testes e Validacao

Checks criticos usados nesta entrega:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew compileJava
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.common.release.ReleaseManifestServiceTest --tests source.transactions.monitoring.BitcoinBlockchainMonitorServiceTest --tests source.common.admin.MobileDownloadServiceTest

cd backend/mpc-sidecar
go test ./...

cd frontend
flutter analyze lib/bootstrap/web_bootstrap.dart lib/features/landing lib/features/web_admin/screens/monitoring
```

`docker compose config` tambem deve passar antes de subir o ambiente. Nao publique a saida porque ela materializa variaveis do `.env`.

## Auditoria de Consistencia

Inconsistencias corrigidas nesta evolucao:

- README e docs ainda descreviam blockchain por gateway externo/electrs primario; foram atualizados para Bitcoin Core pruned, LND real e indexador opcional.
- O Vault documentado era apenas o servico Java legado; agora ha fluxo HashiCorp Vault Raft com quorum real.
- O frontend web nao tinha landing publica separada do painel; as rotas foram divididas.
- Nao havia processo documentado de snapshot/attestation; agora ha script, manifesto e endpoints de versao.
- Logs e status do painel foram limitados a dados saneados, sem seeds, tokens, chaves privadas ou segredos.

## Reconciliacao Manual

Casos financeiros em `AUTO_RESOLUTION_PENDING`, `PENDING_MANUAL` ou issues abertas em `financial.financial_reconciliation_issues` devem seguir `docs/RUNBOOK_MANUAL_RECONCILIATION.md`. O runbook define evidencias obrigatorias, consulta segura aos endpoints operacionais, uso do `operational-proof`, criterios para retry/refund/settlement/reversao e checklist de dois operadores.
