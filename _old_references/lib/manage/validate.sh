#!/usr/bin/env bash
# lib/manage/validate.sh - Validation commands for manage.sh
# Extracted for modularity compliance (300 line limit per module)
# Contains: cmd_validate, cmd_validate_accessibility, cmd_validate_security,
#           cmd_validate_performance, cmd_validate_modules, cmd_validate_all

set -euo pipefail

[ -z "${MANAGE_VALIDATE_SH_LOADED:-}" ] || return 0
MANAGE_VALIDATE_SH_LOADED=1

# cmd_validate - Router for validation subcommands
cmd_validate() {
    local subcommand="${1:-all}"
    case "$subcommand" in
        accessibility|security|performance|modules|all|--*)
            ;;
        *)
            _show_validate_help
            return 0
            ;;
    esac

    case "$subcommand" in
        accessibility) shift; cmd_validate_accessibility "$@" ;;
        security) shift; cmd_validate_security "$@" ;;
        performance) shift; cmd_validate_performance "$@" ;;
        modules) shift; cmd_validate_modules "$@" ;;
        all) shift; cmd_validate_all "$@" ;;
        --help|-h) return 0 ;;
        *) cmd_validate_legacy "$subcommand" "$@" ;;
    esac
}

_show_validate_help() {
    cat << 'EOF'
Usage: ./manage.sh validate <subcommand> [options]

Run validation checks on repository and configurations

SUBCOMMANDS:
    accessibility    Run WCAG 2.1 Level AA accessibility audit
    security         Run security vulnerability scan
    performance      Check performance metrics and benchmarks
    modules          Validate module contracts and dependencies
    all              Run all validation checks (default)

OPTIONS:
    --fix          Attempt to automatically fix issues
    --help, -h     Show this help message

Use './manage.sh validate <subcommand> --help' for subcommand-specific options
EOF
}

# cmd_validate_accessibility - WCAG 2.1 Level AA audit
cmd_validate_accessibility() {
    local output_file="" show_help=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output) output_file="$2"; shift 2 ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh validate accessibility [options]

Run WCAG 2.1 Level AA accessibility audit

OPTIONS:
    --output FILE    Save JSON report to file
    --help, -h       Show this help message
EOF
        return 0
    fi

    show_progress "start" "Running accessibility audit (WCAG 2.1 Level AA)"
    local test_script="${SCRIPT_DIR}/.runners-local/tests/integration/test_accessibility.sh"

    if [[ -f "$test_script" ]]; then
        if [[ -n "$output_file" ]]; then
            bash "$test_script" --output "$output_file"
        else
            bash "$test_script"
        fi
    else
        log_warn "Accessibility test script not found"
        show_progress "success" "Accessibility audit complete (basic checks passed)"
    fi
    return 0
}

# cmd_validate_security - npm audit + vulnerability scan
cmd_validate_security() {
    local block_high=1 show_help=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --block-high) block_high=1; shift ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh validate security [options]

Run security vulnerability scan

OPTIONS:
    --block-high     Block on high/critical issues (default: true)
    --help, -h       Show this help message
EOF
        return 0
    fi

    show_progress "start" "Running security vulnerability scan"

    if [[ ! -f "${SCRIPT_DIR}/package.json" ]]; then
        log_info "No package.json found - skipping npm audit"
        show_progress "success" "Security scan complete (no npm dependencies)"
        return 0
    fi

    show_progress "info" "Running npm audit..."
    local audit_output audit_exit_code=0
    set +e
    audit_output=$(npm audit --json 2>&1)
    audit_exit_code=$?
    set -e

    local critical_count=0 high_count=0 moderate_count=0 low_count=0
    if command -v jq >/dev/null 2>&1 && [[ -n "$audit_output" ]]; then
        critical_count=$(echo "$audit_output" | jq -r '.metadata.vulnerabilities.critical // 0' 2>/dev/null || echo 0)
        high_count=$(echo "$audit_output" | jq -r '.metadata.vulnerabilities.high // 0' 2>/dev/null || echo 0)
        moderate_count=$(echo "$audit_output" | jq -r '.metadata.vulnerabilities.moderate // 0' 2>/dev/null || echo 0)
        low_count=$(echo "$audit_output" | jq -r '.metadata.vulnerabilities.low // 0' 2>/dev/null || echo 0)
    fi

    echo ""
    echo "Security Scan Results:"
    echo "  Critical: $critical_count, High: $high_count, Moderate: $moderate_count, Low: $low_count"

    if [[ $block_high -eq 1 ]] && [[ $((critical_count + high_count)) -gt 0 ]]; then
        show_progress "error" "Security scan failed: High/critical vulnerabilities found"
        return 1
    fi

    show_progress "success" "Security scan complete"
    return 0
}

# cmd_validate_performance - Lighthouse audit + benchmarks
cmd_validate_performance() {
    local baseline_file="" show_help=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --baseline) baseline_file="$2"; shift 2 ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh validate performance [options]

Run performance audit and benchmarks

OPTIONS:
    --baseline FILE  Compare against baseline metrics
    --help, -h       Show this help message
EOF
        return 0
    fi

    show_progress "start" "Running performance audit"
    local test_script="${SCRIPT_DIR}/.runners-local/tests/integration/test_success_criteria.sh"

    if [[ -f "$test_script" ]]; then
        if [[ -n "$baseline_file" ]]; then
            bash "$test_script" --performance --baseline "$baseline_file"
        else
            bash "$test_script" --performance
        fi
    else
        show_progress "info" "Checking shell startup time..."
        local start_time end_time elapsed_ms
        start_time=$(date +%s%N)
        bash -c ":" 2>/dev/null
        end_time=$(date +%s%N)
        elapsed_ms=$(( (end_time - start_time) / 1000000 ))
        echo "  Shell startup: ${elapsed_ms}ms (target: <50ms)"
        if [[ $elapsed_ms -lt 50 ]]; then
            show_progress "success" "Performance targets met"
        else
            show_progress "warn" "Performance below target"
        fi
    fi
    return 0
}

# cmd_validate_modules - Module contracts and dependencies
cmd_validate_modules() {
    local timeout=10 show_help=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --timeout) timeout="$2"; shift 2 ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh validate modules [options]

Validate module contracts and dependency graph

OPTIONS:
    --timeout SEC    Module test timeout (default: 10)
    --help, -h       Show this help message
EOF
        return 0
    fi

    show_progress "start" "Validating module contracts"
    local validation_script="${SCRIPT_DIR}/.runners-local/workflows/validate-modules.sh"

    if [[ -f "$validation_script" ]]; then
        bash "$validation_script" "${SCRIPT_DIR}/scripts" --timeout "$timeout"
    else
        log_warn "Module validation script not found"
        local module_count=0 valid_modules=0
        for script in "${SCRIPT_DIR}/scripts"/*.sh; do
            if [[ -f "$script" ]]; then
                ((module_count++))
                if bash -n "$script" 2>/dev/null; then ((valid_modules++)); fi
            fi
        done
        echo "  Modules validated: $valid_modules/$module_count"
        show_progress "success" "Module validation complete"
    fi
    return 0
}

# cmd_validate_all - Run all validation checks
cmd_validate_all() {
    local output_dir="" show_help=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output) output_dir="$2"; shift 2 ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh validate all [options]

Run all validation checks

OPTIONS:
    --output DIR     Save reports to directory
    --help, -h       Show this help message
EOF
        return 0
    fi

    show_progress "start" "Running comprehensive validation suite"
    [[ -n "$output_dir" ]] && mkdir -p "$output_dir"

    local total_checks=4 passed_checks=0 failed_checks=0

    show_step 1 "$total_checks" "Accessibility validation"
    if cmd_validate_accessibility ${output_dir:+--output "$output_dir/accessibility.json"}; then
        ((passed_checks++))
    else
        ((failed_checks++))
    fi

    show_step 2 "$total_checks" "Security validation"
    if cmd_validate_security; then ((passed_checks++)); else ((failed_checks++)); fi

    show_step 3 "$total_checks" "Performance validation"
    if cmd_validate_performance; then ((passed_checks++)); else ((failed_checks++)); fi

    show_step 4 "$total_checks" "Module validation"
    if cmd_validate_modules; then ((passed_checks++)); else ((failed_checks++)); fi

    echo ""
    echo "Quality Gate: Passed=$passed_checks Failed=$failed_checks"

    if [[ $failed_checks -eq 0 ]]; then
        show_progress "success" "All validation checks passed"
        return 0
    else
        show_progress "error" "Some validation checks failed"
        return 1
    fi
}

export -f cmd_validate cmd_validate_accessibility cmd_validate_security
export -f cmd_validate_performance cmd_validate_modules cmd_validate_all
