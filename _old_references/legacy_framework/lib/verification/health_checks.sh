#!/usr/bin/env bash
#
# lib/verification/health_checks.sh - System health validation (Orchestrator)
# Purpose: Orchestrate pre/post installation health checks
# Refactored: 2025-11-25 - Modularized to <300 lines (was 755 lines)
# Modules: lib/verification/checks/{pre_install,post_install,performance}_checks.sh

set -euo pipefail

# Source guard
[[ -n "${HEALTH_CHECKS_SH_LOADED:-}" ]] && return 0
HEALTH_CHECKS_SH_LOADED=1

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_ROOT="$(dirname "$SCRIPT_DIR")"

# ============================================================================
# Source Modular Check Libraries
# ============================================================================

source_check_modules() {
    local checks_dir="${SCRIPT_DIR}/checks"

    for module in pre_install_checks post_install_checks performance_checks; do
        if [[ -f "${checks_dir}/${module}.sh" ]]; then
            source "${checks_dir}/${module}.sh"
        fi
    done
}

# Source core utilities if available
[[ -f "${LIB_ROOT}/core/logging.sh" ]] && source "${LIB_ROOT}/core/logging.sh"
[[ -f "${LIB_ROOT}/core/utils.sh" ]] && source "${LIB_ROOT}/core/utils.sh"

# Source check modules
source_check_modules

# ============================================================================
# Utility Functions (fallback if not from utils.sh)
# ============================================================================

command_exists() {
    command -v "$1" &>/dev/null
}

log() {
    local level="$1"
    shift
    echo "[$level] $*"
}

get_unix_timestamp_ns() {
    date +%s%N
}

calculate_duration_ns() {
    local start_ns="$1"
    local end_ns="$2"
    echo $(( (end_ns - start_ns) / 1000000 ))
}

# ============================================================================
# Pre-Installation Health Check (Delegated)
# ============================================================================

pre_installation_health_check() {
    # Use modular implementation if available
    if declare -f _pre_installation_health_check &>/dev/null; then
        _pre_installation_health_check
        return $?
    fi

    log "INFO" "Running pre-installation health checks..."

    local critical_failures=0

    # Check disk space
    log "INFO" "Checking disk space..."
    local available_gb
    available_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ "$available_gb" -ge 10 ]]; then
        log "SUCCESS" "Disk space: ${available_gb}GB available"
    else
        log "ERROR" "Insufficient disk space: ${available_gb}GB"
        ((critical_failures++))
    fi

    # Check internet
    log "INFO" "Checking internet connectivity..."
    if ping -c 1 -W 5 github.com &>/dev/null; then
        log "SUCCESS" "Internet connectivity OK"
    else
        log "ERROR" "No internet connectivity"
        ((critical_failures++))
    fi

    # Check required commands
    log "INFO" "Checking required commands..."
    local required=("curl" "wget" "git" "tar" "jq" "bc")
    local missing=()
    for cmd in "${required[@]}"; do
        command_exists "$cmd" || missing+=("$cmd")
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log "SUCCESS" "All required commands available"
    else
        log "ERROR" "Missing commands: ${missing[*]}"
        ((critical_failures++))
    fi

    # Summary
    if [[ "$critical_failures" -eq 0 ]]; then
        log "SUCCESS" "PRE-FLIGHT CHECK: ALL SYSTEMS GO"
        return 0
    else
        log "ERROR" "PRE-FLIGHT CHECK: ${critical_failures} CRITICAL FAILURE(S)"
        return 1
    fi
}

# ============================================================================
# Post-Installation Health Check (Delegated)
# ============================================================================

post_installation_health_check() {
    # Use modular implementation if available
    if declare -f _post_installation_health_check &>/dev/null; then
        _post_installation_health_check
        return $?
    fi

    log "INFO" "Running post-installation health checks..."

    local failures=0

    # Check gum
    if command_exists "gum"; then
        log "SUCCESS" "gum: Installed"
    else
        log "ERROR" "gum: Not installed"
        ((failures++))
    fi

    # Check Ghostty
    if command_exists "ghostty"; then
        log "SUCCESS" "Ghostty: Installed"
    else
        log "ERROR" "Ghostty: Not found"
        ((failures++))
    fi

    # Check ZSH
    if command_exists "zsh" && [[ -d "$HOME/.oh-my-zsh" ]]; then
        log "SUCCESS" "ZSH: Configured with Oh My ZSH"
    else
        log "ERROR" "ZSH: Not properly configured"
        ((failures++))
    fi

    # Check fnm
    if command_exists "fnm"; then
        log "SUCCESS" "fnm: Installed"
    else
        log "ERROR" "fnm: Not installed"
        ((failures++))
    fi

    # Check Node.js version
    if command_exists "node"; then
        local node_major
        node_major=$(node --version | sed 's/v\([0-9]*\).*/\1/')
        if [[ "$node_major" -ge 25 ]]; then
            log "SUCCESS" "Node.js: v$node_major (>=25)"
        else
            log "ERROR" "Node.js: v$node_major (<25)"
            ((failures++))
        fi
    else
        log "ERROR" "Node.js: Not installed"
        ((failures++))
    fi

    # Summary
    if [[ "$failures" -eq 0 ]]; then
        log "SUCCESS" "POST-INSTALLATION CHECK: ALL PASSED"
        return 0
    else
        log "ERROR" "POST-INSTALLATION CHECK: ${failures} FAILURE(S)"
        return 1
    fi
}

# ============================================================================
# Run All Health and Performance Tests
# ============================================================================

run_all_health_and_performance_tests() {
    log "INFO" "========================================"
    log "INFO" "Health Check & Performance Tests"
    log "INFO" "========================================"
    echo ""

    local test_groups_passed=0
    local test_groups_failed=0

    # Run pre-installation checks
    if pre_installation_health_check; then
        ((test_groups_passed++))
    else
        ((test_groups_failed++))
    fi
    echo ""

    # Run post-installation checks
    if post_installation_health_check; then
        ((test_groups_passed++))
    else
        ((test_groups_failed++))
    fi
    echo ""

    # Run performance tests if available
    if declare -f run_all_performance_tests &>/dev/null; then
        if run_all_performance_tests; then
            ((test_groups_passed++))
        else
            ((test_groups_failed++))
        fi
    fi

    # Summary
    local total=$((test_groups_passed + test_groups_failed))
    log "INFO" "========================================"
    log "INFO" "Test groups: $total"
    log "SUCCESS" "Passed: $test_groups_passed"

    if [[ "$test_groups_failed" -gt 0 ]]; then
        log "ERROR" "Failed: $test_groups_failed"
        return 1
    else
        log "SUCCESS" "All health & performance tests passed"
        return 0
    fi
}

# Export functions
export -f pre_installation_health_check
export -f post_installation_health_check
export -f run_all_health_and_performance_tests
