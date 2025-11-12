#!/bin/bash

# Integration Test for Self-Hosted GitHub Actions Runner with Astro
# Based on GitHub documentation and troubleshooting best practices

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
LOG_DIR="$SCRIPT_DIR/../logs"

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

    echo -e "${color}[$timestamp] [TEST] $message${NC}"
    echo "[$timestamp] [TEST] $message" >> "$LOG_DIR/integration-test-$(date +%s).log"
}

# Test GitHub CLI integration
test_github_cli_integration() {
    log "STEP" "🐙 Testing GitHub CLI integration..."

    # Check authentication
    if ! gh auth status >/dev/null 2>&1; then
        log "ERROR" "❌ GitHub CLI not authenticated"
        return 1
    fi

    log "SUCCESS" "✅ GitHub CLI authenticated"

    # Test repository access
    local repo_info
    if repo_info=$(gh repo view --json owner,name 2>/dev/null); then
        local owner=$(echo "$repo_info" | jq -r '.owner.login')
        local repo_name=$(echo "$repo_info" | jq -r '.name')
        log "SUCCESS" "✅ Repository access: $owner/$repo_name"
    else
        log "ERROR" "❌ Cannot access repository"
        return 1
    fi

    # Test workflow API access
    if gh api repos/:owner/:repo/actions/workflows >/dev/null 2>&1; then
        log "SUCCESS" "✅ Actions API accessible"
    else
        log "ERROR" "❌ Actions API not accessible"
        return 1
    fi

    return 0
}

# Test runner configuration
test_runner_configuration() {
    log "STEP" "⚙️ Testing runner configuration..."

    local runner_dir="$HOME/actions-runner"

    if [ ! -d "$runner_dir" ]; then
        log "WARNING" "⚠️ Runner not configured. Use setup-self-hosted-runner.sh to configure."
        return 1
    fi

    cd "$runner_dir"

    # Check configuration files
    if [ -f ".runner" ]; then
        local agent_name
        agent_name=$(jq -r '.agentName // "unknown"' .runner 2>/dev/null || echo "unknown")
        log "SUCCESS" "✅ Runner configured: $agent_name"

        # Check labels
        local labels
        labels=$(jq -r '.labels // []' .runner 2>/dev/null | jq -r 'join(", ")' || echo "none")
        log "INFO" "🏷️ Runner labels: $labels"

        # Verify required labels are present
        local required_labels=("self-hosted" "linux" "x64" "astro" "nodejs" "ghostty-config")
        local missing_labels=()

        for label in "${required_labels[@]}"; do
            if ! echo "$labels" | grep -q "$label"; then
                missing_labels+=("$label")
            fi
        done

        if [ ${#missing_labels[@]} -eq 0 ]; then
            log "SUCCESS" "✅ All required labels present"
        else
            log "WARNING" "⚠️ Missing labels: ${missing_labels[*]}"
        fi

    else
        log "ERROR" "❌ Runner configuration file not found"
        return 1
    fi

    # Check credentials
    if [ -f ".credentials" ]; then
        log "SUCCESS" "✅ Runner credentials found"
    else
        log "ERROR" "❌ Runner credentials not found"
        return 1
    fi

    return 0
}

# Test workflow file validation
test_workflow_validation() {
    log "STEP" "📄 Testing workflow file validation..."

    local workflow_file="$REPO_DIR/.github/workflows/astro-pages-self-hosted.yml"

    if [ ! -f "$workflow_file" ]; then
        log "ERROR" "❌ Workflow file not found: $workflow_file"
        return 1
    fi

    log "SUCCESS" "✅ Workflow file found"

    # Validate YAML syntax
    if command -v yq >/dev/null 2>&1; then
        if yq eval . "$workflow_file" >/dev/null 2>&1; then
            log "SUCCESS" "✅ Workflow YAML syntax valid"
        else
            log "ERROR" "❌ Workflow YAML syntax invalid"
            return 1
        fi
    else
        log "WARNING" "⚠️ yq not available, skipping YAML validation"
    fi

    # Check for required runner labels in workflow
    if grep -q "runs-on: \[self-hosted, linux, x64, astro, nodejs, ghostty-config\]" "$workflow_file"; then
        log "SUCCESS" "✅ Workflow uses correct runner labels"
    else
        log "ERROR" "❌ Workflow missing required runner labels"
        return 1
    fi

    # Check for required permissions
    if grep -q "pages: write" "$workflow_file" && grep -q "id-token: write" "$workflow_file"; then
        log "SUCCESS" "✅ GitHub Pages permissions configured"
    else
        log "WARNING" "⚠️ GitHub Pages permissions may be missing"
    fi

    return 0
}

# Test local Astro build capability
test_astro_build_capability() {
    log "STEP" "🚀 Testing Astro build capability..."

    cd "$REPO_DIR"

    # Check Node.js version
    local node_version
    node_version=$(node --version | sed 's/v//')
    local major_version
    major_version=$(echo "$node_version" | cut -d. -f1)

    if [ "$major_version" -ge 18 ]; then
        log "SUCCESS" "✅ Node.js $node_version (compatible with Astro)"
    else
        log "ERROR" "❌ Node.js $node_version too old for Astro (requires 18+)"
        return 1
    fi

    # Test dependency installation
    log "INFO" "Installing dependencies..."
    if npm ci --silent; then
        log "SUCCESS" "✅ Dependencies installed successfully"
    else
        log "ERROR" "❌ Dependency installation failed"
        return 1
    fi

    # Test TypeScript check
    log "INFO" "Running TypeScript check..."
    if npm run check >/dev/null 2>&1; then
        log "SUCCESS" "✅ TypeScript check passed"
    else
        log "ERROR" "❌ TypeScript check failed"
        return 1
    fi

    # Test build
    log "INFO" "Running Astro build..."
    if npm run build >/dev/null 2>&1; then
        log "SUCCESS" "✅ Astro build successful"

        # Verify build output
        if [ -f "docs/index.html" ]; then
            local build_size
            build_size=$(du -sh docs/ | cut -f1)
            log "SUCCESS" "✅ Build output verified (size: $build_size)"
        else
            log "ERROR" "❌ Build output missing (no index.html)"
            return 1
        fi
    else
        log "ERROR" "❌ Astro build failed"
        return 1
    fi

    return 0
}

# Test GitHub Pages artifact creation
test_pages_artifact_creation() {
    log "STEP" "📦 Testing GitHub Pages artifact creation..."

    cd "$REPO_DIR"

    # Ensure build exists
    if [ ! -d "docs" ]; then
        log "WARNING" "⚠️ No build output found, running build first..."
        npm run build >/dev/null 2>&1
    fi

    # Create a mock Pages artifact (similar to actions/upload-pages-artifact)
    local artifact_dir="$LOG_DIR/mock-pages-artifact"
    mkdir -p "$artifact_dir"

    # Create tar.gz file similar to GitHub Pages artifact
    log "INFO" "Creating mock Pages artifact..."
    cd docs
    tar -czf "$artifact_dir/pages-artifact.tar.gz" .
    cd "$REPO_DIR"

    if [ -f "$artifact_dir/pages-artifact.tar.gz" ]; then
        local artifact_size
        artifact_size=$(du -sh "$artifact_dir/pages-artifact.tar.gz" | cut -f1)
        log "SUCCESS" "✅ Pages artifact created (size: $artifact_size)"

        # Check artifact size (GitHub Pages has 10GB limit)
        local size_bytes
        size_bytes=$(du -b "$artifact_dir/pages-artifact.tar.gz" | cut -f1)
        if [ "$size_bytes" -lt 10737418240 ]; then  # 10GB
            log "SUCCESS" "✅ Artifact size within GitHub Pages limits"
        else
            log "WARNING" "⚠️ Artifact size exceeds GitHub Pages limits"
        fi
    else
        log "ERROR" "❌ Failed to create Pages artifact"
        return 1
    fi

    return 0
}

# Test runner security configuration
test_runner_security() {
    log "STEP" "🔒 Testing runner security configuration..."

    local runner_dir="$HOME/actions-runner"

    if [ ! -d "$runner_dir" ]; then
        log "WARNING" "⚠️ Runner not configured"
        return 1
    fi

    cd "$runner_dir"

    # Check file permissions
    if [ -f ".credentials" ]; then
        local credentials_perms
        credentials_perms=$(stat -c "%a" .credentials)
        if [ "$credentials_perms" = "600" ]; then
            log "SUCCESS" "✅ Credentials file has secure permissions (600)"
        else
            log "WARNING" "⚠️ Credentials file permissions: $credentials_perms (recommended: 600)"
        fi
    fi

    # Check for RSA private key
    if [ -f ".credentials_rsaparams" ]; then
        local rsa_perms
        rsa_perms=$(stat -c "%a" .credentials_rsaparams)
        if [ "$rsa_perms" = "600" ]; then
            log "SUCCESS" "✅ RSA key file has secure permissions (600)"
        else
            log "WARNING" "⚠️ RSA key file permissions: $rsa_perms (recommended: 600)"
        fi
    fi

    # Check runner service user
    if systemctl list-units --type=service | grep -q actions.runner; then
        local service_user
        service_user=$(systemctl show -p User actions.runner.* | head -1 | cut -d= -f2)
        if [ "$service_user" = "$(whoami)" ]; then
            log "SUCCESS" "✅ Runner service runs as current user"
        else
            log "INFO" "ℹ️ Runner service user: $service_user"
        fi
    fi

    return 0
}

# Test end-to-end workflow simulation
test_e2e_workflow_simulation() {
    log "STEP" "🎯 Testing end-to-end workflow simulation..."

    # Simulate the full workflow locally
    cd "$REPO_DIR"

    # Step 1: Checkout (already done)
    log "INFO" "✅ Step 1: Repository checkout"

    # Step 2: Setup Node.js (already available)
    log "INFO" "✅ Step 2: Node.js setup"

    # Step 3: Install dependencies
    log "INFO" "Step 3: Installing dependencies..."
    if npm ci --silent; then
        log "SUCCESS" "✅ Dependencies installed"
    else
        log "ERROR" "❌ Dependency installation failed"
        return 1
    fi

    # Step 4: TypeScript check
    log "INFO" "Step 4: TypeScript validation..."
    if npm run check >/dev/null 2>&1; then
        log "SUCCESS" "✅ TypeScript check passed"
    else
        log "ERROR" "❌ TypeScript check failed"
        return 1
    fi

    # Step 5: Build
    log "INFO" "Step 5: Building Astro site..."
    if npm run build >/dev/null 2>&1; then
        log "SUCCESS" "✅ Build completed"
    else
        log "ERROR" "❌ Build failed"
        return 1
    fi

    # Step 6: Verify build output
    log "INFO" "Step 6: Verifying build output..."
    if [ -f "docs/index.html" ]; then
        log "SUCCESS" "✅ Build output verified"
    else
        log "ERROR" "❌ Build output missing"
        return 1
    fi

    # Step 7: Performance analysis
    log "INFO" "Step 7: Performance analysis..."
    local js_size
    js_size=$(find docs/ -name "*.js" -exec du -cb {} + 2>/dev/null | tail -1 | cut -f1 || echo "0")

    if [ "$js_size" -lt 102400 ]; then  # 100KB
        log "SUCCESS" "✅ Constitutional compliance: JavaScript bundle <100KB"
    else
        log "WARNING" "⚠️ JavaScript bundle >100KB: $(numfmt --to=iec $js_size)"
    fi

    return 0
}

# Generate comprehensive test report
generate_test_report() {
    log "STEP" "📊 Generating integration test report..."

    local report_file="$LOG_DIR/integration-test-report-$(date +%s).json"
    local overall_status="success"

    # Run all tests and capture results
    local test_results=()

    test_github_cli_integration && test_results+=("github_cli:success") || { test_results+=("github_cli:failed"); overall_status="failed"; }
    test_runner_configuration && test_results+=("runner_config:success") || { test_results+=("runner_config:failed"); overall_status="partial"; }
    test_workflow_validation && test_results+=("workflow_validation:success") || { test_results+=("workflow_validation:failed"); overall_status="failed"; }
    test_astro_build_capability && test_results+=("astro_build:success") || { test_results+=("astro_build:failed"); overall_status="failed"; }
    test_pages_artifact_creation && test_results+=("pages_artifact:success") || { test_results+=("pages_artifact:failed"); overall_status="failed"; }
    test_runner_security && test_results+=("runner_security:success") || { test_results+=("runner_security:partial"); }
    test_e2e_workflow_simulation && test_results+=("e2e_simulation:success") || { test_results+=("e2e_simulation:failed"); overall_status="failed"; }

    # Generate JSON report
    cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "overall_status": "$overall_status",
    "test_summary": {
        "total_tests": ${#test_results[@]},
        "environment": "self-hosted-runner",
        "repository": "$(cd "$REPO_DIR" && git remote get-url origin 2>/dev/null || echo 'unknown')",
        "commit": "$(cd "$REPO_DIR" && git rev-parse HEAD 2>/dev/null || echo 'unknown')"
    },
    "system_info": {
        "os": "$(uname -s)",
        "kernel": "$(uname -r)",
        "architecture": "$(uname -m)",
        "hostname": "$(hostname)",
        "node_version": "$(node --version 2>/dev/null || echo 'unknown')",
        "npm_version": "$(npm --version 2>/dev/null || echo 'unknown')"
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
    "next_steps": [
EOF

    # Add recommendations based on failed tests
    local recommendations=()

    for result in "${test_results[@]}"; do
        local test_name=$(echo "$result" | cut -d: -f1)
        local test_status=$(echo "$result" | cut -d: -f2)

        if [ "$test_status" = "failed" ]; then
            case "$test_name" in
                "github_cli")
                    recommendations+=("Run 'gh auth login' to authenticate GitHub CLI")
                    ;;
                "runner_config")
                    recommendations+=("Run './.runners-local/workflows/setup-self-hosted-runner.sh setup' to configure runner")
                    ;;
                "workflow_validation")
                    recommendations+=("Check workflow file syntax and permissions")
                    ;;
                "astro_build")
                    recommendations+=("Fix TypeScript errors and verify Astro configuration")
                    ;;
                "pages_artifact")
                    recommendations+=("Ensure build output is properly structured for GitHub Pages")
                    ;;
                "e2e_simulation")
                    recommendations+=("Review build logs and fix any errors in the workflow")
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

    log "SUCCESS" "✅ Integration test report generated: $report_file"

    # Display summary
    log "INFO" "📋 Integration Test Summary:"
    log "INFO" "   Overall Status: $overall_status"
    log "INFO" "   Total Tests: ${#test_results[@]}"
    log "INFO" "   Report Location: $report_file"

    if [ "$overall_status" = "success" ]; then
        log "SUCCESS" "🎉 All integration tests passed! Runner is ready for GitHub Actions."
    elif [ "$overall_status" = "partial" ]; then
        log "WARNING" "⚠️ Some tests passed with warnings. Review recommendations."
    else
        log "ERROR" "❌ Integration tests failed. Review and fix issues before using runner."
        return 1
    fi
}

# Show help
show_help() {
    cat << EOF
GitHub Actions Self-Hosted Runner Integration Test

Usage: $0 [COMMAND]

Commands:
  github-cli     Test GitHub CLI integration
  runner-config  Test runner configuration
  workflow       Test workflow validation
  astro-build    Test Astro build capability
  pages-artifact Test GitHub Pages artifact creation
  security       Test runner security configuration
  e2e            Test end-to-end workflow simulation
  report         Generate comprehensive test report
  all            Run all tests (same as report)
  help           Show this help message

Examples:
  $0 github-cli    # Test GitHub CLI only
  $0 report        # Generate full test report
  $0 all           # Run all integration tests

Note: This script validates self-hosted runner setup for Astro GitHub Pages deployment.
Logs are stored in $LOG_DIR.
EOF
}

# Main execution
main() {
    case "${1:-help}" in
        "github-cli")
            test_github_cli_integration
            ;;
        "runner-config")
            test_runner_configuration
            ;;
        "workflow")
            test_workflow_validation
            ;;
        "astro-build")
            test_astro_build_capability
            ;;
        "pages-artifact")
            test_pages_artifact_creation
            ;;
        "security")
            test_runner_security
            ;;
        "e2e")
            test_e2e_workflow_simulation
            ;;
        "report"|"all")
            generate_test_report
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