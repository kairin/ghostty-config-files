#!/usr/bin/env bash
#
# lib/tasks/nodejs_fnm.sh - Node.js + fnm (Fast Node Manager) installation
#
# CONTEXT7 STATUS: API authentication failed (invalid key)
# FALLBACK STRATEGY: Constitutional compliance from CLAUDE.md/AGENTS.MD
# - fnm EXCLUSIVE (prohibit nvm/n/asdf per constitutional requirement)
# - Node.js LATEST v25.2.0+ (NOT LTS - constitutional requirement)
# - fnm startup <50ms (CRITICAL constitutional requirement - AGENTS.md line 184)
# - XDG-compliant installation (~/.local/share/fnm)
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - CRITICAL: fnm exclusive (FR-034-035) - NO nvm/n/asdf allowed
# - CRITICAL: fnm startup MUST be <50ms (AGENTS.md constitutional requirement)
# - CRITICAL: Node.js latest v25.2.0+ (NOT LTS)
# - XDG Base Directory compliance
# - Auto-switching on directory change (.node-version/.nvmrc detection)
#
# User Stories: US1 (Fresh Installation), US3 (Re-run Safety), US5 (Best Practices)
#
# Requirements:
# - FR-034: fnm exclusive (prohibit nvm/n/asdf)
# - FR-035: fnm startup <50ms (CONSTITUTIONAL REQUIREMENT)
# - FR-038: Node.js latest v25.2.0+ (NOT LTS)
# - FR-053: Idempotency (skip if already installed)
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${NODEJS_FNM_SH_LOADED:-}" ] || return 0
NODEJS_FNM_SH_LOADED=1

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/state.sh"
source "${SCRIPT_DIR}/../core/errors.sh"
source "${SCRIPT_DIR}/../verification/duplicate_detection.sh"
source "${SCRIPT_DIR}/../verification/unit_tests.sh"

# Installation constants
readonly FNM_INSTALL_URL="https://fnm.vercel.app/install"
readonly FNM_DIR="${HOME}/.local/share/fnm"
readonly FNM_BINARY="${FNM_DIR}/fnm"
readonly NODE_LATEST_VERSION="latest"  # Constitutional: LATEST, not LTS
readonly FNM_STARTUP_THRESHOLD_MS=50  # CRITICAL CONSTITUTIONAL REQUIREMENT

# Conflicting version managers (constitutional prohibition)
readonly NODEJS_CONFLICTING_MANAGERS=(
    "nvm"
    "n"
    "asdf"
    "nodenv"
)

#
# Check for conflicting Node.js version managers
#
# Returns:
#   0 = no conflicts
#   1 = conflicts detected (warnings logged)
#
check_conflicting_version_managers() {
    log "INFO" "Checking for conflicting version managers..."

    local conflicts_found=0

    for manager in "${NODEJS_CONFLICTING_MANAGERS[@]}"; do
        if command_exists "$manager"; then
            log "WARNING" "  ⚠ Conflicting version manager detected: $manager"
            log "WARNING" "    Constitutional requirement: fnm EXCLUSIVE"
            log "WARNING" "    Recommendation: Remove $manager to avoid conflicts"
            conflicts_found=1
        fi
    done

    # Check for nvm directory (may exist even if command doesn't)
    if [ -d "${HOME}/.nvm" ]; then
        log "WARNING" "  ⚠ nvm directory detected: ${HOME}/.nvm"
        log "WARNING" "    Recommendation: Remove to avoid conflicts"
        conflicts_found=1
    fi

    if [ $conflicts_found -eq 0 ]; then
        log "SUCCESS" "✓ No conflicting version managers detected"
    else
        log "INFO" ""
        log "INFO" "Constitutional Compliance Note:"
        log "INFO" "  - fnm is the EXCLUSIVE Node.js version manager"
        log "INFO" "  - nvm/n/asdf usage is PROHIBITED"
        log "INFO" "  - fnm is 40x faster than nvm (<50ms startup required)"
        log "INFO" ""
    fi

    return 0  # Non-blocking (warnings only)
}

#
# Install fnm (Fast Node Manager)
#
# Uses official fnm installation script
#
# Returns:
#   0 = success
#   1 = failure
#
install_fnm() {
    log "INFO" "Installing fnm (Fast Node Manager)..."

    # Download and run official installer
    if ! curl -fsSL "$FNM_INSTALL_URL" | bash -s -- --install-dir "$FNM_DIR" --skip-shell 2>&1 | tee -a "$(get_log_file)"; then
        handle_error "install-fnm" 1 "fnm installation failed" \
            "Check internet connection" \
            "Verify access: curl -I $FNM_INSTALL_URL" \
            "Try manual installation: https://github.com/Schniz/fnm"
        return 1
    fi

    # Verify binary exists
    if [ ! -f "$FNM_BINARY" ]; then
        handle_error "install-fnm" 2 "fnm binary not found after installation" \
            "Expected location: $FNM_BINARY" \
            "Check installation logs" \
            "Verify write permissions to $FNM_DIR"
        return 1
    fi

    # Make executable
    chmod +x "$FNM_BINARY"

    log "SUCCESS" "✓ fnm installed to $FNM_BINARY"
    return 0
}

#
# Configure fnm shell integration
#
# Adds fnm to PATH and enables auto-switching
#
configure_fnm_shell_integration() {
    log "INFO" "Configuring fnm shell integration..."

    for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q "fnm env" "$rc_file" 2>/dev/null; then
                echo "" >> "$rc_file"
                echo "# fnm (Fast Node Manager) - Constitutional Requirement: <50ms startup" >> "$rc_file"
                echo "export PATH=\"${FNM_DIR}:\$PATH\"" >> "$rc_file"
                echo 'eval "$(fnm env --use-on-cd)"' >> "$rc_file"
                log "INFO" "  ✓ Added fnm integration to $rc_file"
            else
                log "INFO" "  ↷ fnm already configured in $rc_file"
            fi
        fi
    done

    # Source fnm for current session
    export PATH="${FNM_DIR}:$PATH"
    if command_exists "fnm"; then
        eval "$(fnm env --use-on-cd)" 2>/dev/null || true
        log "SUCCESS" "✓ fnm shell integration configured"
    else
        log "WARNING" "⚠ fnm not available in PATH after configuration"
        return 1
    fi

    return 0
}

#
# Install Node.js latest version (NOT LTS)
#
# Constitutional requirement: Latest v25.2.0+, NOT LTS
#
# Returns:
#   0 = success
#   1 = failure
#
install_nodejs_latest() {
    log "INFO" "Installing Node.js latest version (constitutional: NOT LTS)..."

    # Ensure fnm is in PATH
    export PATH="${FNM_DIR}:$PATH"
    eval "$(fnm env --use-on-cd)" 2>/dev/null || true

    # Install latest Node.js
    if ! fnm install "$NODE_LATEST_VERSION" 2>&1 | tee -a "$(get_log_file)"; then
        handle_error "install-fnm" 3 "Failed to install Node.js latest" \
            "Check fnm installation" \
            "Try: fnm install --lts (if latest fails)" \
            "Verify internet connection"
        return 1
    fi

    # Set latest as default
    if ! fnm default "$NODE_LATEST_VERSION" 2>&1 | tee -a "$(get_log_file)"; then
        handle_error "install-fnm" 4 "Failed to set Node.js latest as default" \
            "Check fnm installation" \
            "Try: fnm use latest"
        return 1
    fi

    # Verify Node.js version
    eval "$(fnm env --use-on-cd)" 2>/dev/null || true
    local node_version
    node_version=$(node --version 2>/dev/null || echo "unknown")

    log "SUCCESS" "✓ Node.js latest installed: $node_version"

    # Verify constitutional compliance (v25.2.0+)
    local major_version
    major_version=$(echo "$node_version" | sed 's/v//' | cut -d. -f1)

    if [ "$major_version" -lt 25 ]; then
        log "WARNING" "⚠ Node.js version $node_version is below constitutional minimum v25.2.0"
        log "WARNING" "  This may indicate fnm installed LTS instead of latest"
        log "WARNING" "  Constitutional requirement: Latest Node.js (v25.2.0+)"
    else
        log "SUCCESS" "✓ Constitutional compliance: Node.js $node_version (≥v25.2.0 ✓)"
    fi

    return 0
}

#
# Validate fnm performance (CRITICAL CONSTITUTIONAL REQUIREMENT)
#
# fnm startup MUST be <50ms (AGENTS.md line 184)
#
# Returns:
#   0 = success (<50ms)
#   1 = failure (≥50ms CONSTITUTIONAL VIOLATION)
#
validate_fnm_performance() {
    log "INFO" "Validating fnm performance (CONSTITUTIONAL REQUIREMENT: <50ms)..."

    # Ensure fnm is in PATH
    export PATH="${FNM_DIR}:$PATH"

    if ! command_exists "fnm"; then
        log "ERROR" "✗ fnm not available for performance validation"
        return 1
    fi

    # Measure fnm startup time with nanosecond precision
    local start_ns end_ns duration_ns duration_ms

    start_ns=$(date +%s%N)
    fnm env > /dev/null 2>&1
    end_ns=$(date +%s%N)

    duration_ns=$((end_ns - start_ns))
    duration_ms=$((duration_ns / 1000000))  # Convert to milliseconds

    log "INFO" "  fnm startup time: ${duration_ms}ms"

    # CRITICAL: Constitutional requirement check
    if [ "$duration_ms" -ge "$FNM_STARTUP_THRESHOLD_MS" ]; then
        log "ERROR" "✗ CONSTITUTIONAL VIOLATION: fnm startup ${duration_ms}ms ≥ ${FNM_STARTUP_THRESHOLD_MS}ms"
        log "ERROR" "  AGENTS.md line 184: fnm startup MUST be <50ms"
        log "ERROR" "  This is a BLOCKING issue - performance target not met"
        log "ERROR" ""
        log "ERROR" "Possible causes:"
        log "ERROR" "  1. System performance issue (slow disk I/O)"
        log "ERROR" "  2. fnm misconfiguration"
        log "ERROR" "  3. Conflicting version managers interfering"
        log "ERROR" ""
        log "ERROR" "Recommended actions:"
        log "ERROR" "  1. Check system load: top, iotop"
        log "ERROR" "  2. Remove conflicting managers: rm -rf ~/.nvm"
        log "ERROR" "  3. Reinstall fnm: curl -fsSL https://fnm.vercel.app/install | bash"
        return 1
    fi

    log "SUCCESS" "✓ Constitutional compliance: fnm startup ${duration_ms}ms (<${FNM_STARTUP_THRESHOLD_MS}ms ✓)"
    return 0
}

#
# Install Node.js + fnm
#
# Process:
#   1. Check duplicate detection (skip if already installed)
#   2. Check for conflicting version managers (warn if detected)
#   3. Install fnm via official installer
#   4. Configure shell integration (auto-switching enabled)
#   5. Install Node.js latest (NOT LTS - constitutional requirement)
#   6. Verify fnm installation
#   7. Verify Node.js version (≥v25.2.0)
#   8. Validate fnm performance (<50ms CRITICAL requirement)
#
# Returns:
#   0 = success
#   1 = failure
#
task_install_fnm() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Installing Node.js + fnm (Fast Node Manager)"
    log "INFO" "════════════════════════════════════════"

    local task_start
    task_start=$(get_unix_timestamp)

    # Step 1: Duplicate Detection (Idempotency)
    log "INFO" "Checking for existing fnm installation..."

    if verify_fnm_installed 2>/dev/null; then
        log "INFO" "↷ fnm already installed, checking Node.js version..."

        # Even if fnm is installed, verify Node.js meets constitutional requirements
        if verify_nodejs_version 2>/dev/null; then
            log "INFO" "↷ Node.js latest already installed"

            # CRITICAL: Always validate fnm performance (constitutional requirement)
            log "INFO" "Validating fnm performance (mandatory constitutional check)..."
            if ! verify_fnm_performance 2>/dev/null; then
                log "ERROR" "✗ fnm performance check FAILED"
                log "ERROR" "  Constitutional violation: fnm startup ≥50ms"
                handle_error "install-fnm" 5 "fnm performance below constitutional threshold" \
                    "Check verify_fnm_performance output" \
                    "System may be too slow for constitutional compliance"
                return 1
            fi

            mark_task_completed "install-fnm" 0  # 0 seconds (skipped)
            return 0
        else
            log "WARNING" "⚠ Node.js version does not meet requirements, reinstalling..."
        fi
    fi

    # Step 2: Check for conflicting version managers
    check_conflicting_version_managers

    # Step 3: Install fnm
    if ! install_fnm; then
        return 1
    fi

    # Step 4: Configure shell integration
    if ! configure_fnm_shell_integration; then
        handle_error "install-fnm" 6 "Shell integration configuration failed" \
            "Check shell RC files" \
            "Verify fnm binary exists: ls -l $FNM_BINARY"
        return 1
    fi

    # Step 5: Install Node.js latest (NOT LTS)
    if ! install_nodejs_latest; then
        return 1
    fi

    # Step 6: Verify fnm installation
    log "INFO" "Verifying fnm installation..."

    if ! verify_fnm_installed; then
        handle_error "install-fnm" 7 "fnm verification failed" \
            "Check logs for errors" \
            "Try manual verification: $FNM_BINARY --version"
        return 1
    fi

    # Step 7: Verify Node.js version
    log "INFO" "Verifying Node.js version..."

    if ! verify_nodejs_version; then
        handle_error "install-fnm" 8 "Node.js version verification failed" \
            "Check logs for errors" \
            "Try manual verification: node --version" \
            "Expected: v25.2.0 or higher"
        return 1
    fi

    # Step 8: Validate fnm performance (CRITICAL CONSTITUTIONAL REQUIREMENT)
    log "INFO" "Validating fnm performance (CONSTITUTIONAL CRITICAL)..."

    if ! verify_fnm_performance; then
        handle_error "install-fnm" 9 "CONSTITUTIONAL VIOLATION: fnm startup ≥50ms" \
            "fnm performance below constitutional threshold" \
            "This is a BLOCKING issue - installation cannot proceed" \
            "See logs for recommended actions"
        return 1
    fi

    # Success
    local task_end
    task_end=$(get_unix_timestamp)
    local duration
    duration=$(calculate_duration "$task_start" "$task_end")

    mark_task_completed "install-fnm" "$duration"

    log "SUCCESS" "════════════════════════════════════════"
    log "SUCCESS" "✓ fnm + Node.js installed successfully ($(format_duration "$duration"))"
    log "SUCCESS" "════════════════════════════════════════"
    log "INFO" ""
    log "INFO" "Constitutional Compliance:"
    log "INFO" "  ✓ fnm EXCLUSIVE Node.js version manager"
    log "INFO" "  ✓ fnm startup <50ms (CRITICAL requirement met)"
    log "INFO" "  ✓ Node.js latest v25.2.0+ (NOT LTS)"
    log "INFO" "  ✓ Auto-switching enabled (--use-on-cd)"
    log "INFO" ""
    log "INFO" "Next steps:"
    log "INFO" "  1. Restart terminal or run: source ~/.zshrc (or ~/.bashrc)"
    log "INFO" "  2. Verify: fnm --version && node --version"
    log "INFO" "  3. Usage: fnm install <version>, fnm use <version>"
    log "INFO" "  4. Auto-switching: Create .node-version or .nvmrc in project directories"
    log "INFO" ""
    return 0
}

# Export functions
export -f check_conflicting_version_managers
export -f install_fnm
export -f configure_fnm_shell_integration
export -f install_nodejs_latest
export -f validate_fnm_performance
export -f task_install_fnm
