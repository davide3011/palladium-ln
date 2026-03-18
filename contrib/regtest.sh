#!/usr/bin/env bash
# Convenience wrapper to set up paths and source startup_regtest.sh.
#
# Prerequisites:
#   1. lightningd compiled in-tree:  bash contrib/build-lightningd.sh
#   2. palladiumd + palladium-cli in: palladium-bin/
#      (copy pre-built binaries or run: bash contrib/build-palladiumd.sh)
#
# Usage (must be sourced, not executed):
#   source contrib/regtest.sh
#
# Then:
#   start_ln 2        → start palladiumd (regtest) + 2 LN nodes
#   fund_nodes        → mine coins, connect nodes, open channels
#   l1-cli getinfo    → query node 1
#   l2-cli getinfo    → query node 2
#   connect 1 2       → connect nodes (if not done by fund_nodes)
#   stop_ln           → shut everything down
#   destroy_ln        → wipe node data in /tmp
#

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "ERROR: this script must be sourced, not executed."
    echo "  source contrib/regtest.sh"
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Validate prerequisites ────────────────────────────────────────────────────
if [ ! -x "$REPO_ROOT/lightningd/lightningd" ]; then
    echo "ERROR: lightningd not found. Compile it first:"
    echo "  bash contrib/build-lightningd.sh"
    return 1
fi

if [ ! -x "$REPO_ROOT/palladium-bin/palladiumd" ] || [ ! -x "$REPO_ROOT/palladium-bin/palladium-cli" ]; then
    echo "ERROR: palladiumd / palladium-cli not found in palladium-bin/."
    echo "  Copy your pre-built binaries:"
    echo "    bash contrib/build-palladiumd.sh"
    echo "  Or place them manually in palladium-bin/"
    return 1
fi

# ── Export paths expected by startup_regtest.sh ───────────────────────────────
export LIGHTNING_BIN="$REPO_ROOT"
export PALLADIUM_BIN="$REPO_ROOT/palladium-bin"
export PALLADIUM_DIR="${PALLADIUM_DIR:-$HOME/.palladium-regtest}"
export LIGHTNING_DIR="${LIGHTNING_DIR:-/tmp/lightning-regtest}"

mkdir -p "$PALLADIUM_DIR" "$LIGHTNING_DIR"

# ── Install palladium.conf if not already present ─────────────────────────────
PALLADIUM_CONF="$PALLADIUM_DIR/palladium.conf"
if [ ! -f "$PALLADIUM_CONF" ]; then
    echo "==> Installing $PALLADIUM_CONF"
    cp "$REPO_ROOT/contrib/regtest/palladium.conf" "$PALLADIUM_CONF"
fi

# ── Source the actual regtest harness ─────────────────────────────────────────
# shellcheck source=contrib/startup_regtest.sh
source "$REPO_ROOT/contrib/startup_regtest.sh"
