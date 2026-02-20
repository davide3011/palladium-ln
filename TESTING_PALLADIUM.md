# Testing Palladium Lightning

This guide explains how to test the Palladium Lightning (`lightning-plm`) integration with Palladium Core (`palladiumcore`) on your local machine using a Regtest environment.

## Prerequisites

1. **Palladium Core**: You must have `palladiumd` and `palladium-cli` compiled.
2. **Palladium Lightning**: Ensure you have successfully compiled this repository (`make`).
3. **Dependencies**: Make sure you have `bash` and standard Unix utilities installed.

## 1. Regtest Setup

The easiest way to test channels and interactions is by using the provided `startup_regtest.sh` script. This script automatically spins up a local Palladium Regtest network alongside 3 Lightning nodes.

First, you need to make the Palladium binaries accessible to the test scripts. The simplest method is to copy them directly into a `palladium-bin` directory in the root of the repository:

```bash
mkdir -p palladium-bin
cp /path/to/palladiumcore/src/palladiumd palladium-bin/
cp /path/to/palladiumcore/src/palladium-cli palladium-bin/
```

*(Note: The `palladium-bin` directory is correctly ignored by git, so your local binaries won't be pushed).*

Alternatively, you can skip copying the binaries and specify their path manually using an environment variable before running the script:

```bash
export PALLADIUM_BIN=/path/to/palladiumcore/src
```

Then, initialize the test environment using the startup script:

```bash
# Sourcing the script loads useful aliases into your terminal
source contrib/startup_regtest.sh

# Start the cluster with 3 nodes
start_ln 3
```

## 2. Using the Aliases

Once the cluster is running, the script creates several handy aliases to interact with the nodes easily.

- **`bt-cli`**: Connects to the local Palladium backend.

  ```bash
  bt-cli getblockchaininfo
  ```

- **`l1-cli`, `l2-cli`, `l3-cli`**: Connects to the respective Lightning nodes.

  ```bash
  l1-cli getinfo
  l2-cli newaddr
  ```

## 3. Funding and Connecting Nodes

To test the complete lifecycle of a Lightning channel, you can automatically fund the nodes and connect them together with a single command:

```bash
fund_nodes
```

This will:

1. Generate some Palladium blocks to fund the default wallet.
2. Connect `l1` to `l2`, and `l2` to `l3`.
3. Fund the channels automatically and mine the necessary confirmation blocks.

You can verify the channels by running:

```bash
l1-cli listchannels
```

## 4. Teardown

When you are finished testing, cleanly shut down the environment and remove the temporary data.

```bash
# Stop the Palladium and Lightning daemons
stop_ln

# Clean up the temporary node directories in /tmp
destroy_ln
```

## Running Python Integration Tests

If you want to run the automated Python test suite against the Palladium backend:

1. Install the testing dependencies:

   ```bash
   pip3 install -r contrib/pyln-testing/requirements.txt
   ```

2. Run pytest from the root of the repository:

   ```bash
   pytest tests/
   ```

*(Note: Be sure your environment variables correctly point to your Palladium binaries if they are not system-wide installed).*
