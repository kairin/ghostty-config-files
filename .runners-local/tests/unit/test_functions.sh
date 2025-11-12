#!/bin/bash
# Module: test_functions.sh
# Purpose: Test helper functions for bash unit testing (assertions, mocking, utilities)
# Dependencies: None
# Modules Required: None
# Exit Codes: 0=assertion passed, 1=assertion failed

# Note: This is a library file meant to be sourced, not executed

set -euo pipefail

# ============================================================
# GLOBAL TEST STATE
# ============================================================

# Mock command registry
declare -gA MOCKED_COMMANDS
declare -gA ORIGINAL_PATHS

# Temporary PATH override
TEST_MOCK_DIR=""

# ============================================================
# ASSERTION FUNCTIONS
# ============================================================

# Assert two values are equal
# Usage: assert_equals <expected> <actual> [message]
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: $message" >&2
        echo "     Expected: '$expected'" >&2
        echo "     Actual:   '$actual'" >&2
        return 1
    fi
}

# Assert two values are not equal
# Usage: assert_not_equals <expected> <actual> [message]
assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"

    if [[ "$expected" != "$actual" ]]; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: $message" >&2
        echo "     Expected NOT: '$expected'" >&2
        echo "     Actual:       '$actual'" >&2
        return 1
    fi
}

# Assert condition is true
# Usage: assert_true <condition> [message]
assert_true() {
    local condition="$1"
    local message="${2:-Condition should be true}"

    if [[ "$condition" == "true" ]] || [[ "$condition" == "0" ]] || [[ -n "$condition" && "$condition" != "false" ]]; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: $message" >&2
        echo "     Condition: '$condition'" >&2
        return 1
    fi
}

# Assert condition is false
# Usage: assert_false <condition> [message]
assert_false() {
    local condition="$1"
    local message="${2:-Condition should be false}"

    if [[ "$condition" == "false" ]] || [[ "$condition" == "1" ]] || [[ -z "$condition" ]]; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: $message" >&2
        echo "     Condition: '$condition'" >&2
        return 1
    fi
}

# Assert string contains substring
# Usage: assert_contains <haystack> <needle> [message]
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: $message" >&2
        echo "     Haystack: '$haystack'" >&2
        echo "     Needle:   '$needle'" >&2
        return 1
    fi
}

# Assert string does not contain substring
# Usage: assert_not_contains <haystack> <needle> [message]
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should not contain substring}"

    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: $message" >&2
        echo "     Haystack: '$haystack'" >&2
        echo "     Should not contain: '$needle'" >&2
        return 1
    fi
}

# Assert command succeeds (exit code 0)
# Usage: assert_success <command> [args...] [message]
assert_success() {
    local last_arg="${*: -1}"
    local message=""

    # Check if last arg looks like a message (not a command arg)
    if [[ "$last_arg" =~ ^[A-Z] ]]; then
        message="$last_arg"
        set -- "${@:1:$(($#-1))}"
    else
        message="Command should succeed"
    fi

    if "$@" &>/dev/null; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: $message" >&2
        echo "     Command: $*" >&2
        echo "     Expected: exit code 0" >&2
        return 1
    fi
}

# Assert command fails (exit code non-zero)
# Usage: assert_fails <command> [args...] [message]
assert_fails() {
    local last_arg="${*: -1}"
    local message=""

    # Check if last arg looks like a message (not a command arg)
    if [[ "$last_arg" =~ ^[A-Z] ]]; then
        message="$last_arg"
        set -- "${@:1:$(($#-1))}"
    else
        message="Command should fail"
    fi

    if ! "$@" &>/dev/null; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: $message" >&2
        echo "     Command: $*" >&2
        echo "     Expected: non-zero exit code" >&2
        return 1
    fi
}

# Assert file exists
# Usage: assert_file_exists <file_path> [message]
assert_file_exists() {
    local file_path="$1"
    local message="${2:-File should exist}"

    if [[ -f "$file_path" ]]; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: $message" >&2
        echo "     File: '$file_path'" >&2
        return 1
    fi
}

# Assert file does not exist
# Usage: assert_file_not_exists <file_path> [message]
assert_file_not_exists() {
    local file_path="$1"
    local message="${2:-File should not exist}"

    if [[ ! -f "$file_path" ]]; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: $message" >&2
        echo "     File should not exist: '$file_path'" >&2
        return 1
    fi
}

# Assert directory exists
# Usage: assert_dir_exists <dir_path> [message]
assert_dir_exists() {
    local dir_path="$1"
    local message="${2:-Directory should exist}"

    if [[ -d "$dir_path" ]]; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: $message" >&2
        echo "     Directory: '$dir_path'" >&2
        return 1
    fi
}

# Assert exit code matches expected
# Usage: assert_exit_code <expected_code> <command> [args...]
assert_exit_code() {
    local expected_code="$1"
    shift

    set +e
    "$@" &>/dev/null
    local actual_code=$?
    set -e

    if [[ $actual_code -eq $expected_code ]]; then
        return 0
    else
        echo "  ❌ ASSERTION FAILED: Exit code mismatch" >&2
        echo "     Command: $*" >&2
        echo "     Expected: $expected_code" >&2
        echo "     Actual:   $actual_code" >&2
        return 1
    fi
}

# ============================================================
# MOCKING FUNCTIONS
# ============================================================

# Mock a command with a custom script
# Usage: mock_command <command_name> <mock_script>
# Example: mock_command "ghostty" "echo 'mocked ghostty version 1.0'"
mock_command() {
    local command_name="$1"
    local mock_script="$2"

    # Create mock directory if it doesn't exist
    if [[ -z "$TEST_MOCK_DIR" ]]; then
        TEST_MOCK_DIR=$(mktemp -d)
    fi

    # Save original PATH if first mock
    if [[ -z "${ORIGINAL_PATH:-}" ]]; then
        export ORIGINAL_PATH="$PATH"
    fi

    # Create mock executable
    local mock_file="$TEST_MOCK_DIR/$command_name"
    cat > "$mock_file" << EOF
#!/bin/bash
$mock_script
EOF
    chmod +x "$mock_file"

    # Track mocked command
    MOCKED_COMMANDS["$command_name"]="$mock_file"

    # Update PATH to prioritize mock directory
    if [[ "$PATH" != "$TEST_MOCK_DIR"* ]]; then
        export PATH="$TEST_MOCK_DIR:$PATH"
    fi

    echo "  🎭 Mocked command: $command_name" >&2
}

# Restore all mocked commands
# Usage: restore_mocks
restore_mocks() {
    # Restore original PATH
    if [[ -n "${ORIGINAL_PATH:-}" ]]; then
        export PATH="$ORIGINAL_PATH"
        unset ORIGINAL_PATH
    fi

    # Clean up mock directory
    if [[ -n "$TEST_MOCK_DIR" ]] && [[ -d "$TEST_MOCK_DIR" ]]; then
        rm -rf "$TEST_MOCK_DIR"
        TEST_MOCK_DIR=""
    fi

    # Clear mock registry
    MOCKED_COMMANDS=()

    echo "  🔄 Restored all mocked commands" >&2
}

# Check if command is currently mocked
# Usage: is_mocked <command_name>
is_mocked() {
    local command_name="$1"
    [[ -n "${MOCKED_COMMANDS[$command_name]:-}" ]]
}

# ============================================================
# TEST UTILITIES
# ============================================================

# Create a temporary test file with content
# Usage: create_test_file <filename> <content>
# Returns: Full path to created file
create_test_file() {
    local filename="$1"
    local content="$2"

    if [[ -z "${TEST_TEMP_DIR:-}" ]]; then
        echo "ERROR: TEST_TEMP_DIR not set. Call setup_all first." >&2
        return 1
    fi

    local file_path="$TEST_TEMP_DIR/$filename"
    echo "$content" > "$file_path"
    echo "$file_path"
}

# Capture stdout and stderr of a command
# Usage: capture_output <command> [args...]
# Sets: CAPTURED_STDOUT, CAPTURED_STDERR, CAPTURED_EXIT_CODE
capture_output() {
    local stdout_file=$(mktemp)
    local stderr_file=$(mktemp)

    set +e
    "$@" > "$stdout_file" 2> "$stderr_file"
    CAPTURED_EXIT_CODE=$?
    set -e

    CAPTURED_STDOUT=$(cat "$stdout_file")
    CAPTURED_STDERR=$(cat "$stderr_file")

    rm -f "$stdout_file" "$stderr_file"
}

# Wait for condition with timeout
# Usage: wait_for <timeout_seconds> <condition_command>
# Example: wait_for 5 "test -f /tmp/file.txt"
wait_for() {
    local timeout="$1"
    shift
    local condition="$*"

    local elapsed=0
    while (( elapsed < timeout )); do
        if eval "$condition" &>/dev/null; then
            return 0
        fi
        sleep 1
        ((elapsed++))
    done

    echo "  ⏱️ Timeout waiting for condition: $condition" >&2
    return 1
}

# ============================================================
# OUTPUT HELPERS
# ============================================================

# Print a test section header
# Usage: test_section <title>
test_section() {
    local title="$1"
    echo ""
    echo "────────────────────────────────────────────────────────"
    echo "  $title"
    echo "────────────────────────────────────────────────────────"
}

# Print success message
# Usage: test_pass <message>
test_pass() {
    local message="$1"
    echo "  ✅ PASS: $message"
}

# Print failure message
# Usage: test_fail <message>
test_fail() {
    local message="$1"
    echo "  ❌ FAIL: $message" >&2
}

# Print info message
# Usage: test_info <message>
test_info() {
    local message="$1"
    echo "  ℹ️  INFO: $message"
}

# ============================================================
# PERFORMANCE HELPERS
# ============================================================

# Measure execution time of a command
# Usage: measure_time <command> [args...]
# Returns: Execution time in milliseconds
measure_time() {
    local start_time=$(date +%s%N)

    "$@" &>/dev/null || true

    local end_time=$(date +%s%N)
    local duration_ns=$((end_time - start_time))
    local duration_ms=$((duration_ns / 1000000))

    echo "$duration_ms"
}

# Assert command completes within time limit
# Usage: assert_completes_within <max_ms> <command> [args...]
assert_completes_within() {
    local max_ms="$1"
    shift

    local duration_ms=$(measure_time "$@")

    if (( duration_ms <= max_ms )); then
        test_info "Completed in ${duration_ms}ms (limit: ${max_ms}ms)"
        return 0
    else
        echo "  ❌ ASSERTION FAILED: Command too slow" >&2
        echo "     Command: $*" >&2
        echo "     Max time: ${max_ms}ms" >&2
        echo "     Actual:   ${duration_ms}ms" >&2
        return 1
    fi
}

# ============================================================
# SETUP/TEARDOWN HELPERS
# ============================================================

# Standard setup_all implementation
# Usage: Call from test file's setup_all function
_test_helpers_setup() {
    # Create temp directory if not exists
    if [[ -z "${TEST_TEMP_DIR:-}" ]]; then
        export TEST_TEMP_DIR=$(mktemp -d)
        echo "  📁 Created test temp directory: $TEST_TEMP_DIR"
    fi
}

# Standard teardown_all implementation
# Usage: Call from test file's teardown_all function
_test_helpers_teardown() {
    # Restore mocks
    if [[ ${#MOCKED_COMMANDS[@]} -gt 0 ]]; then
        restore_mocks
    fi

    # Clean up temp directory
    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        echo "  🧹 Cleaned up test temp directory"
    fi
}

# ============================================================
# MODULE INFO
# ============================================================

echo "✅ Test helper functions loaded (v1.0.0)" >&2
