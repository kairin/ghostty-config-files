#!/usr/bin/env bash
# Detect network wait service issues
# Finds unnecessary network wait services that slow down boot

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/issue_registry.sh"

# Check if system uses NetworkManager (desktop default) vs systemd-networkd
uses_networkmanager() {
    systemctl is-active NetworkManager.service &>/dev/null
}

uses_systemd_networkd() {
    systemctl is-active systemd-networkd.service &>/dev/null
}

# Check if there are network mounts that require waiting
has_network_mounts() {
    grep -qE "^[^#].*(nfs|cifs|sshfs|smb)" /etc/fstab 2>/dev/null
}

# Check number of services requiring network-online.target
count_network_dependencies() {
    systemctl list-dependencies network-online.target --reverse 2>/dev/null | grep -c "●" || echo 0
}

# Check systemd-networkd-wait-online issues
check_systemd_networkd_wait() {
    local service="systemd-networkd-wait-online.service"

    # Skip if already masked or disabled
    local status
    status=$(systemctl is-enabled "$service" 2>/dev/null) || return 0
    [[ "$status" == "masked" || "$status" == "disabled" ]] && return 0

    # If using NetworkManager (not systemd-networkd), this service is unnecessary
    if uses_networkmanager && ! uses_systemd_networkd; then
        # Check if it's actually causing issues (timing out or failed)
        if systemctl is-failed "$service" &>/dev/null || \
           journalctl -b -u "$service" --no-pager 2>/dev/null | grep -q "Timeout"; then
            format_issue \
                "$TYPE_NETWORK_WAIT" \
                "$SEVERITY_MODERATE" \
                "systemd-networkd-wait-online" \
                "Enabled but system uses NetworkManager (times out every boot)" \
                "YES" \
                "sudo systemctl disable $service; sudo systemctl mask $service"
        fi
    fi
}

# Check NetworkManager-wait-online issues
check_nm_wait_online() {
    local service="NetworkManager-wait-online.service"

    # Skip if not enabled
    systemctl is-enabled "$service" &>/dev/null || return 0

    # Get boot time for this service
    local wait_time
    wait_time=$(systemd-analyze blame 2>/dev/null | grep "$service" | awk '{print $1}' | sed 's/s$//; s/ms$//' | head -1) || return 0

    [[ -z "$wait_time" ]] && return 0

    # Convert to seconds if in milliseconds
    if [[ "$wait_time" == *"m"* ]]; then
        # It's in minutes:seconds format
        wait_time=$(echo "$wait_time" | awk -F'm' '{print $1*60 + $2}')
    fi

    # Check if it's taking more than 10 seconds
    local threshold=10
    if (( $(echo "$wait_time > $threshold" | bc -l 2>/dev/null || echo 0) )); then
        # Check if we actually need it
        if ! has_network_mounts; then
            local deps
            deps=$(count_network_dependencies)

            # If few dependencies and no network mounts, it's probably unnecessary
            if [[ "$deps" -lt 5 ]]; then
                format_issue \
                    "$TYPE_NETWORK_WAIT" \
                    "$SEVERITY_MODERATE" \
                    "NetworkManager-wait-online" \
                    "Takes ${wait_time}s at boot but no network mounts or critical dependencies found" \
                    "YES" \
                    "sudo systemctl disable $service"
            fi
        fi
    fi
}

# Main execution
check_systemd_networkd_wait
check_nm_wait_online
