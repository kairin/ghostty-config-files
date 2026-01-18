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

# Detect CI/CD policy (zero-cost vs runner-based)
# Priority: Constitutional requirement (AGENTS.md) > Local infrastructure > Workflow files
detect_cicd_policy() {
    local policy="unknown"
    local has_zero_cost_constitution=false

    # Check for constitutional zero-cost requirement (HIGHEST PRIORITY)
    if [ -f "$REPO_DIR/AGENTS.md" ]; then
        if grep -qi "zero.*cost\|zero.*github.*actions\|local.*ci/cd" "$REPO_DIR/AGENTS.md"; then
            policy="zero-cost"
            has_zero_cost_constitution=true
        fi
    fi

    # Check for local CI/CD infrastructure (strong indicator of zero-cost)
    if [ -d "$REPO_DIR/.runners-local" ]; then
        policy="zero-cost"
    fi

    # Check if any workflow requires self-hosted runner
    # ONLY applies if there's no constitutional zero-cost requirement
    if [ "$has_zero_cost_constitution" = false ] && [ -d "$REPO_DIR/.github/workflows" ]; then
        if grep -rq "runs-on:.*self-hosted" "$REPO_DIR/.github/workflows/" 2>/dev/null; then
            policy="runner-required"
        fi
    fi

    echo "$policy"
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
# CATEGORY 2: Environment & Authentication (User-Level)
# ═══════════════════════════════════════════════════════════

check_environment_variables() {
    log "STEP" "🔐 Checking authentication (user-level)..."

    # NOTE: MCP servers handle their own API keys via ~/.claude.json
    # No need for project-level .env files - MCP connectivity check is sufficient
    # If claude mcp list shows servers connected, authentication is working

    # Check GitHub CLI authentication (needed for git operations)
    if command -v gh >/dev/null 2>&1; then
        if gh auth status >/dev/null 2>&1; then
            record_check "environment" "gh_auth" "passed" "GitHub CLI authenticated"
            log "SUCCESS" "✅ GitHub CLI authenticated"
        else
            record_check "environment" "gh_auth" "warning" "not authenticated"
            log "WARNING" "⚠️  GitHub CLI not authenticated"
            log "INFO" "   Run: gh auth login"
        fi
    else
        record_check "environment" "gh_auth" "warning" "gh CLI not installed"
        log "WARNING" "⚠️  GitHub CLI not installed"
    fi

    # Note about MCP API keys
    log "INFO" "ℹ️  MCP API keys (Context7, etc.) are managed in ~/.claude.json"
    log "INFO" "   No project-level .env required - MCP handles authentication"
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
# CATEGORY 4: MCP Server Connectivity (User-Level)
# ═══════════════════════════════════════════════════════════

check_mcp_connectivity() {
    log "STEP" "🔌 Checking MCP server connectivity (user-level)..."

    # Check user-level MCP config (~/.claude.json) - NOT project-level .mcp.json
    # MCP servers should be configured at user level for all projects to access
    if [ -f "$HOME/.claude.json" ]; then
        if jq -e '.mcpServers' "$HOME/.claude.json" > /dev/null 2>&1; then
            local server_count=$(jq '.mcpServers | keys | length' "$HOME/.claude.json" 2>/dev/null || echo "0")
            record_check "mcp_servers" "user_config" "passed" "$server_count servers at user level"
            log "SUCCESS" "✅ MCP config: ~/.claude.json ($server_count servers)"
        else
            record_check "mcp_servers" "user_config" "warning" "no mcpServers section"
            log "WARNING" "⚠️  ~/.claude.json exists but no mcpServers configured"
        fi
    else
        record_check "mcp_servers" "user_config" "warning" "~/.claude.json not found"
        log "WARNING" "⚠️  User-level MCP config not found (~/.claude.json)"
    fi

    # Check Claude CLI available
    if command -v claude >/dev/null 2>&1; then
        record_check "mcp_servers" "claude_cli" "passed" "Claude Code CLI available"
        log "SUCCESS" "✅ Claude Code CLI available"

        # Use claude mcp list for actual connectivity check (source of truth)
        local mcp_output=$(timeout 10s claude mcp list 2>/dev/null || echo "")
        # Count "Connected" (case-insensitive) - grep -c returns number, || 0 for safety
        local connected_count=$(echo "$mcp_output" | grep -ci "connected" || echo 0)
        # Count server entries (lines containing colon and path)
        local total_count=$(echo "$mcp_output" | grep -c ":" || echo 0)

        if [ "$connected_count" -gt 0 ] 2>/dev/null; then
            record_check "mcp_servers" "connectivity" "passed" "$connected_count servers connected"
            log "SUCCESS" "✅ MCP servers: $connected_count connected"
        elif [ -n "$mcp_output" ]; then
            record_check "mcp_servers" "connectivity" "warning" "servers configured but not connected"
            log "WARNING" "⚠️  MCP servers configured but none connected"
        else
            record_check "mcp_servers" "connectivity" "warning" "could not check (timeout or error)"
            log "WARNING" "⚠️  MCP connectivity check timed out"
        fi
    else
        record_check "mcp_servers" "claude_cli" "warning" "not installed (optional for local CI/CD)"
        log "WARNING" "⚠️  Claude Code CLI not found (optional)"
        record_check "mcp_servers" "connectivity" "warning" "cannot check (claude CLI missing)"
    fi
}

# ═══════════════════════════════════════════════════════════
# CATEGORY 4b: MCP Config Conflict Detection
# ═══════════════════════════════════════════════════════════

check_mcp_config_conflicts() {
    log "STEP" "🔍 Checking for MCP config conflicts..."

    # User-level config is the expected setup
    if [ ! -f "$HOME/.claude.json" ]; then
        log "INFO" "ℹ️  No user-level config - skipping conflict check"
        return 0
    fi

    # Check for project-level .mcp.json (potential conflict source)
    if [ -f "$REPO_DIR/.mcp.json" ]; then
        record_check "mcp_servers" "project_mcp_json" "warning" "project-level .mcp.json exists"
        log "WARNING" "⚠️  Project-level .mcp.json detected at $REPO_DIR/.mcp.json"

        # Extract server names from both configs
        local user_servers=$(jq -r '.mcpServers | keys[]' "$HOME/.claude.json" 2>/dev/null | sort)
        local project_servers=$(jq -r '.mcpServers | keys[]' "$REPO_DIR/.mcp.json" 2>/dev/null | sort)

        if [ -z "$project_servers" ]; then
            log "INFO" "   .mcp.json has no servers defined (safe to delete)"
            record_check "mcp_servers" "config_conflict" "warning" "empty project .mcp.json"
        else
            # Find conflicts (servers defined in BOTH configs)
            local conflicts=$(comm -12 <(echo "$user_servers") <(echo "$project_servers") 2>/dev/null)

            if [ -n "$conflicts" ]; then
                record_check "mcp_servers" "config_conflict" "failed" "conflicting servers detected"
                log "ERROR" "❌ MCP SERVER CONFLICT DETECTED:"
                log "ERROR" "   The following servers exist in BOTH configs:"
                echo "$conflicts" | while read -r server; do
                    [ -n "$server" ] && log "ERROR" "   • $server"
                done
                log "INFO" ""
                log "INFO" "   RESOLUTION OPTIONS:"
                log "INFO" "   1. Delete project .mcp.json: rm $REPO_DIR/.mcp.json"
                log "INFO" "   2. Rename servers in .mcp.json to avoid conflict"
                log "INFO" "   3. Remove duplicates from .mcp.json, keep only project-specific servers"
            else
                record_check "mcp_servers" "config_conflict" "warning" "no conflicts but project .mcp.json exists"
                log "WARNING" "⚠️  No naming conflicts, but project .mcp.json may cause confusion"
                log "INFO" "   Project servers: $(echo "$project_servers" | tr '\n' ', ' | sed 's/,$//')"
                log "INFO" "   Consider consolidating to ~/.claude.json for consistency"
            fi
        fi
    else
        record_check "mcp_servers" "project_mcp_json" "passed" "no project-level .mcp.json"
        record_check "mcp_servers" "config_conflict" "passed" "user-level only (correct setup)"
        log "SUCCESS" "✅ No project-level .mcp.json (clean - user-level only)"
    fi
}

# ═══════════════════════════════════════════════════════════
# CATEGORY 5: Astro Build Environment
# ═══════════════════════════════════════════════════════════

check_astro_environment() {
    log "STEP" "🌐 Checking Astro build environment..."

    # Astro website can be in website/ or astro-website/ directory
    local ASTRO_DIR=""
    if [ -f "$REPO_DIR/astro-website/package.json" ]; then
        ASTRO_DIR="$REPO_DIR/astro-website"
    elif [ -f "$REPO_DIR/website/package.json" ]; then
        ASTRO_DIR="$REPO_DIR/website"
    fi

    # Check package.json
    if [ -n "$ASTRO_DIR" ]; then
        record_check "astro_build" "package_json" "passed" "exists at ${ASTRO_DIR#$REPO_DIR/}"
        log "SUCCESS" "✅ Astro package.json exists (${ASTRO_DIR#$REPO_DIR/})"
    else
        record_check "astro_build" "package_json" "warning" "not found (optional)"
        log "WARNING" "⚠️  Astro website not found (optional component)"
        # Skip remaining Astro checks if no website directory
        return 0
    fi

    # Check node_modules installed
    if [ -d "$ASTRO_DIR/node_modules" ]; then
        record_check "astro_build" "node_modules" "passed" "dependencies installed"
        log "SUCCESS" "✅ Dependencies installed"
    else
        record_check "astro_build" "node_modules" "warning" "not installed"
        log "WARNING" "⚠️  Dependencies not installed - run: cd ${ASTRO_DIR#$REPO_DIR/} && npm install"
    fi

    # Check astro.config.mjs
    if [ -f "$ASTRO_DIR/astro.config.mjs" ]; then
        record_check "astro_build" "astro_config" "passed" "configuration exists"
        log "SUCCESS" "✅ astro.config.mjs exists"

        # Verify outDir setting
        if grep -q 'outDir.*docs' "$ASTRO_DIR/astro.config.mjs"; then
            log "SUCCESS" "✅ outDir correctly set to ../docs"
        else
            log "WARNING" "⚠️  outDir may not be set to ../docs"
        fi
    else
        record_check "astro_build" "astro_config" "warning" "not found"
        log "WARNING" "⚠️  astro.config.mjs not found"
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
# CATEGORY 6: CI/CD Policy & Runner Check (Context-Aware)
# ═══════════════════════════════════════════════════════════

check_self_hosted_runner() {
    local policy=$(detect_cicd_policy)

    log "STEP" "🏃 Checking CI/CD policy and runner status..."
    log "INFO" "   Detected policy: $policy"

    case "$policy" in
        "zero-cost")
            # Zero-cost policy: no runner = compliant, runner = optional
            if [ -d "$HOME/actions-runner" ]; then
                record_check "runner" "zero_cost_compliance" "passed" "runner exists but not required"
                log "INFO" "ℹ️  Self-hosted runner installed (optional - zero-cost policy active)"
            else
                record_check "runner" "zero_cost_compliance" "passed" "no runner needed (zero-cost policy)"
                log "SUCCESS" "✅ Zero-cost compliance: Local CI/CD only, no GitHub Actions runner required"
            fi
            ;;
        "runner-required")
            # Runner-required policy: no runner = warning, runner = check health
            if [ -d "$HOME/actions-runner" ]; then
                record_check "runner" "runner_installed" "passed" "installed at $HOME/actions-runner"
                log "SUCCESS" "✅ Self-hosted runner installed"

                # Check if systemd service configured
                local service_name="github-actions-runner-$(whoami)"
                if systemctl list-unit-files | grep -q "$service_name" 2>/dev/null; then
                    record_check "runner" "systemd_service" "passed" "service configured"
                    log "SUCCESS" "✅ Systemd service configured"

                    # Check service status
                    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
                        record_check "runner" "service_running" "passed" "service active"
                        log "SUCCESS" "✅ Runner service active"
                    else
                        record_check "runner" "service_running" "warning" "service not running"
                        log "WARNING" "⚠️  Runner service not running"
                    fi
                else
                    record_check "runner" "systemd_service" "warning" "service not configured"
                    log "WARNING" "⚠️  Systemd service not configured"
                fi
            else
                record_check "runner" "runner_required" "warning" "workflows require self-hosted runner but not installed"
                log "WARNING" "⚠️  Self-hosted runner required by workflows but not installed"
                log "INFO" "   Install with: mkdir ~/actions-runner && cd ~/actions-runner && curl -o actions-runner-linux-x64.tar.gz -L <runner-url>"
            fi
            ;;
        *)
            # Unknown policy: informational only
            record_check "runner" "policy_check" "passed" "no specific CI/CD policy detected"
            log "INFO" "ℹ️  No specific CI/CD policy detected (runner check skipped)"
            ;;
    esac
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
        gum style \
            --border double \
            --border-foreground 46 \
            --align center \
            --width 70 \
            --margin "1 0" \
            --padding "1 2" \
            "✅  ALL CHECKS PASSED - READY FOR CI/CD  ✅"
    elif [ $FAILED_CHECKS -eq 0 ]; then
        gum style \
            --border double \
            --border-foreground 214 \
            --align center \
            --width 70 \
            --margin "1 0" \
            --padding "1 2" \
            "⚠️  WARNINGS DETECTED - MOSTLY READY  ⚠️"
    else
        gum style \
            --border double \
            --border-foreground 196 \
            --align center \
            --width 70 \
            --margin "1 0" \
            --padding "1 2" \
            "❌  CRITICAL ISSUES - SETUP NEEDED  ❌"
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
    check_mcp_config_conflicts
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
