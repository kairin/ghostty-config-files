#!/bin/bash
# install_go.sh

echo "Installing Go..."

# 1. Get Latest Version
LATEST_VERSION=$(curl -s "https://go.dev/dl/?mode=json" | grep -oP '"version": "\K[^"]+' | head -1)
if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to get latest version."
    exit 1
fi
echo "Latest version: $LATEST_VERSION"

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="armv6l" ;;
    *) echo "Unsupported arch: $ARCH"; exit 1 ;;
esac

FILENAME="${LATEST_VERSION}.${OS}-${ARCH}.tar.gz"
URL="https://go.dev/dl/${FILENAME}"

echo "Downloading $URL..."
wget -q --show-progress -O /tmp/go.tar.gz "$URL"

echo "Removing old installation..."
sudo rm -rf /usr/local/go

echo "Extracting..."
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

echo "Creating symlinks..."
sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

echo "Go installed."
