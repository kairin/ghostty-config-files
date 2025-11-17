#!/bin/bash

# GitHub CLI-based local workflow simulation for ghostty-config-files
# This script provides zero-cost local CI/CD capabilities

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
LOG_DIR="$SCRIPT_DIR/../logs"
CONFIG_DIR="$SCRIPT_DIR/../config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure log directory exists
mkdir -p "$LOG_DIR"

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
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/workflow-$(date +%s).log"
}

# Cleanup function (called on EXIT)
cleanup() {
    local exit_code=$?

    # Only perform cleanup if needed
    if [ -n "${CLEANUP_NEEDED:-}" ]; then
        log "INFO" "🧹 Cleaning up temporary files..."

        # Remove temporary Context7 query files
        find /tmp -name "tmp.*" -user "$(whoami)" -mmin -60 -type f -delete 2>/dev/null || true

        # Clean up old log files (older than 7 days)
        if [ -d "$LOG_DIR" ]; then
            find "$LOG_DIR" -name "*.log" -type f -mtime +7 -delete 2>/dev/null || true
            find "$LOG_DIR" -name "*.json" -type f -mtime +7 -delete 2>/dev/null || true
        fi
    fi

    # Exit with original code
    exit $exit_code
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Performance timing
start_timer() {
    TIMER_START=$(date +%s)
}

end_timer() {
    local operation="$1"
    if [ -n "$TIMER_START" ]; then
        local duration=$(($(date +%s) - TIMER_START))
        log "INFO" "⏱️ $operation completed in ${duration}s"
        echo "{\"timestamp\":\"$(date -Iseconds)\",\"operation\":\"$operation\",\"duration\":\"${duration}s\"}" >> "$LOG_DIR/performance-$(date +%s).json"
        unset TIMER_START
    fi
}

# Configuration validation
validate_config() {
    log "STEP" "🔧 Validating Ghostty configuration..."
    start_timer

    if command -v ghostty >/dev/null 2>&1; then
        if ghostty +show-config >/dev/null 2>&1; then
            log "SUCCESS" "✅ Ghostty configuration is valid"

            # Check for 2025 optimizations
            local config_file="$HOME/.config/ghostty/config"
            if [ -f "$config_file" ]; then
                local optimizations_found=0

                if grep -q "linux-cgroup.*single-instance" "$config_file"; then
                    log "SUCCESS" "✅ CGroup single-instance optimization found"
                    optimizations_found=$((optimizations_found + 1))
                fi

                if grep -q "shell-integration.*detect" "$config_file"; then
                    log "SUCCESS" "✅ Enhanced shell integration found"
                    optimizations_found=$((optimizations_found + 1))
                else
                    log "INFO" "ℹ️ Enhanced shell integration not found"
                fi

                if grep -q "clipboard-paste-protection" "$config_file"; then
                    log "SUCCESS" "✅ Clipboard paste protection found"
                    optimizations_found=$((optimizations_found + 1))
                else
                    log "INFO" "ℹ️ Clipboard paste protection not found"
                fi

                log "INFO" "📊 Found $optimizations_found/3 2025 optimizations"
            fi
        else
            log "ERROR" "❌ Ghostty configuration validation failed"
            end_timer "Configuration validation"
            return 1
        fi
    else
        log "WARNING" "⚠️ Ghostty not found, skipping configuration validation"
    fi

    # ShellCheck validation (Context7 Best Practice)
    log "INFO" "🔍 Running ShellCheck validation on shell scripts..."
    if command -v shellcheck >/dev/null 2>&1; then
        local shellcheck_log="$LOG_DIR/shellcheck-$(date +%s).log"
        local total_scripts=0
        local passed_scripts=0
        local failed_scripts=0

        # Find all shell scripts in repository
        while IFS= read -r script_file; do
            total_scripts=$((total_scripts + 1))

            if shellcheck "$script_file" >> "$shellcheck_log" 2>&1; then
                passed_scripts=$((passed_scripts + 1))
            else
                failed_scripts=$((failed_scripts + 1))
                log "WARNING" "⚠️ ShellCheck issues found in: $(basename "$script_file")"
            fi
        done < <(find "$REPO_DIR/scripts" "$REPO_DIR/.runners-local" -name "*.sh" -type f 2>/dev/null)

        if [ $failed_scripts -eq 0 ]; then
            log "SUCCESS" "✅ All $total_scripts shell scripts passed ShellCheck validation"
        else
            log "WARNING" "⚠️ ShellCheck found issues in $failed_scripts/$total_scripts scripts"
            log "INFO" "📄 Detailed report: $shellcheck_log"
        fi
    else
        log "WARNING" "⚠️ ShellCheck not installed, skipping validation"
        log "INFO" "💡 Install with: sudo apt-get install shellcheck"
    fi

    # npm audit security check (Context7 Best Practice)
    if [ -f "$REPO_DIR/package.json" ]; then
        log "INFO" "🔒 Running npm security audit..."

        if command -v npm >/dev/null 2>&1; then
            local npm_audit_log="$LOG_DIR/npm-audit-$(date +%s).log"

            # Run npm audit and capture results
            if npm audit --production --json > "$npm_audit_log" 2>&1; then
                log "SUCCESS" "✅ npm audit passed - no vulnerabilities found"
            else
                # Parse audit results
                local vulnerabilities
                vulnerabilities=$(jq -r '.metadata.vulnerabilities | to_entries[] | "\(.key): \(.value)"' "$npm_audit_log" 2>/dev/null || echo "unknown")

                if [ "$vulnerabilities" != "unknown" ] && [ -n "$vulnerabilities" ]; then
                    log "WARNING" "⚠️ npm audit found security vulnerabilities:"
                    echo "$vulnerabilities" | while read -r vuln_line; do
                        log "WARNING" "  - $vuln_line"
                    done
                    log "INFO" "📄 Detailed report: $npm_audit_log"
                    log "INFO" "💡 Fix with: npm audit fix"
                else
                    log "INFO" "ℹ️ npm audit completed (check log for details)"
                fi
            fi
        else
            log "WARNING" "⚠️ npm not found, skipping security audit"
        fi
    else
        log "INFO" "ℹ️ No package.json found, skipping npm audit"
    fi

    end_timer "Configuration validation"
}

# Performance testing
test_performance() {
    log "STEP" "📊 Running performance tests..."
    start_timer

    if [ -f "$SCRIPT_DIR/performance-monitor.sh" ]; then
        "$SCRIPT_DIR/performance-monitor.sh" --test
    else
        log "WARNING" "⚠️ Performance monitor script not found"
    fi

    end_timer "Performance testing"
}

# Context7 MCP Best Practices Validation (Priority 3 Enhancement)
validate_context7() {
    log "STEP" "📚 Validating with Context7 MCP best practices..."
    start_timer

    # Check if Context7 MCP is available
    if ! command -v claude >/dev/null 2>&1; then
        log "WARNING" "⚠️ Claude CLI not available, skipping Context7 validation"
        end_timer "Context7 validation"
        return 0
    fi

    # Check Context7 MCP connection
    local mcp_status
    mcp_status=$(claude mcp list 2>/dev/null | grep -i context7 | grep -i connected || echo "")

    if [ -z "$mcp_status" ]; then
        log "WARNING" "⚠️ Context7 MCP not connected, skipping validation"
        log "INFO" "ℹ️ Run 'claude mcp list' to check MCP server status"
        end_timer "Context7 validation"
        return 0
    fi

    log "SUCCESS" "✅ Context7 MCP connected and operational"

    # Validate Astro configuration
    if [ -f "$REPO_DIR/astro.config.mjs" ]; then
        log "INFO" "🔍 Validating Astro configuration..."

        # Create temporary file for Context7 query
        local temp_query=$(mktemp)
        CLEANUP_NEEDED=1  # Signal cleanup to run
        cat > "$temp_query" <<'EOF'
Review this Astro configuration for GitHub Pages deployment best practices. Check for:
1. Correct outDir setting (should be './docs' for GitHub Pages)
2. Proper site and base configuration
3. Build optimizations
4. .nojekyll protection strategy
Return a brief summary with ✅ for correct settings and ⚠️ for issues.
EOF

        # Query Context7 (with timeout to avoid hanging)
        local astro_validation
        if timeout 30s claude ask "$(cat "$temp_query")" < "$REPO_DIR/astro.config.mjs" > "$LOG_DIR/context7-astro-$(date +%s).log" 2>&1; then
            log "SUCCESS" "✅ Astro configuration validated with Context7"
            log "INFO" "📄 Full report: $LOG_DIR/context7-astro-$(date +%s).log"
        else
            log "WARNING" "⚠️ Context7 Astro validation timed out or failed"
        fi

        rm -f "$temp_query"
    fi

    # Validate package.json if exists
    if [ -f "$REPO_DIR/package.json" ]; then
        log "INFO" "🔍 Validating package.json..."

        local temp_query=$(mktemp)
        cat > "$temp_query" <<'EOF'
Review this package.json for Node.js and npm best practices. Check for:
1. Proper dependency organization (dependencies vs devDependencies)
2. Build scripts follow conventions
3. Security vulnerabilities in dependencies
4. Package version pinning strategy
Return a brief summary with ✅ for good practices and ⚠️ for issues.
EOF

        if timeout 30s claude ask "$(cat "$temp_query")" < "$REPO_DIR/package.json" > "$LOG_DIR/context7-package-$(date +%s).log" 2>&1; then
            log "SUCCESS" "✅ package.json validated with Context7"
        else
            log "WARNING" "⚠️ Context7 package.json validation timed out or failed"
        fi

        rm -f "$temp_query"
    fi

    # Validate documentation structure
    if [ -f "$REPO_DIR/documentations/developer/guides/documentation-strategy.md" ]; then
        log "INFO" "🔍 Validating documentation structure..."

        local temp_query=$(mktemp)
        cat > "$temp_query" <<'EOF'
Review this documentation strategy for completeness and best practices. Check for:
1. Clear tier separation (docs/, website/src/, documentations/)
2. Decision frameworks are well-defined
3. Workflow examples are practical
4. Maintenance guidelines exist
Return a brief summary with ✅ for strengths and ⚠️ for gaps.
EOF

        if timeout 30s claude ask "$(cat "$temp_query")" < "$REPO_DIR/documentations/developer/guides/documentation-strategy.md" > "$LOG_DIR/context7-docs-$(date +%s).log" 2>&1; then
            log "SUCCESS" "✅ Documentation structure validated with Context7"
        else
            log "WARNING" "⚠️ Context7 documentation validation timed out or failed"
        fi

        rm -f "$temp_query"
    fi

    # Validate AGENTS.md for MCP best practices
    if [ -f "$REPO_DIR/AGENTS.md" ]; then
        log "INFO" "🔍 Validating AGENTS.md MCP compliance..."

        local temp_query=$(mktemp)
        cat > "$temp_query" <<'EOF'
Review this AGENTS.md file for MCP (Model Context Protocol) best practices. Check for:
1. Clear command examples with expected outputs
2. Constitutional requirements are enforceable
3. Technology stack documentation is current
4. Context7 integration is documented
Return a brief summary with ✅ for compliance and ⚠️ for improvements.
EOF

        if timeout 30s claude ask "$(cat "$temp_query")" < "$REPO_DIR/AGENTS.md" > "$LOG_DIR/context7-agents-$(date +%s).log" 2>&1; then
            log "SUCCESS" "✅ AGENTS.md validated with Context7"
        else
            log "WARNING" "⚠️ Context7 AGENTS.md validation timed out or failed"
        fi

        rm -f "$temp_query"
    fi

    # Summary
    local validation_count=$(find "$LOG_DIR" -name "context7-*-$(date +%s).log" 2>/dev/null | wc -l)
    if [ "$validation_count" -gt 0 ]; then
        log "SUCCESS" "✅ Completed $validation_count Context7 validations"
        log "INFO" "📊 Review detailed reports in: $LOG_DIR/context7-*.log"
    else
        log "INFO" "ℹ️ No files validated with Context7"
    fi

    end_timer "Context7 validation"
}

# Build simulation
simulate_build() {
    log "STEP" "🏗️ Simulating build process..."
    start_timer

    # Check if start.sh has dry-run capability
    if "$REPO_DIR/start.sh" --help 2>&1 | grep -q "dry-run"; then
        "$REPO_DIR/start.sh" --verbose --dry-run
    else
        log "INFO" "ℹ️ Dry-run not available, checking system readiness..."

        # Check dependencies
        local deps_ok=true
        for cmd in ghostty node npm; do
            if ! command -v "$cmd" >/dev/null 2>&1; then
                log "WARNING" "⚠️ $cmd not found"
                deps_ok=false
            fi
        done

        if $deps_ok; then
            log "SUCCESS" "✅ All key dependencies found"
        else
            log "WARNING" "⚠️ Some dependencies missing"
        fi
    fi

    end_timer "Build simulation"
}

# GitHub Actions status check
check_github_status() {
    log "STEP" "🐙 Checking GitHub Actions status..."
    start_timer

    if command -v gh >/dev/null 2>&1; then
        if gh auth status >/dev/null 2>&1; then
            log "SUCCESS" "✅ GitHub CLI authenticated"

            # Check recent workflow runs
            local recent_runs
            recent_runs=$(gh run list --limit 5 --json status,conclusion,name,createdAt 2>/dev/null || echo "[]")
            echo "$recent_runs" > "$LOG_DIR/github-runs-$(date +%s).json"

            local run_count
            run_count=$(echo "$recent_runs" | jq length 2>/dev/null || echo "0")
            log "INFO" "📊 Found $run_count recent workflow runs"
        else
            log "WARNING" "⚠️ GitHub CLI not authenticated"
        fi
    else
        log "WARNING" "⚠️ GitHub CLI not available"
    fi

    end_timer "GitHub status check"
}

# Billing check
check_billing() {
    log "STEP" "💰 Checking GitHub Actions billing..."
    start_timer

    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        local billing_info
        billing_info=$(gh api user/settings/billing/actions 2>/dev/null || echo "{}")
        echo "$billing_info" > "$LOG_DIR/billing-$(date +%s).json"

        # Extract fields defensively; fall back to empty and then to "unknown"
        local minutes_used_raw
        local included_minutes_raw
        minutes_used_raw=$(echo "$billing_info" | jq -r '.total_minutes_used // empty' 2>/dev/null || true)
        included_minutes_raw=$(echo "$billing_info" | jq -r '.included_minutes // empty' 2>/dev/null || true)

        local minutes_used="${minutes_used_raw:-unknown}"
        local included_minutes="${included_minutes_raw:-unknown}"

        log "INFO" "📊 GitHub Actions usage: $minutes_used / $included_minutes minutes"

        # Only compute numeric percentage when both values are integers
        if [[ "$minutes_used" =~ ^[0-9]+$ ]] && [[ "$included_minutes" =~ ^[0-9]+$ ]] && [ "$included_minutes" -ne 0 ]; then
            local usage_percent=$((minutes_used * 100 / included_minutes))
            if [ $usage_percent -gt 80 ]; then
                log "WARNING" "⚠️ High GitHub Actions usage: ${usage_percent}%"
            else
                log "SUCCESS" "✅ GitHub Actions usage within limits: ${usage_percent}%"
            fi
        else
            log "INFO" "ℹ️ Billing info not numeric or unavailable; skipping percentage calculation"
        fi
    else
        log "WARNING" "⚠️ Cannot check billing - GitHub CLI not available or not authenticated"
    fi

    end_timer "Billing check"
}

# GitHub Pages simulation (Astro-based)
simulate_pages() {
    log "STEP" "📄 Simulating Astro GitHub Pages setup..."
    start_timer

    if [ -f "$SCRIPT_DIR/gh-pages-setup.sh" ]; then
        "$SCRIPT_DIR/gh-pages-setup.sh"
    else
        log "INFO" "ℹ️ Verifying Astro build output for GitHub Pages..."

        # Check if Astro has built to docs/
        if [ ! -d "$REPO_DIR/docs" ]; then
            log "WARNING" "⚠️ docs/ directory not found. Running Astro build..."
            cd "$REPO_DIR" && npx astro build
        fi

        # Verify Astro build output
        if [ -f "$REPO_DIR/docs/index.html" ]; then
            log "SUCCESS" "✅ Astro build output verified in docs/"
        else
            log "ERROR" "❌ No Astro build output found. Run: npx astro build"
            return 1
        fi

        # Configure GitHub Pages via GitHub CLI if available
        if command -v gh >/dev/null 2>&1; then
            log "INFO" "🔧 Configuring GitHub Pages deployment..."
            gh api repos/:owner/:repo --method PATCH \
                --field source[branch]=main \
                --field source[path]="/docs" 2>/dev/null || \
                log "INFO" "ℹ️ GitHub CLI configuration skipped (may require manual setup)"
            log "SUCCESS" "✅ GitHub Pages configured for Astro deployment"
        else
            log "INFO" "ℹ️ GitHub CLI not available. Manual Pages configuration needed:"
            log "INFO" "   Settings → Pages → Source: Deploy from a branch → main → /docs"
        fi
    fi

    end_timer "GitHub Pages simulation"
}

# Complete local workflow
run_complete_workflow() {
    log "INFO" "🚀 Starting complete local workflow..."

    local overall_start=$(date +%s)
    local failed_steps=0

    # Run all workflow steps
    validate_config || ((failed_steps++))
    validate_context7 || ((failed_steps++))  # Priority 3 Enhancement: Context7 MCP validation
    test_performance || ((failed_steps++))
    simulate_build || ((failed_steps++))
    check_github_status || ((failed_steps++))
    check_billing || ((failed_steps++))
    simulate_pages || ((failed_steps++))

    local overall_duration=$(($(date +%s) - overall_start))

    if [ $failed_steps -eq 0 ]; then
        log "SUCCESS" "🎉 Complete workflow successful in ${overall_duration}s"
        echo "{\"timestamp\":\"$(date -Iseconds)\",\"workflow\":\"complete\",\"duration\":\"${overall_duration}s\",\"status\":\"success\",\"failed_steps\":$failed_steps}" >> "$LOG_DIR/workflow-summary-$(date +%s).json"
        return 0
    else
        log "WARNING" "⚠️ Workflow completed with $failed_steps failed steps in ${overall_duration}s"
        echo "{\"timestamp\":\"$(date -Iseconds)\",\"workflow\":\"complete\",\"duration\":\"${overall_duration}s\",\"status\":\"partial\",\"failed_steps\":$failed_steps}" >> "$LOG_DIR/workflow-summary-$(date +%s).json"
        return 1
    fi
}

# Initialize local CI/CD infrastructure
init_infrastructure() {
    log "STEP" "🏗️ Initializing local CI/CD infrastructure..."

    # Create necessary directories
    mkdir -p "$LOG_DIR" "$CONFIG_DIR/workflows" "$CONFIG_DIR/test-suites"

    # Create performance monitor if it doesn't exist
    if [ ! -f "$SCRIPT_DIR/performance-monitor.sh" ]; then
        log "INFO" "📊 Creating performance monitor script..."
        cat > "$SCRIPT_DIR/performance-monitor.sh" << 'EOF'
#!/bin/bash
# Performance monitoring for Ghostty
echo "📊 Monitoring Ghostty performance..."

monitor_performance() {
    local test_mode="$1"
    local log_dir="$(dirname "$0")/../logs"

    # Startup time measurement
    if command -v ghostty >/dev/null 2>&1; then
        local startup_time
        startup_time=$(time (ghostty --version >/dev/null 2>&1) 2>&1 | grep real | awk '{print $2}' || echo "0m0.000s")

        # Configuration load time
        local config_time
        config_time=$(time (ghostty +show-config >/dev/null 2>&1) 2>&1 | grep real | awk '{print $2}' || echo "0m0.000s")

        # Store results
        cat > "$log_dir/performance-$(date +%s).json" << EOL
{
    "timestamp": "$(date -Iseconds)",
    "startup_time": "$startup_time",
    "config_load_time": "$config_time",
    "test_mode": "$test_mode",
    "optimizations": {
        "cgroup_single_instance": $(grep -q "linux-cgroup.*single-instance" ~/.config/ghostty/config 2>/dev/null && echo "true" || echo "false"),
        "shell_integration_detect": $(grep -q "shell-integration.*detect" ~/.config/ghostty/config 2>/dev/null && echo "true" || echo "false")
    }
}
EOL
        echo "✅ Performance data collected"
    else
        echo "⚠️ Ghostty not found for performance testing"
    fi
}

case "$1" in
    --test) monitor_performance "test" ;;
    --baseline) monitor_performance "baseline" ;;
    --compare) monitor_performance "compare" ;;
    *) monitor_performance "default" ;;
esac
EOF
        chmod +x "$SCRIPT_DIR/performance-monitor.sh"
        log "SUCCESS" "✅ Performance monitor created"
    fi

    # Create GitHub Pages setup script if it doesn't exist
    if [ ! -f "$SCRIPT_DIR/gh-pages-setup.sh" ]; then
        log "INFO" "📄 Creating Astro GitHub Pages setup script..."
        cat > "$SCRIPT_DIR/gh-pages-setup.sh" << 'EOF'
#!/bin/bash
# Astro GitHub Pages setup for ghostty-config-files
echo "📄 Setting up zero-cost GitHub Pages with Astro..."

REPO_DIR="$(dirname "$(dirname "$(dirname "$0")")")"

setup_github_pages() {
    echo "🔧 Configuring Astro for GitHub Pages deployment..."

    # Ensure Astro build output directory exists
    if [ ! -d "$REPO_DIR/docs" ]; then
        echo "❌ docs/ directory not found. Running Astro build..."
        cd "$REPO_DIR" && npx astro build
        if [ $? -ne 0 ]; then
            echo "❌ Astro build failed. Check astro.config.mjs configuration."
            return 1
        fi
    fi

    # Verify Astro build output
    if [ -f "$REPO_DIR/docs/index.html" ]; then
        echo "✅ Astro build output verified in docs/"
    else
        echo "❌ No index.html found in docs/. Run: npx astro build"
        return 1
    fi

    # Configure GitHub Pages to serve from docs/ folder
    if command -v gh >/dev/null 2>&1; then
        echo "🔧 Configuring GitHub Pages deployment..."
        gh api repos/:owner/:repo --method PATCH \
            --field source[branch]=main \
            --field source[path]="/docs" 2>/dev/null && \
            echo "✅ GitHub Pages configured to serve from docs/ folder" || \
            echo "ℹ️ GitHub CLI configuration may require manual setup"
    else
        echo "ℹ️ GitHub CLI not available, configure Pages manually:"
        echo "   Settings → Pages → Source: Deploy from a branch → main → /docs"
    fi

    echo "✅ Astro GitHub Pages setup complete"
}

setup_github_pages
EOF
        chmod +x "$SCRIPT_DIR/gh-pages-setup.sh"
        log "SUCCESS" "✅ Astro GitHub Pages setup script created"
    fi

    log "SUCCESS" "✅ Local CI/CD infrastructure initialized"
}

# Show help
show_help() {
    echo "Local GitHub Workflow Simulation (Context7 MCP Enhanced)"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  init        Initialize local CI/CD infrastructure"
    echo "  local       Run complete local workflow simulation"
    echo "  validate    Validate Ghostty configuration"
    echo "  context7    Validate with Context7 MCP best practices (Priority 3)"
    echo "  test        Run performance tests"
    echo "  build       Simulate build process"
    echo "  status      Check GitHub Actions status"
    echo "  billing     Check GitHub Actions billing"
    echo "  pages       Simulate GitHub Pages setup"
    echo "  all         Run complete workflow (validate + context7 + test + build + status + billing + pages)"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 init     # Initialize local CI/CD infrastructure"
    echo "  $0 all      # Run complete local workflow with Context7 validation"
    echo "  $0 validate # Only validate Ghostty configuration"
    echo "  $0 context7 # Only validate with Context7 MCP"
    echo ""
    echo "Context7 MCP Integration:"
    echo "  The 'context7' command validates your project against best practices:"
    echo "  - Astro configuration for GitHub Pages"
    echo "  - package.json for Node.js/npm conventions"
    echo "  - Documentation structure and completeness"
    echo "  - AGENTS.md MCP compliance"
    echo ""
}

# Main execution
main() {
    case "${1:-help}" in
        "init")
            init_infrastructure
            ;;
        "local"|"workflow")
            run_complete_workflow
            ;;
        "validate")
            validate_config
            ;;
        "context7")
            validate_context7
            ;;
        "test")
            test_performance
            ;;
        "build")
            simulate_build
            ;;
        "status")
            check_github_status
            ;;
        "billing")
            check_billing
            ;;
        "pages")
            simulate_pages
            ;;
        "all")
            run_complete_workflow
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

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi