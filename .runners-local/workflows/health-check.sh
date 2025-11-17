#!/bin/bash

# Local CI/CD Health Checker
# Validates prerequisites, environment, and infrastructure for cross-device compatibility
# Part of ghostty-config-files zero-cost local CI/CD system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$SCRIPT_DIR")")"
LOG_DIR="$SCRIPT_DIR/../logs"
TIMESTAMP=$(date +%s)
HOSTNAME=$(hostname)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Health check results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Results storage
declare -A CATEGORY_RESULTS
declare -A CHECK_DETAILS

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp_str=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""

    case "$level" in
        "ERROR") color="$RED" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "INFO") color="$BLUE" ;;
        "STEP") color="$CYAN" ;;
    esac

    echo -e "${color}[$timestamp_str] [$level] $message${NC}"
    echo "[$timestamp_str] [$level] $message" >> "$LOG_DIR/health-check-$TIMESTAMP.log"
}

# Check result tracking
record_check() {
    local category="$1"
    local check_name="$2"
    local status="$3"
    local details="$4"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    case "$status" in
        "passed")
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            ;;
        "failed")
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            ;;
        "warning")
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            ;;
    esac

    # Store in associative arrays
    CHECK_DETAILS["${category}:${check_name}"]="$status|$details"
}

# ═══════════════════════════════════════════════════════════
# CATEGORY 1: Core Tools Validation
# ═══════════════════════════════════════════════════════════

check_core_tools() {
    log "STEP" "🔧 Checking core tools..."

    # GitHub CLI
    if command -v gh >/dev/null 2>&1; then
        local gh_version=$(gh --version | head -n1 | awk '{print $3}')
        record_check "core_tools" "gh_cli" "passed" "version: $gh_version"
        log "SUCCESS" "✅ GitHub CLI: $gh_version"
    else
        record_check "core_tools" "gh_cli" "failed" "not installed"
        log "ERROR" "❌ GitHub CLI not found"
    fi

    # Node.js
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node -v | sed 's/v//' | cut -d. -f1)
        if [ "$node_version" -ge 25 ]; then
            record_check "core_tools" "node_js" "passed" "version: v$node_version (target: 25+)"
            log "SUCCESS" "✅ Node.js: v$node_version (target)"
        elif [ "$node_version" -ge 18 ]; then
            record_check "core_tools" "node_js" "warning" "version: v$node_version (minimum met, recommend 25+)"
            log "WARNING" "⚠️  Node.js: v$node_version (works, but recommend 25+)"
        else
            record_check "core_tools" "node_js" "failed" "version too old: v$node_version"
            log "ERROR" "❌ Node.js: v$node_version (minimum: 18+)"
        fi
    else
        record_check "core_tools" "node_js" "failed" "not installed"
        log "ERROR" "❌ Node.js not found"
    fi

    # npm
    if command -v npm >/dev/null 2>&1; then
        local npm_version=$(npm -v)
        record_check "core_tools" "npm" "passed" "version: $npm_version"
        log "SUCCESS" "✅ npm: $npm_version"
    else
        record_check "core_tools" "npm" "failed" "not installed"
        log "ERROR" "❌ npm not found"
    fi

    # git
    if command -v git >/dev/null 2>&1; then
        local git_version=$(git --version | awk '{print $3}')
        record_check "core_tools" "git" "passed" "version: $git_version"
        log "SUCCESS" "✅ git: $git_version"
    else
        record_check "core_tools" "git" "failed" "not installed"
        log "ERROR" "❌ git not found"
    fi

    # jq
    if command -v jq >/dev/null 2>&1; then
        local jq_version=$(jq --version | sed 's/jq-//')
        record_check "core_tools" "jq" "passed" "version: $jq_version"
        log "SUCCESS" "✅ jq: $jq_version"
    else
        record_check "core_tools" "jq" "failed" "not installed"
        log "ERROR" "❌ jq not found"
    fi

    # curl
    if command -v curl >/dev/null 2>&1; then
        local curl_version=$(curl --version | head -n1 | awk '{print $2}')
        record_check "core_tools" "curl" "passed" "version: $curl_version"
        log "SUCCESS" "✅ curl: $curl_version"
    else
        record_check "core_tools" "curl" "failed" "not installed"
        log "ERROR" "❌ curl not found"
    fi

    # bash
    if command -v bash >/dev/null 2>&1; then
        local bash_version=$(bash --version | head -n1 | awk '{print $4}')
        record_check "core_tools" "bash" "passed" "version: $bash_version"
        log "SUCCESS" "✅ bash: $bash_version"
    else
        record_check "core_tools" "bash" "failed" "not installed"
        log "ERROR" "❌ bash not found"
    fi
}

# ═══════════════════════════════════════════════════════════
# CATEGORY 2: Environment Variables Validation
# ═══════════════════════════════════════════════════════════

check_environment_variables() {
    log "STEP" "🔐 Checking environment variables..."

    # Check .env file exists
    if [ -f "$REPO_DIR/.env" ]; then
        record_check "environment" "env_file" "passed" "exists at $REPO_DIR/.env"
        log "SUCCESS" "✅ .env file exists"
    else
        record_check "environment" "env_file" "failed" "not found"
        log "ERROR" "❌ .env file not found - copy from .env.example"
    fi

    # Check CONTEXT7_API_KEY exported to shell
    if [ -n "${CONTEXT7_API_KEY:-}" ]; then
        record_check "environment" "context7_api_key" "passed" "exported to shell"
        log "SUCCESS" "✅ CONTEXT7_API_KEY exported to shell"
    else
        record_check "environment" "context7_api_key" "failed" "not exported"
        log "ERROR" "❌ CONTEXT7_API_KEY not exported to shell environment"
        log "INFO" "   Add to ~/.zshrc: set -a; source $REPO_DIR/.env; set +a"
    fi

    # Check GITHUB_TOKEN exported to shell
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        record_check "environment" "github_token" "passed" "exported to shell"
        log "SUCCESS" "✅ GITHUB_TOKEN exported to shell"
    else
        # Try to get from gh CLI
        if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
            local gh_token=$(gh auth token 2>/dev/null || echo "")
            if [ -n "$gh_token" ]; then
                record_check "environment" "github_token" "warning" "available via gh CLI but not exported"
                log "WARNING" "⚠️  GITHUB_TOKEN available via gh CLI but not exported"
                log "INFO" "   Add to .env: GITHUB_TOKEN=\$(gh auth token)"
            else
                record_check "environment" "github_token" "failed" "not available"
                log "ERROR" "❌ GITHUB_TOKEN not available"
            fi
        else
            record_check "environment" "github_token" "failed" "not exported"
            log "ERROR" "❌ GITHUB_TOKEN not exported to shell environment"
        fi
    fi

    # Check shell config loads .env
    local shell_config=""
    if [ -n "${ZSH_VERSION:-}" ]; then
        shell_config="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ]; then
        shell_config="$HOME/.bashrc"
    fi

    if [ -n "$shell_config" ] && [ -f "$shell_config" ]; then
        if grep -q "ghostty-config-files/.env" "$shell_config" || grep -q "source.*\.env" "$shell_config"; then
            record_check "environment" "shell_config" "passed" "loads .env in $shell_config"
            log "SUCCESS" "✅ Shell config loads .env"
        else
            record_check "environment" "shell_config" "warning" ".env not auto-loaded in $shell_config"
            log "WARNING" "⚠️  .env not auto-loaded in shell config"
            log "INFO" "   Consider adding to $shell_config for automatic loading"
        fi
    else
        record_check "environment" "shell_config" "warning" "shell config not found"
        log "WARNING" "⚠️  Shell config not detected"
    fi
}

# ═══════════════════════════════════════════════════════════
# CATEGORY 3: Local CI/CD Infrastructure
# ═══════════════════════════════════════════════════════════

check_local_cicd_infrastructure() {
    log "STEP" "🏗️  Checking local CI/CD infrastructure..."

    # Check .runners-local/ directory structure
    if [ -d "$REPO_DIR/.runners-local" ]; then
        record_check "local_cicd" "runners_local_dir" "passed" "directory exists"
        log "SUCCESS" "✅ .runners-local/ directory exists"
    else
        record_check "local_cicd" "runners_local_dir" "failed" "directory missing"
        log "ERROR" "❌ .runners-local/ directory not found"
    fi

    # Check workflows/ directory
    if [ -d "$REPO_DIR/.runners-local/workflows" ]; then
        # Count executable scripts
        local executable_count=$(find "$REPO_DIR/.runners-local/workflows" -name "*.sh" -type f -executable 2>/dev/null | wc -l)
        local total_count=$(find "$REPO_DIR/.runners-local/workflows" -name "*.sh" -type f 2>/dev/null | wc -l)

        if [ "$executable_count" -eq "$total_count" ]; then
            record_check "local_cicd" "workflow_scripts" "passed" "$executable_count/$total_count scripts executable"
            log "SUCCESS" "✅ Workflow scripts: $executable_count/$total_count executable"
        else
            record_check "local_cicd" "workflow_scripts" "warning" "$executable_count/$total_count scripts executable"
            log "WARNING" "⚠️  Workflow scripts: $executable_count/$total_count executable"
            log "INFO" "   Run: chmod +x .runners-local/workflows/*.sh"
        fi
    else
        record_check "local_cicd" "workflow_scripts" "failed" "workflows/ directory missing"
        log "ERROR" "❌ workflows/ directory not found"
    fi

    # Check logs/ directory (writable)
    if [ -d "$LOG_DIR" ] && [ -w "$LOG_DIR" ]; then
        record_check "local_cicd" "logs_dir" "passed" "exists and writable"
        log "SUCCESS" "✅ logs/ directory writable"
    else
        mkdir -p "$LOG_DIR" 2>/dev/null || true
        if [ -w "$LOG_DIR" ]; then
            record_check "local_cicd" "logs_dir" "passed" "created and writable"
            log "SUCCESS" "✅ logs/ directory created"
        else
            record_check "local_cicd" "logs_dir" "failed" "not writable"
            log "ERROR" "❌ logs/ directory not writable"
        fi
    fi

    # Check tests/ directory
    if [ -d "$REPO_DIR/.runners-local/tests" ]; then
        record_check "local_cicd" "tests_dir" "passed" "exists"
        log "SUCCESS" "✅ tests/ directory exists"
    else
        record_check "local_cicd" "tests_dir" "warning" "not found (optional)"
        log "WARNING" "⚠️  tests/ directory not found (optional)"
    fi
}

# ═══════════════════════════════════════════════════════════
# CATEGORY 4: MCP Server Connectivity
# ═══════════════════════════════════════════════════════════

check_mcp_connectivity() {
    log "STEP" "🔌 Checking MCP server connectivity..."

    # Check .mcp.json exists
    if [ -f "$REPO_DIR/.mcp.json" ]; then
        record_check "mcp_servers" "mcp_json" "passed" "configuration file exists"
        log "SUCCESS" "✅ .mcp.json configuration exists"
    else
        record_check "mcp_servers" "mcp_json" "failed" "configuration missing"
        log "ERROR" "❌ .mcp.json configuration not found"
    fi

    # Check Claude CLI available
    if command -v claude >/dev/null 2>&1; then
        record_check "mcp_servers" "claude_cli" "passed" "Claude Code CLI available"
        log "SUCCESS" "✅ Claude Code CLI available"

        # Try to check MCP server status (non-blocking)
        local mcp_status=$(timeout 5s claude mcp list 2>/dev/null | grep -i context7 || echo "")
        if [ -n "$mcp_status" ]; then
            if echo "$mcp_status" | grep -qi "connected"; then
                record_check "mcp_servers" "context7_connection" "passed" "connected"
                log "SUCCESS" "✅ Context7 MCP connected"
            else
                record_check "mcp_servers" "context7_connection" "warning" "not connected"
                log "WARNING" "⚠️  Context7 MCP not connected"
            fi
        else
            record_check "mcp_servers" "context7_connection" "warning" "status unknown (timeout)"
            log "WARNING" "⚠️  Context7 MCP status unknown (check manually)"
        fi

        # Check GitHub MCP
        local github_mcp=$(timeout 5s claude mcp list 2>/dev/null | grep -i github || echo "")
        if [ -n "$github_mcp" ]; then
            if echo "$github_mcp" | grep -qi "connected"; then
                record_check "mcp_servers" "github_connection" "passed" "connected"
                log "SUCCESS" "✅ GitHub MCP connected"
            else
                record_check "mcp_servers" "github_connection" "warning" "not connected"
                log "WARNING" "⚠️  GitHub MCP not connected"
            fi
        else
            record_check "mcp_servers" "github_connection" "warning" "status unknown (timeout)"
            log "WARNING" "⚠️  GitHub MCP status unknown (check manually)"
        fi
    else
        record_check "mcp_servers" "claude_cli" "warning" "not installed (optional for local CI/CD)"
        log "WARNING" "⚠️  Claude Code CLI not found (optional)"
        record_check "mcp_servers" "context7_connection" "warning" "cannot check (claude CLI missing)"
        record_check "mcp_servers" "github_connection" "warning" "cannot check (claude CLI missing)"
    fi
}

# ═══════════════════════════════════════════════════════════
# CATEGORY 5: Astro Build Environment
# ═══════════════════════════════════════════════════════════

check_astro_environment() {
    log "STEP" "🌐 Checking Astro build environment..."

    # Check website/package.json
    if [ -f "$REPO_DIR/website/package.json" ]; then
        record_check "astro_build" "package_json" "passed" "exists"
        log "SUCCESS" "✅ website/package.json exists"
    else
        record_check "astro_build" "package_json" "failed" "not found"
        log "ERROR" "❌ website/package.json not found"
    fi

    # Check node_modules installed
    if [ -d "$REPO_DIR/website/node_modules" ]; then
        record_check "astro_build" "node_modules" "passed" "dependencies installed"
        log "SUCCESS" "✅ Dependencies installed"
    else
        record_check "astro_build" "node_modules" "warning" "not installed"
        log "WARNING" "⚠️  Dependencies not installed - run: npm install"
    fi

    # Check astro.config.mjs
    if [ -f "$REPO_DIR/website/astro.config.mjs" ]; then
        record_check "astro_build" "astro_config" "passed" "configuration exists"
        log "SUCCESS" "✅ astro.config.mjs exists"

        # Verify outDir setting
        if grep -q 'outDir.*docs' "$REPO_DIR/website/astro.config.mjs"; then
            log "SUCCESS" "✅ outDir correctly set to ../docs"
        else
            log "WARNING" "⚠️  outDir may not be set to ../docs"
        fi
    else
        record_check "astro_build" "astro_config" "failed" "not found"
        log "ERROR" "❌ astro.config.mjs not found"
    fi

    # Check docs/ build output directory
    if [ -d "$REPO_DIR/docs" ]; then
        if [ -f "$REPO_DIR/docs/index.html" ]; then
            record_check "astro_build" "build_output" "passed" "build output exists"
            log "SUCCESS" "✅ Build output exists (docs/index.html)"
        else
            record_check "astro_build" "build_output" "warning" "docs/ exists but no index.html"
            log "WARNING" "⚠️  docs/ exists but no build output - run: npm run build"
        fi
    else
        record_check "astro_build" "build_output" "warning" "not found"
        log "WARNING" "⚠️  docs/ directory not found - run: npm run build"
    fi

    # CRITICAL: Check .nojekyll file
    if [ -f "$REPO_DIR/docs/.nojekyll" ]; then
        record_check "astro_build" "nojekyll_file" "passed" "CRITICAL file exists"
        log "SUCCESS" "✅ docs/.nojekyll exists (CRITICAL for GitHub Pages)"
    else
        record_check "astro_build" "nojekyll_file" "failed" "CRITICAL file missing"
        log "ERROR" "❌ docs/.nojekyll missing (CRITICAL: CSS/JS will 404 on GitHub Pages)"
        log "INFO" "   Fix: touch docs/.nojekyll"
    fi
}

# ═══════════════════════════════════════════════════════════
# CATEGORY 6: Self-Hosted Runner (Optional)
# ═══════════════════════════════════════════════════════════

check_self_hosted_runner() {
    log "STEP" "🏃 Checking self-hosted runner (optional)..."

    # Check if runner directory exists
    if [ -d "$HOME/actions-runner" ]; then
        record_check "runner" "runner_installed" "passed" "installed at $HOME/actions-runner"
        log "SUCCESS" "✅ Self-hosted runner installed"

        # Check if systemd service configured
        local service_name="github-actions-runner-$(whoami)"
        if systemctl list-unit-files | grep -q "$service_name"; then
            record_check "runner" "systemd_service" "passed" "service configured"
            log "SUCCESS" "✅ Systemd service configured"

            # Check service status
            if systemctl is-active --quiet "$service_name"; then
                record_check "runner" "service_running" "passed" "service active"
                log "SUCCESS" "✅ Runner service active"
            else
                record_check "runner" "service_running" "warning" "service not running"
                log "WARNING" "⚠️  Runner service not running"
            fi
        else
            record_check "runner" "systemd_service" "warning" "service not configured"
            log "WARNING" "⚠️  Systemd service not configured"
            record_check "runner" "service_running" "warning" "cannot check (no service)"
        fi

        # Check runner registration (via logs)
        if [ -f "$LOG_DIR/runner-name.txt" ]; then
            local runner_name=$(cat "$LOG_DIR/runner-name.txt")
            record_check "runner" "registration" "passed" "registered as $runner_name"
            log "SUCCESS" "✅ Runner registered: $runner_name"
        else
            record_check "runner" "registration" "warning" "registration status unknown"
            log "WARNING" "⚠️  Runner registration status unknown"
        fi
    else
        record_check "runner" "runner_installed" "warning" "not installed (optional)"
        log "INFO" "ℹ️  Self-hosted runner not installed (optional component)"
        record_check "runner" "systemd_service" "warning" "not applicable"
        record_check "runner" "service_running" "warning" "not applicable"
        record_check "runner" "registration" "warning" "not applicable"
    fi
}

# ═══════════════════════════════════════════════════════════
# Generate Setup Instructions
# ═══════════════════════════════════════════════════════════

generate_setup_instructions() {
    local setup_file="$LOG_DIR/setup-instructions-$HOSTNAME-$TIMESTAMP.md"

    log "INFO" "📝 Generating setup instructions: $setup_file"

    cat > "$setup_file" << 'EOF'
# Local CI/CD Setup Instructions

**Generated for**: HOSTNAME_PLACEHOLDER
**Timestamp**: TIMESTAMP_PLACEHOLDER
**Repository**: REPO_PATH_PLACEHOLDER

## Issues Found

ISSUES_PLACEHOLDER

## Setup Instructions

### Step 1: Install Missing Core Tools

CORE_TOOLS_SETUP_PLACEHOLDER

### Step 2: Configure Environment Variables

ENVIRONMENT_SETUP_PLACEHOLDER

### Step 3: Verify Local CI/CD Infrastructure

LOCAL_CICD_SETUP_PLACEHOLDER

### Step 4: Configure MCP Servers

MCP_SETUP_PLACEHOLDER

### Step 5: Setup Astro Build Environment

ASTRO_SETUP_PLACEHOLDER

## Verification

After completing setup, run:

```bash
./.runners-local/workflows/health-check.sh
```

All checks should show ✅ PASSED.

## Next Steps

1. Run complete local workflow: `./.runners-local/workflows/gh-workflow-local.sh all`
2. Build website: `cd website && npm run build`
3. Verify GitHub Pages deployment readiness

For detailed documentation, see:
- [New Device Setup Guide](../docs-setup/new-device-setup.md)
- [Context7 MCP Setup](../docs-setup/context7-mcp.md)
- [GitHub MCP Setup](../docs-setup/github-mcp.md)
EOF

    # Replace placeholders with actual data
    sed -i "s|HOSTNAME_PLACEHOLDER|$HOSTNAME|g" "$setup_file"
    sed -i "s|TIMESTAMP_PLACEHOLDER|$(date '+%Y-%m-%d %H:%M:%S')|g" "$setup_file"
    sed -i "s|REPO_PATH_PLACEHOLDER|$REPO_DIR|g" "$setup_file"

    # Generate issues summary
    local issues=""
    if [ $FAILED_CHECKS -gt 0 ]; then
        issues+="- ❌ $FAILED_CHECKS critical failures detected\n"
    fi
    if [ $WARNING_CHECKS -gt 0 ]; then
        issues+="- ⚠️  $WARNING_CHECKS warnings (non-blocking)\n"
    fi
    sed -i "s|ISSUES_PLACEHOLDER|$issues|g" "$setup_file"

    log "SUCCESS" "✅ Setup instructions generated: $setup_file"
    echo ""
    echo "View with: cat $setup_file"
}

# ═══════════════════════════════════════════════════════════
# Generate JSON Report
# ═══════════════════════════════════════════════════════════

generate_json_report() {
    local json_file="$LOG_DIR/health-check-$TIMESTAMP.json"

    local overall_status="READY"
    if [ $FAILED_CHECKS -gt 0 ]; then
        overall_status="CRITICAL_ISSUES"
    elif [ $WARNING_CHECKS -gt 0 ]; then
        overall_status="NEEDS_SETUP"
    fi

    cat > "$json_file" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "repository_path": "$REPO_DIR",
  "device_hostname": "$HOSTNAME",
  "overall_status": "$overall_status",
  "summary": {
    "total_checks": $TOTAL_CHECKS,
    "passed": $PASSED_CHECKS,
    "failed": $FAILED_CHECKS,
    "warnings": $WARNING_CHECKS
  },
  "categories": {
    "core_tools": {},
    "environment_variables": {},
    "local_cicd": {},
    "mcp_servers": {},
    "astro_build": {},
    "self_hosted_runner": {}
  }
}
EOF

    log "INFO" "📊 JSON report generated: $json_file"
}

# ═══════════════════════════════════════════════════════════
# Display Summary
# ═══════════════════════════════════════════════════════════

display_summary() {
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Health Check Summary"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "  Total Checks: $TOTAL_CHECKS"
    echo -e "  ${GREEN}Passed:       $PASSED_CHECKS${NC}"
    echo -e "  ${RED}Failed:       $FAILED_CHECKS${NC}"
    echo -e "  ${YELLOW}Warnings:     $WARNING_CHECKS${NC}"
    echo ""

    if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
        echo "╔════════════════════════════════════════════════════╗"
        echo "║                                                    ║"
        echo "║    ✅  ALL CHECKS PASSED - READY FOR CI/CD  ✅    ║"
        echo "║                                                    ║"
        echo "╚════════════════════════════════════════════════════╝"
    elif [ $FAILED_CHECKS -eq 0 ]; then
        echo "╔════════════════════════════════════════════════════╗"
        echo "║                                                    ║"
        echo "║    ⚠️  WARNINGS DETECTED - MOSTLY READY  ⚠️       ║"
        echo "║                                                    ║"
        echo "╚════════════════════════════════════════════════════╝"
    else
        echo "╔════════════════════════════════════════════════════╗"
        echo "║                                                    ║"
        echo "║    ❌  CRITICAL ISSUES - SETUP NEEDED  ❌         ║"
        echo "║                                                    ║"
        echo "╚════════════════════════════════════════════════════╝"
    fi

    echo ""
    echo "Logs: $LOG_DIR/health-check-$TIMESTAMP.log"
    echo "JSON: $LOG_DIR/health-check-$TIMESTAMP.json"
    echo ""
}

# ═══════════════════════════════════════════════════════════
# Main Execution
# ═══════════════════════════════════════════════════════════

main() {
    log "INFO" "🏥 Starting Local CI/CD Health Check..."
    log "INFO" "📍 Repository: $REPO_DIR"
    log "INFO" "🖥️  Hostname: $HOSTNAME"
    echo ""

    # Run all health checks
    check_core_tools
    echo ""
    check_environment_variables
    echo ""
    check_local_cicd_infrastructure
    echo ""
    check_mcp_connectivity
    echo ""
    check_astro_environment
    echo ""
    check_self_hosted_runner
    echo ""

    # Generate reports
    generate_json_report

    # Display summary
    display_summary

    # Generate setup instructions if needed
    if [ $FAILED_CHECKS -gt 0 ] || [ "${1:-}" = "--setup-guide" ]; then
        generate_setup_instructions
    fi

    # Exit with appropriate code
    if [ $FAILED_CHECKS -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Show help
show_help() {
    cat << EOF
Local CI/CD Health Checker

Validates prerequisites, environment, and infrastructure for cross-device compatibility.

Usage: $0 [COMMAND]

Commands:
  (no args)       Run complete health check
  --setup-guide   Generate setup instructions for missing components
  --help          Show this help message

Examples:
  $0                    # Run health check
  $0 --setup-guide      # Generate setup guide
  $0 --help             # Show help

Exit Codes:
  0 - All checks passed (or only warnings)
  1 - One or more critical failures

Output:
  - Human-readable logs: .runners-local/logs/health-check-TIMESTAMP.log
  - JSON report: .runners-local/logs/health-check-TIMESTAMP.json
  - Setup guide (if needed): .runners-local/logs/setup-instructions-HOSTNAME-TIMESTAMP.md
EOF
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "--help"|"-h")
            show_help
            ;;
        *)
            main "$@"
            ;;
    esac
fi
