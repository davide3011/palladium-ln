# Palladium Lightning

Palladium Lightning is the standard compliant implementation of the Lightning Network protocol for **Palladium**, a fork of Bitcoin.

This repository is an independent professional fork of [Core Lightning (CLN)](https://github.com/ElementsProject/lightning), maintained by Davide Grilli.

## Fork Information

The Palladium Lightning fork officially begins from the following upstream Core Lightning commit:
**`823a575d9a70ed7f2cb08be462c09a399a4a2842`**

For the original Core Lightning documentation, please refer to [`README-original.md`](README-original.md).

## Getting Started

Palladium Lightning aims to be lightweight, highly customizable, and fully compliant with the Lightning Network protocol adapted for the Palladium network.

### Building from Source

To compile the source code, please refer to the updated instructions or refer to the original installation documentation available in `doc/getting-started/getting-started/installation.md`.

## Running with Docker

### Prerequisites

- `palladium-node:local` image already built (provides `palladium-cli`)
- `palladiumd` running on the `palladium-net` Docker network

### 1. Configure credentials

```bash
cp .env.example .env
# Edit .env and set:
# PALLADIUM_RPCUSER=your_rpc_user
# PALLADIUM_RPCPASSWORD=your_rpc_password
```

### 2. Build the image

```bash
docker build -f Dockerfile.palladium-lightning -t palladium-lightning:local .
```

### 3. Start the node

```bash
docker compose -f docker-compose.lightning.yml up -d
```

### 4. Verify

```bash
docker logs palladium-lightning
docker exec palladium-lightning lightning-cli --network=palladium getinfo
```

### Useful commands

```bash
# Get a new wallet address
docker exec palladium-lightning lightning-cli --network=palladium newaddr

# Rebuild and restart after code changes
docker compose -f docker-compose.lightning.yml down
docker build -f Dockerfile.palladium-lightning -t palladium-lightning:local .
docker compose -f docker-compose.lightning.yml up -d
```

> **Note:** The RPC port `9835` is not exposed on the host —
> use `docker exec` to interact with the node.

### Router / firewall

Open **only** the following inbound port on your router (forward to the host running Docker):

| Port | Protocol | Purpose |
|------|----------|---------|
| `9735` | TCP | Lightning P2P — required for other nodes to connect and open channels |

Do **not** expose port `9835` (RPC) externally.

## Testing

For instructions on how to test Palladium Lightning against a local Palladium Regtest network, please refer to the dedicated guide: **[TESTING_PALLADIUM.md](TESTING_PALLADIUM.md)**.

## License

The code is released under the BSD-MIT License. See the [LICENSE](LICENSE) file for more details.
