#!/bin/bash
#
# Constitutional Local Test Runner
# Comprehensive testing with constitutional compliance validation
#
# Constitutional Requirements:
# - Zero GitHub Actions consumption for testing
# - Local test execution with comprehensive coverage
# - Constitutional compliance validation throughout
# - Performance testing integration
# - Accessibility testing compliance

set -euo pipefail

# Constitutional configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/.update_cache/test_logs"
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly LOG_FILE="${LOG_DIR}/test_run_${TIMESTAMP}.log"
readonly RESULTS_FILE="${LOG_DIR}/test_results_${TIMESTAMP}.json"

# Constitutional test configuration
readonly CONSTITUTIONAL_COVERAGE_TARGET=90
readonly CONSTITUTIONAL_PERFORMANCE_TARGET=95
readonly CONSTITUTIONAL_ACCESSIBILITY_TARGET=95
readonly MAX_TEST_SUITE_TIME=600  # 10 minutes

# Colors for constitutional output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Test results tracking
declare -g TOTAL_TESTS=0
declare -g PASSED_TESTS=0
declare -g FAILED_TESTS=0
declare -g SKIPPED_TESTS=0
declare -g CONSTITUTIONAL_VIOLATIONS=0

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Constitutional logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"

    case "${level}" in
        "ERROR")   echo -e "${RED}❌ ${message}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ ${message}${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  ${message}${NC}" ;;
        "INFO")    echo -e "${BLUE}ℹ️  ${message}${NC}" ;;
        "CONSTITUTIONAL") echo -e "${PURPLE}⚖️  ${message}${NC}" ;;
        "TEST")    echo -e "${CYAN}🧪 ${message}${NC}" ;;
    esac
}

# Test result tracking
track_test_result() {
    local test_name="$1"
    local result="$2"  # "PASS", "FAIL", "SKIP"
    local details="${3:-}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    case "${result}" in
        "PASS")
            PASSED_TESTS=$((PASSED_TESTS + 1))
            log "SUCCESS" "TEST PASSED: ${test_name}"
            ;;
        "FAIL")
            FAILED_TESTS=$((FAILED_TESTS + 1))
            log "ERROR" "TEST FAILED: ${test_name} - ${details}"
            ;;
        "SKIP")
            SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
            log "WARNING" "TEST SKIPPED: ${test_name} - ${details}"
            ;;
    esac
}

# Constitutional compliance test
test_constitutional_compliance() {
    log "CONSTITUTIONAL" "Running constitutional compliance tests..."

    # Test 1: Zero GitHub Actions consumption
    local actions_usage=0
    if command -v gh &>/dev/null && gh auth status &>/dev/null; then
        actions_usage=$(gh api user/settings/billing/actions --jq '.total_paid_minutes_used // 0' 2>/dev/null || echo "0")
    fi

    if [[ "${actions_usage}" -eq 0 ]]; then
        track_test_result "Zero GitHub Actions Consumption" "PASS"
    else
        track_test_result "Zero GitHub Actions Consumption" "FAIL" "Found ${actions_usage} paid minutes used"
        CONSTITUTIONAL_VIOLATIONS=$((CONSTITUTIONAL_VIOLATIONS + 1))
    fi

    # Test 2: Python version compliance
    local python_version=""
    if command -v python3 &>/dev/null; then
        python_version=$(python3 --version | grep -oE '[0-9]+\.[0-9]+')
    fi

    if [[ -n "${python_version}" ]] && python3 -c "import sys; exit(0 if sys.version_info >= (3, 12) else 1)" 2>/dev/null; then
        track_test_result "Python 3.12+ Requirement" "PASS"
    else
        track_test_result "Python 3.12+ Requirement" "FAIL" "Python ${python_version} < 3.12"
        CONSTITUTIONAL_VIOLATIONS=$((CONSTITUTIONAL_VIOLATIONS + 1))
    fi

    # Test 3: uv Python management
    if command -v uv &>/dev/null; then
        local uv_version
        uv_version=$(uv --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        track_test_result "uv Python Management" "PASS" "uv ${uv_version}"
    else
        track_test_result "uv Python Management" "FAIL" "uv not found"
        CONSTITUTIONAL_VIOLATIONS=$((CONSTITUTIONAL_VIOLATIONS + 1))
    fi

    # Test 4: Node.js version compliance
    local node_version=""
    if command -v node &>/dev/null; then
        node_version=$(node --version | grep -oE '[0-9]+')
    fi

    if [[ -n "${node_version}" ]] && [[ "${node_version}" -ge 18 ]]; then
        track_test_result "Node.js 18+ Requirement" "PASS"
    else
        track_test_result "Node.js 18+ Requirement" "FAIL" "Node.js ${node_version} < 18"
        CONSTITUTIONAL_VIOLATIONS=$((CONSTITUTIONAL_VIOLATIONS + 1))
    fi

    # Test 5: Configuration file validation
    local config_files=(
        "pyproject.toml"
        "package.json"
        "tsconfig.json"
        "astro.config.mjs"
    )

    for config_file in "${config_files[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${config_file}" ]]; then
            track_test_result "Config File: ${config_file}" "PASS"
        else
            track_test_result "Config File: ${config_file}" "FAIL" "File not found"
            CONSTITUTIONAL_VIOLATIONS=$((CONSTITUTIONAL_VIOLATIONS + 1))
        fi
    done
}

# Python tests
run_python_tests() {
    log "TEST" "Running Python tests..."

    # Test Python syntax and imports
    local python_files
    mapfile -t python_files < <(find "${PROJECT_ROOT}/scripts" -name "*.py" 2>/dev/null || true)

    if [[ ${#python_files[@]} -eq 0 ]]; then
        track_test_result "Python Files Found" "SKIP" "No Python files to test"
        return
    fi

    # Syntax check
    local syntax_errors=0
    for python_file in "${python_files[@]}"; do
        if python3 -m py_compile "${python_file}" 2>/dev/null; then
            track_test_result "Python Syntax: $(basename "${python_file}")" "PASS"
        else
            track_test_result "Python Syntax: $(basename "${python_file}")" "FAIL" "Syntax error"
            syntax_errors=$((syntax_errors + 1))
        fi
    done

    # Run Python linting if ruff is available
    if command -v python3 &>/dev/null && python3 -m ruff --version &>/dev/null; then
        if python3 -m ruff check "${PROJECT_ROOT}/scripts" --quiet; then
            track_test_result "Python Linting (ruff)" "PASS"
        else
            track_test_result "Python Linting (ruff)" "FAIL" "Linting issues found"
        fi
    else
        track_test_result "Python Linting (ruff)" "SKIP" "ruff not available"
    fi

    # Run Python type checking if mypy is available
    if command -v python3 &>/dev/null && python3 -m mypy --version &>/dev/null; then
        if python3 -m mypy "${PROJECT_ROOT}/scripts" --ignore-missing-imports --no-error-summary 2>/dev/null; then
            track_test_result "Python Type Checking (mypy)" "PASS"
        else
            track_test_result "Python Type Checking (mypy)" "FAIL" "Type checking issues found"
        fi
    else
        track_test_result "Python Type Checking (mypy)" "SKIP" "mypy not available"
    fi

    # Test Python script execution
    local python_scripts=(
        "update_checker.py --help"
        "config_validator.py --help"
        "performance_monitor.py --help"
        "ci_cd_runner.py --help"
        "constitutional_automation.py --help"
    )

    for script_cmd in "${python_scripts[@]}"; do
        local script_name=$(echo "${script_cmd}" | cut -d' ' -f1)
        local script_path="${PROJECT_ROOT}/scripts/${script_name}"

        if [[ -f "${script_path}" ]]; then
            if timeout 10 python3 "${script_path}" --help &>/dev/null; then
                track_test_result "Python Script: ${script_name}" "PASS"
            else
                track_test_result "Python Script: ${script_name}" "FAIL" "Script execution failed"
            fi
        else
            track_test_result "Python Script: ${script_name}" "SKIP" "Script not found"
        fi
    done
}

# Node.js and Astro tests
run_nodejs_tests() {
    log "TEST" "Running Node.js and Astro tests..."

    # Check if package.json exists
    if [[ ! -f "${PROJECT_ROOT}/package.json" ]]; then
        track_test_result "Node.js Package Configuration" "SKIP" "package.json not found"
        return
    fi

    # Check dependencies installation
    if [[ -d "${PROJECT_ROOT}/node_modules" ]]; then
        track_test_result "Node.js Dependencies" "PASS"
    else
        track_test_result "Node.js Dependencies" "FAIL" "node_modules not found"
    fi

    # Test TypeScript compilation
    if command -v npx &>/dev/null && [[ -f "${PROJECT_ROOT}/tsconfig.json" ]]; then
        if cd "${PROJECT_ROOT}" && timeout 30 npx tsc --noEmit &>/dev/null; then
            track_test_result "TypeScript Compilation" "PASS"
        else
            track_test_result "TypeScript Compilation" "FAIL" "TypeScript errors found"
        fi
    else
        track_test_result "TypeScript Compilation" "SKIP" "TypeScript not available"
    fi

    # Test Astro check
    if command -v npx &>/dev/null && [[ -f "${PROJECT_ROOT}/astro.config.mjs" ]]; then
        if cd "${PROJECT_ROOT}" && timeout 60 npx astro check &>/dev/null; then
            track_test_result "Astro Check" "PASS"
        else
            track_test_result "Astro Check" "FAIL" "Astro check failed"
        fi
    else
        track_test_result "Astro Check" "SKIP" "Astro not available"
    fi

    # Test Astro build
    if command -v npm &>/dev/null && [[ -f "${PROJECT_ROOT}/package.json" ]]; then
        if cd "${PROJECT_ROOT}" && timeout 120 npm run build &>/dev/null; then
            track_test_result "Astro Build" "PASS"

            # Check build output
            if [[ -d "${PROJECT_ROOT}/dist" ]]; then
                local build_size
                build_size=$(du -sh "${PROJECT_ROOT}/dist" | cut -f1)
                track_test_result "Build Output Generated" "PASS" "Size: ${build_size}"

                # Constitutional bundle size check
                local js_size=0
                local css_size=0

                if command -v find &>/dev/null; then
                    js_size=$(find "${PROJECT_ROOT}/dist" -name "*.js" -exec wc -c {} + 2>/dev/null | tail -n1 | awk '{print $1}' || echo "0")
                    css_size=$(find "${PROJECT_ROOT}/dist" -name "*.css" -exec wc -c {} + 2>/dev/null | tail -n1 | awk '{print $1}' || echo "0")
                fi

                local js_size_kb=$((js_size / 1024))
                local css_size_kb=$((css_size / 1024))

                if [[ "${js_size_kb}" -le 100 ]]; then
                    track_test_result "Constitutional JS Bundle Size" "PASS" "${js_size_kb}KB ≤ 100KB"
                else
                    track_test_result "Constitutional JS Bundle Size" "FAIL" "${js_size_kb}KB > 100KB"
                    CONSTITUTIONAL_VIOLATIONS=$((CONSTITUTIONAL_VIOLATIONS + 1))
                fi

                if [[ "${css_size_kb}" -le 50 ]]; then
                    track_test_result "Constitutional CSS Bundle Size" "PASS" "${css_size_kb}KB ≤ 50KB"
                else
                    track_test_result "Constitutional CSS Bundle Size" "FAIL" "${css_size_kb}KB > 50KB"
                    CONSTITUTIONAL_VIOLATIONS=$((CONSTITUTIONAL_VIOLATIONS + 1))
                fi
            else
                track_test_result "Build Output Generated" "FAIL" "dist directory not created"
            fi
        else
            track_test_result "Astro Build" "FAIL" "Build process failed"
        fi
    else
        track_test_result "Astro Build" "SKIP" "npm not available"
    fi
}

# Local CI/CD infrastructure tests
test_local_cicd() {
    log "TEST" "Testing local CI/CD infrastructure..."

    # Test runner scripts
    local runner_scripts=(
        "astro-build-local.sh"
        "gh-workflow-local.sh"
        "performance-monitor.sh"
        "pre-commit-local.sh"
        "gh-cli-integration.sh"
    )

    for script in "${runner_scripts[@]}"; do
        local script_path="${SCRIPT_DIR}/${script}"
        if [[ -f "${script_path}" && -x "${script_path}" ]]; then
            track_test_result "Runner Script: ${script}" "PASS"
        elif [[ -f "${script_path}" ]]; then
            track_test_result "Runner Script: ${script}" "FAIL" "Not executable"
        else
            track_test_result "Runner Script: ${script}" "FAIL" "Not found"
        fi
    done

    # Test log directory structure
    local log_dirs=(
        ".update_cache"
        "local-infra/logs"
        "/tmp/ghostty-start-logs"
    )

    for log_dir in "${log_dirs[@]}"; do
        local full_path="${PROJECT_ROOT}/${log_dir}"
        if [[ "${log_dir}" = "/tmp/ghostty-start-logs" ]]; then
            full_path="${log_dir}"
        fi

        if [[ -d "${full_path}" ]]; then
            track_test_result "Log Directory: ${log_dir}" "PASS"
        else
            track_test_result "Log Directory: ${log_dir}" "FAIL" "Directory not found"
        fi
    done

    # Test GitHub CLI integration
    if command -v gh &>/dev/null; then
        if gh auth status &>/dev/null; then
            track_test_result "GitHub CLI Authentication" "PASS"
        else
            track_test_result "GitHub CLI Authentication" "SKIP" "Not authenticated"
        fi
    else
        track_test_result "GitHub CLI" "SKIP" "GitHub CLI not available"
    fi
}

# Performance tests
run_performance_tests() {
    log "TEST" "Running performance tests..."

    # Test script execution times
    local performance_scripts=(
        "scripts/update_checker.py --help"
        "scripts/config_validator.py --help"
        "scripts/performance_monitor.py --help"
    )

    for script_cmd in "${performance_scripts[@]}"; do
        local script_name=$(echo "${script_cmd}" | cut -d' ' -f1 | xargs basename)
        local script_path="${PROJECT_ROOT}/$(echo "${script_cmd}" | cut -d' ' -f1)"

        if [[ -f "${script_path}" ]]; then
            local start_time=$(date +%s%3N)
            if timeout 30 python3 "${script_path}" --help &>/dev/null; then
                local end_time=$(date +%s%3N)
                local execution_time=$((end_time - start_time))

                if [[ "${execution_time}" -le 5000 ]]; then  # 5 seconds
                    track_test_result "Performance: ${script_name}" "PASS" "${execution_time}ms"
                else
                    track_test_result "Performance: ${script_name}" "FAIL" "${execution_time}ms > 5000ms"
                fi
            else
                track_test_result "Performance: ${script_name}" "FAIL" "Script execution failed"
            fi
        else
            track_test_result "Performance: ${script_name}" "SKIP" "Script not found"
        fi
    done

    # Test build performance
    if [[ -f "${PROJECT_ROOT}/package.json" ]] && command -v npm &>/dev/null; then
        local build_start=$(date +%s)
        if cd "${PROJECT_ROOT}" && timeout 120 npm run build &>/dev/null; then
            local build_end=$(date +%s)
            local build_time=$((build_end - build_start))

            if [[ "${build_time}" -le 30 ]]; then  # Constitutional 30s target
                track_test_result "Constitutional Build Performance" "PASS" "${build_time}s ≤ 30s"
            else
                track_test_result "Constitutional Build Performance" "FAIL" "${build_time}s > 30s"
                CONSTITUTIONAL_VIOLATIONS=$((CONSTITUTIONAL_VIOLATIONS + 1))
            fi
        else
            track_test_result "Constitutional Build Performance" "FAIL" "Build failed or timed out"
        fi
    else
        track_test_result "Constitutional Build Performance" "SKIP" "Build not available"
    fi
}

# Accessibility tests
run_accessibility_tests() {
    log "TEST" "Running accessibility tests..."

    # Check for accessibility components
    local a11y_components=(
        "src/components/ui/AccessibilityValidator.astro"
        "src/lib/accessibility.ts"
    )

    for component in "${a11y_components[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${component}" ]]; then
            track_test_result "A11y Component: $(basename "${component}")" "PASS"
        else
            track_test_result "A11y Component: $(basename "${component}")" "FAIL" "Component not found"
        fi
    done

    # Test HTML semantic structure (if dist exists)
    if [[ -d "${PROJECT_ROOT}/dist" ]]; then
        local html_files
        mapfile -t html_files < <(find "${PROJECT_ROOT}/dist" -name "*.html" 2>/dev/null || true)

        for html_file in "${html_files[@]}"; do
            # Check for basic semantic elements
            if grep -q "<main" "${html_file}" && grep -q "role=" "${html_file}"; then
                track_test_result "HTML Semantics: $(basename "${html_file}")" "PASS"
            else
                track_test_result "HTML Semantics: $(basename "${html_file}")" "FAIL" "Missing semantic elements"
            fi
        done
    else
        track_test_result "HTML Accessibility Tests" "SKIP" "No build output to test"
    fi
}

# Bash unit tests
run_bash_unit_tests() {
    log "TEST" "Running bash unit tests..."

    local unit_tests_dir="${PROJECT_ROOT}/local-infra/tests/unit"

    # Check if unit tests directory exists
    if [[ ! -d "$unit_tests_dir" ]]; then
        track_test_result "Bash Unit Tests Directory" "SKIP" "Directory not found"
        return
    fi

    # Find all test files (exclude templates)
    local test_files
    mapfile -t test_files < <(find "$unit_tests_dir" -maxdepth 1 -type f -name "test_*.sh" ! -name ".*" 2>/dev/null || true)

    if [[ ${#test_files[@]} -eq 0 ]]; then
        track_test_result "Bash Unit Tests Found" "SKIP" "No test files to run"
        return
    fi

    log "INFO" "Found ${#test_files[@]} unit test file(s)"

    # Run each test file
    for test_file in "${test_files[@]}"; do
        local test_name=$(basename "$test_file" .sh)

        # Verify test file is executable
        if [[ ! -x "$test_file" ]]; then
            track_test_result "Unit Test: $test_name" "FAIL" "Not executable"
            continue
        fi

        # Run test with timing validation (constitutional requirement: <10s per module per SC-007)
        local start_time=$(date +%s%3N)

        set +e
        local test_output
        test_output=$(timeout 15 "$test_file" 2>&1)
        local test_exit_code=$?
        set -e

        local end_time=$(date +%s%3N)
        local execution_time=$((end_time - start_time))
        local execution_time_seconds=$((execution_time / 1000))

        # Check results
        if [[ $test_exit_code -eq 0 ]]; then
            # Test passed - check timing
            if [[ $execution_time -le 10000 ]]; then
                track_test_result "Unit Test: $test_name" "PASS" "${execution_time}ms"
            else
                track_test_result "Unit Test: $test_name" "FAIL" "${execution_time}ms > 10000ms (constitutional violation)"
                CONSTITUTIONAL_VIOLATIONS=$((CONSTITUTIONAL_VIOLATIONS + 1))
            fi
        elif [[ $test_exit_code -eq 124 ]]; then
            track_test_result "Unit Test: $test_name" "FAIL" "Timeout (>15s)"
        else
            track_test_result "Unit Test: $test_name" "FAIL" "Exit code $test_exit_code"
        fi
    done
}

# Security tests
run_security_tests() {
    log "TEST" "Running security tests..."

    # Check for sensitive files
    local sensitive_patterns=(
        "*.key"
        "*.pem"
        ".env"
        "config.json"
        "secrets.*"
    )

    local security_violations=0
    for pattern in "${sensitive_patterns[@]}"; do
        if find "${PROJECT_ROOT}" -name "${pattern}" -type f 2>/dev/null | grep -q .; then
            track_test_result "Security: No ${pattern} files" "FAIL" "Sensitive files found"
            security_violations=$((security_violations + 1))
        else
            track_test_result "Security: No ${pattern} files" "PASS"
        fi
    done

    # Check .gitignore coverage
    if [[ -f "${PROJECT_ROOT}/.gitignore" ]]; then
        local gitignore_patterns=(
            ".env"
            "*.key"
            "node_modules"
            ".venv"
            "__pycache__"
        )

        local missing_patterns=0
        for pattern in "${gitignore_patterns[@]}"; do
            if grep -q "${pattern}" "${PROJECT_ROOT}/.gitignore"; then
                track_test_result "GitIgnore: ${pattern}" "PASS"
            else
                track_test_result "GitIgnore: ${pattern}" "FAIL" "Pattern not in .gitignore"
                missing_patterns=$((missing_patterns + 1))
            fi
        done
    else
        track_test_result "Security: .gitignore exists" "FAIL" ".gitignore not found"
    fi
}

# Generate test results
generate_test_results() {
    log "INFO" "Generating test results..."

    local end_time=$(date +%s)
    local start_time_file="/tmp/.test_start_time_$$"
    local total_time=0

    if [[ -f "${start_time_file}" ]]; then
        local start_time
        start_time=$(cat "${start_time_file}")
        total_time=$((end_time - start_time))
        rm -f "${start_time_file}"
    fi

    local success_rate=0
    if [[ "${TOTAL_TESTS}" -gt 0 ]]; then
        success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi

    # Generate JSON results
    cat > "${RESULTS_FILE}" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "summary": {
        "total_tests": ${TOTAL_TESTS},
        "passed_tests": ${PASSED_TESTS},
        "failed_tests": ${FAILED_TESTS},
        "skipped_tests": ${SKIPPED_TESTS},
        "success_rate": ${success_rate},
        "constitutional_violations": ${CONSTITUTIONAL_VIOLATIONS},
        "execution_time_seconds": ${total_time}
    },
    "constitutional_compliance": {
        "target_coverage": ${CONSTITUTIONAL_COVERAGE_TARGET},
        "actual_coverage": ${success_rate},
        "violations": ${CONSTITUTIONAL_VIOLATIONS},
        "compliant": $([ "${CONSTITUTIONAL_VIOLATIONS}" -eq 0 ] && echo "true" || echo "false")
    },
    "performance": {
        "execution_time": ${total_time},
        "target_time": ${MAX_TEST_SUITE_TIME},
        "within_target": $([ "${total_time}" -le "${MAX_TEST_SUITE_TIME}" ] && echo "true" || echo "false")
    }
}
EOF

    # Log summary
    log "INFO" "Test execution summary:"
    log "INFO" "  Total tests: ${TOTAL_TESTS}"
    log "INFO" "  Passed: ${PASSED_TESTS}"
    log "INFO" "  Failed: ${FAILED_TESTS}"
    log "INFO" "  Skipped: ${SKIPPED_TESTS}"
    log "INFO" "  Success rate: ${success_rate}%"
    log "INFO" "  Constitutional violations: ${CONSTITUTIONAL_VIOLATIONS}"
    log "INFO" "  Execution time: ${total_time}s"

    # Constitutional compliance assessment
    if [[ "${CONSTITUTIONAL_VIOLATIONS}" -eq 0 && "${success_rate}" -ge "${CONSTITUTIONAL_COVERAGE_TARGET}" ]]; then
        log "CONSTITUTIONAL" "COMPLIANCE PASSED: All constitutional requirements met"
        return 0
    else
        log "CONSTITUTIONAL" "COMPLIANCE FAILED: ${CONSTITUTIONAL_VIOLATIONS} violations, ${success_rate}% success rate"
        return 1
    fi
}

# Main test execution
run_test_suite() {
    local test_categories="${1:-all}"

    # Record start time
    echo "$(date +%s)" > "/tmp/.test_start_time_$$"

    log "INFO" "Starting Constitutional Test Suite"
    log "INFO" "Test categories: ${test_categories}"
    log "INFO" "Target coverage: ${CONSTITUTIONAL_COVERAGE_TARGET}%"

    case "${test_categories}" in
        "all")
            test_constitutional_compliance
            run_bash_unit_tests
            run_python_tests
            run_nodejs_tests
            test_local_cicd
            run_performance_tests
            run_accessibility_tests
            run_security_tests
            ;;
        "constitutional")
            test_constitutional_compliance
            ;;
        "bash"|"unit")
            run_bash_unit_tests
            ;;
        "python")
            run_python_tests
            ;;
        "nodejs")
            run_nodejs_tests
            ;;
        "cicd")
            test_local_cicd
            ;;
        "performance")
            run_performance_tests
            ;;
        "accessibility")
            run_accessibility_tests
            ;;
        "security")
            run_security_tests
            ;;
        *)
            log "ERROR" "Unknown test category: ${test_categories}"
            log "INFO" "Available categories: all, constitutional, bash, python, nodejs, cicd, performance, accessibility, security"
            return 1
            ;;
    esac

    generate_test_results
}

# Usage function
show_usage() {
    cat << EOF
Constitutional Local Test Runner

USAGE:
    $0 [test_category]

TEST CATEGORIES:
    all             - Run all test categories (default)
    constitutional  - Constitutional compliance tests
    bash, unit      - Bash unit tests with timing validation (<10s per test)
    python          - Python syntax, linting, and execution tests
    nodejs          - Node.js, TypeScript, and Astro tests
    cicd            - Local CI/CD infrastructure tests
    performance     - Performance and timing tests
    accessibility   - Accessibility compliance tests
    security        - Security and sensitive data tests

EXAMPLES:
    $0                    # Run all tests
    $0 constitutional     # Run only constitutional compliance tests
    $0 performance        # Run only performance tests

CONSTITUTIONAL REQUIREMENTS:
    • Zero GitHub Actions consumption
    • ${CONSTITUTIONAL_COVERAGE_TARGET}% minimum test success rate
    • Performance within constitutional targets
    • Accessibility compliance validation
    • Security best practices enforcement

OUTPUT:
    • Console output with colored status indicators
    • Detailed log file: ${LOG_DIR}/test_run_TIMESTAMP.log
    • JSON results file: ${LOG_DIR}/test_results_TIMESTAMP.json

EOF
}

# Main execution
main() {
    local test_category="${1:-all}"

    case "${test_category}" in
        "help"|"--help"|"-h")
            show_usage
            exit 0
            ;;
        *)
            if ! run_test_suite "${test_category}"; then
                log "ERROR" "Test suite failed"
                exit 1
            fi
            ;;
    esac

    log "SUCCESS" "Constitutional Test Suite completed successfully"
    log "INFO" "Results saved to: ${RESULTS_FILE}"
}

# Execute main function with all arguments
main "$@"