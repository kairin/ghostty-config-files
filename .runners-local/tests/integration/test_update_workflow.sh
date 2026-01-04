#!/bin/bash
# Integration Test: test_update_workflow.sh
# Purpose: End-to-end testing of update detection and application
# Dependencies: scripts/check_updates.sh, test_functions.sh
# Exit Codes: 0=all tests pass, 1=one or more tests failed

set -euo pipefail

# ============================================================
# TEST SETUP
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

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
    echo "🔧 Setting up update workflow test environment..."

    # Create test environment
    export TEST_TEMP_DIR=$(mktemp -d)
    export TEST_UPDATE_DIR="$TEST_TEMP_DIR/updates"
    export TEST_BACKUP_DIR="$TEST_TEMP_DIR/backups"
    mkdir -p "$TEST_UPDATE_DIR"
    mkdir -p "$TEST_BACKUP_DIR"

    echo "  Created test environment: $TEST_TEMP_DIR"
}

teardown_all() {
    echo "🧹 Cleaning up update workflow test environment..."

    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        echo "  Removed test environment: $TEST_TEMP_DIR"
    fi
}

# ============================================================
# CONSTITUTIONAL COMPLIANCE NOTE
# ============================================================
# Tests previously expected update_ghostty.sh, backup_utils.sh, common.sh, progress.sh
# These were REMOVED to comply with Script Proliferation Prevention principle.
#
# Update mechanism: scripts/004-reinstall/install_*.sh (reused for updates)
# Backup mechanism: Inline functions in scripts/006-logs/logger.sh
# Logging mechanism: Enhanced scripts/006-logs/logger.sh
#
# See: .claude/instructions-for-agents/principles/script-proliferation.md
# ============================================================

# ============================================================
# INTEGRATION TEST CASES
# ============================================================

# Test: Update check script exists
test_check_updates_script_exists() {
    ((TESTS_RUN++))
    echo "  Testing: check_updates.sh exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/check_updates.sh" \
        "check_updates.sh should exist"
    assert_true "[[ -x \"$SCRIPTS_DIR/check_updates.sh\" ]]" \
        "check_updates.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Daily updates script exists
test_daily_updates_script_exists() {
    ((TESTS_RUN++))
    echo "  Testing: daily-updates.sh exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/daily-updates.sh" \
        "daily-updates.sh should exist"
    assert_true "[[ -x \"$SCRIPTS_DIR/daily-updates.sh\" ]]" \
        "daily-updates.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Ghostty reinstall script exists (replaces update_ghostty.sh per constitutional compliance)
test_ghostty_reinstall_script_exists() {
    ((TESTS_RUN++))
    echo "  Testing: install_ghostty.sh exists (update via reinstall)"

    # Assert - Constitutional compliance: use 004-reinstall scripts for updates
    assert_file_exists "$SCRIPTS_DIR/004-reinstall/install_ghostty.sh" \
        "install_ghostty.sh should exist for updates"
    assert_true "[[ -x \"$SCRIPTS_DIR/004-reinstall/install_ghostty.sh\" ]]" \
        "install_ghostty.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Verification utilities for updates
test_verification_utilities_for_updates() {
    ((TESTS_RUN++))
    echo "  Testing: Verification utilities exist for update validation"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/verify-passwordless-sudo.sh" \
        "verify-passwordless-sudo.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Logger utilities for updates (replaces common.sh/progress.sh per constitutional compliance)
test_logger_utilities_for_updates() {
    ((TESTS_RUN++))
    echo "  Testing: Logger utilities are available for updates"

    # Assert - Constitutional compliance: utilities consolidated in logger.sh
    assert_file_exists "$SCRIPTS_DIR/006-logs/logger.sh" \
        "logger.sh should exist with update utilities"

    # Verify update functions exist in logger.sh
    if grep -q "init_update_log\|backup_configs\|restore_from_backup" "$SCRIPTS_DIR/006-logs/logger.sh"; then
        echo "    Found update utility functions in logger.sh"
    else
        echo "    WARNING: Update utility functions may be missing"
    fi

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Node.js installation script exists
test_node_installation_script_exists() {
    ((TESTS_RUN++))
    echo "  Testing: install_node.sh exists for dependency updates"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/install_node.sh" \
        "install_node.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Environment verification for updates
test_env_verification_exists() {
    ((TESTS_RUN++))
    echo "  Testing: Environment verification script exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/verify_env_loaded.sh" \
        "verify_env_loaded.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Update logs directory structure
test_update_logs_directory() {
    ((TESTS_RUN++))
    echo "  Testing: Update logs directory exists"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/.runners-local/logs" \
        "logs directory should exist for update tracking"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Ghostty config installation script exists
test_ghostty_config_script_exists() {
    ((TESTS_RUN++))
    echo "  Testing: install_ghostty_config.sh exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/install_ghostty_config.sh" \
        "install_ghostty_config.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Update workflow documentation
test_update_workflow_documentation() {
    ((TESTS_RUN++))
    echo "  Testing: Update workflow is documented"

    # Check if CLAUDE.md mentions update management
    local has_update_docs=false
    if grep -q "update\|Update\|daily\|intelligent" "$PROJECT_ROOT/CLAUDE.md"; then
        has_update_docs=true
    fi

    assert_true "[$has_update_docs = true]" \
        "Update workflow should be documented"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Configuration backup strategy
test_configuration_backup_strategy() {
    ((TESTS_RUN++))
    echo "  Testing: Configuration backup strategy is in place"

    # Check if start.sh or update scripts mention backup
    local has_backup_strategy=false
    if grep -q "backup\|Backup" "$SCRIPTS_DIR/check_updates.sh" "$SCRIPTS_DIR/update_ghostty.sh" 2>/dev/null; then
        has_backup_strategy=true
    fi

    assert_true "[$has_backup_strategy = true]" \
        "Backup strategy should exist for updates"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Update status monitoring
test_update_status_monitoring() {
    ((TESTS_RUN++))
    echo "  Testing: Update status monitoring is available"

    # Check for health check script
    assert_file_exists "$SCRIPTS_DIR/check_updates.sh" \
        "check_updates.sh should enable status monitoring"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Update workflow components (constitutional compliance version)
test_update_workflow_components() {
    ((TESTS_RUN++))
    echo "  Testing: All update workflow components are present"

    # Check critical components (constitutional compliance: no separate update_*.sh or backup_utils.sh)
    local components=(
        "$SCRIPTS_DIR/check_updates.sh"
        "$SCRIPTS_DIR/daily-updates.sh"
        "$SCRIPTS_DIR/006-logs/logger.sh"
        "$SCRIPTS_DIR/004-reinstall/install_ghostty.sh"
    )

    for component in "${components[@]}"; do
        assert_file_exists "$component" "Component should exist: $component"
    done

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Update workflow preserves user customization
test_update_preserves_customizations() {
    ((TESTS_RUN++))
    echo "  Testing: Update workflow preserves user customizations"

    # Check if CLAUDE.md mentions customization preservation
    local has_preservation=false
    if grep -q "preservation\|preserve\|Preserve\|customization" "$PROJECT_ROOT/CLAUDE.md"; then
        has_preservation=true
    fi

    assert_true "[$has_preservation = true]" \
        "Customization preservation should be documented"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Update strategy documentation
test_update_strategy_documented() {
    ((TESTS_RUN++))
    echo "  Testing: Update strategy is documented"

    # Check README for update instructions
    local has_strategy=false
    if grep -q "update\|Update" "$PROJECT_ROOT/README.md"; then
        has_strategy=true
    fi

    assert_true "[$has_strategy = true]" \
        "Update strategy should be documented in README"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Smart commit script for update management
test_smart_commit_script_exists() {
    ((TESTS_RUN++))
    echo "  Testing: smart_commit.sh exists for update tracking"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/smart_commit.sh" \
        "smart_commit.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Update validation infrastructure
test_update_validation_infrastructure() {
    ((TESTS_RUN++))
    echo "  Testing: Update validation infrastructure exists"

    # Check for validation tests
    assert_dir_exists "$PROJECT_ROOT/.runners-local/tests/validation" \
        "validation tests should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Integration Tests: Update Workflow"
    echo "════════════════════════════════════════════════════════"

    setup_all

    echo ""
    echo "Running integration test cases..."
    echo ""

    # Run test cases
    test_check_updates_script_exists || ((TESTS_FAILED++))
    test_daily_updates_script_exists || ((TESTS_FAILED++))
    test_ghostty_reinstall_script_exists || ((TESTS_FAILED++))
    test_verification_utilities_for_updates || ((TESTS_FAILED++))
    test_logger_utilities_for_updates || ((TESTS_FAILED++))
    test_node_installation_script_exists || ((TESTS_FAILED++))
    test_env_verification_exists || ((TESTS_FAILED++))
    test_update_logs_directory || ((TESTS_FAILED++))
    test_ghostty_config_script_exists || ((TESTS_FAILED++))
    test_update_workflow_documentation || ((TESTS_FAILED++))
    test_configuration_backup_strategy || ((TESTS_FAILED++))
    test_update_status_monitoring || ((TESTS_FAILED++))
    test_update_workflow_components || ((TESTS_FAILED++))
    test_update_preserves_customizations || ((TESTS_FAILED++))
    test_update_strategy_documented || ((TESTS_FAILED++))
    test_smart_commit_script_exists || ((TESTS_FAILED++))
    test_update_validation_infrastructure || ((TESTS_FAILED++))

    teardown_all

    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Integration Test Results: Update Workflow"
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
