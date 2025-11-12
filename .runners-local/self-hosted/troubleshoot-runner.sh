#!/bin/bash

# GitHub Actions Self-Hosted Runner Troubleshooting and Verification
# Based on: https://docs.github.com/en/actions/how-tos/troubleshoot-workflows
# Reference: https://github.com/actions/runner/blob/main/docs/checks/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"
RUNNER_DIR="$HOME/actions-runner"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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

    echo -e "${color}[$timestamp] [TROUBLESHOOT] $message${NC}"
    echo "[$timestamp] [TROUBLESHOOT] $message" >> "$LOG_DIR/troubleshoot-$(date +%s).log"
}

# Test network connectivity to GitHub
test_github_connectivity() {
    log "STEP" "🌐 Testing GitHub connectivity..."

    local failed_tests=0

    # Test GitHub API
    log "INFO" "Testing GitHub API..."
    if curl -s --max-time 10 https://api.github.com/zen >/dev/null; then
        log "SUCCESS" "✅ GitHub API accessible"
    else
        log "ERROR" "❌ GitHub API not accessible"
        ((failed_tests++))
    fi

    # Test GitHub codeload
    log "INFO" "Testing GitHub codeload..."
    if curl -s --max-time 10 https://codeload.github.com/_ping >/dev/null; then
        log "SUCCESS" "✅ GitHub codeload accessible"
    else
        log "ERROR" "❌ GitHub codeload not accessible"
        ((failed_tests++))
    fi

    # Test Actions services
    local actions_endpoints=(
        "https://vstoken.actions.githubusercontent.com/_apis/health"
        "https://pipelines.actions.githubusercontent.com/_apis/health"
        "https://results-receiver.actions.githubusercontent.com/health"
    )

    for endpoint in "${actions_endpoints[@]}"; do
        local service_name=$(echo "$endpoint" | sed 's|https://||' | cut -d'.' -f1)
        log "INFO" "Testing $service_name..."

        if curl -s --max-time 10 "$endpoint" >/dev/null; then
            log "SUCCESS" "✅ $service_name accessible"
        else
            log "ERROR" "❌ $service_name not accessible"
            ((failed_tests++))
        fi
    done

    if [ $failed_tests -eq 0 ]; then
        log "SUCCESS" "✅ All GitHub services accessible"
        return 0
    else
        log "ERROR" "❌ $failed_tests GitHub services failed connectivity test"
        return 1
    fi
}

# Test DNS resolution
test_dns_resolution() {
    log "STEP" "🔍 Testing DNS resolution..."

    local dns_hosts=(
        "github.com"
        "api.github.com"
        "codeload.github.com"
        "vstoken.actions.githubusercontent.com"
        "pipelines.actions.githubusercontent.com"
        "results-receiver.actions.githubusercontent.com"
    )

    local failed_dns=0

    for host in "${dns_hosts[@]}"; do
        if nslookup "$host" >/dev/null 2>&1; then
            log "SUCCESS" "✅ DNS resolution for $host"
        else
            log "ERROR" "❌ DNS resolution failed for $host"
            ((failed_dns++))
        fi
    done

    if [ $failed_dns -eq 0 ]; then
        log "SUCCESS" "✅ All DNS resolutions successful"
        return 0
    else
        log "ERROR" "❌ $failed_dns DNS resolutions failed"
        return 1
    fi
}

# Test TLS/SSL configuration
test_tls_configuration() {
    log "STEP" "🔒 Testing TLS/SSL configuration..."

    local tls_hosts=(
        "github.com"
        "api.github.com"
        "vstoken.actions.githubusercontent.com"
    )

    local failed_tls=0

    for host in "${tls_hosts[@]}"; do
        log "INFO" "Testing TLS handshake for $host..."

        # Test TLS handshake with detailed output
        local tls_output
        tls_output=$(curl -v --max-time 10 "https://$host" 2>&1 | grep -E "(TLS|SSL)" | head -3)

        if echo "$tls_output" | grep -q "TLS"; then
            log "SUCCESS" "✅ TLS handshake successful for $host"
        else
            log "ERROR" "❌ TLS handshake failed for $host"
            log "INFO" "TLS details: $tls_output"
            ((failed_tls++))
        fi
    done

    # Check for common TLS issues
    log "INFO" "Checking system TLS configuration..."

    # Check OpenSSL version
    local openssl_version
    openssl_version=$(openssl version 2>/dev/null || echo "OpenSSL not found")
    log "INFO" "OpenSSL version: $openssl_version"

    # Check system CA certificates
    if [ -f "/etc/ssl/certs/ca-certificates.crt" ]; then
        log "SUCCESS" "✅ System CA certificates found"
    elif [ -d "/etc/ssl/certs" ]; then
        log "SUCCESS" "✅ CA certificates directory found"
    else
        log "WARNING" "⚠️ System CA certificates not found in standard location"
    fi

    if [ $failed_tls -eq 0 ]; then
        log "SUCCESS" "✅ All TLS configurations successful"
        return 0
    else
        log "ERROR" "❌ $failed_tls TLS configurations failed"
        return 1
    fi
}

# Test Git connectivity
test_git_connectivity() {
    log "STEP" "📂 Testing Git connectivity..."

    # Enable Git debugging
    export GIT_TRACE=1
    export GIT_CURL_VERBOSE=1

    # Test Git access to GitHub
    log "INFO" "Testing Git ls-remote to GitHub..."

    if git ls-remote --exit-code https://github.com/actions/checkout HEAD >/dev/null 2>&1; then
        log "SUCCESS" "✅ Git can access GitHub repositories"
    else
        log "ERROR" "❌ Git cannot access GitHub repositories"

        # Try with verbose output for debugging
        log "INFO" "Running Git with verbose output for debugging..."
        git ls-remote --exit-code https://github.com/actions/checkout HEAD 2>&1 | head -10 >> "$LOG_DIR/git-debug-$(date +%s).log"
        return 1
    fi

    # Check Git configuration
    local git_version
    git_version=$(git --version)
    log "INFO" "Git version: $git_version"

    # Check Git credentials configuration
    local git_credential_helper
    git_credential_helper=$(git config --global credential.helper 2>/dev/null || echo "none")
    log "INFO" "Git credential helper: $git_credential_helper"

    return 0
}

# Check runner dependencies
check_runner_dependencies() {
    log "STEP" "🔧 Checking runner dependencies..."

    local missing_deps=()
    local deps=(
        "curl"
        "tar"
        "gzip"
        "git"
        "node"
        "npm"
        "jq"
        "systemctl"
    )

    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            local version
            case "$dep" in
                "node") version=$(node --version) ;;
                "npm") version=$(npm --version) ;;
                "git") version=$(git --version | cut -d' ' -f3) ;;
                "curl") version=$(curl --version | head -1 | cut -d' ' -f2) ;;
                *) version=$(command -v "$dep") ;;
            esac
            log "SUCCESS" "✅ $dep: $version"
        else
            log "ERROR" "❌ Missing dependency: $dep"
            missing_deps+=("$dep")
        fi
    done

    # Check Node.js version for Astro compatibility
    if command -v node >/dev/null 2>&1; then
        local node_version
        node_version=$(node --version | sed 's/v//')
        local major_version
        major_version=$(echo "$node_version" | cut -d. -f1)

        if [ "$major_version" -ge 18 ]; then
            log "SUCCESS" "✅ Node.js $node_version (compatible with Astro)"
        else
            log "WARNING" "⚠️ Node.js $node_version may be too old for Astro (requires 18+)"
        fi
    fi

    if [ ${#missing_deps[@]} -eq 0 ]; then
        log "SUCCESS" "✅ All dependencies available"
        return 0
    else
        log "ERROR" "❌ Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
}

# Check runner configuration
check_runner_configuration() {
    log "STEP" "⚙️ Checking runner configuration..."

    if [ ! -d "$RUNNER_DIR" ]; then
        log "WARNING" "⚠️ Runner directory not found: $RUNNER_DIR"
        return 1
    fi

    cd "$RUNNER_DIR"

    # Check configuration files
    if [ -f ".runner" ]; then
        log "SUCCESS" "✅ Runner configuration file found"

        # Extract key configuration details
        local agent_name
        agent_name=$(jq -r '.agentName // "unknown"' .runner 2>/dev/null || echo "unknown")
        log "INFO" "Runner name: $agent_name"

        local pool_name
        pool_name=$(jq -r '.poolName // "unknown"' .runner 2>/dev/null || echo "unknown")
        log "INFO" "Pool name: $pool_name"
    else
        log "ERROR" "❌ Runner configuration file not found"
        return 1
    fi

    # Check credentials file
    if [ -f ".credentials" ]; then
        log "SUCCESS" "✅ Runner credentials file found"
    else
        log "ERROR" "❌ Runner credentials file not found"
        return 1
    fi

    # Check if runner service is configured
    local service_files=(
        "/etc/systemd/system/actions.runner.*.service"
        "/etc/systemd/system/github-actions-runner-*.service"
    )

    local service_found=false
    for pattern in "${service_files[@]}"; do
        if ls $pattern >/dev/null 2>&1; then
            log "SUCCESS" "✅ Runner systemd service found"
            service_found=true
            break
        fi
    done

    if [ "$service_found" = false ]; then
        log "WARNING" "⚠️ No runner systemd service found"
    fi

    return 0
}

# Test runner status
test_runner_status() {
    log "STEP" "🏃 Testing runner status..."

    if [ ! -f "$LOG_DIR/service-name.txt" ]; then
        log "WARNING" "⚠️ Service name file not found - runner may not be configured as service"
        return 1
    fi

    local service_name
    service_name=$(cat "$LOG_DIR/service-name.txt")

    # Check service status
    if systemctl is-active --quiet "$service_name"; then
        log "SUCCESS" "✅ Runner service is active"

        # Get service details
        local service_status
        service_status=$(systemctl status "$service_name" --no-pager -l | grep "Active:" | awk '{print $2}')
        log "INFO" "Service status: $service_status"

        # Check recent logs for errors
        local recent_errors
        recent_errors=$(journalctl -u "$service_name" --since "10 minutes ago" --grep "ERROR" --no-pager | wc -l)

        if [ "$recent_errors" -eq 0 ]; then
            log "SUCCESS" "✅ No recent errors in runner logs"
        else
            log "WARNING" "⚠️ Found $recent_errors recent errors in runner logs"
        fi

    else
        log "ERROR" "❌ Runner service is not active"

        # Get service status details
        systemctl status "$service_name" --no-pager -l >> "$LOG_DIR/service-debug-$(date +%s).log"
        return 1
    fi

    return 0
}

# Test Astro build environment
test_astro_environment() {
    log "STEP" "🚀 Testing Astro build environment..."

    local repo_dir
    repo_dir="$(dirname "$(dirname "$SCRIPT_DIR")")"

    # Check if we're in the correct directory
    if [ ! -f "$repo_dir/package.json" ]; then
        log "ERROR" "❌ Not in Astro project directory (package.json not found)"
        return 1
    fi

    # Check package.json for Astro
    if grep -q '"astro"' "$repo_dir/package.json"; then
        local astro_version
        astro_version=$(grep '"astro"' "$repo_dir/package.json" | sed 's/.*"astro": *"\([^"]*\)".*/\1/')
        log "SUCCESS" "✅ Astro $astro_version configured"
    else
        log "ERROR" "❌ Astro not found in package.json"
        return 1
    fi

    # Check astro.config.mjs
    if [ -f "$repo_dir/astro.config.mjs" ]; then
        log "SUCCESS" "✅ Astro configuration found"

        # Check for GitHub Pages configuration
        if grep -q 'outDir.*docs' "$repo_dir/astro.config.mjs"; then
            log "SUCCESS" "✅ GitHub Pages output configuration verified"
        else
            log "WARNING" "⚠️ GitHub Pages output configuration not found"
        fi
    else
        log "ERROR" "❌ Astro configuration not found"
        return 1
    fi

    # Test Astro build
    log "INFO" "Testing Astro check..."
    cd "$repo_dir"

    if npm run check >/dev/null 2>&1; then
        log "SUCCESS" "✅ Astro TypeScript check passed"
    else
        log "ERROR" "❌ Astro TypeScript check failed"
        return 1
    fi

    return 0
}

# Generate comprehensive report
generate_troubleshooting_report() {
    log "STEP" "📊 Generating troubleshooting report..."

    local report_file="$LOG_DIR/troubleshooting-report-$(date +%s).json"
    local overall_status="success"

    # Run all tests and capture results
    local test_results=()

    test_github_connectivity && test_results+=("github_connectivity:success") || { test_results+=("github_connectivity:failed"); overall_status="failed"; }
    test_dns_resolution && test_results+=("dns_resolution:success") || { test_results+=("dns_resolution:failed"); overall_status="failed"; }
    test_tls_configuration && test_results+=("tls_configuration:success") || { test_results+=("tls_configuration:failed"); overall_status="failed"; }
    test_git_connectivity && test_results+=("git_connectivity:success") || { test_results+=("git_connectivity:failed"); overall_status="failed"; }
    check_runner_dependencies && test_results+=("dependencies:success") || { test_results+=("dependencies:failed"); overall_status="failed"; }
    check_runner_configuration && test_results+=("runner_config:success") || { test_results+=("runner_config:failed"); overall_status="failed"; }
    test_runner_status && test_results+=("runner_status:success") || { test_results+=("runner_status:failed"); overall_status="partial"; }
    test_astro_environment && test_results+=("astro_environment:success") || { test_results+=("astro_environment:failed"); overall_status="partial"; }

    # Generate JSON report
    cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "overall_status": "$overall_status",
    "system_info": {
        "os": "$(uname -s)",
        "kernel": "$(uname -r)",
        "architecture": "$(uname -m)",
        "hostname": "$(hostname)"
    },
    "test_results": {
EOF

    # Add test results
    local first=true
    for result in "${test_results[@]}"; do
        local test_name=$(echo "$result" | cut -d: -f1)
        local test_status=$(echo "$result" | cut -d: -f2)

        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$report_file"
        fi

        echo "        \"$test_name\": \"$test_status\"" >> "$report_file"
    done

    cat >> "$report_file" << EOF
    },
    "recommendations": [
EOF

    # Add recommendations based on failed tests
    local recommendations=()

    for result in "${test_results[@]}"; do
        local test_name=$(echo "$result" | cut -d: -f1)
        local test_status=$(echo "$result" | cut -d: -f2)

        if [ "$test_status" = "failed" ]; then
            case "$test_name" in
                "github_connectivity")
                    recommendations+=("Check firewall settings and internet connectivity")
                    recommendations+=("Verify proxy configuration if behind corporate firewall")
                    ;;
                "dns_resolution")
                    recommendations+=("Check DNS server configuration")
                    recommendations+=("Try using different DNS servers (8.8.8.8, 1.1.1.1)")
                    ;;
                "tls_configuration")
                    recommendations+=("Update system CA certificates")
                    recommendations+=("Check TLS version compatibility")
                    ;;
                "git_connectivity")
                    recommendations+=("Configure Git with proper SSL certificates")
                    recommendations+=("Check Git credential helper configuration")
                    ;;
                "dependencies")
                    recommendations+=("Install missing dependencies using package manager")
                    ;;
                "runner_config")
                    recommendations+=("Reconfigure runner using setup script")
                    ;;
            esac
        fi
    done

    # Write recommendations to JSON
    local first_rec=true
    for rec in "${recommendations[@]}"; do
        if [ "$first_rec" = true ]; then
            first_rec=false
        else
            echo "," >> "$report_file"
        fi
        echo "        \"$rec\"" >> "$report_file"
    done

    cat >> "$report_file" << EOF
    ]
}
EOF

    log "SUCCESS" "✅ Troubleshooting report generated: $report_file"

    # Display summary
    log "INFO" "📋 Troubleshooting Summary:"
    log "INFO" "   Overall Status: $overall_status"
    log "INFO" "   Total Tests: ${#test_results[@]}"
    log "INFO" "   Report Location: $report_file"
}

# Show help
show_help() {
    cat << EOF
GitHub Actions Self-Hosted Runner Troubleshooting

Usage: $0 [COMMAND]

Commands:
  connectivity    Test GitHub connectivity
  dns            Test DNS resolution
  tls            Test TLS/SSL configuration
  git            Test Git connectivity
  deps           Check dependencies
  config         Check runner configuration
  status         Check runner status
  astro          Test Astro environment
  report         Generate comprehensive troubleshooting report
  all            Run all tests (same as report)
  help           Show this help message

Examples:
  $0 connectivity  # Test GitHub API connectivity
  $0 report        # Generate full troubleshooting report
  $0 all           # Run all diagnostics

Note: This script helps troubleshoot self-hosted GitHub Actions runners
and Astro build environments. Logs are stored in $LOG_DIR.
EOF
}

# Main execution
main() {
    case "${1:-help}" in
        "connectivity")
            test_github_connectivity
            ;;
        "dns")
            test_dns_resolution
            ;;
        "tls")
            test_tls_configuration
            ;;
        "git")
            test_git_connectivity
            ;;
        "deps")
            check_runner_dependencies
            ;;
        "config")
            check_runner_configuration
            ;;
        "status")
            test_runner_status
            ;;
        "astro")
            test_astro_environment
            ;;
        "report"|"all")
            generate_troubleshooting_report
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