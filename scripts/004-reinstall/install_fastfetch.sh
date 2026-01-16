#!/bin/bash
# install_fastfetch.sh

echo "Installing fastfetch..."

# Get Latest Version from GitHub
LATEST_VERSION=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' || echo "")

CURRENT_VERSION=""
if command -v fastfetch &> /dev/null; then
    CURRENT_VERSION=$(fastfetch --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "")
fi

echo "Current: $CURRENT_VERSION"
echo "Latest:  $LATEST_VERSION"

if [[ -n "$LATEST_VERSION" ]] && [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo "Already at latest version ($LATEST_VERSION)."
    exit 0
fi

# If we are here, we need to install/update.

# 1. Try Adding PPA if not present (Ubuntu/Debian)
if command -v apt-get &> /dev/null; then
    NEED_UPDATE=0
    if ! grep -q "fastfetch" /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "Adding Fastfetch PPA..."
        sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
        NEED_UPDATE=1
    fi

    # Smart apt update - skip if cache is fresh (< 5 min) and no new repo added
    APT_LISTS="/var/lib/apt/lists"
    CACHE_AGE=$(($(date +%s) - $(stat -c%Y "$APT_LISTS" 2>/dev/null || echo 0)))
    if [[ $NEED_UPDATE -eq 1 ]] || [[ $CACHE_AGE -gt 300 ]]; then
        sudo stdbuf -oL apt-get update
    else
        echo "APT cache fresh (${CACHE_AGE}s ago), skipping update"
    fi

    echo "Attempting APT install..."
    sudo stdbuf -oL apt-get install -y fastfetch
    
    # Check if it worked
    NEW_VERSION=$(fastfetch --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "")
    
    # If we successfully installed *something* and we don't know the latest, assume success
    if [[ -z "$LATEST_VERSION" ]] && [[ -n "$NEW_VERSION" ]]; then
         echo "Installed via APT (Latest version unknown)."
         exit 0
    fi

    if [[ "$NEW_VERSION" == "$LATEST_VERSION" ]]; then
        echo "Installed/Updated via APT/PPA."
        exit 0
    fi
    
    # If APT gave us a version that matches what we had, and we know there is a newer one, proceed.
    # But if APT gave us a NEWER version (but maybe not THE latest?), we might want to stop?
    # For now, strict check: if not equal to latest, try GitHub.
    echo "APT did not give the latest version. Trying GitHub Release..."
fi

# 2. GitHub Release (Fallback or Primary if no APT)
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) DEB_ARCH="amd64" ;;
    aarch64) DEB_ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep "browser_download_url.*linux-${DEB_ARCH}.deb" | cut -d'"' -f4 | head -1)

if [ -z "$URL" ]; then
    echo "Failed to find download URL."
    # If we already have a working fastfetch from APT, don't fail hard?
    if command -v fastfetch &> /dev/null; then
        echo "Fallback: Keeping existing APT version."
        exit 0
    fi
    exit 1
fi

echo "Downloading $URL..."
wget -q --show-progress -O /tmp/fastfetch.deb "$URL"
sudo dpkg -i /tmp/fastfetch.deb
rm /tmp/fastfetch.deb

echo "Installed via GitHub Release."
