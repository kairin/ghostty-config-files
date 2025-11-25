#!/usr/bin/env bash
# unit_tests.sh - Unit test orchestrator (thin orchestrator)
# Orchestrates test modules from tests/unit/ and lib/verification/tests/
# Original: 1,378 lines -> Orchestrator: ~95 lines (93% reduction)

set -euo pipefail

# Source guard
[ -z "${UNIT_TESTS_SH_LOADED:-}" ] || return 0
UNIT_TESTS_SH_LOADED=1

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source core utilities
source "${REPO_ROOT}/lib/core/logging.sh"
source "${REPO_ROOT}/lib/core/utils.sh"

# Source test modules from tests/unit/
source "${REPO_ROOT}/tests/unit/test_core_libraries.sh"
source "${REPO_ROOT}/tests/unit/test_installers.sh"
source "${REPO_ROOT}/tests/unit/test_utilities.sh"
source "${REPO_ROOT}/tests/unit/test_ui_components.sh"
source "${REPO_ROOT}/tests/unit/test_verification.sh"
source "${REPO_ROOT}/tests/unit/run_all_tests.sh"

# Source Phase 8 test modules
source "${REPO_ROOT}/lib/verification/tests/zsh-fnm-test.sh"
source "${REPO_ROOT}/lib/verification/tests/ghostty-zsh-test.sh"
source "${REPO_ROOT}/lib/verification/tests/ai-nodejs-test.sh"
source "${REPO_ROOT}/lib/verification/tests/context-menu-test.sh"
source "${REPO_ROOT}/lib/verification/tests/phase8-tests.sh"

# Run all unit tests
run_all_unit_tests() {
    log "INFO" "========================================"
    log "INFO" "Phase 8: Unit Test Suite (Orchestrator)"
    log "INFO" "========================================"
    echo ""

    local test_groups_passed=0
    local test_groups_failed=0

    # Core library tests
    if test_core_libraries; then ((test_groups_passed++)); else ((test_groups_failed++)); fi
    echo ""

    # Installer tests
    if test_installers; then ((test_groups_passed++)); else ((test_groups_failed++)); fi
    echo ""

    # Utility tests
    if test_utilities; then ((test_groups_passed++)); else ((test_groups_failed++)); fi
    echo ""

    # UI component tests
    if test_ui_components; then ((test_groups_passed++)); else ((test_groups_failed++)); fi
    echo ""

    # Verification tests
    if test_verification; then ((test_groups_passed++)); else ((test_groups_failed++)); fi
    echo ""

    # Phase 8 tests
    if run_phase8_tests; then ((test_groups_passed++)); else ((test_groups_failed++)); fi
    echo ""

    # Summary
    local total=$((test_groups_passed + test_groups_failed))
    log "INFO" "========================================"
    log "INFO" "Unit Tests Summary"
    log "INFO" "========================================"
    log "INFO" "Test groups: $total"
    log "SUCCESS" "Passed: $test_groups_passed"

    if [ "$test_groups_failed" -gt 0 ]; then
        log "ERROR" "Failed: $test_groups_failed"
        return 1
    else
        log "SUCCESS" "All unit tests passed"
        return 0
    fi
}

# Export for external use
export -f run_all_unit_tests
