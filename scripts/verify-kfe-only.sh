#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

run_grep_check() {
  local label="$1"
  shift
  : > "$TMP"
  if grep "$@" > "$TMP" 2>/dev/null; then
    true
  else
    : > "$TMP"
  fi

  if [ -s "$TMP" ]; then
    printf '%s\n' "FAIL: $label"
    sed -n '1,120p' "$TMP"
    fail=1
  else
    printf '%s\n' "OK: $label"
  fi
}

run_grep_check \
  "legacy financial feature flag must not exist in executable code" \
  -RIn --exclude-dir=.git --exclude-dir=build --exclude='verify-kfe-only.sh' 'kfe\.legacy-financial\.enabled' backend/kerosene/src frontend/lib

for pkg in ledger payments wallet bitcoinaccounts; do
  path="backend/kerosene/src/main/java/source/$pkg"
  if [ -d "$path" ]; then
    printf '%s\n' "FAIL: legacy backend package still exists: source/$pkg"
    fail=1
  else
    printf '%s\n' "OK: legacy backend package absent: source/$pkg"
  fi
done

run_grep_check \
  "legacy financial package dependencies must not exist" \
  -RInE --exclude-dir=.git --exclude-dir=build 'source\.(ledger|payments|wallet|bitcoinaccounts)' backend/kerosene/src/main backend/kerosene/src/test

run_grep_check \
  "legacy financial API routes must not exist in executable code" \
  -RInE --exclude-dir=.git --exclude-dir=build '"/(ledger|payments|deposit|treasury)(/|")|"/wallet/(create|all|find|update|delete)(/|")|"/bitcoin/(accounts|cold-wallets|psbt|receive|receive-requests|tax-events)(/|")|"/transactions/(estimate-fee|deposit-address|create-unsigned|broadcast|create-payment-link|payment-link|payment-links|withdraw)(/|")' backend/kerosene/src/main frontend/lib

run_grep_check \
  "legacy financial AppConfig aliases must not exist" \
  -RInE --exclude-dir=.git --exclude-dir=build '\b(walletCreate|walletAll|walletFind|ledgerAll|ledgerFind|ledgerBalance|ledgerHistory|ledgerTransaction|treasuryOverview|bitcoinTaxEvents|bitcoinTaxEventsExport|bitcoinTaxEventClassify|bitcoinPsbt|bitcoinPsbtSigned|bitcoinColdWalletPsbt|bitcoinColdWalletUtxos|bitcoinAccountReceiveRequests)\b' frontend/lib/core/config frontend/test/core/config

if [ "${STRICT_DOCS:-0}" = "1" ]; then
  run_grep_check \
    "legacy financial API routes must not exist in docs" \
    -RInE --exclude-dir=.git --exclude-dir=build '`/(ledger|payments|deposit|treasury)(/|`)|`/wallet/(create|all|find|update|delete)(/|`)|`/bitcoin/(accounts|cold-wallets|psbt|receive|receive-requests|tax-events)(/|`)|`/transactions/(estimate-fee|deposit-address|create-unsigned|broadcast|create-payment-link|payment-link|payment-links|withdraw)(/|`)' docs
fi

exit "$fail"
