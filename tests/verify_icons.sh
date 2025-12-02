#!/usr/bin/env bash
#
# Icon Cache Health Check with Auto-Fix
# Verifies icon infrastructure and cache validity to prevent broken system icons
#
# Usage:
#   ./verify_icons.sh           # Check only (report issues)
#   ./verify_icons.sh --fix     # Check and auto-fix issues
#
set -euo pipefail

# Parse arguments
AUTO_FIX=0
if [[ "${1:-}" == "--fix" ]]; then
    AUTO_FIX=1
fi

ISSUES_FOUND=0

echo "=========================================="
echo "Icon Cache Health Check"
echo "=========================================="
echo ""

# =============================================================================
# Check index.theme existence (CRITICAL - required for GTK icon resolution)
# =============================================================================
check_index_theme() {
    local icon_dir="$1"
    local label="$2"

    echo "Checking $label index.theme..."

    if [ ! -d "$icon_dir" ]; then
        echo "  - Directory does not exist (skipping)"
        return 0
    fi

    if [ -f "$icon_dir/index.theme" ]; then
        echo "  OK: index.theme exists"
        return 0
    else
        echo "  CRITICAL: index.theme MISSING in $icon_dir"
        echo "           GTK cannot resolve icons without this file!"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    fi
}

# =============================================================================
# Check icon cache validity (size-based detection)
# =============================================================================
check_cache_validity() {
    local icon_dir="$1"
    local label="$2"
    local min_valid_size=1024  # Valid cache should be > 1KB (invalid is ~496 bytes)

    echo "Checking $label icon cache..."

    if [ ! -d "$icon_dir" ]; then
        echo "  - Directory does not exist (skipping)"
        return 0
    fi

    local cache_file="$icon_dir/icon-theme.cache"

    if [ ! -f "$cache_file" ]; then
        echo "  WARNING: Icon cache does not exist"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    fi

    local cache_size
    cache_size=$(stat -c%s "$cache_file" 2>/dev/null || stat -f%z "$cache_file" 2>/dev/null || echo "0")

    if [ "$cache_size" -lt "$min_valid_size" ]; then
        echo "  CRITICAL: Icon cache INVALID (${cache_size} bytes, expected >1KB)"
        echo "           This is the root cause of broken icons!"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    fi

    echo "  OK: Icon cache valid (${cache_size} bytes)"
    return 0
}

# =============================================================================
# Check icon files exist
# =============================================================================
check_ghostty_icons() {
    echo "Checking Ghostty icon files..."

    # Check user directory
    local user_dir="$HOME/.local/share/icons/hicolor"
    local found_user=0
    for size in 512x512 256x256 128x128; do
        if [ -f "$user_dir/$size/apps/com.mitchellh.ghostty.png" ]; then
            found_user=1
            break
        fi
    done

    # Check system directory
    local system_dir="/usr/local/share/icons/hicolor"
    local found_system=0
    for size in 512x512 256x256 128x128 32x32 16x16; do
        if [ -f "$system_dir/$size/apps/ghostty.png" ]; then
            found_system=1
            break
        fi
    done

    if [ $found_user -eq 1 ]; then
        echo "  OK: Ghostty icon found in ~/.local/share/icons/hicolor/"
    elif [ $found_system -eq 1 ]; then
        echo "  OK: Ghostty icon found in /usr/local/share/icons/hicolor/"
    else
        echo "  WARNING: Ghostty icon NOT found in expected locations"
    fi

    # Check desktop entry
    if grep -q "Icon=com.mitchellh.ghostty" "$HOME/.local/share/applications/ghostty.desktop" 2>/dev/null || \
       grep -q "Icon=ghostty" "/usr/local/share/applications/ghostty.desktop" 2>/dev/null; then
        echo "  OK: Ghostty desktop entry found"
    else
        echo "  INFO: Ghostty desktop entry not found (may be installed elsewhere)"
    fi
}

check_feh_icons() {
    echo "Checking Feh icon files..."

    local user_dir="$HOME/.local/share/icons/hicolor"
    if [ -f "$user_dir/48x48/apps/feh.png" ] || [ -f "$user_dir/scalable/apps/feh.svg" ]; then
        echo "  OK: Feh icon found in ~/.local/share/icons/hicolor/"
    else
        echo "  INFO: Feh icon not found (may not be installed)"
    fi

    if grep -q "Icon=feh" "$HOME/.local/share/applications/feh.desktop" 2>/dev/null; then
        echo "  OK: Feh desktop entry uses correct icon name"
    else
        echo "  INFO: Feh desktop entry not found"
    fi
}

# =============================================================================
# Auto-fix function
# =============================================================================
auto_fix_user_icons() {
    local icon_dir="$HOME/.local/share/icons/hicolor"
    local fixes_applied=0

    echo ""
    echo "=========================================="
    echo "Auto-Remediation (User Icons)"
    echo "=========================================="

    # Ensure directory exists
    mkdir -p "$icon_dir"

    # Fix 1: Copy missing index.theme
    if [ ! -f "$icon_dir/index.theme" ]; then
        if [ -f "/usr/share/icons/hicolor/index.theme" ]; then
            cp /usr/share/icons/hicolor/index.theme "$icon_dir/"
            echo "  FIXED: Copied index.theme from system"
            fixes_applied=$((fixes_applied + 1))
        else
            echo "  ERROR: Cannot fix - system index.theme not found at /usr/share/icons/hicolor/"
            return 1
        fi
    fi

    # Fix 2: Rebuild icon cache
    if command -v gtk-update-icon-cache &> /dev/null; then
        if gtk-update-icon-cache --force "$icon_dir" 2>/dev/null; then
            echo "  FIXED: Rebuilt icon cache"
            fixes_applied=$((fixes_applied + 1))
        else
            echo "  WARNING: gtk-update-icon-cache returned non-zero (may be normal)"
        fi
    else
        echo "  WARNING: gtk-update-icon-cache not available"
    fi

    echo ""
    if [ $fixes_applied -gt 0 ]; then
        echo "Applied $fixes_applied fix(es) to user icon directory."
        echo "NOTE: Log out and back in for changes to take effect."
    fi
    return 0
}

auto_fix_system_icons() {
    local icon_dir="/usr/local/share/icons/hicolor"
    local fixes_applied=0

    echo ""
    echo "=========================================="
    echo "Auto-Remediation (System Icons - requires sudo)"
    echo "=========================================="

    if [ ! -d "$icon_dir" ]; then
        echo "  INFO: System icon directory does not exist - skipping"
        return 0
    fi

    # Fix 1: Copy missing index.theme
    if [ ! -f "$icon_dir/index.theme" ]; then
        if [ -f "/usr/share/icons/hicolor/index.theme" ]; then
            if sudo cp /usr/share/icons/hicolor/index.theme "$icon_dir/"; then
                echo "  FIXED: Copied index.theme from system"
                fixes_applied=$((fixes_applied + 1))
            else
                echo "  ERROR: Failed to copy index.theme (sudo required)"
                return 1
            fi
        else
            echo "  ERROR: Cannot fix - system index.theme not found"
            return 1
        fi
    fi

    # Fix 2: Rebuild icon cache
    if command -v gtk-update-icon-cache &> /dev/null; then
        if sudo gtk-update-icon-cache --force "$icon_dir" 2>/dev/null; then
            echo "  FIXED: Rebuilt system icon cache"
            fixes_applied=$((fixes_applied + 1))
        else
            echo "  WARNING: gtk-update-icon-cache returned non-zero"
        fi
    fi

    echo ""
    if [ $fixes_applied -gt 0 ]; then
        echo "Applied $fixes_applied fix(es) to system icon directory."
    fi
    return 0
}

# =============================================================================
# Main Execution
# =============================================================================

# Check user icon directory
echo "--- User Icon Directory ---"
check_index_theme "$HOME/.local/share/icons/hicolor" "user" || true
check_cache_validity "$HOME/.local/share/icons/hicolor" "user" || true
echo ""

# Check system icon directory (if it exists)
if [ -d "/usr/local/share/icons/hicolor" ]; then
    echo "--- System Icon Directory ---"
    check_index_theme "/usr/local/share/icons/hicolor" "system" || true
    check_cache_validity "/usr/local/share/icons/hicolor" "system" || true
    echo ""
fi

# Check icon files
echo "--- Icon Files ---"
check_ghostty_icons
check_feh_icons
echo ""

# Summary and action
echo "=========================================="

if [ $ISSUES_FOUND -gt 0 ]; then
    echo "RESULT: $ISSUES_FOUND CRITICAL ISSUE(S) FOUND"
    echo ""

    if [ $AUTO_FIX -eq 1 ]; then
        auto_fix_user_icons || true
        auto_fix_system_icons || true
        echo ""
        echo "Auto-fix complete. Re-run this script to verify."
    else
        echo "To auto-fix, run:"
        echo "  $0 --fix"
        echo ""
        echo "Manual fix:"
        echo "  1. cp /usr/share/icons/hicolor/index.theme ~/.local/share/icons/hicolor/"
        echo "  2. gtk-update-icon-cache --force ~/.local/share/icons/hicolor/"
        echo "  3. Log out and back in"
    fi
    exit 1
else
    echo "RESULT: ALL CHECKS PASSED"
    echo ""
    echo "Icon infrastructure is healthy."
    exit 0
fi
