#!/usr/bin/env bash
# One-time local setup for palladium-lightning development.
#
# Adds the `lcli` shell alias so you can run lightning-cli commands
# without typing the full docker exec invocation each time.
#
# Usage:
#   bash contrib/setup.sh
#   source ~/.bashrc   (or open a new terminal)
#
set -euo pipefail

ALIAS_LINE='alias lcli="docker exec palladium-lightning lightning-cli --lightning-dir=/data --network=palladium"'
COMMENT_LINE='# Palladium Lightning CLI shortcut'

# Detect shell config file
if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    RC_FILE="$HOME/.zshrc"
else
    RC_FILE="$HOME/.bashrc"
fi

if grep -qF "alias lcli=" "$RC_FILE" 2>/dev/null; then
    echo "lcli alias already present in $RC_FILE — nothing to do."
else
    printf '\n%s\n%s\n' "$COMMENT_LINE" "$ALIAS_LINE" >> "$RC_FILE"
    echo "Added lcli alias to $RC_FILE"
fi

echo ""
echo "To activate in the current terminal:"
echo "  source $RC_FILE"
