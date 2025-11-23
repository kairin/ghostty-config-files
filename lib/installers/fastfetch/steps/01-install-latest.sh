#!/usr/bin/env bash
#
# Step 01: Install latest fastfetch
# Purpose: Install fastfetch using best available method (APT preferred)
# Exit Codes: 0=success, 1=installation failed
#

set -eo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Installing fastfetch..."

    # Try APT first (Ubuntu 25.10+ has fastfetch in repositories)
    if command_exists "apt-get"; then
        log "INFO" "Attempting to install fastfetch via APT..."

        # Update package list if not done recently
        if [ ! -f /var/lib/apt/periodic/update-success-stamp ] || \
           [ $(($(date +%s) - $(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null || echo 0))) -gt 3600 ]; then
            log "INFO" "Updating apt package list..."
            sudo apt-get update -qq 2>&1 | grep -v "Hit:" | grep -v "Get:" || true
        fi

        # Install fastfetch
        if sudo apt-get install -y fastfetch >/dev/null 2>&1; then
            log "SUCCESS" "✓ fastfetch installed via APT"
            return 0
        else
            log "WARNING" "APT installation failed, trying PPA..."

            # Add PPA for latest version
            if ! grep -q "fastfetch" /etc/apt/sources.list.d/* 2>/dev/null; then
                log "INFO" "Adding fastfetch PPA..."
                sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch >/dev/null 2>&1 || true
                sudo apt-get update -qq 2>&1 | grep -v "Hit:" | grep -v "Get:" || true
            fi

            if sudo apt-get install -y fastfetch >/dev/null 2>&1; then
                log "SUCCESS" "✓ fastfetch installed via PPA"
                return 0
            fi
        fi
    fi

    # Fallback: Download latest binary from GitHub releases
    log "WARNING" "APT not available, downloading binary from GitHub..."

    # Detect architecture
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        armv7l) arch="armhf" ;;
        *)
            handle_error "install-fastfetch" 1 "Unsupported architecture: $arch" \
                "Please install fastfetch manually from: https://github.com/fastfetch-cli/fastfetch"
            return 1
            ;;
    esac

    # Download latest release
    local download_url
    download_url=$(curl -fsSL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | \
        grep "browser_download_url.*linux-${arch}.deb" | \
        cut -d'"' -f4 | head -1)

    if [ -z "$download_url" ]; then
        handle_error "install-fastfetch" 1 "Failed to find download URL for architecture: $arch" \
            "Please install fastfetch manually from: https://github.com/fastfetch-cli/fastfetch"
        return 1
    fi

    log "INFO" "Downloading: $download_url"
    local temp_deb
    temp_deb=$(mktemp --suffix=.deb)

    if curl -fsSL -o "$temp_deb" "$download_url"; then
        log "INFO" "Installing downloaded package..."
        if sudo dpkg -i "$temp_deb" >/dev/null 2>&1; then
            rm -f "$temp_deb"
            log "SUCCESS" "✓ fastfetch installed via GitHub release"
            return 0
        else
            # Fix dependencies if needed
            sudo apt-get install -f -y >/dev/null 2>&1 || true
            rm -f "$temp_deb"

            if command_exists "fastfetch"; then
                log "SUCCESS" "✓ fastfetch installed (dependencies resolved)"
                return 0
            fi
        fi
    fi

    rm -f "$temp_deb"
    handle_error "install-fastfetch" 1 "Failed to install fastfetch" \
        "Please install manually from: https://github.com/fastfetch-cli/fastfetch"
    return 1
}

main "$@"
