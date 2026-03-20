---
title: Running your node
slug: beginners-guide
content:
  excerpt: A guide to all the basics you need to get up and running immediately.
privacy:
  view: public
---
## Starting Palladium Lightning

### Prerequisites

- Docker and Docker Compose installed
- A running `palladiumd` node, fully synced, connected to the `palladium-net` Docker network
- A `.env` file with `PALLADIUM_RPCUSER` and `PALLADIUM_RPCPASSWORD`

### Starting with Docker Compose

```bash
docker compose up -d
```

Check that the container is running and follow the logs:

```bash
docker compose ps
docker logs -f palladium-lightning
```

### One-time CLI alias setup

Run the setup script once after cloning the repo — it adds the `lcli` alias to your shell:

```bash
bash contrib/setup.sh
source ~/.bashrc   # or open a new terminal
```

From then on you can use `lcli <command>` instead of the full Docker invocation:

```bash
docker exec palladium-lightning lightning-cli --network=palladium <command>
```

## Using The JSON-RPC Interface

Palladium Lightning exposes a [JSON-RPC 2.0](https://www.jsonrpc.org/specification) interface over a Unix Domain socket; the `lightning-cli` tool (via the `lcli` alias) is used to access it.

Print the full list of available RPC methods:

```bash
lcli help
lcli help <command>
```

### Essential commands

| Command | Description |
|---|---|
| `lcli getinfo` | Node summary: ID, alias, peers, active channels |
| `lcli newaddr` | Generate an on-chain address to receive PLM |
| `lcli listfunds` | On-chain UTXOs and channel balances |
| `lcli listpeers` | List connected peers |
| `lcli connect <pubkey@host:port>` | Connect to another Lightning node |
| `lcli fundchannel <pubkey> <sat>` | Open a channel with a connected peer |
| `lcli listpeerchannels` | Channels with balance detail |
| `lcli invoice <msat> <label> <desc>` | Create an invoice to receive PLM |
| `lcli pay <bolt11>` | Pay a BOLT11 invoice |
| `lcli listsendpays` | Payment history |
| `lcli listinvoices` | Invoice status |
| `lcli withdraw <address> <sat>` | Send PLM on-chain |
| `lcli close <pubkey>` | Cooperatively close a channel |
| `lcli plugin` | Manage plugins/extensions |
| `lcli stop` | Gracefully stop the daemon |

## Funding Your Node

Use the `contrib/fund-node.sh` script for the initial liquidity setup:

**Show node info, on-chain address, and balance:**

```bash
bash contrib/fund-node.sh info
```

**Connect to a peer and open a channel in one step:**

```bash
bash contrib/fund-node.sh open <pubkey@host:port> <amount_sat>
# Example:
bash contrib/fund-node.sh open 02abc...@1.2.3.4:9735 1000000
```

The channel will be usable after approximately 6 Palladium block confirmations.

## Care And Feeding Of Your New Lightning Node

Once you've started for the first time, `contrib/bootstrap-node.sh` will connect you to other nodes on the Palladium Lightning network:

```bash
bash contrib/bootstrap-node.sh
```

There are also numerous plugins available which add capabilities: see the [Plugins](doc:plugins) guide.

For a less reckless experience, you can encrypt the HD wallet seed: see [HD wallet encryption](doc:backup-and-recovery#hsm-secret-backup).

For offline channel protection, see [Watchtowers](doc:watchtowers).

## Regtest (local development)

To experiment locally without real funds, source the regtest helper script:

```bash
source contrib/startup_regtest.sh
start_ln
```

This starts `palladiumd` in regtest mode and two Lightning nodes available as `l1-cli` and `l2-cli`. Use `fund_nodes` to mine blocks, fund wallets, and open a test channel between them. Use `stop_ln` and `destroy_ln` to tear down.
