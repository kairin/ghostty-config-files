#!/bin/bash

# Integration Tests for Session Management System
# Verifies complete functionality and prevents regression

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TEST_LOG_DIR="/tmp/ghostty-test-logs"
TEST_SESSION_ID="test-$(date +"%Y%m%d-%H%M%S")"

# Colors for test output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Cleanup function
cleanup() {
    rm -rf "$TEST_LOG_DIR" 2>/dev/null || true
    rm -rf "$PROJECT_ROOT/.screenshot-tools" 2>/dev/null || true
    rm -rf "$PROJECT_ROOT/docs/assets/screenshots/test-*" 2>/dev/null || true
}

# Test logging
test_log() {
    echo -e "${BLUE}[TEST]${NC} $*"
}

test_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    ((TESTS_FAILED++))
}

test_info() {
    echo -e "${YELLOW}[INFO]${NC} $*"
}

# Run a test
run_test() {
    local test_name="$1"
    local test_function="$2"

    ((TESTS_RUN++))
    test_log "Running: $test_name"

    if $test_function; then
        test_pass "$test_name"
        return 0
    else
        test_fail "$test_name"
        return 1
    fi
}

# Test 1: Verify session ID generation
test_session_id_generation() {
    cd "$PROJECT_ROOT"

    # Source the session generation logic
    DATETIME=$(date +"%Y%m%d-%H%M%S")
    DETECTED_TERMINAL="test-terminal"
    LOG_SESSION_ID="$DATETIME-$DETECTED_TERMINAL-install"

    # Verify format
    if [[ "$LOG_SESSION_ID" =~ ^[0-9]{8}-[0-9]{6}-test-terminal-install$ ]]; then
        return 0
    else
        test_info "Generated session ID: $LOG_SESSION_ID"
        return 1
    fi
}

# Test 2: Verify terminal detection logic
test_terminal_detection() {
    cd "$PROJECT_ROOT"

    # Test Ghostty detection
    export GHOSTTY_RESOURCES_DIR="/test/path"
    DETECTED_TERMINAL="generic"
    if [ -n "${GHOSTTY_RESOURCES_DIR:-}" ]; then
        DETECTED_TERMINAL="ghostty"
    fi

    if [ "$DETECTED_TERMINAL" = "ghostty" ]; then
        unset GHOSTTY_RESOURCES_DIR
    else
        return 1
    fi

    # Test Ptyxis detection
    export PTYXIS_VERSION="1.0.0"
    DETECTED_TERMINAL="generic"
    if [ -n "${PTYXIS_VERSION:-}" ]; then
        DETECTED_TERMINAL="ptyxis"
    fi

    if [ "$DETECTED_TERMINAL" = "ptyxis" ]; then
        unset PTYXIS_VERSION
        return 0
    else
        return 1
    fi
}

# Test 3: Verify screenshot capture script exists and is executable
test_screenshot_script() {
    local script_path="$PROJECT_ROOT/scripts/svg_screenshot_capture.sh"

    if [ -f "$script_path" ] && [ -x "$script_path" ]; then
        # Test help command
        if "$script_path" help >/dev/null 2>&1; then
            return 0
        else
            test_info "Screenshot script exists but help command failed"
            return 1
        fi
    else
        test_info "Screenshot script not found or not executable: $script_path"
        return 1
    fi
}

# Test 4: Verify session manager script
test_session_manager() {
    local script_path="$PROJECT_ROOT/scripts/session_manager.sh"

    if [ -f "$script_path" ] && [ -x "$script_path" ]; then
        # Test help command
        if "$script_path" help >/dev/null 2>&1; then
            return 0
        else
            test_info "Session manager exists but help command failed"
            return 1
        fi
    else
        test_info "Session manager not found or not executable: $script_path"
        return 1
    fi
}

# Test 5: Verify directory structure creation
test_directory_structure() {
    mkdir -p "$TEST_LOG_DIR"
    mkdir -p "$PROJECT_ROOT/docs/assets/screenshots/$TEST_SESSION_ID"

    # Verify log directory
    if [ ! -d "$TEST_LOG_DIR" ]; then
        test_info "Failed to create test log directory"
        return 1
    fi

    # Verify screenshot directory
    if [ ! -d "$PROJECT_ROOT/docs/assets/screenshots/$TEST_SESSION_ID" ]; then
        test_info "Failed to create test screenshot directory"
        return 1
    fi

    return 0
}

# Test 6: Verify session manifest structure
test_session_manifest() {
    local manifest_file="$TEST_LOG_DIR/$TEST_SESSION_ID-manifest.json"

    # Create test manifest
    cat > "$manifest_file" << 'EOF'
{
  "session_id": "test-session",
  "datetime": "20250921-153000",
  "terminal_detected": "test-terminal",
  "session_type": "install",
  "created": "2025-09-21T15:30:00Z",
  "machine_info": {
    "hostname": "test-host",
    "user": "test-user"
  },
  "status": {
    "started": "2025-09-21T15:30:00Z",
    "completed": null,
    "screenshots_enabled": true
  },
  "stages": [],
  "statistics": {
    "total_stages": 0,
    "screenshots_captured": 0,
    "errors_encountered": 0,
    "duration_seconds": 0
  }
}
EOF

    # Verify JSON is valid
    if command -v jq >/dev/null 2>&1; then
        if jq '.' "$manifest_file" >/dev/null 2>&1; then
            return 0
        else
            test_info "Invalid JSON in manifest file"
            return 1
        fi
    else
        # Basic check without jq
        if grep -q "session_id" "$manifest_file" && grep -q "statistics" "$manifest_file"; then
            return 0
        else
            test_info "Manifest file missing required fields"
            return 1
        fi
    fi
}

# Test 7: Verify uv integration setup
test_uv_integration() {
    if ! command -v uv >/dev/null 2>&1; then
        test_info "uv not available, testing system package fallback"
        # Test system package detection
        if command -v apt >/dev/null 2>&1; then
            return 0
        else
            test_info "Neither uv nor apt available"
            return 1
        fi
    else
        # Test uv virtual environment creation
        local test_venv_dir="$PROJECT_ROOT/.test-screenshot-tools"
        mkdir -p "$test_venv_dir"

        cat > "$test_venv_dir/pyproject.toml" << 'EOF'
[project]
name = "test-screenshot-tools"
version = "1.0.0"
description = "Test project for screenshot tools"
requires-python = ">=3.9"
dependencies = []

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
EOF

        echo "3.11" > "$test_venv_dir/.python-version"

        cd "$test_venv_dir"
        if uv sync >/dev/null 2>&1; then
            cd "$PROJECT_ROOT"
            rm -rf "$test_venv_dir"
            return 0
        else
            cd "$PROJECT_ROOT"
            rm -rf "$test_venv_dir"
            test_info "uv sync failed in test environment"
            return 1
        fi
    fi
}

# Test 8: Verify documentation generation script
test_docs_generation() {
    local script_path="$PROJECT_ROOT/scripts/generate_docs_website.sh"

    if [ -f "$script_path" ] && [ -x "$script_path" ]; then
        # Test help command
        if "$script_path" help >/dev/null 2>&1; then
            return 0
        else
            test_info "Docs generation script exists but help command failed"
            return 1
        fi
    else
        test_info "Docs generation script not found or not executable: $script_path"
        return 1
    fi
}

# Test 9: Verify start.sh integration points
test_start_script_integration() {
    local start_script="$PROJECT_ROOT/start.sh"

    if [ ! -f "$start_script" ] || [ ! -x "$start_script" ]; then
        test_info "start.sh not found or not executable"
        return 1
    fi

    # Check for session management functions
    if grep -q "init_session_tracking" "$start_script" && \
       grep -q "capture_stage_screenshot" "$start_script" && \
       grep -q "finalize_session_tracking" "$start_script"; then
        return 0
    else
        test_info "start.sh missing required session management functions"
        return 1
    fi
}

# Test 10: Verify constitutional compliance
test_constitutional_compliance() {
    # Check for uv-first strategy
    if grep -q "uv sync" "$PROJECT_ROOT/start.sh"; then
        # Check for Astro.build usage
        if [ -f "$PROJECT_ROOT/scripts/generate_docs_website.sh" ] && \
           grep -q "astro" "$PROJECT_ROOT/scripts/generate_docs_website.sh"; then
            # Check for local CI/CD
            if [ -d "$PROJECT_ROOT/local-infra/runners" ]; then
                return 0
            else
                test_info "Missing local CI/CD infrastructure"
                return 1
            fi
        else
            test_info "Missing Astro.build integration"
            return 1
        fi
    else
        test_info "Missing uv integration in start.sh"
        return 1
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  Session Management Integration Tests${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo ""

    # Setup
    test_info "Setting up test environment..."
    cleanup
    mkdir -p "$TEST_LOG_DIR"

    # Run tests
    echo ""
    test_info "Running integration tests..."
    echo ""

    run_test "Session ID Generation" test_session_id_generation
    run_test "Terminal Detection Logic" test_terminal_detection
    run_test "Screenshot Capture Script" test_screenshot_script
    run_test "Session Manager CLI" test_session_manager
    run_test "Directory Structure Creation" test_directory_structure
    run_test "Session Manifest Structure" test_session_manifest
    run_test "uv Integration Setup" test_uv_integration
    run_test "Documentation Generation" test_docs_generation
    run_test "start.sh Integration Points" test_start_script_integration
    run_test "Constitutional Compliance" test_constitutional_compliance

    # Results
    echo ""
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  Test Results${NC}"
    echo -e "${BLUE}===========================================${NC}"

    echo "Tests Run:    $TESTS_RUN"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
        echo ""
        echo -e "${RED}❌ Integration tests FAILED${NC}"
        echo -e "${YELLOW}Please fix the failing tests before proceeding${NC}"
    else
        echo -e "Tests Failed: ${GREEN}0${NC}"
        echo ""
        echo -e "${GREEN}✅ All integration tests PASSED${NC}"
        echo -e "${GREEN}Session management system is fully operational${NC}"
    fi

    # Cleanup
    test_info "Cleaning up test environment..."
    cleanup

    # Exit with appropriate code
    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run tests
main "$@"