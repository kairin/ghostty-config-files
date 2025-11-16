#!/bin/bash
# Module: verification.sh
# Purpose: Dynamic verification framework for installation validation
# Dependencies: common.sh, progress.sh
# Modules Required: None
# Exit Codes: 0=success, 1=verification failed, 2=invalid argument

set -euo pipefail

# Prevent multiple sourcing of this module (idempotent sourcing)
[[ -n "${VERIFICATION_SH_LOADED:-}" ]] && return 0
readonly VERIFICATION_SH_LOADED=1

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/progress.sh"

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: verify_binary
# Purpose: Verify binary installation and optionally check version
# Args:
#   $1=binary_name (required)
#   $2=minimum_version (optional, e.g., "1.2.0")
#   $3=version_command (optional, defaults to "$binary_name --version")
# Returns: 0 if binary exists and meets version requirement, 1 otherwise
# Side Effects: Prints verification status to stdout
# Example: verify_binary "node" "18.0.0" "node --version"
verify_binary() {
    local binary_name="$1"
    local min_version="${2:-}"
    local version_cmd="${3:-$binary_name --version}"

    if [[ -z "$binary_name" ]]; then
        echo "ERROR: Binary name is required" >&2
        return 2
    fi

    # Check if binary exists in PATH
    if ! command -v "$binary_name" &> /dev/null; then
        echo "✗ Binary not found: $binary_name" >&2
        return 1
    fi

    # If no version requirement, just confirm existence
    if [[ -z "$min_version" ]]; then
        local bin_path
        bin_path="$(command -v "$binary_name")"
        echo "✓ Binary found: $binary_name at $bin_path"
        return 0
    fi

    # Extract version from command output
    local installed_version
    if ! installed_version=$(eval "$version_cmd" 2>&1); then
        echo "✗ Failed to get version for $binary_name" >&2
        return 1
    fi

    # Extract version number (first occurrence of semver pattern)
    local version_regex='([0-9]+\.[0-9]+\.[0-9]+)'
    if [[ $installed_version =~ $version_regex ]]; then
        installed_version="${BASH_REMATCH[1]}"
    else
        echo "⚠ Could not parse version from: $installed_version" >&2
        # Still return success if binary exists, just warn
        echo "✓ Binary found: $binary_name (version check skipped)"
        return 0
    fi

    # Compare versions using sort -V
    if printf '%s\n' "$min_version" "$installed_version" | sort -V -C; then
        echo "✓ Binary verified: $binary_name v$installed_version (>= $min_version)"
        return 0
    else
        echo "✗ Version too old: $binary_name v$installed_version (requires >= $min_version)" >&2
        return 1
    fi
}

# Function: verify_config
# Purpose: Validate configuration file syntax and required settings
# Args:
#   $1=config_file (required, absolute path)
#   $2=syntax_checker (optional, command to validate syntax)
#   $3=required_settings (optional, space-separated list of required keys)
# Returns: 0 if config is valid, 1 otherwise
# Side Effects: Prints validation status to stdout
# Example: verify_config "/path/to/config" "jq empty" "key1 key2"
verify_config() {
    local config_file="$1"
    local syntax_checker="${2:-}"
    local required_settings="${3:-}"

    if [[ -z "$config_file" ]]; then
        echo "ERROR: Config file path is required" >&2
        return 2
    fi

    # Check file existence
    if [[ ! -f "$config_file" ]]; then
        echo "✗ Config file not found: $config_file" >&2
        return 1
    fi

    # Check file readability
    if [[ ! -r "$config_file" ]]; then
        echo "✗ Config file not readable: $config_file" >&2
        return 1
    fi

    # Syntax validation (if syntax_checker provided)
    if [[ -n "$syntax_checker" ]]; then
        if eval "$syntax_checker $config_file" &> /dev/null; then
            echo "✓ Config syntax valid: $config_file"
        else
            echo "✗ Config syntax invalid: $config_file" >&2
            return 1
        fi
    fi

    # Check required settings (if provided)
    if [[ -n "$required_settings" ]]; then
        local missing_settings=()
        for setting in $required_settings; do
            if ! grep -q "^$setting" "$config_file"; then
                missing_settings+=("$setting")
            fi
        done

        if [[ ${#missing_settings[@]} -gt 0 ]]; then
            echo "✗ Missing required settings in $config_file: ${missing_settings[*]}" >&2
            return 1
        fi
    fi

    echo "✓ Config validated: $config_file"
    return 0
}

# Function: verify_service
# Purpose: Check service status and health
# Args:
#   $1=service_name (required)
#   $2=health_check_cmd (optional, custom health check command)
#   $3=expected_output (optional, expected output from health check)
# Returns: 0 if service is healthy, 1 otherwise
# Side Effects: Prints service status to stdout
# Example: verify_service "sshd" "systemctl is-active sshd" "active"
verify_service() {
    local service_name="$1"
    local health_check_cmd="${2:-}"
    local expected_output="${3:-}"

    if [[ -z "$service_name" ]]; then
        echo "ERROR: Service name is required" >&2
        return 2
    fi

    # If no health check provided, use systemctl (if available)
    if [[ -z "$health_check_cmd" ]]; then
        if command -v systemctl &> /dev/null; then
            health_check_cmd="systemctl is-active $service_name"
            expected_output="active"
        else
            # Fallback: check if process exists
            health_check_cmd="pgrep -x $service_name"
            expected_output="" # pgrep returns 0 if found
        fi
    fi

    # Run health check
    local output
    if output=$(eval "$health_check_cmd" 2>&1); then
        # Check expected output if provided
        if [[ -n "$expected_output" ]]; then
            if [[ "$output" == "$expected_output" ]]; then
                echo "✓ Service healthy: $service_name ($output)"
                return 0
            else
                echo "✗ Service unhealthy: $service_name (expected: $expected_output, got: $output)" >&2
                return 1
            fi
        else
            echo "✓ Service healthy: $service_name"
            return 0
        fi
    else
        echo "✗ Service check failed: $service_name" >&2
        return 1
    fi
}

# Function: verify_integration
# Purpose: Functional end-to-end validation of integrated components
# Args:
#   $1=test_name (required, descriptive name)
#   $2=test_command (required, command to execute)
#   $3=expected_exit_code (optional, defaults to 0)
#   $4=expected_output_pattern (optional, regex pattern to match)
# Returns: 0 if integration test passes, 1 otherwise
# Side Effects: Prints test results to stdout
# Example: verify_integration "Node.js script execution" "node -e 'console.log(42)'" "0" "42"
verify_integration() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    local expected_output_pattern="${4:-}"

    if [[ -z "$test_name" ]]; then
        echo "ERROR: Test name is required" >&2
        return 2
    fi

    if [[ -z "$test_command" ]]; then
        echo "ERROR: Test command is required" >&2
        return 2
    fi

    # Run integration test
    local output
    local exit_code

    set +e  # Temporarily disable errexit to capture exit code
    output=$(eval "$test_command" 2>&1)
    exit_code=$?
    set -e

    # Check exit code
    if [[ $exit_code -ne $expected_exit_code ]]; then
        echo "✗ Integration test failed: $test_name" >&2
        echo "  Expected exit code: $expected_exit_code, got: $exit_code" >&2
        echo "  Output: $output" >&2
        return 1
    fi

    # Check output pattern if provided
    if [[ -n "$expected_output_pattern" ]]; then
        if echo "$output" | grep -qE "$expected_output_pattern"; then
            echo "✓ Integration test passed: $test_name"
            return 0
        else
            echo "✗ Integration test failed: $test_name" >&2
            echo "  Output did not match pattern: $expected_output_pattern" >&2
            echo "  Actual output: $output" >&2
            return 1
        fi
    fi

    echo "✓ Integration test passed: $test_name"
    return 0
}

# ============================================================
# MODULE SELF-TEST (runs if executed directly, not sourced)
# ============================================================

if [[ $SOURCED_FOR_TESTING -eq 0 ]]; then
    echo "=== Verification Module Self-Test ==="
    echo

    # Test verify_binary
    echo "Test 1: verify_binary with bash (should pass)"
    verify_binary "bash" || echo "FAIL: bash not found"
    echo

    # Test verify_config with /etc/os-release
    echo "Test 2: verify_config with /etc/os-release (should pass)"
    verify_config "/etc/os-release" "" "NAME VERSION_ID" || echo "FAIL: os-release validation"
    echo

    # Test verify_service with cron (if available)
    echo "Test 3: verify_service with cron"
    verify_service "cron" || echo "INFO: cron not running (expected on some systems)"
    echo

    # Test verify_integration with simple command
    echo "Test 4: verify_integration with echo command"
    verify_integration "Echo test" "echo 'Hello World'" "0" "Hello World" || echo "FAIL: integration test"
    echo

    echo "=== Self-Test Complete ==="
fi
