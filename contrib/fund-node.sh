#!/usr/bin/env bash
# Fund the Palladium Lightning node and open channels.
#
# This script helps with the initial liquidity setup:
#   1. Shows the node's on-chain address to receive PLM
#   2. Shows current on-chain balance
#   3. Opens a channel to a peer
#
# Usage:
#   bash contrib/fund-node.sh info                          # show address + balance
#   bash contrib/fund-node.sh open <peer_uri> <amount_sat>  # open channel
#
# Examples:
#   bash contrib/fund-node.sh info
#   bash contrib/fund-node.sh open 02abc...@1.2.3.4:9735 1000000
#
set -euo pipefail

CONTAINER="palladium-lightning"
CLI="docker exec $CONTAINER lightning-cli --lightning-dir=/data --network=palladium"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo "ERROR: container '$CONTAINER' is not running."
    echo "       Start it with: docker compose up -d"
    exit 1
fi

cmd="${1:-info}"

case "$cmd" in
    info)
        echo "==> Node info"
        $CLI getinfo | jq '{id, alias, color, num_peers, num_active_channels, num_inactive_channels}'

        echo ""
        echo "==> On-chain address (send PLM here to fund the node)"
        $CLI newaddr | jq -r '.bech32'

        echo ""
        echo "==> On-chain balance"
        $CLI listfunds | jq '
            .outputs | {
                total_sat:       ([.[].amount_msat // 0] | add // 0 | . / 1000 | floor),
                confirmed_sat:   ([.[] | select(.status=="confirmed")   | .amount_msat // 0] | add // 0 | . / 1000 | floor),
                unconfirmed_sat: ([.[] | select(.status=="unconfirmed") | .amount_msat // 0] | add // 0 | . / 1000 | floor)
            }'

        echo ""
        echo "==> Open channels"
        $CLI listpeerchannels | jq '
            .channels[] | {
                peer_id,
                state,
                spendable_sat:  ((.spendable_msat  // 0) | . / 1000 | floor),
                receivable_sat: ((.receivable_msat // 0) | . / 1000 | floor)
            }' 2>/dev/null || echo "    (no channels)"
        ;;

    open)
        if [ $# -lt 3 ]; then
            echo "Usage: bash contrib/fund-node.sh open <peer_uri> <amount_sat>"
            echo "       peer_uri format: <pubkey>@<host>:<port>"
            echo "       amount_sat: channel size in satoshis (min ~20000)"
            exit 1
        fi
        peer_uri="$2"
        amount_sat="$3"
        pubkey="${peer_uri%%@*}"

        echo "==> Connecting to peer $pubkey ..."
        $CLI connect "$peer_uri"

        echo "==> Opening channel: ${amount_sat} sat to ${pubkey} ..."
        result=$($CLI fundchannel "$pubkey" "$amount_sat")
        echo "$result" | jq '{txid, channel_id, outnum}'

        echo ""
        echo "Channel funding transaction broadcast."
        echo "The channel will be usable after ~6 confirmations (~6 Palladium blocks)."
        echo ""
        echo "Monitor with:"
        echo "  docker exec $CONTAINER lightning-cli --network=palladium listpeerchannels"
        ;;

    *)
        echo "Usage: bash contrib/fund-node.sh <info|open>"
        exit 1
        ;;
esac
