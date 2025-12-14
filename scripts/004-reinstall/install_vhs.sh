#!/bin/bash
# install_vhs.sh

echo "Installing vhs..."

CHARM_GPG_URL="https://repo.charm.sh/apt/gpg.key"
CHARM_GPG_KEYRING="/etc/apt/keyrings/charm.gpg"
CHARM_REPO_LIST="/etc/apt/sources.list.d/charm.list"

if [ ! -f "$CHARM_REPO_LIST" ]; then
    echo "Adding Charm repository..."
    sudo mkdir -p /etc/apt/keyrings
    if [ -f "$CHARM_GPG_KEYRING" ]; then sudo rm -f "$CHARM_GPG_KEYRING"; fi
    curl -fsSL "$CHARM_GPG_URL" | sudo gpg --dearmor -o "$CHARM_GPG_KEYRING"
    echo "deb [signed-by=$CHARM_GPG_KEYRING] https://repo.charm.sh/apt/ * *" | sudo tee "$CHARM_REPO_LIST"
fi

# Smart apt update - skip if cache is fresh (< 5 min)
APT_LISTS="/var/lib/apt/lists"
CACHE_AGE=$(($(date +%s) - $(stat -c%Y "$APT_LISTS" 2>/dev/null || echo 0)))
if [[ $CACHE_AGE -gt 300 ]]; then
    sudo stdbuf -oL apt-get update
else
    echo "APT cache fresh (${CACHE_AGE}s ago), skipping update"
fi
sudo stdbuf -oL apt-get install -y vhs
