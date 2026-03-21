---
title: Docker Images
slug: docker-images
privacy:
  view: public
---
# Palladium Lightning Docker Image

The Palladium Lightning Docker image is **not published to Docker Hub**. It is built locally from the source repository using `docker compose`.

## Building the image

```bash
docker build -t palladium-lightning:local .
```

Or let `docker compose` build it automatically on first start:

```bash
docker compose up -d --build
```

The resulting image is tagged `palladium-lightning:local` and is used directly by the `docker-compose.yml` service definition.

## Running with Docker Compose

```bash
docker compose up -d
```

Check that the container is running:

```bash
docker compose ps
docker logs -f palladium-lightning
```

## Network requirements

The image expects a `palladium-net` Docker network to exist (created by the `palladiumd` compose stack):

```bash
docker network create palladium-net   # only needed if not already created by palladiumd
```

## Rebuilding after code changes

```bash
docker compose down
docker compose up -d --build
```

## Architecture notes

- The image is built for the host architecture (no multiarch / cross-compilation).
- RPC port `9835` is **not** exposed externally — use `docker exec` or the `lcli` alias to interact with the node.
- Lightning P2P port `9735` is exposed and must be reachable from the internet for peers to open channels.
