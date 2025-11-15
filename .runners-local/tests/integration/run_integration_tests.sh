#!/bin/bash
# Integration Test Runner: run_integration_tests.sh
# Purpose: Orchestrates all integration tests and provides summary report
# Exit Codes: 0=all tests pass, 1=one or more test suites failed

set -euo pipefail

# ============================================================
# CONFIGURATION
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TESTS_DIR="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test suites
declare -a TEST_SUITES=(
    "test_full_installation.sh"
    "test_astro_build_deploy.sh"
    "test_mcp_integration.sh"
    "test_local_cicd_workflow.sh"
    "test_health_checks.sh"
    "test_update_workflow.sh"
)

# Results tracking
declare -a SUITE_RESULTS=()
declare -a SUITE_NAMES=()
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Logging
LOG_DIR="${PROJECT_ROOT}/.runners-local/logs"
LOG_FILE="${LOG_DIR}/integration-tests-$(date +%Y%m%d-%H%M%S).log"
SUMMARY_FILE="${LOG_DIR}/integration-tests-summary-$(date +%Y%m%d-%H%M%S).txt"

# Options
RUN_ALL=true
VERBOSE=false
PARALLEL=false
SELECTED_SUITES=()

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Print colored output
print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Initialize logging
initialize_logging() {
    mkdir -p "$LOG_DIR"
    echo "Integration Test Suite Execution Log" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# Log message
log_message() {
    echo "$1" >> "$LOG_FILE"
}

# Show usage
show_usage() {
    cat << EOF
Usage: run_integration_tests.sh [OPTIONS]

Integration Test Suite Runner

OPTIONS:
  --help              Show this help message
  --verbose           Show detailed test output
  --parallel          Run tests in parallel (experimental)
  --suite <name>      Run specific test suite (can be used multiple times)
  --list              List available test suites
  --quick             Run quick tests only (excludes slow tests)

EXAMPLES:
  # Run all integration tests
  ./run_integration_tests.sh

  # Run specific test suite
  ./run_integration_tests.sh --suite test_full_installation.sh

  # Run multiple specific suites
  ./run_integration_tests.sh --suite test_full_installation.sh --suite test_health_checks.sh

  # Run with verbose output
  ./run_integration_tests.sh --verbose

  # List available suites
  ./run_integration_tests.sh --list

EXIT CODES:
  0 - All test suites passed
  1 - One or more test suites failed
  2 - Invalid options or configuration

EOF
}

# List available test suites
list_test_suites() {
    echo ""
    print_header "Available Integration Test Suites"
    echo ""

    for i in "${!TEST_SUITES[@]}"; do
        suite="${TEST_SUITES[$i]}"
        echo "  $(($i + 1)). $suite"

        # Extract description from first comment
        if [[ -f "$TESTS_DIR/$suite" ]]; then
            desc=$(grep "^# Purpose:" "$TESTS_DIR/$suite" | sed 's/# Purpose: //' || echo "No description")
            echo "     $desc"
        fi
        echo ""
    done
}

# Validate test suite file
validate_test_suite() {
    local suite="$1"

    if [[ ! -f "$TESTS_DIR/$suite" ]]; then
        print_error "Test suite not found: $suite"
        return 1
    fi

    if [[ ! -x "$TESTS_DIR/$suite" ]]; then
        chmod +x "$TESTS_DIR/$suite"
    fi

    return 0
}

# Run single test suite
run_test_suite() {
    local suite="$1"
    local suite_name="${suite%.sh}"

    print_info "Running: $suite_name"
    log_message "Starting test suite: $suite_name"

    # Run test and capture output
    local output
    local exit_code=0

    if [[ "$VERBOSE" == "true" ]]; then
        # Show output to console
        if "$TESTS_DIR/$suite"; then
            exit_code=0
        else
            exit_code=$?
        fi
    else
        # Capture output to log
        if output=$("$TESTS_DIR/$suite" 2>&1); then
            exit_code=0
        else
            exit_code=$?
        fi
    fi

    # Log output
    if [[ -n "$output" ]]; then
        log_message "Output from $suite_name:"
        log_message "$output"
        log_message ""
    fi

    # Extract test counts from output
    if [[ -n "$output" ]]; then
        local test_total=$(echo "$output" | grep "Total Tests:" | awk '{print $NF}' || echo "0")
        local test_passed=$(echo "$output" | grep "Passed:" | awk '{print $NF}' || echo "0")
        local test_failed=$(echo "$output" | grep "Failed:" | awk '{print $NF}' || echo "0")

        if [[ -n "$test_total" && "$test_total" != "0" ]]; then
            ((TOTAL_TESTS += test_total))
            ((PASSED_TESTS += test_passed))
            ((FAILED_TESTS += test_failed))
        fi
    fi

    return $exit_code
}

# ============================================================
# ARGUMENT PARSING
# ============================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                show_usage
                exit 0
                ;;
            --list)
                list_test_suites
                exit 0
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --parallel)
                PARALLEL=true
                shift
                ;;
            --quick)
                # Quick mode: exclude slow tests
                # For now, run all tests
                shift
                ;;
            --suite)
                if [[ -z "${2:-}" ]]; then
                    print_error "Missing test suite name after --suite"
                    exit 2
                fi
                SELECTED_SUITES+=("$2")
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 2
                ;;
        esac
    done
}

# ============================================================
# TEST EXECUTION
# ============================================================

main() {
    # Initialize
    parse_arguments "$@"
    initialize_logging

    print_header "Integration Test Suite Executor"
    print_info "Test Directory: $TESTS_DIR"
    print_info "Log Directory: $LOG_DIR"
    print_info "Log File: $LOG_FILE"
    echo ""

    # Determine which suites to run
    local suites_to_run=()
    if [[ ${#SELECTED_SUITES[@]} -gt 0 ]]; then
        suites_to_run=("${SELECTED_SUITES[@]}")
    else
        suites_to_run=("${TEST_SUITES[@]}")
    fi

    # Validate all suites
    print_info "Validating test suites..."
    for suite in "${suites_to_run[@]}"; do
        if ! validate_test_suite "$suite"; then
            print_error "Validation failed for: $suite"
            exit 2
        fi
    done
    echo ""

    # Run test suites
    print_header "Running Integration Tests"
    echo ""

    for suite in "${suites_to_run[@]}"; do
        ((TOTAL_SUITES++))
        suite_name="${suite%.sh}"
        SUITE_NAMES+=("$suite_name")

        if run_test_suite "$suite"; then
            ((PASSED_SUITES++))
            print_success "$suite_name PASSED"
            SUITE_RESULTS+=("PASS")
        else
            ((FAILED_SUITES++))
            print_error "$suite_name FAILED"
            SUITE_RESULTS+=("FAIL")
        fi
        echo ""
    done

    # Generate summary report
    generate_summary_report

    # Print summary
    print_summary

    # Exit with appropriate code
    if [[ $FAILED_SUITES -eq 0 ]]; then
        print_success "ALL INTEGRATION TEST SUITES PASSED"
        return 0
    else
        print_error "SOME INTEGRATION TEST SUITES FAILED"
        return 1
    fi
}

# Generate detailed summary report
generate_summary_report() {
    {
        echo "═════════════════════════════════════════════════════════"
        echo "INTEGRATION TEST SUITE SUMMARY REPORT"
        echo "═════════════════════════════════════════════════════════"
        echo ""
        echo "Execution Time: $(date)"
        echo "Test Directory: $TESTS_DIR"
        echo ""

        echo "SUITE RESULTS:"
        echo "─────────────────────────────────────────────────────────"
        for i in "${!SUITE_NAMES[@]}"; do
            suite_name="${SUITE_NAMES[$i]}"
            result="${SUITE_RESULTS[$i]}"

            if [[ "$result" == "PASS" ]]; then
                echo "✅ $suite_name : PASSED"
            else
                echo "❌ $suite_name : FAILED"
            fi
        done
        echo ""

        echo "OVERALL STATISTICS:"
        echo "─────────────────────────────────────────────────────────"
        echo "Total Test Suites: $TOTAL_SUITES"
        echo "Passed Suites: $PASSED_SUITES"
        echo "Failed Suites: $FAILED_SUITES"
        echo ""
        echo "Total Tests (across all suites): $TOTAL_TESTS"
        echo "Passed Tests: $PASSED_TESTS"
        echo "Failed Tests: $FAILED_TESTS"
        echo ""

        if [[ $FAILED_SUITES -eq 0 ]]; then
            echo "STATUS: ✅ ALL TESTS PASSED"
        else
            echo "STATUS: ❌ SOME TESTS FAILED"
        fi
        echo ""
        echo "For detailed logs, see: $LOG_FILE"
        echo "═════════════════════════════════════════════════════════"
    } | tee "$SUMMARY_FILE"
}

# Print console summary
print_summary() {
    echo ""
    print_header "INTEGRATION TEST SUMMARY"
    echo ""
    echo "Test Suites Run: $TOTAL_SUITES"
    echo "Passed: ${GREEN}$PASSED_SUITES${NC}"
    echo "Failed: ${RED}$FAILED_SUITES${NC}"
    echo ""
    echo "Individual Tests:"
    echo "  Total: $TOTAL_TESTS"
    echo "  Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo "  Failed: ${RED}$FAILED_TESTS${NC}"
    echo ""
    echo "Detailed results: $SUMMARY_FILE"
    echo ""
}

# ============================================================
# MAIN EXECUTION
# ============================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
