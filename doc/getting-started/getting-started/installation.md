---
title: Installation
slug: installation
content:
  excerpt: >-
    Palladium Lightning runs as a Docker container alongside palladiumd. Learn how to set it up.
privacy:
  view: public
---
# Docker (recommended)

Palladium Lightning is distributed as a Docker image and is designed to run alongside a `palladiumd` node on the same Docker network.

## Prerequisites

- Docker and Docker Compose installed
- A running `palladiumd` node connected to the `palladium-net` Docker network
- RPC credentials for `palladiumd`

## 1. Configure credentials

```bash
cp .env.example .env
# Edit .env and set:
# PALLADIUM_RPCUSER=your_rpc_user
# PALLADIUM_RPCPASSWORD=your_rpc_password
```

## 2. Build the image

```bash
docker build -f Dockerfile.palladium-lightning -t palladium-lightning:local .
```

## 3. Start the node

```bash
docker compose up -d
```

## 4. Verify

```bash
docker compose ps
docker logs palladium-lightning
docker exec palladium-lightning lightning-cli --network=palladium getinfo
```

## 5. CLI alias (optional but recommended)

Run the setup script once to add the `lcli` shortcut to your shell:

```bash
bash contrib/setup.sh
source ~/.bashrc
```

After this, `lcli <command>` replaces the full `docker exec` invocation.

---

# Router / firewall

Open **only** the following inbound port on your router (forward to the host running Docker):

| Port | Protocol | Purpose |
|------|----------|---------|
| `9735` | TCP | Lightning P2P — required for peers to connect and open channels |

Do **not** expose port `9835` (RPC) externally.

---

# Building from Source

To compile `lightningd` and `lightning-cli` directly (for development or regtest use):

```bash
bash contrib/build-lightningd.sh
```

This installs build dependencies and compiles the binaries in-tree. See [Reproducible builds](doc:repro) for verified release builds.
