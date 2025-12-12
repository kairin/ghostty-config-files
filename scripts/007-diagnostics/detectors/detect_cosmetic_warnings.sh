#!/usr/bin/env bash
# Detect cosmetic/informational warnings
# Identifies known harmless warnings that don't require fixes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/issue_registry.sh"

# Track reported issues to avoid duplicates
declare -A SEEN=()

report_cosmetic() {
    local name="$1"
    local description="$2"

    # Skip if already reported
    [[ -n "${SEEN[$name]:-}" ]] && return 0
    SEEN["$name"]=1

    format_issue \
        "$TYPE_COSMETIC" \
        "$SEVERITY_LOW" \
        "$name" \
        "$description" \
        "NO" \
        "No action needed"
}

# Use a temp file to avoid SIGPIPE issues with pipefail and grep -q
TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

journalctl -b --no-pager 2>/dev/null > "$TMPFILE" || true

# ALSA udev rules GOTO label issue (Ubuntu bug #2105475)
if grep -q "GOTO.*has no matching label" "$TMPFILE"; then
    report_cosmetic "alsa-udev-rules" "ALSA GOTO label missing - Known Ubuntu packaging bug (#2105475)"
fi

# GNOME Keyring PAM timing issue
if grep -q "unable to locate daemon control file" "$TMPFILE"; then
    report_cosmetic "gnome-keyring-pam" "Keyring PAM timing issue - Normal startup race condition"
fi

# SCSI loop device warnings (normal for snap)
if grep -q "SCSI device.*has no device ID" "$TMPFILE"; then
    report_cosmetic "scsi-loop-devices" "SCSI loop device warnings - Normal for snap packages"
fi

# SATA port warnings (empty ports on motherboard)
if grep -q "failed to resume link.*SControl" "$TMPFILE"; then
    report_cosmetic "sata-empty-ports" "SATA resume warnings - Empty ports on motherboard"
fi

# Kernel taint from proprietary drivers
if grep -q "loading out-of-tree module taints kernel" "$TMPFILE"; then
    report_cosmetic "kernel-taint-drivers" "Kernel taint from proprietary drivers (NVIDIA/etc)"
fi

# Bluetooth HCI command limitation
if grep -q "HCI.*command is advertised.*not supported" "$TMPFILE"; then
    report_cosmetic "bluetooth-hci-limit" "Bluetooth HCI command limitation - Minor driver issue"
fi

# Snap service desktop integration (usually race condition, not harmful)
if grep -q "snap.*desktop.*integration.*Failed" "$TMPFILE"; then
    report_cosmetic "snap-desktop-integration" "Snap desktop integration race condition - Normal on boot"
fi

# ModemManager port probe warnings (normal for WiFi adapters)
if grep -q "ModemManager.*Missing port probe" "$TMPFILE"; then
    report_cosmetic "modemmanager-wifi" "ModemManager WiFi adapter probe - Normal behavior"
fi
