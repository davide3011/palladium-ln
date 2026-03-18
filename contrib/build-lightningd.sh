#!/usr/bin/env bash
# Compile lightningd + lightning-cli in-tree so that startup_regtest.sh
# can find them automatically when sourced from the repo root.
#
# Usage:
#   bash contrib/build-lightningd.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    gcc \
    git \
    gettext \
    jq \
    libffi-dev \
    libicu-dev \
    libprotobuf-c-dev \
    libsodium-dev \
    libsqlite3-dev \
    libssl-dev \
    libtool \
    pkg-config \
    protobuf-compiler \
    python3-dev \
    python3-pip \
    zlib1g-dev

echo "==> Installing Python build dependency (mako)..."
sudo apt-get install -y --no-install-recommends python3-mako

echo "==> Initialising git submodules..."
git submodule update --init --recursive --depth 1 --jobs "$(nproc)"

echo "==> Configuring..."
./configure \
    --disable-valgrind \
    --disable-compat

echo "==> Compiling with $(nproc) jobs (programs only, skipping docs)..."
make -j"$(nproc)" all-programs DEVELOPER=1

echo
echo "==> Done!"
echo "    $(lightningd/lightningd --version)"
echo
echo "You can now run:"
echo "    source contrib/startup_regtest.sh"
echo "    start_ln 2"
