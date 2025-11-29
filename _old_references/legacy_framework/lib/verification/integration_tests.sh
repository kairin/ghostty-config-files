#!/usr/bin/env bash
# integration_tests.sh - Integration test orchestrator (thin orchestrator)
# Orchestrates cross-component validation tests from lib/verification/tests/
# Original: 649 lines -> Orchestrator: ~120 lines (82% reduction)

set -euo pipefail

# Source guard
[ -z "${INTEGRATION_TESTS_SH_LOADED:-}" ] || return 0
INTEGRATION_TESTS_SH_LOADED=1

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source core utilities
source "${REPO_ROOT}/lib/core/logging.sh"
source "${REPO_ROOT}/lib/core/utils.sh"

# Source integration test modules
source "${REPO_ROOT}/lib/verification/tests/zsh-fnm-test.sh"
source "${REPO_ROOT}/lib/verification/tests/ghostty-zsh-test.sh"
source "${REPO_ROOT}/lib/verification/tests/ai-nodejs-test.sh"
source "${REPO_ROOT}/lib/verification/tests/context-menu-test.sh"
source "${REPO_ROOT}/lib/verification/tests/phase8-tests.sh"

# Run all integration tests
run_all_integration_tests() {
    log "INFO" "========================================"
    log "INFO" "Running Integration Tests (Orchestrator)"
    log "INFO" "========================================"
    echo ""

    local total_tests=0
    local passed_tests=0
    local failed_tests=0

    # Test 1: ZSH + fnm integration
    ((total_tests++))
    if test_zsh_fnm_integration; then ((passed_tests++)); else ((failed_tests++)); fi
    echo ""

    # Test 2: Ghostty + ZSH integration
    ((total_tests++))
    if test_ghostty_zsh_integration; then ((passed_tests++)); else ((failed_tests++)); fi
    echo ""

    # Test 3: AI tools + Node.js integration
    ((total_tests++))
    if test_ai_tools_nodejs_integration; then ((passed_tests++)); else ((failed_tests++)); fi
    echo ""

    # Test 4: Context menu + Ghostty integration
    ((total_tests++))
    if test_context_menu_ghostty_integration; then ((passed_tests++)); else ((failed_tests++)); fi
    echo ""

    # Phase 8 integration tests
    ((total_tests++))
    if test_full_installation_flow; then ((passed_tests++)); else ((failed_tests++)); fi
    echo ""

    ((total_tests++))
    if test_dependency_resolution; then ((passed_tests++)); else ((failed_tests++)); fi
    echo ""

    ((total_tests++))
    if test_rerun_safety; then ((passed_tests++)); else ((failed_tests++)); fi
    echo ""

    # Summary
    log "INFO" "========================================"
    log "INFO" "Integration Tests Summary"
    log "INFO" "========================================"
    log "INFO" "Total tests: $total_tests"
    log "SUCCESS" "Passed: $passed_tests"

    if [ "$failed_tests" -gt 0 ]; then
        log "ERROR" "Failed: $failed_tests"
        return 1
    else
        log "SUCCESS" "All integration tests passed"
        return 0
    fi
}

# Export functions
export -f run_all_integration_tests
