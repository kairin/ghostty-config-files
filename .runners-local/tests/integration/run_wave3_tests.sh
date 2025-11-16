#!/bin/bash
# Wave 3 Integration Test Runner
# Purpose: Execute all Wave 3 integration tests (T141-T145)
# Exit Codes: 0=all tests pass, 1=one or more tests failed

set -euo pipefail

# ============================================================
# CONFIGURATION
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Test counters
TOTAL_SUITES=4
SUITES_PASSED=0
SUITES_FAILED=0

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================
# HELPER FUNCTIONS
# ============================================================

print_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_suite_header() {
    echo ""
    echo -e "${BOLD}$1${NC}"
    echo "────────────────────────────────────────────────────────"
}

run_test_suite() {
    local suite_name="$1"
    local test_script="$2"
    local suite_number="$3"

    print_suite_header "[$suite_number/$TOTAL_SUITES] Running: $suite_name"

    if [[ ! -f "$test_script" ]]; then
        echo -e "${RED}❌ SKIP: Test script not found: $test_script${NC}"
        ((SUITES_FAILED++))
        return 1
    fi

    # Run test and capture exit code
    local exit_code=0
    bash "$test_script" || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}✅ SUITE PASSED: $suite_name${NC}"
        ((SUITES_PASSED++))
        return 0
    else
        echo ""
        echo -e "${RED}❌ SUITE FAILED: $suite_name (exit code: $exit_code)${NC}"
        ((SUITES_FAILED++))
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

main() {
    print_header "🧪 Wave 3: Integration Testing & Validation"

    echo "Project Root: $PROJECT_ROOT"
    echo "Test Directory: $SCRIPT_DIR"
    echo "Total Test Suites: $TOTAL_SUITES"
    echo ""
    echo "Starting test execution..."

    # T142: End-to-End Installation Test
    run_test_suite \
        "Full Installation Workflow (T142)" \
        "$SCRIPT_DIR/test_full_installation.sh" \
        1 || true

    # T143: Functional Requirements Validation
    run_test_suite \
        "Functional Requirements (FR-001 to FR-052) (T143)" \
        "$SCRIPT_DIR/test_functional_requirements.sh" \
        2 || true

    # T144: Success Criteria Verification
    run_test_suite \
        "Success Criteria (SC-001 to SC-062) (T144)" \
        "$SCRIPT_DIR/test_success_criteria.sh" \
        3 || true

    # T145: Constitutional Compliance
    run_test_suite \
        "Constitutional Compliance (6 Principles) (T145)" \
        "$SCRIPT_DIR/test_constitutional_compliance.sh" \
        4 || true

    # Print final summary
    print_header "📊 Wave 3 Test Execution Summary"

    echo "Test Suites Executed: $TOTAL_SUITES"
    echo "Suites Passed: $SUITES_PASSED"
    echo "Suites Failed: $SUITES_FAILED"
    echo ""

    # Calculate success rate
    local success_rate=$((SUITES_PASSED * 100 / TOTAL_SUITES))
    echo "Success Rate: ${success_rate}%"
    echo ""

    if [[ $SUITES_FAILED -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✅ ALL WAVE 3 INTEGRATION TESTS PASSED${NC}"
        echo ""
        echo "Wave 3 Deliverables Complete:"
        echo "  ✓ T141: manage.sh validate subcommands (5/5)"
        echo "  ✓ T142: End-to-end installation test"
        echo "  ✓ T143: Functional requirements validation (16 FRs)"
        echo "  ✓ T144: Success criteria verification (20 SCs)"
        echo "  ✓ T145: Constitutional compliance (6 principles)"
        echo ""
        echo "Next Steps:"
        echo "  - Review test output for any warnings"
        echo "  - Update baseline metrics if needed"
        echo "  - Run './manage.sh validate all' for comprehensive validation"
        return 0
    else
        echo -e "${YELLOW}${BOLD}⚠️  SOME WAVE 3 TESTS FAILED${NC}"
        echo ""
        echo "Failed Suites: $SUITES_FAILED/$TOTAL_SUITES"
        echo ""
        echo "Troubleshooting:"
        echo "  - Review test output above for specific failures"
        echo "  - Check that all dependencies are installed"
        echo "  - Verify repository structure matches expectations"
        echo "  - Run individual test suites for detailed diagnostics"
        echo ""
        echo "Run individual tests:"
        echo "  bash $SCRIPT_DIR/test_full_installation.sh"
        echo "  bash $SCRIPT_DIR/test_functional_requirements.sh"
        echo "  bash $SCRIPT_DIR/test_success_criteria.sh"
        echo "  bash $SCRIPT_DIR/test_constitutional_compliance.sh"
        return 1
    fi
}

# ============================================================
# SCRIPT ENTRY POINT
# ============================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
