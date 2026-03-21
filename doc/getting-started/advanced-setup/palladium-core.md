---
title: Palladium Core
slug: palladium-core
privacy:
  view: public
---

# Using palladiumd as the backend

Palladium Lightning requires JSON-RPC access to a fully synchronized `palladiumd` in order to synchronize with the Palladium network.

Access to ZeroMQ is not required and `palladiumd` does not need to be run with `txindex`.

The lightning daemon polls `palladiumd` for new blocks that it hasn't processed yet, synchronizing itself with the chain.

## Docker setup (recommended)

In the standard Docker Compose setup, `lightningd` connects to `palladiumd` over the `palladium-net` internal Docker network using the container hostname `palladium-node`. The RPC credentials are provided via environment variables in `.env` and must match the values set in `palladium-stack/.palladium/palladium.conf`:

```
PALLADIUM_RPCUSER=your_rpc_user
PALLADIUM_RPCPASSWORD=your_rpc_password
```

`lightningd` is pre-configured to reach `palladium-node` on port `2332`. No additional configuration is needed.

## Pruned nodes

If `palladiumd` prunes a block that Palladium Lightning has not yet processed (e.g., the lightning node was offline for an extended period), `palladiumd` will not be able to serve the missing blocks and `lightningd` will stall.

To avoid this, monitor the gap between Palladium Lightning's blockheight:

```bash
lcli getinfo
```

and `palladiumd`'s blockheight:

```bash
palladium-cli getblockchaininfo
```

If the two blockheights drift apart, use `--rescan` to recover (see [configuration](doc:configuration)).

## Remote palladiumd

If you need to connect `lightningd` to a `palladiumd` running on a different host, set the following in your `lightningd` config or `.env`:

```
palladium-rpcconnect=<host>
palladium-rpcport=<port>
palladium-rpcuser=<user>
palladium-rpcpassword=<password>
```
