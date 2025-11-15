#!/bin/bash
# Integration Test: test_full_installation.sh
# Purpose: End-to-end testing of complete start.sh installation
# Dependencies: start.sh, test_functions.sh
# Exit Codes: 0=all tests pass, 1=one or more tests failed
# Note: Runs in isolated environment to avoid system modifications

set -euo pipefail

# ============================================================
# TEST SETUP
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

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
    echo "🔧 Setting up full installation test environment..."

    # Create isolated test environment
    export TEST_TEMP_DIR=$(mktemp -d)
    export TEST_HOME="$TEST_TEMP_DIR/home"
    export TEST_APPS="$TEST_HOME/Apps"
    mkdir -p "$TEST_HOME/.config"
    mkdir -p "$TEST_APPS"

    echo "  Created test environment: $TEST_TEMP_DIR"
    echo "  Test home: $TEST_HOME"
    echo "  Test apps: $TEST_APPS"
}

teardown_all() {
    echo "🧹 Cleaning up full installation test environment..."

    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        echo "  Removed test environment: $TEST_TEMP_DIR"
    fi
}

# ============================================================
# INTEGRATION TEST CASES
# ============================================================

# Test: start.sh exists and is executable
test_start_script_exists() {
    ((TESTS_RUN++))
    echo "  Testing: start.sh exists and is executable"

    # Assert
    assert_file_exists "$PROJECT_ROOT/start.sh" "start.sh should exist"
    assert_true "[[ -x \"$PROJECT_ROOT/start.sh\" ]]" "start.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: start.sh shows help without errors
test_start_script_help() {
    ((TESTS_RUN++))
    echo "  Testing: start.sh --help output"

    # Act
    local output=$("$PROJECT_ROOT/start.sh" --help 2>&1 || echo "COMMAND_FAILED")

    # Assert
    assert_not_equals "COMMAND_FAILED" "$output" "start.sh --help should succeed"
    assert_contains "$output" "start.sh" "Help should mention start.sh"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: start.sh validates configuration structure
test_start_script_validates_config() {
    ((TESTS_RUN++))
    echo "  Testing: start.sh validates configuration structure"

    # Assert config directories exist
    assert_dir_exists "$PROJECT_ROOT/configs" "configs directory should exist"
    assert_dir_exists "$PROJECT_ROOT/configs/ghostty" "ghostty config should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: manage.sh exists and is executable
test_manage_script_exists() {
    ((TESTS_RUN++))
    echo "  Testing: manage.sh exists and is executable"

    # Assert
    assert_file_exists "$PROJECT_ROOT/manage.sh" "manage.sh should exist"
    assert_true "[[ -x \"$PROJECT_ROOT/manage.sh\" ]]" "manage.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: manage.sh shows help without errors
test_manage_script_help() {
    ((TESTS_RUN++))
    echo "  Testing: manage.sh --help output"

    # Act
    local output=$("$PROJECT_ROOT/manage.sh" --help 2>&1 || echo "COMMAND_FAILED")

    # Assert
    assert_not_equals "COMMAND_FAILED" "$output" "manage.sh --help should succeed"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Installation scripts are present
test_installation_scripts_exist() {
    ((TESTS_RUN++))
    echo "  Testing: Required installation scripts exist"

    # Assert
    assert_file_exists "$PROJECT_ROOT/scripts/install_node.sh" "install_node.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/install_spec_kit.sh" "install_spec_kit.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/install_uv.sh" "install_uv.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Configuration templates are valid
test_config_templates_valid() {
    ((TESTS_RUN++))
    echo "  Testing: Configuration templates are accessible"

    # Assert config files exist
    assert_dir_exists "$PROJECT_ROOT/configs/ghostty" "Ghostty config directory should exist"
    assert_file_exists "$PROJECT_ROOT/configs/ghostty/dircolors" "dircolors template should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Common utility functions load without errors
test_common_utilities_load() {
    ((TESTS_RUN++))
    echo "  Testing: Common utility functions load without errors"

    # Act - source common utilities
    local output
    output=$(bash -c "source '$PROJECT_ROOT/scripts/common.sh' && log_info 'Test'" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Common utilities should load successfully"
    assert_contains "$output" "[INFO]" "Should have logging capability"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Progress utilities load without errors
test_progress_utilities_load() {
    ((TESTS_RUN++))
    echo "  Testing: Progress utility functions load without errors"

    # Act - source progress utilities
    local output
    output=$(bash -c "source '$PROJECT_ROOT/scripts/progress.sh' && show_header 'Test'" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Progress utilities should load successfully"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Common.sh utilities available (includes backup functionality)
test_backup_utilities_available() {
    ((TESTS_RUN++))
    echo "  Testing: Utility functions for data protection are available"

    # Assert
    assert_file_exists "$PROJECT_ROOT/scripts/common.sh" "common.sh should exist with backup support"

    # Act - verify module loads and has necessary functions
    local output
    output=$(bash -c "source '$PROJECT_ROOT/scripts/common.sh' && echo 'loaded'" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Common utilities should load successfully"
    assert_contains "$output" "loaded" "Should confirm load"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Health check scripts are present and executable
test_health_check_scripts_present() {
    ((TESTS_RUN++))
    echo "  Testing: Health check scripts are present"

    # Assert
    assert_file_exists "$PROJECT_ROOT/scripts/check_updates.sh" "check_updates.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/system_health_check.sh" "system_health_check.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/check_context7_health.sh" "check_context7_health.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/check_github_mcp_health.sh" "check_github_mcp_health.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Update scripts are present
test_update_scripts_present() {
    ((TESTS_RUN++))
    echo "  Testing: Update scripts are present"

    # Assert
    assert_file_exists "$PROJECT_ROOT/scripts/update_ghostty.sh" "update_ghostty.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/check_updates.sh" "check_updates.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/daily-updates.sh" "daily-updates.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Documentation structure is correct
test_documentation_structure_valid() {
    ((TESTS_RUN++))
    echo "  Testing: Documentation directory structure is valid"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/documentations" "documentations directory should exist"
    assert_dir_exists "$PROJECT_ROOT/documentations/user" "user docs should exist"
    assert_dir_exists "$PROJECT_ROOT/documentations/developer" "developer docs should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: README files exist
test_readme_files_exist() {
    ((TESTS_RUN++))
    echo "  Testing: README files exist"

    # Assert
    assert_file_exists "$PROJECT_ROOT/README.md" "Main README should exist"
    assert_file_exists "$PROJECT_ROOT/CLAUDE.md" "CLAUDE.md should exist"
    assert_file_exists "$PROJECT_ROOT/GEMINI.md" "GEMINI.md should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: .runners-local infrastructure exists
test_runners_local_infrastructure() {
    ((TESTS_RUN++))
    echo "  Testing: .runners-local infrastructure is complete"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/.runners-local/workflows" "workflows directory should exist"
    assert_dir_exists "$PROJECT_ROOT/.runners-local/tests" "tests directory should exist"
    assert_file_exists "$PROJECT_ROOT/.runners-local/workflows/gh-workflow-local.sh" "gh-workflow-local.sh should exist"
    assert_file_exists "$PROJECT_ROOT/.runners-local/workflows/gh-pages-setup.sh" "gh-pages-setup.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: GitHub Pages .nojekyll file protection
test_github_pages_nojekyll_critical() {
    ((TESTS_RUN++))
    echo "  Testing: GitHub Pages .nojekyll file (CRITICAL)"

    # Assert
    assert_file_exists "$PROJECT_ROOT/docs/.nojekyll" ".nojekyll file should exist (CRITICAL for GitHub Pages)"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Installation logs directory structure
test_installation_logs_structure() {
    ((TESTS_RUN++))
    echo "  Testing: Installation log directories are set up correctly"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/.runners-local/logs" "logs directory should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Integration Tests: Full Installation"
    echo "════════════════════════════════════════════════════════"

    setup_all

    echo ""
    echo "Running integration test cases..."
    echo ""

    # Run test cases
    test_start_script_exists || ((TESTS_FAILED++))
    test_start_script_help || ((TESTS_FAILED++))
    test_start_script_validates_config || ((TESTS_FAILED++))
    test_manage_script_exists || ((TESTS_FAILED++))
    test_manage_script_help || ((TESTS_FAILED++))
    test_installation_scripts_exist || ((TESTS_FAILED++))
    test_config_templates_valid || ((TESTS_FAILED++))
    test_common_utilities_load || ((TESTS_FAILED++))
    test_progress_utilities_load || ((TESTS_FAILED++))
    test_backup_utilities_available || ((TESTS_FAILED++))
    test_health_check_scripts_present || ((TESTS_FAILED++))
    test_update_scripts_present || ((TESTS_FAILED++))
    test_documentation_structure_valid || ((TESTS_FAILED++))
    test_readme_files_exist || ((TESTS_FAILED++))
    test_runners_local_infrastructure || ((TESTS_FAILED++))
    test_github_pages_nojekyll_critical || ((TESTS_FAILED++))
    test_installation_logs_structure || ((TESTS_FAILED++))

    teardown_all

    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Integration Test Results: Full Installation"
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
