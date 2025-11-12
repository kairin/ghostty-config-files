#!/bin/bash
# Unit Test: test_common_utils.sh
# Purpose: Unit tests for common.sh, progress.sh, and backup_utils.sh modules
# Dependencies: test_functions.sh (assertion helpers)
# Exit Codes: 0=all tests pass, 1=one or more tests failed

set -euo pipefail

# ============================================================
# TEST SETUP
# ============================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test helper functions
source "${SCRIPT_DIR}/test_functions.sh"

# Source the modules being tested
COMMON_MODULE="${SCRIPT_DIR}/../../../scripts/common.sh"
PROGRESS_MODULE="${SCRIPT_DIR}/../../../scripts/progress.sh"
BACKUP_MODULE="${SCRIPT_DIR}/../../../scripts/backup_utils.sh"

source "$COMMON_MODULE"
source "$PROGRESS_MODULE"
source "$BACKUP_MODULE"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================
# TEST FIXTURES & MOCKS
# ============================================================

# Setup: Run before all tests
setup_all() {
    echo "🔧 Setting up test environment..."

    # Create temporary test directory
    export TEST_TEMP_DIR=$(mktemp -d)
    echo "  Created temp directory: $TEST_TEMP_DIR"

    # Create test files
    echo "test content" > "$TEST_TEMP_DIR/test_file.txt"
    mkdir -p "$TEST_TEMP_DIR/test_dir"
    echo "nested content" > "$TEST_TEMP_DIR/test_dir/nested_file.txt"

    # Set custom backup directory for testing
    export MANAGE_BACKUP_DIR="$TEST_TEMP_DIR/backups"
}

# Teardown: Run after all tests
teardown_all() {
    echo "🧹 Cleaning up test environment..."

    # Remove temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        echo "  Removed temp directory: $TEST_TEMP_DIR"
    fi
}

# ============================================================
# TEST CASES - common.sh
# ============================================================

# Test: resolve_absolute_path with valid path
test_resolve_absolute_path_success() {
    ((TESTS_RUN++))
    echo "  Testing: resolve_absolute_path with valid path"

    # Arrange
    local test_file="$TEST_TEMP_DIR/test_file.txt"

    # Act
    local result
    result=$(resolve_absolute_path "$test_file")
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Exit code should be 0"
    assert_contains "$result" "test_file.txt" "Should return absolute path"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: resolve_absolute_path with non-existent path
test_resolve_absolute_path_failure() {
    ((TESTS_RUN++))
    echo "  Testing: resolve_absolute_path with non-existent path"

    # Arrange
    local nonexistent_path="/nonexistent/path/file.txt"

    # Act
    local result
    result=$(resolve_absolute_path "$nonexistent_path" 2>&1)
    local exit_code=$?

    # Assert
    assert_not_equals 0 "$exit_code" "Should fail with non-existent path"
    assert_contains "$result" "ERROR" "Should output error message"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: get_project_root
test_get_project_root() {
    ((TESTS_RUN++))
    echo "  Testing: get_project_root"

    # Act
    local result
    result=$(get_project_root)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Should find project root"
    assert_contains "$result" "ghostty-config-files" "Should return repository root"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: log_info
test_log_info() {
    ((TESTS_RUN++))
    echo "  Testing: log_info"

    # Act
    local result
    result=$(log_info "Test message")

    # Assert
    assert_contains "$result" "[INFO]" "Should include [INFO] prefix"
    assert_contains "$result" "Test message" "Should include message"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: log_error
test_log_error() {
    ((TESTS_RUN++))
    echo "  Testing: log_error"

    # Act
    local result
    result=$(log_error "Error message" 2>&1)

    # Assert
    assert_contains "$result" "[ERROR]" "Should include [ERROR] prefix"
    assert_contains "$result" "Error message" "Should include error message"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: require_command with existing command
test_require_command_success() {
    ((TESTS_RUN++))
    echo "  Testing: require_command with existing command"

    # Act
    require_command "bash" >/dev/null 2>&1
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Should succeed for existing command"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: require_command with non-existing command
test_require_command_failure() {
    ((TESTS_RUN++))
    echo "  Testing: require_command with non-existing command"

    # Act
    require_command "nonexistent_command_xyz" >/dev/null 2>&1
    local exit_code=$?

    # Assert
    assert_not_equals 0 "$exit_code" "Should fail for non-existing command"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: ensure_dir
test_ensure_dir() {
    ((TESTS_RUN++))
    echo "  Testing: ensure_dir"

    # Arrange
    local new_dir="$TEST_TEMP_DIR/new_directory"

    # Act
    ensure_dir "$new_dir" >/dev/null 2>&1
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Should create directory successfully"
    assert_true "[[ -d \"$new_dir\" ]]" "Directory should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: get_timestamp
test_get_timestamp() {
    ((TESTS_RUN++))
    echo "  Testing: get_timestamp"

    # Act
    local timestamp_file
    timestamp_file=$(get_timestamp "file")
    local timestamp_log
    timestamp_log=$(get_timestamp "log")
    local timestamp_iso
    timestamp_iso=$(get_timestamp "iso")

    # Assert
    assert_contains "$timestamp_file" "-" "File timestamp should contain dash separator"
    assert_contains "$timestamp_log" ":" "Log timestamp should contain colon separator"
    assert_contains "$timestamp_iso" "T" "ISO timestamp should contain T separator"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# ============================================================
# TEST CASES - progress.sh
# ============================================================

# Test: show_progress with different statuses
test_show_progress() {
    ((TESTS_RUN++))
    echo "  Testing: show_progress with different statuses"

    # Act
    local result_start
    result_start=$(show_progress "start" "Starting operation")
    local result_success
    result_success=$(show_progress "success" "Operation completed")
    local result_error
    result_error=$(show_progress "error" "Operation failed" 2>&1)

    # Assert
    assert_contains "$result_start" "Starting operation" "Should include start message"
    assert_contains "$result_success" "Operation completed" "Should include success message"
    assert_contains "$result_error" "Operation failed" "Should include error message"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: show_step
test_show_step() {
    ((TESTS_RUN++))
    echo "  Testing: show_step"

    # Act
    local result
    result=$(show_step 1 3 "First step")

    # Assert
    assert_contains "$result" "[1/3]" "Should show step counter"
    assert_contains "$result" "First step" "Should show step description"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: show_header
test_show_header() {
    ((TESTS_RUN++))
    echo "  Testing: show_header"

    # Act
    local result
    result=$(show_header "Test Section")

    # Assert
    assert_contains "$result" "=" "Should contain separator"
    assert_contains "$result" "Test Section" "Should contain title"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: show_summary
test_show_summary() {
    ((TESTS_RUN++))
    echo "  Testing: show_summary"

    # Act
    show_summary 5 0 "tests" >/dev/null 2>&1
    local exit_code_success=$?

    show_summary 3 2 "operations" >/dev/null 2>&1
    local exit_code_failure=$?

    # Assert
    assert_equals 0 "$exit_code_success" "Should return 0 for all successful"
    assert_not_equals 0 "$exit_code_failure" "Should return non-zero for failures"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# ============================================================
# TEST CASES - backup_utils.sh
# ============================================================

# Test: create_backup for file
test_create_backup_file() {
    ((TESTS_RUN++))
    echo "  Testing: create_backup for file"

    # Arrange
    local test_file="$TEST_TEMP_DIR/test_file.txt"

    # Act
    local backup_path
    backup_path=$(create_backup "$test_file" 2>/dev/null)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Should create backup successfully"
    assert_true "[[ -f \"$backup_path\" ]]" "Backup file should exist"
    assert_contains "$backup_path" "backup-" "Backup path should contain timestamp"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: create_backup for directory
test_create_backup_directory() {
    ((TESTS_RUN++))
    echo "  Testing: create_backup for directory"

    # Arrange
    local test_dir="$TEST_TEMP_DIR/test_dir"

    # Act
    local backup_path
    backup_path=$(create_backup "$test_dir" 2>/dev/null)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Should create directory backup successfully"
    assert_true "[[ -d \"$backup_path\" ]]" "Backup directory should exist"
    assert_true "[[ -f \"$backup_path/nested_file.txt\" ]]" "Backup should preserve directory structure"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: create_backup with non-existent path
test_create_backup_nonexistent() {
    ((TESTS_RUN++))
    echo "  Testing: create_backup with non-existent path"

    # Act
    create_backup "/nonexistent/path" >/dev/null 2>&1
    local exit_code=$?

    # Assert
    assert_not_equals 0 "$exit_code" "Should fail for non-existent path"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: list_backups
test_list_backups() {
    ((TESTS_RUN++))
    echo "  Testing: list_backups"

    # Arrange
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    create_backup "$test_file" "test_file" >/dev/null 2>&1

    # Act
    local result
    result=$(list_backups "test_file" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Should list backups successfully"
    assert_contains "$result" "test_file" "Should show backup name"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: find_latest_backup
test_find_latest_backup() {
    ((TESTS_RUN++))
    echo "  Testing: find_latest_backup"

    # Arrange
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    create_backup "$test_file" "test_file" >/dev/null 2>&1
    sleep 1  # Ensure different timestamps
    create_backup "$test_file" "test_file" >/dev/null 2>&1

    # Act
    local latest
    latest=$(find_latest_backup "test_file" 2>/dev/null)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Should find latest backup"
    assert_contains "$latest" "test_file.backup-" "Should return backup path"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: verify_backup
test_verify_backup() {
    ((TESTS_RUN++))
    echo "  Testing: verify_backup"

    # Arrange
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    local backup_path
    backup_path=$(create_backup "$test_file" 2>/dev/null)

    # Act
    verify_backup "$backup_path" >/dev/null 2>&1
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Should verify valid backup"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: restore_backup
test_restore_backup() {
    ((TESTS_RUN++))
    echo "  Testing: restore_backup"

    # Arrange
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    local backup_path
    backup_path=$(create_backup "$test_file" 2>/dev/null)

    # Modify original file
    echo "modified content" > "$test_file"

    # Act
    restore_backup "$backup_path" "$test_file" >/dev/null 2>&1
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Should restore backup successfully"
    assert_contains "$(cat "$test_file")" "test content" "Should restore original content"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Unit Tests for Common Utilities"
    echo "════════════════════════════════════════════════════════"

    setup_all

    # Run test cases
    echo ""
    echo "Running test cases..."
    echo ""

    echo "📦 Testing common.sh..."
    test_resolve_absolute_path_success || ((TESTS_FAILED++))
    test_resolve_absolute_path_failure || ((TESTS_FAILED++))
    test_get_project_root || ((TESTS_FAILED++))
    test_log_info || ((TESTS_FAILED++))
    test_log_error || ((TESTS_FAILED++))
    test_require_command_success || ((TESTS_FAILED++))
    test_require_command_failure || ((TESTS_FAILED++))
    test_ensure_dir || ((TESTS_FAILED++))
    test_get_timestamp || ((TESTS_FAILED++))

    echo ""
    echo "📊 Testing progress.sh..."
    test_show_progress || ((TESTS_FAILED++))
    test_show_step || ((TESTS_FAILED++))
    test_show_header || ((TESTS_FAILED++))
    test_show_summary || ((TESTS_FAILED++))

    echo ""
    echo "💾 Testing backup_utils.sh..."
    test_create_backup_file || ((TESTS_FAILED++))
    test_create_backup_directory || ((TESTS_FAILED++))
    test_create_backup_nonexistent || ((TESTS_FAILED++))
    test_list_backups || ((TESTS_FAILED++))
    test_find_latest_backup || ((TESTS_FAILED++))
    test_verify_backup || ((TESTS_FAILED++))
    test_restore_backup || ((TESTS_FAILED++))

    teardown_all

    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Test Results Summary"
    echo "════════════════════════════════════════════════════════"
    echo "  Total Tests: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo "  ✅ ALL TESTS PASSED"
        return 0
    else
        echo ""
        echo "  ❌ SOME TESTS FAILED"
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
    exit $?
fi
