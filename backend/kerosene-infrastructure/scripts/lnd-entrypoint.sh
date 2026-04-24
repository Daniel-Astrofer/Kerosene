#!/bin/sh
set -eu

network="${BITCOIN_NETWORK:-testnet}"
lnd_dir="${LND_DATA_DIR:-/root/.lnd}"
grpc_port="${LND_GRPC_PORT:-10009}"
rest_port="${LND_REST_PORT:-8080}"
listen_port="${LND_LISTEN_PORT:-9735}"
alias_name="${LND_ALIAS:-kerosene-neutrino}"
color="${LND_COLOR:-#D1495B}"
connect_peer="${LND_NEUTRINO_CONNECT:-}"
add_peers="${LND_NEUTRINO_ADDPEERS:-}"
external_ip="${LND_EXTERNAL_IP:-}"

set -- \
  lnd \
  "--lnddir=${lnd_dir}" \
  "--rpclisten=0.0.0.0:${grpc_port}" \
  "--restlisten=0.0.0.0:${rest_port}" \
  "--listen=0.0.0.0:${listen_port}" \
  "--bitcoin.node=neutrino" \
  "--alias=${alias_name}" \
  "--color=${color}"

case "$network" in
  mainnet)
    set -- "$@" "--bitcoin.mainnet"
    ;;
  testnet|testnet3)
    set -- "$@" "--bitcoin.testnet"
    ;;
  testnet4)
    set -- "$@" "--bitcoin.testnet4"
    ;;
  signet)
    set -- "$@" "--bitcoin.signet"
    ;;
  regtest)
    set -- "$@" "--bitcoin.regtest"
    ;;
  *)
    echo "Unsupported BITCOIN_NETWORK: $network" >&2
    exit 1
    ;;
esac

if [ -n "$external_ip" ]; then
  set -- "$@" "--externalip=${external_ip}"
fi

if [ -n "$connect_peer" ]; then
  set -- "$@" "--neutrino.connect=${connect_peer}"
fi

old_ifs=$IFS
IFS=','
for peer in $add_peers; do
  if [ -n "$peer" ]; then
    set -- "$@" "--neutrino.addpeer=${peer}"
  fi
done
IFS=$old_ifs

exec "$@"
