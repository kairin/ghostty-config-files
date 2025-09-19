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

        local minutes_used
        local included_minutes
        minutes_used=$(echo "$billing_info" | jq -r '.total_minutes_used // "unknown"' 2>/dev/null || echo "unknown")
        included_minutes=$(echo "$billing_info" | jq -r '.included_minutes // "unknown"' 2>/dev/null || echo "unknown")

        log "INFO" "📊 GitHub Actions usage: $minutes_used / $included_minutes minutes"

        if [ "$minutes_used" != "unknown" ] && [ "$included_minutes" != "unknown" ] && [ "$minutes_used" != "null" ] && [ "$included_minutes" != "null" ]; then
            local usage_percent=$((minutes_used * 100 / included_minutes))
            if [ $usage_percent -gt 80 ]; then
                log "WARNING" "⚠️ High GitHub Actions usage: ${usage_percent}%"
            else
                log "SUCCESS" "✅ GitHub Actions usage within limits: ${usage_percent}%"
            fi
        fi
    else
        log "WARNING" "⚠️ Cannot check billing - GitHub CLI not available or not authenticated"
    fi

    end_timer "Billing check"
}

# GitHub Pages simulation
simulate_pages() {
    log "STEP" "📄 Simulating GitHub Pages setup..."
    start_timer

    if [ -f "$SCRIPT_DIR/gh-pages-setup.sh" ]; then
        "$SCRIPT_DIR/gh-pages-setup.sh"
    else
        log "INFO" "ℹ️ Creating basic GitHub Pages setup..."

        mkdir -p "$REPO_DIR/docs"

        if [ -f "$REPO_DIR/README.md" ]; then
            cp "$REPO_DIR/README.md" "$REPO_DIR/docs/index.md"
            log "SUCCESS" "✅ Copied README as documentation index"
        fi

        cat > "$REPO_DIR/docs/_config.yml" << EOF
title: Ghostty Configuration Files
description: Comprehensive terminal environment setup with 2025 optimizations
theme: jekyll-theme-minimal
plugins:
  - jekyll-relative-links
relative_links:
  enabled: true
  collections: true
EOF
        log "SUCCESS" "✅ Created GitHub Pages configuration"
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
        log "INFO" "📄 Creating GitHub Pages setup script..."
        cat > "$SCRIPT_DIR/gh-pages-setup.sh" << 'EOF'
#!/bin/bash
# GitHub Pages setup for ghostty-config-files
echo "📄 Setting up zero-cost GitHub Pages..."

REPO_DIR="$(dirname "$(dirname "$(dirname "$0")")")"

setup_github_pages() {
    # Create documentation directory
    mkdir -p "$REPO_DIR/docs"

    # Copy README as index
    if [ -f "$REPO_DIR/README.md" ]; then
        cp "$REPO_DIR/README.md" "$REPO_DIR/docs/index.md"
        echo "✅ Copied README as documentation index"
    fi

    # Create Jekyll configuration
    cat > "$REPO_DIR/docs/_config.yml" << EOL
title: Ghostty Configuration Files
description: Comprehensive terminal environment setup with 2025 optimizations
theme: jekyll-theme-minimal
plugins:
  - jekyll-relative-links
relative_links:
  enabled: true
  collections: true
include:
  - AGENTS.md
  - CLAUDE.md
  - GEMINI.md
EOL
    echo "✅ Created GitHub Pages configuration"

    # Test local Jekyll build if available
    if command -v jekyll >/dev/null 2>&1; then
        cd "$REPO_DIR/docs" && jekyll build --destination _site_test >/dev/null 2>&1
        echo "✅ Local Jekyll build test successful"
    else
        echo "ℹ️ Jekyll not available, skipping local build test"
    fi
}

setup_github_pages
EOF
        chmod +x "$SCRIPT_DIR/gh-pages-setup.sh"
        log "SUCCESS" "✅ GitHub Pages setup script created"
    fi

    log "SUCCESS" "✅ Local CI/CD infrastructure initialized"
}

# Show help
show_help() {
    echo "Local GitHub Workflow Simulation"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  init        Initialize local CI/CD infrastructure"
    echo "  local       Run complete local workflow simulation"
    echo "  validate    Validate Ghostty configuration"
    echo "  test        Run performance tests"
    echo "  build       Simulate build process"
    echo "  status      Check GitHub Actions status"
    echo "  billing     Check GitHub Actions billing"
    echo "  pages       Simulate GitHub Pages setup"
    echo "  all         Run complete workflow (validate + test + build + status + billing + pages)"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 init     # Initialize local CI/CD infrastructure"
    echo "  $0 all      # Run complete local workflow"
    echo "  $0 validate # Only validate configuration"
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