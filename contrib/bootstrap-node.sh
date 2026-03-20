#! /bin/sh
# Simple script to bootstrap a running Palladium Lightning node.

set -e

CONTAINER="palladium-lightning"

# Prefer Docker-based lcli (standard Palladium Lightning setup).
# Fall back to a local lightning-cli binary if found.
# shellcheck disable=SC2039
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER}$"; then
    LCLI="docker exec ${CONTAINER} lightning-cli --lightning-dir=/data --network=palladium"
elif type lightning-cli >/dev/null 2>&1; then
    LCLI="lightning-cli --network=palladium"
elif [ -x cli/lightning-cli ]; then
    LCLI="cli/lightning-cli --network=palladium"
else
    echo "Cannot find lightning-cli and container '${CONTAINER}' is not running." >&2
    echo "Start the node with: docker compose up -d" >&2
    exit 1
fi

if ! $LCLI "$@" -H getinfo | grep -q 'network=palladium'; then
    echo "lightningd not running, or not on palladium network?" >&2
    exit 1
fi

# Pick up to 3 random Palladium Lightning peers from this list and connect.
# Add known Palladium Lightning node URIs below in the format:
#   IPV4: <pubkey>@<host>:<port>
#
# Example (do not uncomment — placeholder only):
#   IPV4: 02abc...@1.2.3.4:9735

PEERS=$(grep '^# IPV4:' "$0" | sort -R | tail -n 3 | cut -d' ' -f3-)

if [ -z "$PEERS" ]; then
    echo "No peers configured. Add Palladium Lightning node URIs to contrib/bootstrap-node.sh." >&2
    exit 0
fi

for p in $PEERS; do
    echo "Trying to connect to random peer $p..."
    $LCLI "$@" connect "$p" || true
done
