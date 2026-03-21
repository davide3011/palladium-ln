# Palladium Lightning

Palladium Lightning is the standard compliant implementation of the Lightning Network protocol for **Palladium**, a fork of Bitcoin.

This repository is an independent professional fork of [Core Lightning (CLN)](https://github.com/ElementsProject/lightning), maintained by Davide Grilli.

## Fork Information

The Palladium Lightning fork officially begins from the following upstream Core Lightning commit:
**`823a575d9a70ed7f2cb08be462c09a399a4a2842`**

For the original Core Lightning documentation, please refer to [`README-original.md`](README-original.md).

## Getting Started

Palladium Lightning aims to be lightweight, highly customizable, and fully compliant with the Lightning Network protocol adapted for the Palladium network.


## Documentation

### Getting Started
- **[Beginner's Guide](doc/beginners-guide/beginners-guide.md)** — Docker setup, CLI alias, essential commands, funding your node
- **[Installation](doc/getting-started/getting-started/installation.md)** — Docker install and building from source
- **[Configuration](doc/getting-started/getting-started/configuration.md)** — all `lightningd` configuration options
- **[Hardware Considerations](doc/getting-started/getting-started/hardware-considerations.md)** — RAM, storage, and hardware requirements
- **[Upgrade](doc/getting-started/upgrade.md)** — how to upgrade the node

### Node Operations
- **[Node Operations](docs/node-operations.md)** — day-to-day operations reference
- **[Opening Channels](doc/beginners-guide/opening-channels.md)** — connect to peers and open channels
- **[Sending & Receiving Payments](doc/beginners-guide/sending-and-receiving-payments.md)** — invoices and payments
- **[FAQ & Troubleshooting](doc/node-operators-guide/faq.md)** — common issues and answers
- **[Plugins](doc/node-operators-guide/plugins.md)** — managing extensions with `reckless`
- **[Watchtowers](doc/beginners-guide/watchtowers.md)** — protect channels while offline

### Backup & Recovery
- **[Backup](doc/beginners-guide/backup.md)** — HSM secret, static channel backup, database
- **[HSM Secret](doc/beginners-guide/backup-and-recovery/hsm-secret.md)** — key management and mnemonic
- **[Recovery](doc/beginners-guide/backup-and-recovery/recovery.md)** — restore from backup
- **[Advanced DB Backup](doc/beginners-guide/backup-and-recovery/advanced-db-backup.md)** — real-time replication

### Advanced Setup
- **[Palladium Core](doc/getting-started/advanced-setup/palladium-core.md)** — palladiumd backend configuration
- **[Tor](doc/getting-started/advanced-setup/tor.md)** — privacy and NAT traversal with Tor

### Developer Guides
- **[Developer's Guide](doc/developers-guide/developers-guide.md)** — setting up a development environment
- **[App Development](doc/developers-guide/app-development.md)** — JSON-RPC, REST, gRPC, Commando APIs
- **[Plugin Development](doc/developers-guide/plugin-development.md)** — writing plugins and hooks
- **[Palladium Backend Plugin](doc/developers-guide/plugin-development/bitcoin-backend.md)** — custom chain backend specification

## Testing

For instructions on how to test Palladium Lightning against a local Palladium Regtest network, please refer to the dedicated guide: **[TESTING_PALLADIUM.md](TESTING_PALLADIUM.md)**.

## License

The code is released under the BSD-MIT License. See the [LICENSE](LICENSE) file for more details.
