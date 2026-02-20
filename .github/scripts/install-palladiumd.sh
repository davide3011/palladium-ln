#!/bin/sh

set -e

# Generic CI download script for Palladium Core Linux x86_64
cd /tmp/

wget https://github.com/palladium-coin/palladiumcore/releases/latest/download/palladium-linux-x86_64.tar.gz
tar -xzf palladium-linux-x86_64.tar.gz

# Move binaries to a location in the CI PATH
cd linux-x86_64
sudo mv palladium* /usr/local/bin/

# Clean up
cd ..
rm -rf linux-x86_64/ palladium-linux-x86_64.tar.gz
