# Palladium Lightning — Node Operations

This document covers day-to-day operations for a running `palladium-lightning` node.

## Setup: CLI shortcut

Run the setup script once after cloning the repo — it adds the `lcli` alias to your shell:

```bash
bash contrib/setup.sh
source ~/.bashrc
```

All examples below use `lcli`. You can also run any command without the alias:

```bash
docker exec palladium-lightning lightning-cli --network=palladium <command>
```

---

## Node info

```bash
# Summary: ID, alias, peers, active channels
lcli getinfo

# Detailed script output: address, balance, open channels
bash contrib/fund-node.sh info
```

---

## On-chain funds

```bash
# List UTXOs and channel funds
lcli listfunds

# Generate a new on-chain address to receive PLM
lcli newaddr

# Send PLM on-chain
lcli withdraw <palladium-address> <amount_sat>
lcli withdraw plm1q... 100000

# Send all on-chain funds
lcli withdraw plm1q... all
```

---

## Peers

```bash
# List connected peers
lcli listpeers

# Connect to a peer (required before opening a channel)
lcli connect <pubkey>@<host>:<port>
lcli connect 02abc...@1.2.3.4:9735

# Disconnect a peer
lcli disconnect <pubkey>
```

---

## Channels

```bash
# List channels with balance detail
lcli listpeerchannels

# Open a channel (peer must be connected first)
# amount_sat: channel size in satoshis
lcli fundchannel <pubkey> <amount_sat>
lcli fundchannel 02abc... 1000000

# One-step connect + open (uses contrib script)
bash contrib/fund-node.sh open 02abc...@1.2.3.4:9735 1000000

# Close a channel cooperatively (funds return on-chain after ~6 blocks)
lcli close <pubkey>

# Force-close (use only if peer is unresponsive)
lcli close <pubkey> 1
```

---

## Payments

```bash
# Create an invoice (amount in millisatoshis, 1 sat = 1000 msat)
lcli invoice <amount_msat> <label> <description>
lcli invoice 50000000 "order-42" "Payment for order 42"

# Pay a BOLT11 invoice
lcli pay <bolt11>

# Payment history
lcli listsendpays

# Invoice status
lcli listinvoices
lcli listinvoices <label>   # specific invoice
```

---

## Network gossip

```bash
# All nodes known via gossip
lcli listnodes

# Specific node info
lcli listnodes <pubkey>

# All channels known via gossip
lcli listchannels

# Find a route to a destination
# risk_factor: 1 is standard
lcli getroute <pubkey> <amount_msat> <risk_factor>
lcli getroute 02abc... 50000000 1
```

---

## Logs and diagnostics

```bash
# Tail live logs
docker logs -f palladium-lightning

# Last 100 lines
docker logs --tail 100 palladium-lightning

# CLN log level (inside the node)
lcli getlog
lcli getlog unusual    # warnings and errors only
```

---

## Start / stop

```bash
# Start
docker compose up -d

# Stop (graceful — waits for HTLCs to settle)
docker compose stop

# Restart
docker compose restart palladium-lightning

# Status
docker compose ps
```

---

## All available commands

```bash
lcli help               # full command list
lcli help <command>     # help for a specific command
```
