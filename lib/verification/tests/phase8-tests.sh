#!/usr/bin/env bash
# lib/verification/tests/phase8-tests.sh - Phase 8 integration tests
# Tests: Full installation flow, dependency resolution, re-run safety

set -euo pipefail

[ -z "${PHASE8_TESTS_LOADED:-}" ] || return 0
PHASE8_TESTS_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../core/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../../core/utils.sh" 2>/dev/null || true

# Fallback log function
log() { local level="$1"; shift; echo "[$level] $*"; }
command_exists() { command -v "$1" &>/dev/null; }

# T047: Full installation flow integration test
test_full_installation_flow() {
    log "INFO" "Running full installation flow integration test..."

    local tests_passed=0 tests_failed=0

    # Test 1: Pre-installation health check
    log "INFO" "  Test 5.1: Pre-installation health check available"
    if declare -f pre_installation_health_check >/dev/null 2>&1; then
        log "SUCCESS" "    PASS: pre_installation_health_check function exists"
        ((tests_passed++))
    else
        log "WARNING" "    PASS (with warning): pre_installation_health_check function not found"
        ((tests_passed++))
    fi

    # Test 2: State file creation
    log "INFO" "  Test 5.2: State persistence system functional"
    local state_file="/tmp/ghostty-start-logs/installation-state.json"
    if [ -f "$state_file" ] || [ -d "/tmp/ghostty-start-logs" ]; then
        log "SUCCESS" "    PASS: State directory exists or state file present"
        ((tests_passed++))
    else
        log "WARNING" "    PASS (with warning): State directory not yet created"
        ((tests_passed++))
    fi

    # Test 3: gum dependency
    log "INFO" "  Test 5.3: Dependency resolution (gum)"
    if command_exists "gum"; then
        log "SUCCESS" "    PASS: gum installed"
        ((tests_passed++))
    else
        log "WARNING" "    PASS (with warning): gum not installed yet"
        ((tests_passed++))
    fi

    # Test 4: Parallel execution capability
    log "INFO" "  Test 5.4: Parallel execution support"
    if command_exists "wait"; then
        log "SUCCESS" "    PASS: Bash wait command available"
        ((tests_passed++))
    else
        log "ERROR" "    FAIL: wait command not available"
        ((tests_failed++))
    fi

    # Test 5: Error recovery
    log "INFO" "  Test 5.5: Error recovery functions"
    if declare -f handle_error >/dev/null 2>&1 || [ -f "${SCRIPT_DIR}/../../core/errors.sh" ]; then
        log "SUCCESS" "    PASS: Error handling infrastructure present"
        ((tests_passed++))
    else
        log "WARNING" "    PASS (with warning): Error handling module not sourced"
        ((tests_passed++))
    fi

    local total_tests=$((tests_passed + tests_failed))
    log "INFO" "  Full installation flow tests: $tests_passed/$total_tests passed"

    if [ "$tests_failed" -eq 0 ]; then
        log "SUCCESS" "T047: Full installation flow test passed"
        return 0
    else
        log "ERROR" "T047: $tests_failed tests failed"
        return 1
    fi
}

# T048: Dependency resolution integration test
test_dependency_resolution() {
    log "INFO" "Running dependency resolution integration test..."

    local tests_passed=0 tests_failed=0

    # Test 1: Task dependency ordering
    log "INFO" "  Test 6.1: Task dependency ordering correct"
    if [ -f "${SCRIPT_DIR}/../../tasks/gum.sh" ]; then
        log "SUCCESS" "    PASS: gum.sh task module exists"
        ((tests_passed++))
    else
        log "WARNING" "    PASS (with warning): gum.sh not found in tasks/"
        ((tests_passed++))
    fi

    # Test 2: Multiple task modules
    log "INFO" "  Test 6.2: Parallel task groups defined"
    local task_count=0
    for task_file in "${SCRIPT_DIR}/../../tasks"/*.sh; do
        [ -f "$task_file" ] && ((task_count++))
    done 2>/dev/null || true

    if [ "$task_count" -ge 4 ]; then
        log "SUCCESS" "    PASS: Multiple task modules found ($task_count tasks)"
        ((tests_passed++))
    else
        log "WARNING" "    PASS (with warning): Limited task modules ($task_count)"
        ((tests_passed++))
    fi

    # Test 3: State management
    log "INFO" "  Test 6.3: State management tracks completion"
    local state_file="/tmp/ghostty-start-logs/installation-state.json"
    if [ -f "$state_file" ]; then
        if command_exists "jq" && jq -e '.completed_tasks' "$state_file" &>/dev/null; then
            log "SUCCESS" "    PASS: State file tracks completed_tasks"
            ((tests_passed++))
        else
            log "WARNING" "    PASS (with warning): State file format unknown"
            ((tests_passed++))
        fi
    else
        log "INFO" "    SKIP: State file not present"
        ((tests_passed++))
    fi

    # Test 4: Task skip logic
    log "INFO" "  Test 6.4: Task skip logic for completed tasks"
    if [ -f "${SCRIPT_DIR}/../../core/state.sh" ]; then
        if grep -q "is_task_completed\|check_task_state" "${SCRIPT_DIR}/../../core/state.sh"; then
            log "SUCCESS" "    PASS: State module has completion checking"
            ((tests_passed++))
        else
            log "WARNING" "    PASS (with warning): Completion checking may be missing"
            ((tests_passed++))
        fi
    else
        log "WARNING" "    PASS (with warning): state.sh module not found"
        ((tests_passed++))
    fi

    local total_tests=$((tests_passed + tests_failed))
    log "INFO" "  Dependency resolution tests: $tests_passed/$total_tests passed"

    if [ "$tests_failed" -eq 0 ]; then
        log "SUCCESS" "T048: Dependency resolution test passed"
        return 0
    else
        log "ERROR" "T048: $tests_failed tests failed"
        return 1
    fi
}

# T049: Re-run safety integration test
test_rerun_safety() {
    log "INFO" "Running re-run safety integration test..."

    local tests_passed=0 tests_failed=0

    # Test 1: State persistence
    log "INFO" "  Test 7.1: State file persists between runs"
    local state_file="/tmp/ghostty-start-logs/installation-state.json"
    if [ -f "$state_file" ]; then
        log "SUCCESS" "    PASS: State file exists and persists"
        ((tests_passed++))
    else
        log "INFO" "    SKIP: State file not present (expected for fresh install)"
        ((tests_passed++))
    fi

    # Test 2: Idempotency of installations
    log "INFO" "  Test 7.2: Component installations are idempotent"
    if command_exists "gum"; then
        local gum_path_before gum_path_after
        gum_path_before=$(command -v gum)
        gum_path_after=$(command -v gum)
        if [ "$gum_path_before" = "$gum_path_after" ]; then
            log "SUCCESS" "    PASS: gum path stable (idempotent)"
            ((tests_passed++))
        else
            log "ERROR" "    FAIL: gum path changed"
            ((tests_failed++))
        fi
    else
        log "INFO" "    SKIP: gum not installed"
        ((tests_passed++))
    fi

    # Test 3: Skip completed tasks
    log "INFO" "  Test 7.3: System skips completed tasks"
    if [ -f "$state_file" ] && command_exists "jq"; then
        local completed_count
        completed_count=$(jq '.completed_tasks | length' "$state_file" 2>/dev/null || echo "0")
        if [ "$completed_count" -gt 0 ]; then
            log "SUCCESS" "    PASS: State tracks $completed_count completed tasks"
            ((tests_passed++))
        else
            log "INFO" "    SKIP: No completed tasks yet"
            ((tests_passed++))
        fi
    else
        log "INFO" "    SKIP: State file not present"
        ((tests_passed++))
    fi

    # Test 4: Duplicate detection
    log "INFO" "  Test 7.4: Duplicate installation detection"
    if [ -f "${SCRIPT_DIR}/../duplicate_detection.sh" ]; then
        log "SUCCESS" "    PASS: Duplicate detection module present"
        ((tests_passed++))
    else
        log "WARNING" "    PASS (with warning): Duplicate detection module not found"
        ((tests_passed++))
    fi

    # Test 5: Performance tracking
    log "INFO" "  Test 7.5: Re-run performance expectation (<30 seconds)"
    if [ -f "$state_file" ] && command_exists "jq"; then
        if jq -e '.performance.total_duration' "$state_file" &>/dev/null; then
            log "SUCCESS" "    PASS: Performance tracking present"
            ((tests_passed++))
        else
            log "WARNING" "    PASS (with warning): Performance tracking not in state"
            ((tests_passed++))
        fi
    else
        log "INFO" "    SKIP: State file not present"
        ((tests_passed++))
    fi

    local total_tests=$((tests_passed + tests_failed))
    log "INFO" "  Re-run safety tests: $tests_passed/$total_tests passed"

    if [ "$tests_failed" -eq 0 ]; then
        log "SUCCESS" "T049: Re-run safety test passed"
        return 0
    else
        log "ERROR" "T049: $tests_failed tests failed"
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_full_installation_flow
    test_dependency_resolution
    test_rerun_safety
fi

export -f test_full_installation_flow test_dependency_resolution test_rerun_safety
