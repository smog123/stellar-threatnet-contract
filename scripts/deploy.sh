#!/usr/bin/env bash
# ============================================================ #
# Soroban ThreatNet — contract deploy + initialize sequence.  #
#                                                              #
# Deploys the contract and calls initialize() in dependency    #
# order, then prints final contract IDs in a copy-pasteable    #
# block. Never run against mainnet with a real admin unless    #
# you have reviewed every flag.                                #
#                                                              #
# Usage:                                                       #
#   ADMIN_SECRET=<secret> ADMIN_ADDRESS=<addr> \               #
#     NETWORK=testnet ./scripts/deploy.sh                      #
# ============================================================ #
set -euo pipefail

NETWORK="${NETWORK:-testnet}"
RPC_URL="${RPC_URL:-https://soroban-testnet.stellar.org}"
WASM="target/wasm32v1-none/release/soroban_threatnet.wasm"

# stellar-cli (the maintained successor of soroban-cli) requires a network
# passphrase when --rpc-url is given. Resolve it from the network name.
case "$NETWORK" in
  testnet)  NETWORK_PASSPHRASE="${NETWORK_PASSPHRASE:-Test SDF Network ; September 2015}" ;;
  mainnet)  NETWORK_PASSPHRASE="${NETWORK_PASSPHRASE:-Public Global Stellar Network ; September 2015}" ;;
  *)        NETWORK_PASSPHRASE="${NETWORK_PASSPHRASE:?Set NETWORK_PASSPHRASE for custom networks}" ;;
esac

: "${ADMIN_SECRET:?Set ADMIN_SECRET (admin signing key secret).}"
: "${ADMIN_ADDRESS:?Set ADMIN_ADDRESS (public key of the admin).}"

echo "==> [1/4] Building contract (target: wasm32v1-none)"
cargo build --target wasm32v1-none --release

echo "==> [2/4] Deploying contract to ${NETWORK}"
CONTRACT_ID="$(soroban contract deploy \
  --wasm "$WASM" \
  --source "$ADMIN_SECRET" \
  --rpc-url "$RPC_URL" \
  --network-passphrase "$NETWORK_PASSPHRASE")"
echo "    deployed: ${CONTRACT_ID}"

echo "==> [3/4] Calling initialize(admin=${ADMIN_ADDRESS})"
soroban contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_SECRET" \
  --network "$NETWORK" \
  -- initialize --admin "$ADMIN_ADDRESS"

echo "==> [4/4] Verifying read path"
soroban contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_SECRET" \
  --network "$NETWORK" \
  -- get_total_indicators

echo
echo "============================================================"
echo "  DEPLOYMENT COMPLETE — copy-paste these values:"
echo "============================================================"
echo "  CONTRACT_ID=${CONTRACT_ID}"
echo "  ADMIN_ADDRESS=${ADMIN_ADDRESS}"
echo "  NETWORK=${NETWORK}"
echo "  RPC_URL=${RPC_URL}"
echo "============================================================"
