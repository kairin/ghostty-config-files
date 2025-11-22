#!/bin/bash
#
# Performance Benchmarking System
# Comprehensive performance measurement and monitoring
#
# Performance Metrics:
# - Lighthouse performance scores
# - Core Web Vitals measurements
# - Build time monitoring
# - Bundle size tracking
# - Memory usage monitoring

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/.update_cache/benchmark_logs"
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly LOG_FILE="${LOG_DIR}/benchmark_${TIMESTAMP}.log"
readonly RESULTS_FILE="${LOG_DIR}/benchmark_results_${TIMESTAMP}.json"
readonly BASELINE_FILE="${LOG_DIR}/baseline_benchmark.json"

# Performance measurement baselines (informational only, not hard targets)
readonly LIGHTHOUSE_PERFORMANCE_BASELINE=95
readonly LIGHTHOUSE_ACCESSIBILITY_BASELINE=95
readonly LIGHTHOUSE_BEST_PRACTICES_BASELINE=95
readonly LIGHTHOUSE_SEO_BASELINE=95
readonly FCP_BASELINE_MS=1500
readonly LCP_BASELINE_MS=2500
readonly CLS_BASELINE=0.1
readonly FID_BASELINE_MS=100
readonly BUILD_TIME_BASELINE_S=30
readonly JS_BUNDLE_BASELINE_KB=100
readonly CSS_BUNDLE_BASELINE_KB=50
readonly MEMORY_BASELINE_MB=512

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Benchmark results tracking
declare -A BENCHMARK_RESULTS

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"

    case "${level}" in
        "ERROR")   echo -e "${RED}❌ ${message}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ ${message}${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  ${message}${NC}" ;;
        "INFO")    echo -e "${BLUE}ℹ️  ${message}${NC}" ;;
        "BENCHMARK") echo -e "${CYAN}📊 ${message}${NC}" ;;
    esac
}

# Store benchmark result
store_result() {
    local metric="$1"
    local value="$2"
    local unit="${3:-}"

    BENCHMARK_RESULTS["${metric}"]="${value}"
    log "BENCHMARK" "${metric}: ${value}${unit}"
}

# Compare against baseline (informational only)
check_baseline() {
    local metric="$1"
    local value="$2"
    local baseline="$3"
    local operator="${4:-le}"  # le (less or equal), ge (greater or equal)

    local comparison="within baseline"
    case "${operator}" in
        "le")
            if (( $(echo "${value} <= ${baseline}" | bc -l) )); then
                comparison="within baseline"
            else
                comparison="above baseline"
            fi
            ;;
        "ge")
            if (( $(echo "${value} >= ${baseline}" | bc -l) )); then
                comparison="within baseline"
            else
                comparison="below baseline"
            fi
            ;;
    esac

    log "INFO" "${metric}: ${value} (baseline: ${operator} ${baseline}, ${comparison})"
    echo "${comparison}"
}

# Build performance benchmark
benchmark_build_performance() {
    log "BENCHMARK" "Running build performance benchmark..."

    if [[ ! -f "${PROJECT_ROOT}/package.json" ]]; then
        log "WARNING" "package.json not found, skipping build benchmark"
        return
    fi

    # Clean previous build
    if [[ -d "${PROJECT_ROOT}/dist" ]]; then
        rm -rf "${PROJECT_ROOT}/dist"
    fi

    # Measure build time
    local start_time=$(date +%s%3N)
    local build_success=false

    if cd "${PROJECT_ROOT}" && timeout 120 npm run build &>/dev/null; then
        build_success=true
    fi

    local end_time=$(date +%s%3N)
    local build_time_ms=$((end_time - start_time))
    local build_time_s=$(echo "scale=2; ${build_time_ms} / 1000" | bc)

    store_result "build_time_ms" "${build_time_ms}" "ms"
    store_result "build_time_s" "${build_time_s}" "s"
    store_result "build_success" "${build_success}"

    if [[ "${build_success}" == "true" ]]; then
        check_baseline "Build Time" "${build_time_s}" "${BUILD_TIME_BASELINE_S}" "le"
    else
        log "ERROR" "Build failed"
    fi
}

# Bundle size benchmark
benchmark_bundle_size() {
    log "BENCHMARK" "Running bundle size benchmark..."

    if [[ ! -d "${PROJECT_ROOT}/dist" ]]; then
        log "WARNING" "dist directory not found, skipping bundle size benchmark"
        return
    fi

    # Calculate JavaScript bundle size
    local js_size_bytes=0
    local js_files
    mapfile -t js_files < <(find "${PROJECT_ROOT}/dist" -name "*.js" -type f 2>/dev/null || true)

    for js_file in "${js_files[@]}"; do
        if [[ -f "${js_file}" ]]; then
            js_size_bytes=$((js_size_bytes + $(stat -c%s "${js_file}")))
        fi
    done

    local js_size_kb=$(echo "scale=2; ${js_size_bytes} / 1024" | bc)

    # Calculate CSS bundle size
    local css_size_bytes=0
    local css_files
    mapfile -t css_files < <(find "${PROJECT_ROOT}/dist" -name "*.css" -type f 2>/dev/null || true)

    for css_file in "${css_files[@]}"; do
        if [[ -f "${css_file}" ]]; then
            css_size_bytes=$((css_size_bytes + $(stat -c%s "${css_file}")))
        fi
    done

    local css_size_kb=$(echo "scale=2; ${css_size_bytes} / 1024" | bc)

    # Calculate total bundle size
    local total_size_bytes=$((js_size_bytes + css_size_bytes))
    local total_size_kb=$(echo "scale=2; ${total_size_bytes} / 1024" | bc)

    store_result "js_bundle_bytes" "${js_size_bytes}" " bytes"
    store_result "js_bundle_kb" "${js_size_kb}" "KB"
    store_result "css_bundle_bytes" "${css_size_bytes}" " bytes"
    store_result "css_bundle_kb" "${css_size_kb}" "KB"
    store_result "total_bundle_bytes" "${total_size_bytes}" " bytes"
    store_result "total_bundle_kb" "${total_size_kb}" "KB"

    # Compare against baselines
    check_baseline "JavaScript Bundle" "${js_size_kb}" "${JS_BUNDLE_BASELINE_KB}" "le"
    check_baseline "CSS Bundle" "${css_size_kb}" "${CSS_BUNDLE_BASELINE_KB}" "le"
}

# Memory usage benchmark
benchmark_memory_usage() {
    log "BENCHMARK" "Running memory usage benchmark..."

    # Get system memory info
    local total_memory_mb
    total_memory_mb=$(free -m | awk 'NR==2{print $2}')

    local available_memory_mb
    available_memory_mb=$(free -m | awk 'NR==2{print $7}')

    local used_memory_mb
    used_memory_mb=$(free -m | awk 'NR==2{print $3}')

    local memory_usage_percent
    memory_usage_percent=$(echo "scale=2; ${used_memory_mb} * 100 / ${total_memory_mb}" | bc)

    store_result "total_memory_mb" "${total_memory_mb}" "MB"
    store_result "available_memory_mb" "${available_memory_mb}" "MB"
    store_result "used_memory_mb" "${used_memory_mb}" "MB"
    store_result "memory_usage_percent" "${memory_usage_percent}" "%"

    # Check if memory usage is reasonable
    check_baseline "Memory Usage" "${used_memory_mb}" "${MEMORY_BASELINE_MB}" "le"
}

# Development server performance benchmark
benchmark_dev_server() {
    log "BENCHMARK" "Running development server benchmark..."

    if [[ ! -f "${PROJECT_ROOT}/package.json" ]]; then
        log "WARNING" "package.json not found, skipping dev server benchmark"
        return
    fi

    # Start dev server in background
    local dev_server_pid=""
    local server_start_time=$(date +%s%3N)

    if cd "${PROJECT_ROOT}"; then
        npm run dev &>/dev/null &
        dev_server_pid=$!

        # Wait for server to start (max 30 seconds)
        local wait_time=0
        local server_ready=false

        while [[ "${wait_time}" -lt 30 ]]; do
            if curl -s http://localhost:4321 &>/dev/null; then
                server_ready=true
                break
            fi
            sleep 1
            wait_time=$((wait_time + 1))
        done

        local server_start_duration=$(( $(date +%s%3N) - server_start_time ))

        if [[ "${server_ready}" == "true" ]]; then
            store_result "dev_server_start_time_ms" "${server_start_duration}" "ms"

            # Test server response time
            local response_start=$(date +%s%3N)
            local response_code
            response_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4321 2>/dev/null || echo "000")
            local response_time=$(( $(date +%s%3N) - response_start ))

            store_result "dev_server_response_time_ms" "${response_time}" "ms"
            store_result "dev_server_response_code" "${response_code}"

            if [[ "${response_code}" == "200" ]]; then
                log "SUCCESS" "Development server responding correctly"
                check_baseline "Dev Server Response Time" "${response_time}" "2000" "le"
            else
                log "ERROR" "Development server returned status ${response_code}"
            fi
        else
            log "ERROR" "Development server failed to start within 30 seconds"
            store_result "dev_server_start_time_ms" "-1" "ms"
        fi

        # Clean up
        if [[ -n "${dev_server_pid}" ]]; then
            kill "${dev_server_pid}" 2>/dev/null || true
            wait "${dev_server_pid}" 2>/dev/null || true
        fi
    fi
}

# Lighthouse performance benchmark
benchmark_lighthouse() {
    log "BENCHMARK" "Running Lighthouse performance benchmark..."

    # Check if lighthouse is available
    if ! command -v lighthouse &>/dev/null; then
        log "WARNING" "Lighthouse not available, skipping Lighthouse benchmark"
        return
    fi

    # Start a temporary server for testing
    local server_pid=""
    if cd "${PROJECT_ROOT}" && [[ -d "dist" ]]; then
        # Use a simple HTTP server for the built site
        python3 -m http.server 8080 --directory dist &>/dev/null &
        server_pid=$!
        sleep 3
    elif cd "${PROJECT_ROOT}" && [[ -f "package.json" ]]; then
        # Use npm run preview if available
        npm run preview &>/dev/null &
        server_pid=$!
        sleep 5
    else
        log "WARNING" "No server available for Lighthouse testing"
        return
    fi

    # Run Lighthouse audit
    local lighthouse_output="/tmp/lighthouse_${TIMESTAMP}.json"
    local lighthouse_url="http://localhost:8080"

    if lighthouse "${lighthouse_url}" \
        --output=json \
        --output-path="${lighthouse_output}" \
        --chrome-flags="--headless --no-sandbox" \
        --quiet &>/dev/null; then

        # Parse Lighthouse results
        if [[ -f "${lighthouse_output}" ]]; then
            local performance_score
            performance_score=$(jq -r '.categories.performance.score * 100 | floor' "${lighthouse_output}" 2>/dev/null || echo "0")

            local accessibility_score
            accessibility_score=$(jq -r '.categories.accessibility.score * 100 | floor' "${lighthouse_output}" 2>/dev/null || echo "0")

            local best_practices_score
            best_practices_score=$(jq -r '.categories["best-practices"].score * 100 | floor' "${lighthouse_output}" 2>/dev/null || echo "0")

            local seo_score
            seo_score=$(jq -r '.categories.seo.score * 100 | floor' "${lighthouse_output}" 2>/dev/null || echo "0")

            # Core Web Vitals
            local fcp_ms
            fcp_ms=$(jq -r '.audits["first-contentful-paint"].numericValue' "${lighthouse_output}" 2>/dev/null || echo "0")

            local lcp_ms
            lcp_ms=$(jq -r '.audits["largest-contentful-paint"].numericValue' "${lighthouse_output}" 2>/dev/null || echo "0")

            local cls_score
            cls_score=$(jq -r '.audits["cumulative-layout-shift"].numericValue' "${lighthouse_output}" 2>/dev/null || echo "0")

            # Store results
            store_result "lighthouse_performance" "${performance_score}" "/100"
            store_result "lighthouse_accessibility" "${accessibility_score}" "/100"
            store_result "lighthouse_best_practices" "${best_practices_score}" "/100"
            store_result "lighthouse_seo" "${seo_score}" "/100"
            store_result "fcp_ms" "${fcp_ms}" "ms"
            store_result "lcp_ms" "${lcp_ms}" "ms"
            store_result "cls_score" "${cls_score}"

            # Compare against baselines
            check_baseline "Lighthouse Performance" "${performance_score}" "${LIGHTHOUSE_PERFORMANCE_BASELINE}" "ge"
            check_baseline "Lighthouse Accessibility" "${accessibility_score}" "${LIGHTHOUSE_ACCESSIBILITY_BASELINE}" "ge"
            check_baseline "Lighthouse Best Practices" "${best_practices_score}" "${LIGHTHOUSE_BEST_PRACTICES_BASELINE}" "ge"
            check_baseline "Lighthouse SEO" "${seo_score}" "${LIGHTHOUSE_SEO_BASELINE}" "ge"
            check_baseline "First Contentful Paint" "${fcp_ms}" "${FCP_BASELINE_MS}" "le"
            check_baseline "Largest Contentful Paint" "${lcp_ms}" "${LCP_BASELINE_MS}" "le"
            check_baseline "Cumulative Layout Shift" "${cls_score}" "${CLS_BASELINE}" "le"

            # Clean up
            rm -f "${lighthouse_output}"
        else
            log "ERROR" "Lighthouse output file not found"
        fi
    else
        log "ERROR" "Lighthouse audit failed"
    fi

    # Clean up server
    if [[ -n "${server_pid}" ]]; then
        kill "${server_pid}" 2>/dev/null || true
        wait "${server_pid}" 2>/dev/null || true
    fi
}

# Python scripts performance benchmark
benchmark_python_scripts() {
    log "BENCHMARK" "Running Python scripts performance benchmark..."

    local python_scripts=(
        "update_checker.py --help"
        "config_validator.py --help"
        "performance_monitor.py --help"
        "ci_cd_runner.py --help"
        "constitutional_automation.py --help"
    )

    for script_cmd in "${python_scripts[@]}"; do
        local script_name=$(echo "${script_cmd}" | cut -d' ' -f1)
        local script_path="${PROJECT_ROOT}/scripts/${script_name}"

        if [[ -f "${script_path}" ]]; then
            local start_time=$(date +%s%3N)
            if timeout 30 python3 "${script_path}" --help &>/dev/null; then
                local end_time=$(date +%s%3N)
                local execution_time=$((end_time - start_time))

                store_result "python_${script_name%.*}_time_ms" "${execution_time}" "ms"
                check_baseline "Python ${script_name}" "${execution_time}" "5000" "le"
            else
                log "ERROR" "Python script ${script_name} failed or timed out"
                store_result "python_${script_name%.*}_time_ms" "-1" "ms"
            fi
        else
            log "WARNING" "Python script ${script_name} not found"
        fi
    done
}

# File system performance benchmark
benchmark_filesystem() {
    log "BENCHMARK" "Running file system performance benchmark..."

    local temp_dir="/tmp/fs_benchmark_$$"
    mkdir -p "${temp_dir}"

    # Write performance test
    local write_start=$(date +%s%3N)
    dd if=/dev/zero of="${temp_dir}/test_file" bs=1M count=10 &>/dev/null
    local write_end=$(date +%s%3N)
    local write_time=$((write_end - write_start))

    # Read performance test
    local read_start=$(date +%s%3N)
    dd if="${temp_dir}/test_file" of=/dev/null bs=1M &>/dev/null
    local read_end=$(date +%s%3N)
    local read_time=$((read_end - read_start))

    # Clean up
    rm -rf "${temp_dir}"

    store_result "fs_write_time_ms" "${write_time}" "ms"
    store_result "fs_read_time_ms" "${read_time}" "ms"

    check_baseline "File System Write (10MB)" "${write_time}" "2000" "le"
    check_baseline "File System Read (10MB)" "${read_time}" "1000" "le"
}

# Generate benchmark comparison
compare_with_baseline() {
    log "BENCHMARK" "Comparing with baseline performance..."

    if [[ ! -f "${BASELINE_FILE}" ]]; then
        log "INFO" "No baseline found, current results will be used as baseline"
        return
    fi

    # Key metrics to compare
    local comparison_metrics=(
        "build_time_s"
        "js_bundle_kb"
        "css_bundle_kb"
        "lighthouse_performance"
        "fcp_ms"
        "lcp_ms"
    )

    log "INFO" "Performance comparison with baseline:"

    for metric in "${comparison_metrics[@]}"; do
        if [[ -n "${BENCHMARK_RESULTS[${metric}]:-}" ]]; then
            local current_value="${BENCHMARK_RESULTS[${metric}]}"
            local baseline_value
            baseline_value=$(jq -r ".${metric} // \"null\"" "${BASELINE_FILE}" 2>/dev/null)

            if [[ "${baseline_value}" != "null" && "${baseline_value}" != "" ]]; then
                local difference
                difference=$(echo "scale=2; ${current_value} - ${baseline_value}" | bc 2>/dev/null || echo "0")

                local percent_change
                if [[ "${baseline_value}" != "0" ]]; then
                    percent_change=$(echo "scale=2; ${difference} * 100 / ${baseline_value}" | bc 2>/dev/null || echo "0")
                else
                    percent_change="N/A"
                fi

                local status="="
                if (( $(echo "${difference} > 0" | bc -l) )); then
                    status="↑"
                elif (( $(echo "${difference} < 0" | bc -l) )); then
                    status="↓"
                fi

                log "INFO" "  ${metric}: ${current_value} ${status} (baseline: ${baseline_value}, change: ${percent_change}%)"
            else
                log "INFO" "  ${metric}: ${current_value} (no baseline)"
            fi
        fi
    done
}

# Save benchmark results
save_benchmark_results() {
    log "BENCHMARK" "Saving benchmark results..."

    # Create JSON output
    local json_output="{"
    json_output="${json_output}\"timestamp\": \"$(date -Iseconds)\","
    json_output="${json_output}\"performance_baselines\": {"
    json_output="${json_output}\"lighthouse_performance\": ${LIGHTHOUSE_PERFORMANCE_BASELINE},"
    json_output="${json_output}\"build_time_s\": ${BUILD_TIME_BASELINE_S},"
    json_output="${json_output}\"js_bundle_kb\": ${JS_BUNDLE_BASELINE_KB},"
    json_output="${json_output}\"css_bundle_kb\": ${CSS_BUNDLE_BASELINE_KB},"
    json_output="${json_output}\"fcp_ms\": ${FCP_BASELINE_MS},"
    json_output="${json_output}\"lcp_ms\": ${LCP_BASELINE_MS},"
    json_output="${json_output}\"cls_score\": ${CLS_BASELINE}"
    json_output="${json_output}},"

    json_output="${json_output}\"results\": {"

    local first=true
    for metric in "${!BENCHMARK_RESULTS[@]}"; do
        if [[ "${first}" == "false" ]]; then
            json_output="${json_output},"
        fi
        json_output="${json_output}\"${metric}\": \"${BENCHMARK_RESULTS[${metric}]}\""
        first=false
    done

    json_output="${json_output}}"
    json_output="${json_output}}"

    echo "${json_output}" | jq '.' > "${RESULTS_FILE}"

    log "SUCCESS" "Benchmark results saved to: ${RESULTS_FILE}"
}

# Update baseline if performance improved
update_baseline() {
    local force_update="${1:-false}"

    if [[ "${force_update}" == "true" || ! -f "${BASELINE_FILE}" ]]; then
        cp "${RESULTS_FILE}" "${BASELINE_FILE}"
        log "SUCCESS" "Baseline updated with current results"
    else
        # Check if performance improved in key metrics
        local should_update=false
        local improvement_metrics=("lighthouse_performance" "build_time_s")

        for metric in "${improvement_metrics[@]}"; do
            if [[ -n "${BENCHMARK_RESULTS[${metric}]:-}" ]]; then
                local current_value="${BENCHMARK_RESULTS[${metric}]}"
                local baseline_value
                baseline_value=$(jq -r ".results.${metric} // \"0\"" "${BASELINE_FILE}" 2>/dev/null)

                # For performance scores, higher is better
                # For time metrics, lower is better
                if [[ "${metric}" == "lighthouse_performance" ]]; then
                    if (( $(echo "${current_value} > ${baseline_value}" | bc -l) )); then
                        should_update=true
                        break
                    fi
                else
                    if (( $(echo "${current_value} < ${baseline_value}" | bc -l) )); then
                        should_update=true
                        break
                    fi
                fi
            fi
        done

        if [[ "${should_update}" == "true" ]]; then
            cp "${RESULTS_FILE}" "${BASELINE_FILE}"
            log "SUCCESS" "Baseline updated due to performance improvements"
        else
            log "INFO" "Baseline not updated (no significant improvements)"
        fi
    fi
}

# Performance baseline comparison (informational)
check_baseline_compliance() {
    log "INFO" "Comparing against performance baselines..."

    local baseline_deviations=0
    local baseline_checks=(
        "lighthouse_performance:${LIGHTHOUSE_PERFORMANCE_BASELINE}:ge"
        "build_time_s:${BUILD_TIME_BASELINE_S}:le"
        "js_bundle_kb:${JS_BUNDLE_BASELINE_KB}:le"
        "css_bundle_kb:${CSS_BUNDLE_BASELINE_KB}:le"
    )

    for check in "${baseline_checks[@]}"; do
        IFS=':' read -r metric baseline operator <<< "${check}"

        if [[ -n "${BENCHMARK_RESULTS[${metric}]:-}" ]]; then
            local value="${BENCHMARK_RESULTS[${metric}]}"
            local result
            result=$(check_baseline "Baseline ${metric}" "${value}" "${baseline}" "${operator}")

            if [[ "${result}" != "within baseline" ]]; then
                baseline_deviations=$((baseline_deviations + 1))
            fi
        fi
    done

    if [[ "${baseline_deviations}" -eq 0 ]]; then
        log "SUCCESS" "✅ All metrics within performance baselines"
        return 0
    else
        log "INFO" "${baseline_deviations} metrics outside baselines (informational)"
        return 0  # Non-blocking
    fi
}

# Main benchmark execution
run_benchmark_suite() {
    local benchmark_type="${1:-all}"

    log "BENCHMARK" "Starting Performance Benchmark Suite"
    log "BENCHMARK" "Benchmark type: ${benchmark_type}"

    case "${benchmark_type}" in
        "all")
            benchmark_build_performance
            benchmark_bundle_size
            benchmark_memory_usage
            benchmark_dev_server
            benchmark_lighthouse
            benchmark_python_scripts
            benchmark_filesystem
            ;;
        "build")
            benchmark_build_performance
            benchmark_bundle_size
            ;;
        "lighthouse")
            benchmark_lighthouse
            ;;
        "scripts")
            benchmark_python_scripts
            ;;
        "system")
            benchmark_memory_usage
            benchmark_filesystem
            ;;
        "server")
            benchmark_dev_server
            ;;
        *)
            log "ERROR" "Unknown benchmark type: ${benchmark_type}"
            log "INFO" "Available types: all, build, lighthouse, scripts, system, server"
            return 1
            ;;
    esac

    compare_with_baseline
    save_benchmark_results

    # Compare against baselines (informational only, non-blocking)
    check_baseline_compliance

    log "SUCCESS" "Performance benchmark completed successfully"
    return 0
}

# Usage function
show_usage() {
    cat << EOF
Performance Benchmarking System

USAGE:
    $0 [benchmark_type] [options]

BENCHMARK TYPES:
    all         - Run complete benchmark suite (default)
    build       - Build performance and bundle size
    lighthouse  - Lighthouse performance audit
    scripts     - Python scripts execution time
    system      - Memory and file system performance
    server      - Development server performance

OPTIONS:
    --update-baseline   - Force update baseline with current results
    --help             - Show this help message

EXAMPLES:
    $0                    # Run complete benchmark suite
    $0 build             # Run only build benchmarks
    $0 lighthouse        # Run only Lighthouse audit
    $0 all --update-baseline  # Run all and update baseline

PERFORMANCE BASELINES (informational):
    • Lighthouse Performance: ≥${LIGHTHOUSE_PERFORMANCE_BASELINE}
    • Build Time: ≤${BUILD_TIME_BASELINE_S}s
    • JavaScript Bundle: ≤${JS_BUNDLE_BASELINE_KB}KB
    • CSS Bundle: ≤${CSS_BUNDLE_BASELINE_KB}KB
    • First Contentful Paint: ≤${FCP_BASELINE_MS}ms
    • Largest Contentful Paint: ≤${LCP_BASELINE_MS}ms
    • Cumulative Layout Shift: ≤${CLS_BASELINE}

OUTPUT:
    • Console output with performance metrics
    • JSON results: ${LOG_DIR}/benchmark_results_TIMESTAMP.json
    • Baseline comparison and updates

EOF
}

# Main execution
main() {
    local benchmark_type="${1:-all}"
    local update_baseline_flag=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --update-baseline)
                update_baseline_flag=true
                shift
                ;;
            --help|-h|help)
                show_usage
                exit 0
                ;;
            *)
                benchmark_type="$1"
                shift
                ;;
        esac
    done

    if ! run_benchmark_suite "${benchmark_type}"; then
        log "ERROR" "Benchmark suite failed"
        exit 1
    fi

    # Update baseline if requested or if it's the first run
    update_baseline "${update_baseline_flag}"

    log "SUCCESS" "Performance Benchmark completed"
    log "INFO" "Results saved to: ${RESULTS_FILE}"
}

# Execute main function with all arguments
main "$@"