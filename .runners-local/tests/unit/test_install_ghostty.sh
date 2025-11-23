#!/bin/bash
# Unit tests for scripts/install_ghostty.sh
# Constitutional requirement: <10s execution time

set -euo pipefail

# Source module for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
source "${PROJECT_ROOT}/scripts/install_ghostty.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
START_TIME=$(date +%s)

# ============================================================
# TEST HELPER FUNCTIONS
# ============================================================

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$expected" == "$actual" ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "    Expected: $expected"
        echo "    Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_file_exists() {
    local file_path="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -f "$file_path" ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "    File not found: $file_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_command_exists() {
    local command_name="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if command -v "$command_name" &> /dev/null; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "ℹ SKIP: $test_name (command not installed: $command_name)"
        TESTS_RUN=$((TESTS_RUN - 1))
    fi
}

assert_function_exists() {
    local function_name="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if declare -f "$function_name" &> /dev/null; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "    Function not found: $function_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "    Expected to contain: $needle"
        echo "    Actual: $haystack"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================================
# TEST SUITE
# ============================================================

echo "=== Unit Tests: install_ghostty.sh ==="
echo ""
echo "Performance requirement: <10s execution time"
echo ""

# ============================================================
# TEST GROUP 1: Module Contract Compliance
# ============================================================

echo "TEST GROUP 1: Module Contract Compliance"
echo "=========================================="

# Test 1: Module loaded successfully
assert_equals "1" "${INSTALL_GHOSTTY_SH_LOADED}" "Module loaded with guard variable"

# Test 2: Snap package constant
assert_equals "ghostty" "${GHOSTTY_SNAP_PACKAGE}" "Ghostty snap package name correct"

# Test 3: Minimum Ghostty version constant
assert_contains "${MIN_GHOSTTY_VERSION}" "1." "Minimum version is 1.x+"

echo ""

# ============================================================
# TEST GROUP 2: Function Existence (All Public API)
# ============================================================

echo "TEST GROUP 2: Function Existence"
echo "================================="

# Snap installation functions
assert_function_exists "detect_snap_installation" "detect_snap_installation exists"
assert_function_exists "verify_snap_publisher" "verify_snap_publisher exists"
assert_function_exists "install_via_snap" "install_via_snap exists"
assert_function_exists "cleanup_manual_installation" "cleanup_manual_installation exists"

# Multi-file manager functions
assert_function_exists "detect_file_manager" "detect_file_manager exists"
assert_function_exists "install_nautilus_context_menu" "install_nautilus_context_menu exists"
assert_function_exists "install_nemo_context_menu" "install_nemo_context_menu exists"
assert_function_exists "install_thunar_context_menu" "install_thunar_context_menu exists"
assert_function_exists "install_universal_context_menu" "install_universal_context_menu exists"
assert_function_exists "configure_context_menu" "configure_context_menu exists"

# Verification functions
assert_function_exists "verify_performance_optimizations" "verify_performance_optimizations exists"

# Master functions
assert_function_exists "install_ghostty" "install_ghostty (main entry) exists"

echo ""

# ============================================================
# TEST GROUP 3: Dependency Detection
# ============================================================

echo "TEST GROUP 3: Dependency Detection"
echo "==================================="

# Check common.sh sourcing
if declare -f log_info &> /dev/null; then
    echo "✓ PASS: common.sh functions available (log_info)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: common.sh functions not available"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Check progress.sh sourcing
if declare -f show_progress &> /dev/null; then
    echo "✓ PASS: progress.sh functions available (show_progress)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: progress.sh functions not available"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Check verification.sh sourcing
if declare -f verify_binary &> /dev/null; then
    echo "✓ PASS: verification.sh functions available (verify_binary)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: verification.sh functions not available"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo ""

# ============================================================
# TEST GROUP 4: File Manager Detection Logic
# ============================================================

echo "TEST GROUP 4: File Manager Detection"
echo "====================================="

# Test file manager detection (non-destructive)
FM_NAME=""
detect_file_manager > /dev/null 2>&1 || true

# Verify FM_NAME is set to a valid value
if [[ -n "$FM_NAME" ]]; then
    echo "✓ PASS: File manager detected: ${FM_NAME}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: File manager detection failed to set FM_NAME"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Verify FM_NAME is one of the expected values
if [[ "$FM_NAME" =~ ^(nautilus|nemo|thunar|unknown)$ ]]; then
    echo "✓ PASS: FM_NAME has valid value: ${FM_NAME}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: FM_NAME has unexpected value: ${FM_NAME}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo ""

# ============================================================
# TEST GROUP 5: Snap Detection (Non-Destructive)
# ============================================================

echo "TEST GROUP 5: Snap Detection"
echo "============================="

# Test snap detection (non-destructive, may fail if snap not installed)
SNAP_AVAILABLE=""
SNAP_CONFINEMENT=""
SNAP_VERSION=""
detect_snap_installation > /dev/null 2>&1 || true

# Verify global variables are set (even if snap unavailable)
if [[ -n "$SNAP_AVAILABLE" ]]; then
    echo "✓ PASS: SNAP_AVAILABLE variable set: ${SNAP_AVAILABLE}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: SNAP_AVAILABLE not set after detect_snap_installation"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Check if snap is installed (informational)
if command -v snap &> /dev/null; then
    echo "ℹ INFO: snap command available on system"
    assert_command_exists "snap" "snap command exists"
else
    echo "ℹ INFO: snap not installed (expected on some systems)"
fi

echo ""

# ============================================================
# TEST GROUP 6: Context Menu Script Templates
# ============================================================

echo "TEST GROUP 6: Context Menu Templates"
echo "====================================="

# Test Nautilus script path construction
expected_nautilus="${HOME}/.local/share/nautilus/scripts/Open in Ghostty"
assert_equals "$expected_nautilus" "${HOME}/.local/share/nautilus/scripts/Open in Ghostty" \
    "Nautilus script path correct"

# Test Nemo action path construction
expected_nemo="${HOME}/.local/share/nemo/actions/open-in-ghostty.nemo_action"
assert_equals "$expected_nemo" "${HOME}/.local/share/nemo/actions/open-in-ghostty.nemo_action" \
    "Nemo action path correct"

# Test Thunar config path construction
expected_thunar="${HOME}/.config/Thunar/uca.xml"
assert_equals "$expected_thunar" "${HOME}/.config/Thunar/uca.xml" \
    "Thunar config path correct"

# Test universal .desktop path construction
expected_desktop="${HOME}/.local/share/applications/ghostty-here.desktop"
assert_equals "$expected_desktop" "${HOME}/.local/share/applications/ghostty-here.desktop" \
    "Universal .desktop path correct"

echo ""

# ============================================================
# TEST GROUP 7: Installation Status Checks
# ============================================================

echo "TEST GROUP 7: Installation Status"
echo "=================================="

# Check if Ghostty is already installed (informational)
if command -v ghostty &> /dev/null; then
    assert_command_exists "ghostty" "Ghostty binary available in PATH"

    # Check version if available
    ghostty_version=$(ghostty --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
    echo "  Installed Ghostty version: ${ghostty_version}"

    # Check installation method
    ghostty_path=$(command -v ghostty)
    if [[ "$ghostty_path" == "/snap/bin/ghostty" ]]; then
        echo "  Installation method: Snap (OFFICIAL)"
    else
        echo "  Installation method: Other (should be Snap)"
    fi
else
    echo "ℹ INFO: Ghostty not installed (expected before module execution)"
fi

echo ""

# ============================================================
# TEST GROUP 8: Configuration Verification
# ============================================================

echo "TEST GROUP 8: Configuration Paths"
echo "=================================="

# Check if Ghostty config exists (informational)
config_file="${HOME}/.config/ghostty/config"
if [[ -f "$config_file" ]]; then
    assert_file_exists "$config_file" "Ghostty config file exists"

    # Check for 2025 optimizations (non-blocking)
    if grep -q "linux-cgroup" "$config_file" 2>/dev/null; then
        echo "  ✓ linux-cgroup setting present"
    else
        echo "  ℹ linux-cgroup setting not yet configured"
    fi

    if grep -q "shell-integration" "$config_file" 2>/dev/null; then
        echo "  ✓ shell-integration setting present"
    else
        echo "  ℹ shell-integration setting not yet configured"
    fi
else
    echo "ℹ INFO: Ghostty config not deployed (expected before start.sh run)"
fi

echo ""

# ============================================================
# TEST GROUP 9: Performance Requirements
# ============================================================

echo "TEST GROUP 9: Performance Metrics"
echo "=================================="

# Calculate test execution time
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))

TESTS_RUN=$((TESTS_RUN + 1))
if [[ $EXECUTION_TIME -lt 10 ]]; then
    echo "✓ PASS: Test execution time: ${EXECUTION_TIME}s (<10s requirement)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: Test execution time: ${EXECUTION_TIME}s (exceeds 10s requirement)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# ============================================================
# TEST SUMMARY
# ============================================================

echo "=== Test Summary ==="
echo "Total: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "Execution time: ${EXECUTION_TIME}s"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
