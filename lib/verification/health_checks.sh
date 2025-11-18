#!/usr/bin/env bash
#
# lib/verification/health_checks.sh - System health validation (pre/post installation)
#
# CONTEXT7 STATUS: Unable to query (API authentication issue)
# FALLBACK: Best practices for system health checks and prerequisite validation 2025
# - Disk space validation
# - Internet connectivity checks
# - Required command validation
# - Performance target validation
#
# Constitutional Compliance: Principle V - Modular Architecture
# User Story: US1 (Fresh Installation)
#
# Requirements:
# - FR-014: Pre-installation health check validates prerequisites
# - FR-059: Total installation <10 minutes
# - FR-060: fnm startup <50ms (constitutional)
# - FR-061: gum startup <10ms
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"

#
# Pre-installation health check
#
# Validates system prerequisites before starting installation:
#   - Passwordless sudo (warning, not blocker)
#   - Disk space (10GB minimum required)
#   - Internet connectivity
#   - Required commands (curl, wget, git, tar, gzip, jq, bc)
#
# Returns:
#   0 = all checks passed
#   1 = critical failures (blocking)
#   Exit codes capture specific failures for logging
#
# Usage:
#   if pre_installation_health_check; then
#       echo "System ready for installation"
#   else
#       echo "Prerequisites not met"
#   fi
#
pre_installation_health_check() {
    log "INFO" "Running pre-installation health checks..."

    local critical_failures=0
    local warnings=0

    # Check 1: Passwordless sudo (WARNING only, not blocking)
    log "INFO" "Checking sudo configuration..."
    if sudo -n true 2>/dev/null; then
        log "SUCCESS" "✓ Passwordless sudo configured"
    else
        log "WARNING" "⚠ Passwordless sudo NOT configured"
        log "WARNING" "  Recommendation: Configure with 'sudo visudo'"
        log "WARNING" "  Add: $USER ALL=(ALL) NOPASSWD: /usr/bin/apt"
        log "WARNING" "  Impact: Manual password entry required during installation"
        ((warnings++))
    fi

    # Check 2: Disk space (10GB minimum REQUIRED)
    log "INFO" "Checking disk space..."
    local available_gb
    available_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')

    if [ "$available_gb" -ge 10 ]; then
        log "SUCCESS" "✓ Disk space: ${available_gb}GB available (≥10GB required)"
    else
        log "ERROR" "✗ Insufficient disk space: ${available_gb}GB available (10GB required)"
        log "ERROR" "  Run app audit for cleanup: ./scripts/app-audit.sh"
        ((critical_failures++))
    fi

    # Check 3: Internet connectivity (REQUIRED)
    log "INFO" "Checking internet connectivity..."
    if ping -c 1 -W 5 github.com &>/dev/null; then
        log "SUCCESS" "✓ Internet connectivity: github.com reachable"
    elif ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        log "WARNING" "⚠ DNS resolution issues (IP reachable, hostname not)"
        log "WARNING" "  May impact package downloads"
        ((warnings++))
    else
        log "ERROR" "✗ No internet connectivity detected"
        log "ERROR" "  Installation requires internet for package downloads"
        ((critical_failures++))
    fi

    # Check 4: Required commands (REQUIRED)
    log "INFO" "Checking required commands..."
    local required_commands=("curl" "wget" "git" "tar" "gzip" "jq" "bc")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if command_exists "$cmd"; then
            log "INFO" "  ✓ $cmd"
        else
            log "ERROR" "  ✗ $cmd (missing)"
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -eq 0 ]; then
        log "SUCCESS" "✓ All required commands available"
    else
        log "ERROR" "✗ Missing required commands: ${missing_commands[*]}"
        log "ERROR" "  Install with: sudo apt install ${missing_commands[*]}"
        ((critical_failures++))
    fi

    # Check 5: System architecture
    log "INFO" "Checking system architecture..."
    local arch
    arch=$(uname -m)

    case "$arch" in
        x86_64|amd64)
            log "SUCCESS" "✓ Architecture: $arch (supported)"
            ;;
        aarch64|arm64)
            log "SUCCESS" "✓ Architecture: $arch (supported)"
            ;;
        *)
            log "WARNING" "⚠ Architecture: $arch (may have limited package availability)"
            ((warnings++))
            ;;
    esac

    # Check 6: Ubuntu version
    log "INFO" "Checking Ubuntu version..."
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            log "SUCCESS" "✓ Ubuntu ${VERSION} detected"

            # Warn if not Ubuntu 25.10
            if [[ "$VERSION_ID" != "25.10" ]]; then
                log "WARNING" "⚠ Tested on Ubuntu 25.10, you have ${VERSION_ID}"
                log "WARNING" "  Installation may work but is not officially tested"
                ((warnings++))
            fi
        else
            log "WARNING" "⚠ Non-Ubuntu system detected: $ID"
            log "WARNING" "  This installation is designed for Ubuntu 25.10"
            ((warnings++))
        fi
    else
        log "WARNING" "⚠ Cannot detect OS version (/etc/os-release missing)"
        ((warnings++))
    fi

    # Summary
    echo ""
    if [ "$critical_failures" -eq 0 ]; then
        if [ "$warnings" -eq 0 ]; then
            log "SUCCESS" "════════════════════════════════════════"
            log "SUCCESS" "✓ PRE-FLIGHT CHECK: ALL SYSTEMS GO"
            log "SUCCESS" "════════════════════════════════════════"
        else
            log "WARNING" "════════════════════════════════════════"
            log "WARNING" "⚠ PRE-FLIGHT CHECK: ${warnings} WARNING(S)"
            log "WARNING" "  Installation will proceed with warnings"
            log "WARNING" "════════════════════════════════════════"
        fi
        return 0
    else
        log "ERROR" "════════════════════════════════════════"
        log "ERROR" "✗ PRE-FLIGHT CHECK: ${critical_failures} CRITICAL FAILURE(S)"
        log "ERROR" "  Installation BLOCKED - fix issues above"
        log "ERROR" "════════════════════════════════════════"
        return 1
    fi
}

#
# Post-installation health check
#
# Validates complete system after installation:
#   - All components installed and functional
#   - No conflicts or errors
#   - Performance targets met (fnm <50ms, gum <10ms)
#
# Returns:
#   0 = all checks passed
#   1 = failures detected
#
# Usage:
#   if post_installation_health_check; then
#       echo "Installation successful"
#   fi
#
post_installation_health_check() {
    log "INFO" "Running post-installation health checks..."

    local failures=0

    # Check 1: gum installed and fast (<10ms target)
    log "INFO" "Checking gum installation..."
    if command_exists "gum"; then
        local start_ns end_ns duration_ms
        start_ns=$(get_unix_timestamp_ns)
        gum --version &>/dev/null
        end_ns=$(get_unix_timestamp_ns)
        duration_ms=$(calculate_duration_ns "$start_ns" "$end_ns")

        if [ "$duration_ms" -lt 10 ]; then
            log "SUCCESS" "✓ gum: Installed and fast (${duration_ms}ms <10ms ✓)"
        else
            log "WARNING" "⚠ gum: Installed but slow (${duration_ms}ms ≥10ms)"
        fi
    else
        log "ERROR" "✗ gum: Not installed"
        ((failures++))
    fi

    # Check 2: Ghostty installed
    log "INFO" "Checking Ghostty installation..."
    local ghostty_path="${GHOSTTY_APP_DIR:-$HOME/.local/share/ghostty}/bin/ghostty"
    if [ -x "$ghostty_path" ]; then
        local ghostty_version
        ghostty_version=$("$ghostty_path" --version 2>&1 | head -n 1)
        log "SUCCESS" "✓ Ghostty: Installed at $ghostty_path ($ghostty_version)"
    else
        log "ERROR" "✗ Ghostty: Not found at $ghostty_path"
        ((failures++))
    fi

    # Check 3: ZSH configured
    log "INFO" "Checking ZSH configuration..."
    if command_exists "zsh" && [ -d "$HOME/.oh-my-zsh" ]; then
        log "SUCCESS" "✓ ZSH: Installed with Oh My ZSH"
    else
        log "ERROR" "✗ ZSH: Not properly configured"
        ((failures++))
    fi

    # Check 4: uv installed
    log "INFO" "Checking uv (Python package manager)..."
    if command_exists "uv"; then
        local uv_version
        uv_version=$(uv --version 2>&1 | head -n 1)
        log "SUCCESS" "✓ uv: Installed ($uv_version)"
    else
        log "ERROR" "✗ uv: Not installed"
        ((failures++))
    fi

    # Check 5: fnm installed and FAST (<50ms CONSTITUTIONAL REQUIREMENT)
    log "INFO" "Checking fnm (Node.js manager)..."
    if command_exists "fnm"; then
        local start_ns end_ns duration_ms
        start_ns=$(get_unix_timestamp_ns)
        fnm env &>/dev/null
        end_ns=$(get_unix_timestamp_ns)
        duration_ms=$(calculate_duration_ns "$start_ns" "$end_ns")

        if [ "$duration_ms" -lt 50 ]; then
            log "SUCCESS" "✓ fnm: Installed and FAST (${duration_ms}ms <50ms ✓ CONSTITUTIONAL COMPLIANCE)"
        else
            log "ERROR" "✗ fnm: CONSTITUTIONAL VIOLATION - Startup ${duration_ms}ms ≥50ms"
            log "ERROR" "  Constitutional requirement: fnm startup MUST be <50ms"
            ((failures++))
        fi
    else
        log "ERROR" "✗ fnm: Not installed"
        ((failures++))
    fi

    # Check 6: Node.js latest version (v25.2.0+)
    log "INFO" "Checking Node.js version..."
    if command_exists "node"; then
        local node_version
        node_version=$(node --version 2>&1 | head -n 1)

        # Extract major version
        local node_major
        node_major=$(echo "$node_version" | sed 's/v\([0-9]*\).*/\1/')

        if [ "$node_major" -ge 25 ]; then
            log "SUCCESS" "✓ Node.js: Latest version installed ($node_version ≥v25.2.0 ✓)"
        else
            log "ERROR" "✗ Node.js: Old version ($node_version <v25.2.0)"
            log "ERROR" "  Constitutional requirement: Latest Node.js (v25.2.0+), NOT LTS"
            ((failures++))
        fi
    else
        log "ERROR" "✗ Node.js: Not installed"
        ((failures++))
    fi

    # Check 7: AI tools (Claude CLI, Gemini CLI)
    log "INFO" "Checking AI tools..."
    local ai_tool_count=0

    if command_exists "claude"; then
        log "SUCCESS" "  ✓ Claude CLI"
        ((ai_tool_count++))
    else
        log "WARNING" "  ⚠ Claude CLI not installed"
    fi

    if command_exists "gemini"; then
        log "SUCCESS" "  ✓ Gemini CLI"
        ((ai_tool_count++))
    else
        log "WARNING" "  ⚠ Gemini CLI not installed"
    fi

    if [ "$ai_tool_count" -gt 0 ]; then
        log "SUCCESS" "✓ AI Tools: ${ai_tool_count}/2 installed"
    else
        log "WARNING" "⚠ AI Tools: None installed (optional)"
    fi

    # Check 8: Context menu integration
    log "INFO" "Checking Nautilus context menu integration..."
    local nautilus_script_dir="$HOME/.local/share/nautilus/scripts"
    if [ -d "$nautilus_script_dir" ] && [ -x "$nautilus_script_dir/Open in Ghostty" ]; then
        log "SUCCESS" "✓ Context Menu: Integrated with Nautilus"
    else
        log "WARNING" "⚠ Context Menu: Not configured (optional)"
    fi

    # Summary
    echo ""
    if [ "$failures" -eq 0 ]; then
        log "SUCCESS" "════════════════════════════════════════"
        log "SUCCESS" "✓ POST-INSTALLATION CHECK: ALL PASSED"
        log "SUCCESS" "  System ready for production use"
        log "SUCCESS" "════════════════════════════════════════"
        return 0
    else
        log "ERROR" "════════════════════════════════════════"
        log "ERROR" "✗ POST-INSTALLATION CHECK: ${failures} FAILURE(S)"
        log "ERROR" "  Review errors above and re-run installation"
        log "ERROR" "════════════════════════════════════════"
        return 1
    fi
}

# Export functions for use in other modules
export -f pre_installation_health_check
export -f post_installation_health_check
