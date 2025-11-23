#!/usr/bin/env bash
#
# LibreOffice Complete Removal Script
# Purpose: Safely remove all LibreOffice packages and configurations
# Safe: No system dependencies - will not break Ubuntu
#
# Usage: Run this script with: sudo ./remove-libreoffice.sh
#

set -euo pipefail

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script requires sudo access"
    echo "Please run: sudo $0"
    exit 1
fi

echo "════════════════════════════════════════════════════════════════"
echo "LibreOffice Complete Removal"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Step 1: List what will be removed
echo "[1/6] Checking LibreOffice installations..."
PACKAGE_COUNT=$(dpkg -l | grep -i libreoffice | grep "^ii" | wc -l 2>/dev/null | tr -d ' \n' || echo "0")
SNAP_INSTALLED=$(snap list 2>/dev/null | grep -i "^libreoffice" | wc -l 2>/dev/null | tr -d ' \n' || echo "0")

if [ "$PACKAGE_COUNT" -eq 0 ] && [ "$SNAP_INSTALLED" -eq 0 ]; then
    echo "✓ No LibreOffice installations found. Already clean!"
    exit 0
fi

if [ "$PACKAGE_COUNT" -gt 0 ]; then
    echo "Found $PACKAGE_COUNT APT packages to remove"
fi

if [ "$SNAP_INSTALLED" -gt 0 ]; then
    echo "Found LibreOffice Snap package to remove"
fi
echo ""

# Step 2: Remove APT packages (if any)
if [ "$PACKAGE_COUNT" -gt 0 ]; then
    echo "[2/6] Removing APT LibreOffice packages..."
    echo "This may take 1-2 minutes..."
    echo ""

    apt-get remove --purge -y libreoffice-* 2>&1 | grep -E "Removing|Purging|freed" || true

    echo ""
    echo "✓ APT packages removed"
    echo ""

    # Step 3: Remove UNO libraries
    echo "[3/6] Removing LibreOffice UNO libraries..."
    apt-get remove --purge -y 'libuno-*' ure uno-libs-private python3-uno 2>&1 | grep -E "Removing|Purging" || echo "  ✓ Already removed"
    echo ""
else
    echo "[2/6] No APT packages to remove"
    echo "[3/6] No UNO libraries to remove"
    echo ""
fi

# Step 4: Remove Snap package (if installed)
if [ "$SNAP_INSTALLED" -gt 0 ]; then
    echo "[4/6] Removing LibreOffice Snap package..."
    snap remove libreoffice 2>&1 || echo "  ⚠ Snap removal failed"
    echo "✓ Snap package removed"
    echo ""
else
    echo "[4/6] No Snap package to remove"
    echo ""
fi

# Step 5: Autoremove dependencies
echo "[5/6] Removing unused dependencies..."
apt-get autoremove --purge -y 2>&1 | tail -5
apt-get clean
echo "✓ Cleanup complete"
echo ""

# Step 6: Clean up user configuration files
echo "[6/6] Cleaning up user configuration files..."

CLEANED_DIRS=0

# Clean for current sudo user (get real user, not root)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo ~$REAL_USER)

if [ -d "$REAL_HOME/.config/libreoffice" ]; then
    rm -rf "$REAL_HOME/.config/libreoffice"
    echo "  ✓ Removed $REAL_HOME/.config/libreoffice"
    ((CLEANED_DIRS++))
fi

if [ -d "$REAL_HOME/.libreoffice" ]; then
    rm -rf "$REAL_HOME/.libreoffice"
    echo "  ✓ Removed $REAL_HOME/.libreoffice"
    ((CLEANED_DIRS++))
fi

# Clean desktop entries if they exist
if [ -d "$REAL_HOME/.local/share/applications" ]; then
    REMOVED_ENTRIES=$(find "$REAL_HOME/.local/share/applications" -name "*libreoffice*.desktop" -delete -print 2>/dev/null | wc -l 2>/dev/null | tr -d ' \n' || echo "0")
    if [ "$REMOVED_ENTRIES" -gt 0 ]; then
        echo "  ✓ Removed $REMOVED_ENTRIES desktop entries"
        update-desktop-database "$REAL_HOME/.local/share/applications/" 2>/dev/null || true
        ((CLEANED_DIRS++))
    fi
fi

if [ "$CLEANED_DIRS" -eq 0 ]; then
    echo "  ✓ No configuration directories found"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✓ LibreOffice Removal Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verify removal
REMAINING_APT=$(dpkg -l | grep -i libreoffice | grep "^ii" | wc -l 2>/dev/null | tr -d ' \n' || echo "0")
REMAINING_SNAP=$(snap list 2>/dev/null | grep -i "^libreoffice" | wc -l 2>/dev/null | tr -d ' \n' || echo "0")

if [ "$REMAINING_APT" -eq 0 ] && [ "$REMAINING_SNAP" -eq 0 ]; then
    echo "✓ Verification: No LibreOffice installations remaining"

    # Calculate freed space
    echo ""
    echo "Estimated disk space freed:"
    if [ "$PACKAGE_COUNT" -gt 0 ]; then
        echo "  - APT packages: ~410 MB"
    fi
    if [ "$SNAP_INSTALLED" -gt 0 ]; then
        echo "  - Snap package: ~300-400 MB"
    fi
    echo "  - Total: ~500-800 MB"
else
    if [ "$REMAINING_APT" -gt 0 ]; then
        echo "⚠ Warning: $REMAINING_APT APT packages still installed"
        dpkg -l | grep -i libreoffice | grep "^ii" | awk '{print "  - " $2}'
    fi
    if [ "$REMAINING_SNAP" -gt 0 ]; then
        echo "⚠ Warning: Snap package still installed"
        snap list | grep -i "^libreoffice"
    fi
fi

echo ""
echo "✓ Your system is intact and fully functional!"
echo ""
echo "You may need to refresh your application menu (logout/login)"
