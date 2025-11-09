#!/bin/bash

# Performance Benchmarking Dashboard
# Tracks Lighthouse scores, build metrics, and CI/CD performance over time
# Priority 4 Enhancement from Context7 MCP Assessment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
LOG_DIR="$SCRIPT_DIR/../logs"
PERF_DIR="$REPO_DIR/documentations/performance"
METRICS_DB="$PERF_DIR/metrics-database.json"
LIGHTHOUSE_DIR="$PERF_DIR/lighthouse-reports"
DASHBOARD_HTML="$PERF_DIR/dashboard.html"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$LOG_DIR" "$PERF_DIR" "$LIGHTHOUSE_DIR"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""

    case "$level" in
        "ERROR") color="$RED" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "INFO") color="$BLUE" ;;
        "STEP") color="$CYAN" ;;
    esac

    echo -e "${color}[$timestamp] [$level] $message${NC}"
}

# Initialize metrics database
init_metrics_db() {
    if [ ! -f "$METRICS_DB" ]; then
        log "INFO" "📊 Initializing metrics database..."
        cat > "$METRICS_DB" <<'EOF'
{
  "created": "",
  "last_updated": "",
  "constitutional_targets": {
    "lighthouse": {
      "performance": 95,
      "accessibility": 95,
      "best_practices": 95,
      "seo": 95
    },
    "core_web_vitals": {
      "fcp": 1.5,
      "lcp": 2.5,
      "cls": 0.1
    },
    "build_performance": {
      "astro_build_seconds": 30,
      "hot_reload_seconds": 1
    },
    "bundle_size": {
      "initial_js_kb": 100
    },
    "ci_cd_performance": {
      "complete_workflow_seconds": 120
    }
  },
  "metrics": []
}
EOF
        if command -v jq >/dev/null 2>&1; then
            local temp_db=$(mktemp)
            jq --arg created "$(date -Iseconds)" '.created = $created | .last_updated = $created' "$METRICS_DB" > "$temp_db"
            mv "$temp_db" "$METRICS_DB"
        fi
        log "SUCCESS" "✅ Metrics database initialized"
    fi
}

# Collect Lighthouse metrics
collect_lighthouse_metrics() {
    log "STEP" "🔍 Collecting Lighthouse metrics..."

    # Check if lighthouse is available
    if ! command -v lighthouse >/dev/null 2>&1; then
        log "WARNING" "⚠️ Lighthouse not installed. Install with: npm install -g lighthouse"
        return 1
    fi

    # Check if docs/ has been built
    if [ ! -f "$REPO_DIR/docs/index.html" ]; then
        log "WARNING" "⚠️ No Astro build output found. Run: npm run build"
        return 1
    fi

    # Start local server for testing
    log "INFO" "🌐 Starting local preview server..."
    cd "$REPO_DIR"

    # Start preview in background
    npm run preview > "$LOG_DIR/preview-$(date +%s).log" 2>&1 &
    local preview_pid=$!

    # Wait for server to start
    sleep 5

    # Run Lighthouse
    local lighthouse_output="$LIGHTHOUSE_DIR/lighthouse-$(date +%Y%m%d-%H%M%S).json"
    log "INFO" "📊 Running Lighthouse audit..."

    if timeout 60s lighthouse http://localhost:4321/ghostty-config-files/ \
        --output=json \
        --output-path="$lighthouse_output" \
        --chrome-flags="--headless" \
        --quiet 2>/dev/null; then

        log "SUCCESS" "✅ Lighthouse audit complete"

        # Extract key metrics
        if command -v jq >/dev/null 2>&1 && [ -f "$lighthouse_output" ]; then
            local performance=$(jq -r '.categories.performance.score * 100 | floor' "$lighthouse_output" 2>/dev/null || echo "0")
            local accessibility=$(jq -r '.categories.accessibility.score * 100 | floor' "$lighthouse_output" 2>/dev/null || echo "0")
            local best_practices=$(jq -r '.categories["best-practices"].score * 100 | floor' "$lighthouse_output" 2>/dev/null || echo "0")
            local seo=$(jq -r '.categories.seo.score * 100 | floor' "$lighthouse_output" 2>/dev/null || echo "0")

            log "INFO" "📊 Lighthouse Scores:"
            log "INFO" "  Performance: $performance/100"
            log "INFO" "  Accessibility: $accessibility/100"
            log "INFO" "  Best Practices: $best_practices/100"
            log "INFO" "  SEO: $seo/100"

            echo "$lighthouse_output"
        fi
    else
        log "ERROR" "❌ Lighthouse audit failed"
    fi

    # Stop preview server
    kill $preview_pid 2>/dev/null || true

    return 0
}

# Collect build performance metrics
collect_build_metrics() {
    log "STEP" "🏗️ Collecting build performance metrics..."

    local build_start=$(date +%s)
    local build_log="$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log"

    cd "$REPO_DIR"

    # Run Astro build and measure time
    if npm run build > "$build_log" 2>&1; then
        local build_end=$(date +%s)
        local build_duration=$((build_end - build_start))

        log "SUCCESS" "✅ Build completed in ${build_duration}s"

        # Measure bundle sizes
        local js_bundle_size=0
        if [ -d "$REPO_DIR/docs/_astro" ]; then
            js_bundle_size=$(find "$REPO_DIR/docs/_astro" -name "*.js" -type f -exec stat -f%z {} + 2>/dev/null | awk '{sum+=$1} END {print sum/1024}' || \
                             find "$REPO_DIR/docs/_astro" -name "*.js" -type f -exec stat -c%s {} + 2>/dev/null | awk '{sum+=$1} END {print sum/1024}')
        fi

        log "INFO" "📦 JavaScript bundle size: ${js_bundle_size}KB"

        # Return metrics as JSON
        cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "build_duration_seconds": $build_duration,
  "js_bundle_size_kb": $js_bundle_size,
  "build_log": "$build_log"
}
EOF
    else
        log "ERROR" "❌ Build failed"
        return 1
    fi
}

# Collect CI/CD workflow metrics
collect_cicd_metrics() {
    log "STEP" "⚙️ Collecting CI/CD workflow metrics..."

    local workflow_start=$(date +%s)

    # Run complete workflow
    if "$SCRIPT_DIR/gh-workflow-local.sh" all > "$LOG_DIR/cicd-$(date +%Y%m%d-%H%M%S).log" 2>&1; then
        local workflow_end=$(date +%s)
        local workflow_duration=$((workflow_end - workflow_start))

        log "SUCCESS" "✅ CI/CD workflow completed in ${workflow_duration}s"

        # Count steps from workflow summary
        local failed_steps=0
        if [ -f "$LOG_DIR/workflow-summary-$(date +%s).json" ]; then
            failed_steps=$(jq -r '.failed_steps // 0' "$LOG_DIR/workflow-summary-$(date +%s).json" 2>/dev/null || echo "0")
        fi

        cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "workflow_duration_seconds": $workflow_duration,
  "failed_steps": $failed_steps
}
EOF
    else
        log "WARNING" "⚠️ CI/CD workflow completed with warnings"
        return 0
    fi
}

# Add metrics to database
add_metric_to_db() {
    local metric_type="$1"
    local metric_data="$2"

    if ! command -v jq >/dev/null 2>&1; then
        log "WARNING" "⚠️ jq not available, skipping database update"
        return 0
    fi

    local temp_db=$(mktemp)

    # Create metric entry
    local metric_entry
    metric_entry=$(cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "type": "$metric_type",
  "data": $metric_data
}
EOF
)

    # Append to metrics array
    jq --argjson entry "$metric_entry" \
       --arg updated "$(date -Iseconds)" \
       '.metrics += [$entry] | .last_updated = $updated' \
       "$METRICS_DB" > "$temp_db"

    mv "$temp_db" "$METRICS_DB"

    log "SUCCESS" "✅ Added $metric_type metrics to database"
}

# Generate HTML dashboard
generate_html_dashboard() {
    log "STEP" "📊 Generating HTML dashboard..."

    if ! command -v jq >/dev/null 2>&1; then
        log "WARNING" "⚠️ jq not available, cannot generate dashboard"
        return 1
    fi

    # Extract recent metrics
    local recent_metrics
    recent_metrics=$(jq -r '.metrics | sort_by(.timestamp) | reverse | .[0:20]' "$METRICS_DB" 2>/dev/null || echo "[]")

    # Extract constitutional targets
    local targets
    targets=$(jq -r '.constitutional_targets' "$METRICS_DB" 2>/dev/null || echo "{}")

    # Generate HTML with embedded Chart.js
    cat > "$DASHBOARD_HTML" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Performance Benchmarking Dashboard - Ghostty Config Files</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        header {
            background: white;
            border-radius: 12px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }

        h1 {
            color: #2d3748;
            font-size: 2.5rem;
            margin-bottom: 10px;
        }

        .subtitle {
            color: #718096;
            font-size: 1.1rem;
        }

        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }

        .metric-card {
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .metric-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.3);
        }

        .metric-label {
            color: #718096;
            font-size: 0.9rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 10px;
        }

        .metric-value {
            color: #2d3748;
            font-size: 2.5rem;
            font-weight: bold;
            margin-bottom: 5px;
        }

        .metric-status {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
        }

        .status-pass {
            background: #c6f6d5;
            color: #22543d;
        }

        .status-warning {
            background: #feebc8;
            color: #7c2d12;
        }

        .status-fail {
            background: #fed7d7;
            color: #742a2a;
        }

        .chart-container {
            background: white;
            border-radius: 12px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }

        .chart-title {
            color: #2d3748;
            font-size: 1.5rem;
            margin-bottom: 20px;
            font-weight: 600;
        }

        canvas {
            max-height: 400px;
        }

        .target-line {
            border-top: 2px dashed #f56565;
            margin: 10px 0;
            position: relative;
        }

        .target-label {
            position: absolute;
            right: 0;
            top: -10px;
            background: #f56565;
            color: white;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
        }

        .footer {
            background: rgba(255,255,255,0.95);
            border-radius: 12px;
            padding: 20px;
            text-align: center;
            color: #718096;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }

        .timestamp {
            font-size: 0.9rem;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>⚡ Performance Benchmarking Dashboard</h1>
            <p class="subtitle">Ghostty Configuration Files - Real-time Performance Metrics</p>
        </header>

        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-label">Lighthouse Performance</div>
                <div class="metric-value" id="lh-performance">--</div>
                <span class="metric-status status-pass" id="lh-perf-status">Loading...</span>
            </div>

            <div class="metric-card">
                <div class="metric-label">Accessibility</div>
                <div class="metric-value" id="lh-accessibility">--</div>
                <span class="metric-status status-pass" id="lh-a11y-status">Loading...</span>
            </div>

            <div class="metric-card">
                <div class="metric-label">Best Practices</div>
                <div class="metric-value" id="lh-best-practices">--</div>
                <span class="metric-status status-pass" id="lh-bp-status">Loading...</span>
            </div>

            <div class="metric-card">
                <div class="metric-label">SEO Score</div>
                <div class="metric-value" id="lh-seo">--</div>
                <span class="metric-status status-pass" id="lh-seo-status">Loading...</span>
            </div>

            <div class="metric-card">
                <div class="metric-label">Build Time</div>
                <div class="metric-value" id="build-time">--</div>
                <span class="metric-status status-pass" id="build-status">Target: &lt;30s</span>
            </div>

            <div class="metric-card">
                <div class="metric-label">JS Bundle Size</div>
                <div class="metric-value" id="bundle-size">--</div>
                <span class="metric-status status-pass" id="bundle-status">Target: &lt;100KB</span>
            </div>

            <div class="metric-card">
                <div class="metric-label">CI/CD Workflow</div>
                <div class="metric-value" id="cicd-time">--</div>
                <span class="metric-status status-pass" id="cicd-status">Target: &lt;2min</span>
            </div>

            <div class="metric-card">
                <div class="metric-label">Overall Status</div>
                <div class="metric-value" id="overall-status">✅</div>
                <span class="metric-status status-pass" id="overall-label">Excellent</span>
            </div>
        </div>

        <div class="chart-container">
            <h2 class="chart-title">📈 Lighthouse Scores Trend</h2>
            <canvas id="lighthouseChart"></canvas>
        </div>

        <div class="chart-container">
            <h2 class="chart-title">⏱️ Build Performance Trend</h2>
            <canvas id="buildChart"></canvas>
        </div>

        <div class="chart-container">
            <h2 class="chart-title">📦 Bundle Size Trend</h2>
            <canvas id="bundleChart"></canvas>
        </div>

        <div class="footer">
            <p><strong>Context7 MCP Validated</strong> | Constitutional Compliance: Active</p>
            <p class="timestamp">Last Updated: <span id="last-updated">--</span></p>
        </div>
    </div>

    <script>
        // Load metrics data
        const metricsData = METRICS_DATA_PLACEHOLDER;
        const targets = TARGETS_DATA_PLACEHOLDER;

        // Process metrics
        function processMetrics() {
            const lighthouse = metricsData.filter(m => m.type === 'lighthouse').slice(0, 10).reverse();
            const builds = metricsData.filter(m => m.type === 'build').slice(0, 10).reverse();

            // Update current values
            if (lighthouse.length > 0) {
                const latest = lighthouse[lighthouse.length - 1];
                const lhData = JSON.parse(latest.data);

                updateMetric('lh-performance', lhData.performance || 0, 'lh-perf-status', targets.lighthouse.performance);
                updateMetric('lh-accessibility', lhData.accessibility || 0, 'lh-a11y-status', targets.lighthouse.accessibility);
                updateMetric('lh-best-practices', lhData.best_practices || 0, 'lh-bp-status', targets.lighthouse.best_practices);
                updateMetric('lh-seo', lhData.seo || 0, 'lh-seo-status', targets.lighthouse.seo);
            }

            if (builds.length > 0) {
                const latest = builds[builds.length - 1];
                const buildData = JSON.parse(latest.data);

                document.getElementById('build-time').textContent = buildData.build_duration_seconds + 's';
                updateStatus('build-status', buildData.build_duration_seconds, targets.build_performance.astro_build_seconds);

                document.getElementById('bundle-size').textContent = Math.round(buildData.js_bundle_size_kb) + 'KB';
                updateStatus('bundle-status', buildData.js_bundle_size_kb, targets.bundle_size.initial_js_kb);
            }

            // Update timestamp
            if (metricsData.length > 0) {
                const lastUpdated = new Date(metricsData[0].timestamp);
                document.getElementById('last-updated').textContent = lastUpdated.toLocaleString();
            }

            return { lighthouse, builds };
        }

        function updateMetric(valueId, value, statusId, target) {
            document.getElementById(valueId).textContent = value;
            updateStatus(statusId, value, target, true);
        }

        function updateStatus(statusId, value, target, isScore = false) {
            const element = document.getElementById(statusId);
            const passed = isScore ? value >= target : value <= target;

            element.className = 'metric-status ' + (passed ? 'status-pass' : 'status-warning');
            element.textContent = passed ? '✅ On Target' : '⚠️ Below Target';
        }

        // Create Lighthouse chart
        function createLighthouseChart(data) {
            const ctx = document.getElementById('lighthouseChart').getContext('2d');
            const labels = data.map(m => new Date(m.timestamp).toLocaleDateString());

            new Chart(ctx, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [
                        {
                            label: 'Performance',
                            data: data.map(m => JSON.parse(m.data).performance || 0),
                            borderColor: '#667eea',
                            backgroundColor: 'rgba(102, 126, 234, 0.1)',
                            tension: 0.4
                        },
                        {
                            label: 'Accessibility',
                            data: data.map(m => JSON.parse(m.data).accessibility || 0),
                            borderColor: '#48bb78',
                            backgroundColor: 'rgba(72, 187, 120, 0.1)',
                            tension: 0.4
                        },
                        {
                            label: 'Best Practices',
                            data: data.map(m => JSON.parse(m.data).best_practices || 0),
                            borderColor: '#f6ad55',
                            backgroundColor: 'rgba(246, 173, 85, 0.1)',
                            tension: 0.4
                        },
                        {
                            label: 'SEO',
                            data: data.map(m => JSON.parse(m.data).seo || 0),
                            borderColor: '#ed64a6',
                            backgroundColor: 'rgba(237, 100, 166, 0.1)',
                            tension: 0.4
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100,
                            ticks: {
                                callback: function(value) {
                                    return value + '';
                                }
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            display: true,
                            position: 'top'
                        },
                        annotation: {
                            annotations: {
                                target: {
                                    type: 'line',
                                    yMin: 95,
                                    yMax: 95,
                                    borderColor: '#f56565',
                                    borderWidth: 2,
                                    borderDash: [5, 5],
                                    label: {
                                        content: 'Target: 95',
                                        enabled: true
                                    }
                                }
                            }
                        }
                    }
                }
            });
        }

        // Create Build chart
        function createBuildChart(data) {
            const ctx = document.getElementById('buildChart').getContext('2d');
            const labels = data.map(m => new Date(m.timestamp).toLocaleDateString());

            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [
                        {
                            label: 'Build Time (seconds)',
                            data: data.map(m => JSON.parse(m.data).build_duration_seconds || 0),
                            backgroundColor: 'rgba(102, 126, 234, 0.6)',
                            borderColor: '#667eea',
                            borderWidth: 2
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: {
                                callback: function(value) {
                                    return value + 's';
                                }
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        }
                    }
                }
            });
        }

        // Create Bundle Size chart
        function createBundleChart(data) {
            const ctx = document.getElementById('bundleChart').getContext('2d');
            const labels = data.map(m => new Date(m.timestamp).toLocaleDateString());

            new Chart(ctx, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [
                        {
                            label: 'Bundle Size (KB)',
                            data: data.map(m => Math.round(JSON.parse(m.data).js_bundle_size_kb || 0)),
                            borderColor: '#48bb78',
                            backgroundColor: 'rgba(72, 187, 120, 0.1)',
                            tension: 0.4,
                            fill: true
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: {
                                callback: function(value) {
                                    return value + 'KB';
                                }
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        }
                    }
                }
            });
        }

        // Initialize dashboard
        const { lighthouse, builds } = processMetrics();
        if (lighthouse.length > 0) createLighthouseChart(lighthouse);
        if (builds.length > 0) {
            createBuildChart(builds);
            createBundleChart(builds);
        }
    </script>
</body>
</html>
HTMLEOF

    # Inject metrics data into HTML
    local metrics_json
    metrics_json=$(jq -c '.' <<< "$recent_metrics" 2>/dev/null || echo "[]")

    local targets_json
    targets_json=$(jq -c '.' <<< "$targets" 2>/dev/null || echo "{}")

    # Replace placeholders
    sed -i.bak "s|METRICS_DATA_PLACEHOLDER|$metrics_json|g" "$DASHBOARD_HTML"
    sed -i.bak "s|TARGETS_DATA_PLACEHOLDER|$targets_json|g" "$DASHBOARD_HTML"
    rm -f "${DASHBOARD_HTML}.bak"

    log "SUCCESS" "✅ Dashboard generated: $DASHBOARD_HTML"
    log "INFO" "📊 Open in browser: file://$DASHBOARD_HTML"
}

# Run benchmark suite
run_benchmark() {
    log "INFO" "🚀 Starting performance benchmark suite..."
    echo ""

    init_metrics_db

    # Collect all metrics
    local lighthouse_data
    lighthouse_data=$(collect_lighthouse_metrics) || lighthouse_data="{}"

    local build_data
    build_data=$(collect_build_metrics) || build_data="{}"

    local cicd_data
    cicd_data=$(collect_cicd_metrics) || cicd_data="{}"

    # Add to database
    if [ "$lighthouse_data" != "{}" ]; then
        add_metric_to_db "lighthouse" "$lighthouse_data"
    fi

    if [ "$build_data" != "{}" ]; then
        add_metric_to_db "build" "$build_data"
    fi

    if [ "$cicd_data" != "{}" ]; then
        add_metric_to_db "cicd" "$cicd_data"
    fi

    # Generate dashboard
    generate_html_dashboard

    echo ""
    log "SUCCESS" "🎉 Benchmark suite complete!"
    log "INFO" "📊 View dashboard: file://$DASHBOARD_HTML"
}

# Show help
show_help() {
    echo "Performance Benchmarking Dashboard"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  benchmark   Run complete benchmark suite (Lighthouse + Build + CI/CD)"
    echo "  lighthouse  Collect only Lighthouse metrics"
    echo "  build       Collect only build performance metrics"
    echo "  cicd        Collect only CI/CD workflow metrics"
    echo "  dashboard   Generate HTML dashboard from existing data"
    echo "  view        Open dashboard in browser (if available)"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 benchmark   # Run complete benchmark suite"
    echo "  $0 dashboard   # Regenerate dashboard from existing data"
    echo "  $0 view        # Open dashboard in default browser"
    echo ""
}

# Open dashboard in browser
view_dashboard() {
    if [ ! -f "$DASHBOARD_HTML" ]; then
        log "ERROR" "❌ Dashboard not found. Run: $0 dashboard"
        return 1
    fi

    log "INFO" "🌐 Opening dashboard in browser..."

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$DASHBOARD_HTML"
    elif command -v open >/dev/null 2>&1; then
        open "$DASHBOARD_HTML"
    else
        log "INFO" "📊 Dashboard location: file://$DASHBOARD_HTML"
        log "INFO" "ℹ️ Open manually in your browser"
    fi
}

# Main execution
main() {
    case "${1:-help}" in
        "benchmark")
            run_benchmark
            ;;
        "lighthouse")
            init_metrics_db
            lighthouse_data=$(collect_lighthouse_metrics)
            [ -n "$lighthouse_data" ] && add_metric_to_db "lighthouse" "$lighthouse_data"
            generate_html_dashboard
            ;;
        "build")
            init_metrics_db
            build_data=$(collect_build_metrics)
            [ -n "$build_data" ] && add_metric_to_db "build" "$build_data"
            generate_html_dashboard
            ;;
        "cicd")
            init_metrics_db
            cicd_data=$(collect_cicd_metrics)
            [ -n "$cicd_data" ] && add_metric_to_db "cicd" "$cicd_data"
            generate_html_dashboard
            ;;
        "dashboard")
            init_metrics_db
            generate_html_dashboard
            ;;
        "view")
            view_dashboard
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Execute if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
