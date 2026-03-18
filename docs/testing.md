# Palladium Lightning — Test Suite

Automated integration tests for two-node Lightning Network functionality on Palladium regtest.

## Overview

The test suite runs on an isolated regtest environment managed entirely by the `pyln-testing` framework. No manual setup is required: the framework starts `palladiumd` in regtest mode, mines 122 blocks (enough for spendable coinbase outputs), starts two `lightningd` nodes, opens and funds a channel between them, and cleans up everything after each test.

**Topology tested:**

```
l1 ──────────────── l2
   funded channel
   (l1 holds all initial balance)
```

## Prerequisites

### Binaries

Both `palladiumd` and `lightningd` must be available. Place pre-built binaries in `palladium-bin/`:

```bash
bash contrib/build-palladiumd.sh   # copies palladiumd + palladium-cli
bash contrib/build-lightningd.sh   # compiles lightningd with DEVELOPER=1
```

`lightningd` **must** be compiled with `DEVELOPER=1` — the tests use dev-only RPC methods (`dev_pay`, `dev-palladiumd-poll`).

### Python environment

```bash
python3 -m venv .venv
.venv/bin/pip install \
    -e contrib/pyln-testing \
    -e contrib/pyln-client \
    -e contrib/pyln-proto \
    mnemonic
```

## Running the tests

```bash
# All tests (recommended entry point)
bash contrib/run-tests.sh

# Specific test
bash contrib/run-tests.sh -k test_basic_payment

# Specific file
bash contrib/run-tests.sh tests/test_palladium_regtest.py

# Parallel execution (requires pytest-xdist)
bash contrib/run-tests.sh -n 2

# With verbose output and short tracebacks
bash contrib/run-tests.sh -v --tb=short
```

Or directly with pytest from the repo root:

```bash
PATH="$(pwd)/palladium-bin:$PATH" .venv/bin/pytest tests/test_palladium_regtest.py -v
```

> **Note:** run from the repo root, not from `tests/`. The framework resolves binary paths relative to the working directory.

Expected output:

```
tests/test_palladium_regtest.py::test_nodes_start                  PASSED
tests/test_palladium_regtest.py::test_channel_opened               PASSED
tests/test_palladium_regtest.py::test_basic_payment                PASSED
tests/test_palladium_regtest.py::test_payment_amount_correct       PASSED
tests/test_palladium_regtest.py::test_channel_balance_after_payment PASSED
tests/test_palladium_regtest.py::test_payment_reverse              PASSED
tests/test_palladium_regtest.py::test_invoice_expiry               PASSED
tests/test_palladium_regtest.py::test_cooperative_close            PASSED

8 passed in ~90s
```

## Test descriptions

### Fixture: `two_nodes`

Most tests share this fixture. It creates two connected LN nodes with an open, funded channel in `CHANNELD_NORMAL` state. `l1` holds the full channel balance at start.

```python
l1, l2 = node_factory.line_graph(2, fundchannel=True, announce_channels=True)
```

### 1. `test_nodes_start`

Verifies that both nodes start correctly and connect to each other as peers.

- Both nodes report `network == "regtest"`
- Each node sees `num_peers == 1`
- Node IDs are distinct

### 2. `test_channel_opened`

Verifies that the channel between `l1` and `l2` is fully operational.

- Channel state is `CHANNELD_NORMAL`
- `spendable_msat > 0` (l1 has balance to spend)
- Channel peer ID matches l2

### 3. `test_basic_payment`

Verifies a standard BOLT11 payment from `l1` to `l2`.

- l2 creates an invoice for 100,000 msat
- l1 pays it via `dev_pay` (deterministic, no shadow routing)
- Payment result status is `complete`
- Invoice status on l2 is `paid`

### 4. `test_payment_amount_correct`

Verifies that the amount received matches the invoiced amount exactly.

- Invoice for 50,000 msat
- `amount_msat == 50,000 msat` in the payment result
- `amount_sent_msat == 50,000 msat` (no routing fees on a direct channel)

### 5. `test_channel_balance_after_payment`

Verifies that channel balances update correctly after a payment settles.

- Records `spendable_msat` (l1) and `receivable_msat` (l2) before payment
- Pays 200,000 msat from l1 to l2
- Waits for all HTLCs to settle
- Asserts `spendable_msat` decreased for l1
- Asserts `receivable_msat` decreased for l2 (capacity now partially used)

### 6. `test_payment_reverse`

Verifies that l2 can pay l1 through the same channel (bidirectional).

Since gossip propagation is not guaranteed in regtest, this test uses an **explicit route** via `sendpay` rather than relying on pathfinding.

Steps:
1. Push 200,000,000 msat (200k sat) from l1 to l2 to give l2 spendable balance (enough to cover HTLC fees ~4,220 sat)
2. Wait for HTLCs to settle
3. l1 creates an invoice for 100,000,000 msat
4. l2 builds an explicit single-hop route and calls `sendpay` with `payment_secret`
5. `waitsendpay` confirms completion
6. Invoice on l1 is marked `paid`

### 7. `test_invoice_expiry`

Verifies that an expired invoice is rejected.

- l2 creates an invoice with `expiry=1` (1 second)
- Waits 2 seconds
- Asserts that `l1.rpc.pay()` raises `RpcError` matching `[Ee]xpir`

### 8. `test_cooperative_close`

Verifies the full cooperative channel close flow and on-chain fund recovery.

Steps:
1. Open a funded channel between l1 and l2
2. Pay 50,000,000 msat to l2 so both parties have on-chain outputs to recover
3. `l1.rpc.close(l2_id)` negotiates and broadcasts the closing transaction
4. Mine 100 blocks (waits for closing tx in mempool first)
5. Asserts both l1 and l2 have at least one `confirmed` output in `listfunds()`

## Architecture

The test framework is provided by `contrib/pyln-testing` (part of the Core Lightning test infrastructure, adapted for Palladium).

Key components:

| Component | Role |
|---|---|
| `PalladiumD` | Manages the `palladiumd` regtest process |
| `NodeFactory` | Creates and connects `lightningd` nodes |
| `LightningNode` | Wraps a single node with RPC + helpers |
| `fixtures.py` | pytest fixtures: `bitcoind`, `node_factory`, etc. |
| `utils.py` | Helpers: `only_one()`, `wait_for()` |

Each test gets a fresh environment. Temporary directories, ports, and processes are allocated and cleaned up automatically.

## Troubleshooting

**`palladiumd not found`**
Ensure `palladium-bin/` contains the binary and you are running from the repo root (or using `contrib/run-tests.sh`).

**`lightningd not found`**
Run `bash contrib/build-lightningd.sh` first. The binary must be in `lightningd/lightningd` (in-tree build) or in `palladium-bin/`.

**`ModuleNotFoundError`**
Activate the venv or use `.venv/bin/pytest` directly. Re-run the pip install commands above if modules are missing.

**Tests timeout**
The framework has a default timeout of ~60s per `wait_for` call. On slow machines (e.g. Raspberry Pi) some tests may need more time. Run with `-v` to see which step is hanging.

**`DEVELOPER` features unavailable**
`lightningd` must be compiled with `DEVELOPER=1`. The `dev_pay` helper and `dev-palladiumd-poll` option are only available in developer builds.
