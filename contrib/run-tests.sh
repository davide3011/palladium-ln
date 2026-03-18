#!/usr/bin/env bash
# Run the Palladium Lightning test suite.
#
# Usage:
#   bash contrib/run-tests.sh                          # all tests
#   bash contrib/run-tests.sh tests/test_palladium_regtest.py   # specific file
#   bash contrib/run-tests.sh -k test_basic_payment    # specific test
#   bash contrib/run-tests.sh -n 2                     # parallel (needs pytest-xdist)
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [ ! -d ".venv" ]; then
    echo "ERROR: venv not found. Run first:"
    echo "  python3 -m venv .venv"
    echo "  .venv/bin/pip install -e contrib/pyln-testing -e contrib/pyln-client -e contrib/pyln-proto mnemonic"
    exit 1
fi

if [ ! -x "palladium-bin/palladiumd" ]; then
    echo "ERROR: palladiumd not found in palladium-bin/."
    exit 1
fi

export PATH="$REPO_ROOT/palladium-bin:$PATH"

.venv/bin/pytest "${@:-tests/test_palladium_regtest.py}" -v
