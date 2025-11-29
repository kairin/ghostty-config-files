#!/bin/bash
# install_glow.sh

echo "Installing glow..."

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

sudo apt-get update
sudo apt-get install -y glow
