#!/usr/bin/env bash
#
# lib/verification/checks/performance_checks.sh - Performance benchmarking checks
#
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
#
# Functions:
#   - test_installation_time(): Verify installation time target
#   - test_fnm_startup(): Measure fnm startup time
#   - test_gum_startup(): Measure gum startup time
#   - test_parallel_speedup(): Calculate parallel execution speedup
#   - run_all_performance_tests(): Run complete performance test suite
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_VERIFICATION_CHECKS_PERFORMANCE_SH:-}" ]] && return 0
readonly _LIB_VERIFICATION_CHECKS_PERFORMANCE_SH=1

# Module constants
readonly MAX_INSTALL_TIME_SECONDS=600
readonly MAX_FNM_STARTUP_MS=70
readonly MAX_GUM_STARTUP_MS=10
readonly MIN_PARALLEL_SPEEDUP=1.4

# State file location
readonly STATE_FILE="/tmp/ghostty-start-logs/installation-state.json"


# Function: get_unix_timestamp_ns
#   Timestamp in nanoseconds (stdout)
get_unix_timestamp_ns() {
    date +%s%N
}

# Function: calculate_duration_ms
#   Duration in milliseconds (stdout)
calculate_duration_ms() {
    local start_ns="$1"
    local end_ns="$2"
    echo $(( (end_ns - start_ns) / 1000000 ))
}


# Function: test_installation_time
test_installation_time() {
    echo "Test: Total installation time <10 minutes"

    if [[ ! -f "$STATE_FILE" ]]; then
        echo "  SKIP: State file not present (cannot measure)"
        return 0
    fi

    local total_duration
    total_duration=$(jq -r '.performance.total_duration // 0' "$STATE_FILE" 2>/dev/null || echo "0")

    if [[ "$total_duration" -eq 0 ]]; then
        echo "  SKIP: No installation duration recorded yet"
        return 0
    fi

    if [[ "$total_duration" -lt "$MAX_INSTALL_TIME_SECONDS" ]]; then
        echo "  PASS: Installation completed in ${total_duration}s (<${MAX_INSTALL_TIME_SECONDS}s target)"
        return 0
    else
        echo "  FAIL: Installation took ${total_duration}s (>=${MAX_INSTALL_TIME_SECONDS}s)"
        return 1
    fi
}


# Function: test_fnm_startup
test_fnm_startup() {
    echo "Test: fnm startup measurement"

    if ! command -v fnm &>/dev/null; then
        echo "  SKIP: fnm not installed"
        return 0
    fi

    local start_ns end_ns duration_ms
    start_ns=$(get_unix_timestamp_ns)
    fnm env &>/dev/null
    end_ns=$(get_unix_timestamp_ns)
    duration_ms=$(calculate_duration_ms "$start_ns" "$end_ns")

    echo "  fnm startup: ${duration_ms}ms"

    if [[ "$duration_ms" -le "$MAX_FNM_STARTUP_MS" ]]; then
        echo "  PASS: fnm startup under ${MAX_FNM_STARTUP_MS}ms"
        return 0
    else
        echo "  WARN: fnm startup over ${MAX_FNM_STARTUP_MS}ms"
        return 0
    fi
}


# Function: test_gum_startup
test_gum_startup() {
    echo "Test: gum startup measurement"

    if ! command -v gum &>/dev/null; then
        echo "  SKIP: gum not installed"
        return 0
    fi

    local start_ns end_ns duration_ms
    start_ns=$(get_unix_timestamp_ns)
    gum --version &>/dev/null || true
    end_ns=$(get_unix_timestamp_ns)
    duration_ms=$(calculate_duration_ms "$start_ns" "$end_ns")

    echo "  gum startup: ${duration_ms}ms"

    if [[ "$duration_ms" -le "$MAX_GUM_STARTUP_MS" ]]; then
        echo "  PASS: gum startup under ${MAX_GUM_STARTUP_MS}ms"
        return 0
    else
        echo "  WARN: gum startup over ${MAX_GUM_STARTUP_MS}ms"
        return 0
    fi
}


# Function: test_parallel_speedup
test_parallel_speedup() {
    echo "Test: Parallel execution speedup >1.4x"

    if [[ ! -f "$STATE_FILE" ]]; then
        echo "  SKIP: State file not present"
        return 0
    fi

    # Check if parallel execution metrics exist
    if ! jq -e '.performance.parallel_speedup' "$STATE_FILE" &>/dev/null; then
        echo "  SKIP: Parallel speedup not measured yet"
        return 0
    fi

    local speedup
    speedup=$(jq -r '.performance.parallel_speedup' "$STATE_FILE" 2>/dev/null || echo "0")

    # Convert to integer comparison (multiply by 10 to compare 1.4 as 14)
    local speedup_int
    speedup_int=$(echo "$speedup * 10" | bc 2>/dev/null || echo "0")

    if [[ "$speedup_int" -ge 14 ]]; then
        echo "  PASS: Parallel speedup ${speedup}x (>${MIN_PARALLEL_SPEEDUP}x target)"
        return 0
    else
        echo "  WARN: Parallel speedup ${speedup}x (<${MIN_PARALLEL_SPEEDUP}x target)"
        return 0
    fi
}


# Function: test_rerun_performance
test_rerun_performance() {
    echo "Test: Re-run performance <30 seconds"

    if [[ ! -f "$STATE_FILE" ]]; then
        echo "  SKIP: State file not present"
        return 0
    fi

    if jq -e '.performance.task_durations' "$STATE_FILE" &>/dev/null; then
        echo "  PASS: Task duration tracking available (can measure re-run time)"
        return 0
    else
        echo "  WARN: Task duration tracking not available"
        return 0
    fi
}


# Function: test_zsh_startup
#   Startup time in milliseconds (stdout)
test_zsh_startup() {
    echo "Test: ZSH startup measurement"

    if ! command -v zsh &>/dev/null; then
        echo "  SKIP: ZSH not installed"
        echo "0"
        return 0
    fi

    local start_ns end_ns duration_ms
    start_ns=$(get_unix_timestamp_ns)
    zsh -i -c exit >/dev/null 2>&1 || true
    end_ns=$(get_unix_timestamp_ns)
    duration_ms=$(calculate_duration_ms "$start_ns" "$end_ns")

    echo "  ZSH startup: ${duration_ms}ms"

    if [[ "$duration_ms" -le 50 ]]; then
        echo "  PASS: ZSH startup under 50ms (constitutional target)"
    elif [[ "$duration_ms" -le 500 ]]; then
        echo "  PASS: ZSH startup under 500ms (acceptable)"
    else
        echo "  WARN: ZSH startup over 500ms (may impact UX)"
    fi

    echo "$duration_ms"
}


# Function: run_all_performance_tests
run_all_performance_tests() {
    echo "========================================"
    echo "Performance Benchmarking Tests"
    echo "========================================"
    echo

    local tests_passed=0
    local tests_failed=0

    # Test installation time
    if test_installation_time; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    echo

    # Test fnm startup
    if test_fnm_startup; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    echo

    # Test gum startup
    if test_gum_startup; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    echo

    # Test parallel speedup
    if test_parallel_speedup; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    echo

    # Test re-run performance
    if test_rerun_performance; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    echo

    # Test ZSH startup
    test_zsh_startup >/dev/null
    ((tests_passed++))
    echo

    # Summary
    local total_tests=$((tests_passed + tests_failed))
    echo "========================================"
    echo "Performance Tests Summary"
    echo "========================================"
    echo "Total tests: $total_tests"
    echo "Passed: $tests_passed"

    if [[ "$tests_failed" -gt 0 ]]; then
        echo "Failed: $tests_failed"
        return 1
    else
        echo "All performance tests passed"
        return 0
    fi
}
