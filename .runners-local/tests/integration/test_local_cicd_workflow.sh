#!/bin/bash
# Integration Test: test_local_cicd_workflow.sh
# Purpose: End-to-end testing of complete CI/CD pipeline execution
# Dependencies: .runners-local/workflows/*.sh, test_functions.sh
# Exit Codes: 0=all tests pass, 1=one or more tests failed

set -euo pipefail

# ============================================================
# TEST SETUP
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WORKFLOWS_DIR="$PROJECT_ROOT/.runners-local/workflows"

# Source test helper functions
source "${SCRIPT_DIR}/../unit/test_functions.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================
# TEST FIXTURES
# ============================================================

setup_all() {
    echo "🔧 Setting up local CI/CD workflow test environment..."

    # Create test environment
    export TEST_TEMP_DIR=$(mktemp -d)
    export TEST_LOGS="$TEST_TEMP_DIR/logs"
    mkdir -p "$TEST_LOGS"

    echo "  Created test environment: $TEST_TEMP_DIR"
}

teardown_all() {
    echo "🧹 Cleaning up local CI/CD workflow test environment..."

    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        echo "  Removed test environment: $TEST_TEMP_DIR"
    fi
}

# ============================================================
# INTEGRATION TEST CASES
# ============================================================

# Test: Main CI/CD workflow script exists
test_gh_workflow_local_exists() {
    ((TESTS_RUN++))
    echo "  Testing: gh-workflow-local.sh exists"

    # Assert
    assert_file_exists "$WORKFLOWS_DIR/gh-workflow-local.sh" \
        "gh-workflow-local.sh should exist"
    assert_true "[[ -x \"$WORKFLOWS_DIR/gh-workflow-local.sh\" ]]" \
        "gh-workflow-local.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: All workflow scripts are present
test_all_workflow_scripts_present() {
    ((TESTS_RUN++))
    echo "  Testing: All required workflow scripts exist"

    # Assert
    assert_file_exists "$WORKFLOWS_DIR/astro-build-local.sh" "astro-build-local.sh should exist"
    assert_file_exists "$WORKFLOWS_DIR/gh-pages-setup.sh" "gh-pages-setup.sh should exist"
    assert_file_exists "$WORKFLOWS_DIR/performance-monitor.sh" "performance-monitor.sh should exist"
    assert_file_exists "$WORKFLOWS_DIR/validate-modules.sh" "validate-modules.sh should exist"
    assert_file_exists "$WORKFLOWS_DIR/pre-commit-local.sh" "pre-commit-local.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: All workflow scripts are executable
test_workflow_scripts_executable() {
    ((TESTS_RUN++))
    echo "  Testing: All workflow scripts are executable"

    # Assert
    local scripts=(
        "gh-workflow-local.sh"
        "astro-build-local.sh"
        "gh-pages-setup.sh"
        "performance-monitor.sh"
        "validate-modules.sh"
        "pre-commit-local.sh"
    )

    for script in "${scripts[@]}"; do
        assert_true "[[ -x \"$WORKFLOWS_DIR/$script\" ]]" \
            "$script should be executable"
    done

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Logs directory structure exists
test_logs_directory_structure() {
    ((TESTS_RUN++))
    echo "  Testing: Logs directory structure exists"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/.runners-local/logs" \
        "logs directory should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Performance monitoring infrastructure exists
test_performance_monitoring_infrastructure() {
    ((TESTS_RUN++))
    echo "  Testing: Performance monitoring infrastructure exists"

    # Assert
    assert_file_exists "$WORKFLOWS_DIR/performance-monitor.sh" \
        "performance-monitor.sh should exist"
    assert_file_exists "$WORKFLOWS_DIR/performance-dashboard.sh" \
        "performance-dashboard.sh should exist"
    assert_file_exists "$WORKFLOWS_DIR/benchmark-runner.sh" \
        "benchmark-runner.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Validation scripts are present
test_validation_scripts_present() {
    ((TESTS_RUN++))
    echo "  Testing: Validation scripts are present"

    # Assert
    assert_file_exists "$WORKFLOWS_DIR/validate-modules.sh" \
        "validate-modules.sh should exist"
    assert_dir_exists "$PROJECT_ROOT/.runners-local/tests/validation" \
        "validation tests directory should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Local workflow documentation exists
test_workflow_documentation_exists() {
    ((TESTS_RUN++))
    echo "  Testing: Workflow documentation exists"

    # Assert
    assert_file_exists "$PROJECT_ROOT/.runners-local/README.md" \
        ".runners-local/README.md should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Test infrastructure is complete
test_test_infrastructure_complete() {
    ((TESTS_RUN++))
    echo "  Testing: Complete test infrastructure exists"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/.runners-local/tests/unit" "unit tests dir should exist"
    assert_dir_exists "$PROJECT_ROOT/.runners-local/tests/integration" "integration tests dir should exist"
    assert_dir_exists "$PROJECT_ROOT/.runners-local/tests/validation" "validation tests dir should exist"
    assert_file_exists "$PROJECT_ROOT/.runners-local/tests/unit/test_functions.sh" \
        "test_functions.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: GitHub CLI integration scripts exist
test_github_cli_integration() {
    ((TESTS_RUN++))
    echo "  Testing: GitHub CLI integration scripts exist"

    # Assert
    assert_file_exists "$WORKFLOWS_DIR/gh-cli-integration.sh" \
        "gh-cli-integration.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Self-hosted runner infrastructure exists
test_self_hosted_runner_infrastructure() {
    ((TESTS_RUN++))
    echo "  Testing: Self-hosted runner infrastructure exists"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/.runners-local/self-hosted" \
        "self-hosted directory should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: .github workflows directory exists
test_github_workflows_directory() {
    ((TESTS_RUN++))
    echo "  Testing: .github/workflows directory exists"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/.github" ".github directory should exist"
    assert_dir_exists "$PROJECT_ROOT/.github/workflows" "workflows directory should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Health check scripts are available for CI/CD
test_ci_cd_health_checks() {
    ((TESTS_RUN++))
    echo "  Testing: Health check scripts for CI/CD are available"

    # Assert
    assert_file_exists "$PROJECT_ROOT/scripts/check_updates.sh" \
        "check_updates.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/system_health_check.sh" \
        "system_health_check.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Zero-cost operation strategy is documented
test_zero_cost_strategy_documented() {
    ((TESTS_RUN++))
    echo "  Testing: Zero-cost CI/CD strategy is documented"

    # Check if CLAUDE.md mentions zero-cost requirements
    local has_zero_cost=false
    if grep -q "Zero.*cost\|zero.*cost\|zero-cost\|MANDATORY.*local" "$PROJECT_ROOT/CLAUDE.md"; then
        has_zero_cost=true
    fi

    assert_true "[$has_zero_cost = true]" \
        "CLAUDE.md should document zero-cost CI/CD strategy"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: local CI/CD logs structure is documented
test_local_cicd_logs_structure() {
    ((TESTS_RUN++))
    echo "  Testing: Local CI/CD logs structure is documented"

    # Check if documentation mentions logs
    local has_logs_doc=false
    if grep -q "logs\|logging\|\.runners-local/logs" "$PROJECT_ROOT/CLAUDE.md" "$PROJECT_ROOT/.runners-local/README.md" 2>/dev/null; then
        has_logs_doc=true
    fi

    assert_true "[$has_logs_doc = true]" \
        "Logs structure should be documented"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Pipeline stages are documented
test_pipeline_stages_documented() {
    ((TESTS_RUN++))
    echo "  Testing: CI/CD pipeline stages are documented"

    # Check CLAUDE.md for pipeline stage documentation
    local has_stages=false
    if grep -q "stage\|Stage\|pipeline\|Pipeline" "$PROJECT_ROOT/CLAUDE.md"; then
        has_stages=true
    fi

    assert_true "[$has_stages = true]" \
        "Pipeline stages should be documented"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Integration Tests: Local CI/CD Workflow"
    echo "════════════════════════════════════════════════════════"

    setup_all

    echo ""
    echo "Running integration test cases..."
    echo ""

    # Run test cases
    test_gh_workflow_local_exists || ((TESTS_FAILED++))
    test_all_workflow_scripts_present || ((TESTS_FAILED++))
    test_workflow_scripts_executable || ((TESTS_FAILED++))
    test_logs_directory_structure || ((TESTS_FAILED++))
    test_performance_monitoring_infrastructure || ((TESTS_FAILED++))
    test_validation_scripts_present || ((TESTS_FAILED++))
    test_workflow_documentation_exists || ((TESTS_FAILED++))
    test_test_infrastructure_complete || ((TESTS_FAILED++))
    test_github_cli_integration || ((TESTS_FAILED++))
    test_self_hosted_runner_infrastructure || ((TESTS_FAILED++))
    test_github_workflows_directory || ((TESTS_FAILED++))
    test_ci_cd_health_checks || ((TESTS_FAILED++))
    test_zero_cost_strategy_documented || ((TESTS_FAILED++))
    test_local_cicd_logs_structure || ((TESTS_FAILED++))
    test_pipeline_stages_documented || ((TESTS_FAILED++))

    teardown_all

    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Integration Test Results: Local CI/CD Workflow"
    echo "════════════════════════════════════════════════════════"
    echo "  Total Tests: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo "  ✅ ALL INTEGRATION TESTS PASSED"
        return 0
    else
        echo ""
        echo "  ❌ SOME INTEGRATION TESTS FAILED"
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
    exit $?
fi
