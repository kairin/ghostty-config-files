#!/usr/bin/env bash
# tests/unit/run_all_tests.sh - Test orchestrator for all unit tests
# Runs all test suites in tests/unit/ and reports aggregate results

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Aggregate test results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

run_test_suite() {
    local suite_name="$1"
    local suite_file="$2"

    ((TOTAL_SUITES++))
    echo ""
    echo "Running: $suite_name"
    echo "-----------------------------------------"

    if [[ -f "$suite_file" ]] && bash "$suite_file"; then
        ((PASSED_SUITES++))
        echo "[SUITE PASS] $suite_name"
    else
        ((FAILED_SUITES++))
        echo "[SUITE FAIL] $suite_name"
    fi
}

main() {
    echo "========================================="
    echo "Unit Test Orchestrator"
    echo "========================================="
    echo "Repository: $REPO_ROOT"
    echo "Date: $(date -Iseconds)"
    echo ""

    # Run all test suites
    run_test_suite "Core Libraries" "${SCRIPT_DIR}/test_core_libraries.sh"
    run_test_suite "Installers" "${SCRIPT_DIR}/test_installers.sh"
    run_test_suite "Utilities" "${SCRIPT_DIR}/test_utilities.sh"
    run_test_suite "UI Components" "${SCRIPT_DIR}/test_ui_components.sh"
    run_test_suite "Verification" "${SCRIPT_DIR}/test_verification.sh"

    # Final summary
    echo ""
    echo "========================================="
    echo "FINAL RESULTS"
    echo "========================================="
    echo "Total Suites: $TOTAL_SUITES"
    echo "Passed: $PASSED_SUITES"
    echo "Failed: $FAILED_SUITES"
    echo ""

    if [[ $FAILED_SUITES -eq 0 ]]; then
        echo "[SUCCESS] All test suites passed!"
        return 0
    else
        echo "[FAILURE] $FAILED_SUITES test suite(s) failed"
        return 1
    fi
}

main "$@"
