#!/usr/bin/env bash
#
# lib/verification/checks/pre_install_checks.sh - Pre-installation validation checks
#
# Purpose: Validate system prerequisites before installation
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - check_sudo_access(): Verify sudo configuration
#   - check_disk_space(): Validate disk space requirements
#   - check_internet(): Verify internet connectivity
#   - check_required_commands(): Verify required tools
#   - pre_installation_health_check(): Run all pre-install checks
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_VERIFICATION_CHECKS_PRE_INSTALL_SH:-}" ]] && return 0
readonly _LIB_VERIFICATION_CHECKS_PRE_INSTALL_SH=1

# Module constants
readonly DISK_MIN_GB=10
readonly REQUIRED_COMMANDS=("curl" "wget" "git" "tar" "gzip" "jq" "bc")

# ============================================================================
# SUDO ACCESS CHECK
# ============================================================================

# Function: check_sudo_access
# Purpose: Verify sudo configuration (warning, not blocking)
# Args: None
# Returns:
#   0 = passwordless sudo, 1 = requires password
check_sudo_access() {
    echo "Checking sudo configuration..."

    if sudo -n true 2>/dev/null; then
        echo "PASS: Passwordless sudo configured"
        return 0
    else
        echo "WARN: Passwordless sudo NOT configured"
        echo "  Recommendation: Configure with 'sudo visudo'"
        echo "  Impact: Manual password entry required during installation"
        return 1
    fi
}

# ============================================================================
# DISK SPACE CHECK
# ============================================================================

# Function: check_disk_space
# Purpose: Validate available disk space meets requirements
# Args:
#   $1 - Minimum required GB (default: 10)
# Returns:
#   0 = sufficient space, 1 = insufficient space
# shellcheck disable=SC2120 # Function designed for external calls with optional args
check_disk_space() {
    local min_gb="${1:-$DISK_MIN_GB}"

    echo "Checking disk space..."

    local available_gb
    available_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')

    if [[ "$available_gb" -ge "$min_gb" ]]; then
        echo "PASS: Disk space: ${available_gb}GB available (>=${min_gb}GB required)"
        return 0
    else
        echo "FAIL: Insufficient disk space: ${available_gb}GB available (<${min_gb}GB required)"
        echo "  Run app audit for cleanup: ./scripts/app-audit.sh"
        return 1
    fi
}

# ============================================================================
# INTERNET CONNECTIVITY CHECK
# ============================================================================

# Function: check_internet
# Purpose: Verify internet connectivity
# Args: None
# Returns:
#   0 = connected, 1 = no connectivity
check_internet() {
    echo "Checking internet connectivity..."

    if ping -c 1 -W 5 github.com &>/dev/null; then
        echo "PASS: Internet connectivity: github.com reachable"
        return 0
    elif ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        echo "WARN: DNS resolution issues (IP reachable, hostname not)"
        return 0
    else
        echo "FAIL: No internet connectivity detected"
        echo "  Installation requires internet for package downloads"
        return 1
    fi
}

# ============================================================================
# REQUIRED COMMANDS CHECK
# ============================================================================

# Function: check_required_commands
# Purpose: Verify required commands are available
# Args: None
# Returns:
#   0 = all available, 1 = some missing
check_required_commands() {
    echo "Checking required commands..."

    local missing_commands=()

    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            echo "  PASS: $cmd"
        else
            echo "  FAIL: $cmd (missing)"
            missing_commands+=("$cmd")
        fi
    done

    if [[ ${#missing_commands[@]} -eq 0 ]]; then
        echo "PASS: All required commands available"
        return 0
    else
        echo "FAIL: Missing required commands: ${missing_commands[*]}"
        echo "  Install with: sudo apt install ${missing_commands[*]}"
        return 1
    fi
}

# ============================================================================
# ARCHITECTURE CHECK
# ============================================================================

# Function: check_architecture
# Purpose: Verify system architecture is supported
# Args: None
# Returns:
#   0 = supported, 1 = unsupported
check_architecture() {
    echo "Checking system architecture..."

    local arch
    arch=$(uname -m)

    case "$arch" in
        x86_64|amd64)
            echo "PASS: Architecture: $arch (supported)"
            return 0
            ;;
        aarch64|arm64)
            echo "PASS: Architecture: $arch (supported)"
            return 0
            ;;
        *)
            echo "WARN: Architecture: $arch (may have limited package availability)"
            return 0
            ;;
    esac
}

# ============================================================================
# OS VERSION CHECK
# ============================================================================

# Function: check_os_version
# Purpose: Verify Ubuntu version compatibility
# Args: None
# Returns:
#   0 = compatible, 1 = unknown
check_os_version() {
    echo "Checking Ubuntu version..."

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release

        if [[ "$ID" == "ubuntu" ]]; then
            echo "PASS: Ubuntu ${VERSION} detected"

            # Warn if not Ubuntu 25.10
            if [[ "$VERSION_ID" != "25.10" ]]; then
                echo "WARN: Tested on Ubuntu 25.10, you have ${VERSION_ID}"
                echo "  Installation may work but is not officially tested"
            fi
            return 0
        else
            echo "WARN: Non-Ubuntu system detected: $ID"
            echo "  This installation is designed for Ubuntu 25.10"
            return 0
        fi
    else
        echo "WARN: Cannot detect OS version (/etc/os-release missing)"
        return 0
    fi
}

# ============================================================================
# COMPREHENSIVE PRE-INSTALL CHECK
# ============================================================================

# Function: pre_installation_health_check
# Purpose: Run all pre-installation validation checks
# Args: None
# Returns:
#   0 = all critical checks passed, 1 = critical failures
pre_installation_health_check() {
    echo "Running pre-installation health checks..."
    echo

    local critical_failures=0
    local warnings=0

    # Check sudo (warning only)
    if ! check_sudo_access; then
        ((warnings++))
    fi
    echo

    # Check disk space (critical)
    if ! check_disk_space; then
        ((critical_failures++))
    fi
    echo

    # Check internet (critical)
    if ! check_internet; then
        ((critical_failures++))
    fi
    echo

    # Check required commands (critical)
    if ! check_required_commands; then
        ((critical_failures++))
    fi
    echo

    # Check architecture (warning only)
    if ! check_architecture; then
        ((warnings++))
    fi
    echo

    # Check OS version (warning only)
    if ! check_os_version; then
        ((warnings++))
    fi
    echo

    # Summary
    if [[ "$critical_failures" -eq 0 ]]; then
        if [[ "$warnings" -eq 0 ]]; then
            echo "========================================"
            echo "PASS: PRE-FLIGHT CHECK: ALL SYSTEMS GO"
            echo "========================================"
        else
            echo "========================================"
            echo "WARN: PRE-FLIGHT CHECK: ${warnings} WARNING(S)"
            echo "  Installation will proceed with warnings"
            echo "========================================"
        fi
        return 0
    else
        echo "========================================"
        echo "FAIL: PRE-FLIGHT CHECK: ${critical_failures} CRITICAL FAILURE(S)"
        echo "  Installation BLOCKED - fix issues above"
        echo "========================================"
        return 1
    fi
}
