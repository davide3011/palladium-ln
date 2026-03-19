#!/usr/bin/env bash

: "${EXPOSE_TCP:=false}"

networkdatadir="${LIGHTNINGD_DATA}/${LIGHTNINGD_NETWORK}"

# Auto-detect public IP
# Tries three services in order; silently skips if all fail (node still works,
# just won't announce an address until a peer connects inbound).
if [ -z "${ANNOUNCE_DOMAIN:-}" ]; then
    for url in "https://ifconfig.me" "https://api.ipify.org" "https://icanhazip.com"; do
        detected_ip=$(curl -sf --max-time 5 "$url" 2>/dev/null | tr -d '[:space:]') || true
        if echo "$detected_ip" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
            echo "Auto-detected public IP: $detected_ip"
            set -- "$@" "--announce-addr=${detected_ip}"
            break
        fi
    done
fi

set -m
lightningd --network="${LIGHTNINGD_NETWORK}" "$@" &

echo "Core-Lightning starting"
while read -r i; do if [ "$i" = "lightning-rpc" ]; then break; fi; done \
    < <(inotifywait -e create,open --format '%f' --quiet "${networkdatadir}" --monitor)

if [ "$EXPOSE_TCP" == "true" ]; then
    echo "Core-Lightning started, RPC available on port $LIGHTNINGD_RPC_PORT"

    socat "TCP4-listen:$LIGHTNINGD_RPC_PORT,fork,reuseaddr" "UNIX-CONNECT:${networkdatadir}/lightning-rpc" &
fi

# Now run any scripts which exist in the lightning-poststart.d directory
if [ -d "$LIGHTNINGD_DATA"/lightning-poststart.d ]; then
    for f in "$LIGHTNINGD_DATA"/lightning-poststart.d/*; do
	"$f"
    done
fi

fg %-
