#!/bin/bash
# System Health Check & Validation Script
# Purpose: Comprehensive validation of ghostty-config-files installation
# Author: Auto-generated for ghostty-config-files
# Last Modified: 2025-11-13

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Health tracking
HEALTH_SCORE=0
MAX_SCORE=0
ISSUES=()
WARNINGS=()
SUCCESSES=()

# Report file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${REPO_ROOT}/system_health_report_${TIMESTAMP}.json"
REPORT_TEXT="${REPO_ROOT}/system_health_report_${TIMESTAMP}.txt"

# Performance tracking
declare -A PERF_METRICS

# ============================================================================
# Logging Functions
# ============================================================================

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

log_subsection() {
    echo ""
    echo -e "${CYAN}--- $1 ---${NC}"
}

log_pass() {
    echo -e "${GREEN}✅ PASS${NC} - $1"
    SUCCESSES+=("$1")
}

log_fail() {
    echo -e "${RED}❌ FAIL${NC} - $1"
    ISSUES+=("$1")
}

log_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC} - $1"
    WARNINGS+=("$1")
}

log_info() {
    echo -e "${CYAN}ℹ️  INFO${NC} - $1"
}

log_metric() {
    local name="$1"
    local value="$2"
    PERF_METRICS["$name"]="$value"
    echo -e "${MAGENTA}📊 METRIC${NC} - $name: ${value}"
}

# ============================================================================
# Check Functions
# ============================================================================

# Generic check function
check_feature() {
    local name="$1"
    local check_command="$2"
    local expected="$3"

    MAX_SCORE=$((MAX_SCORE + 1))

    echo -n "Checking $name... "
    if eval "$check_command" >/dev/null 2>&1; then
        log_pass "$name: $expected"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))
        return 0
    else
        log_fail "$name: Expected $expected"
        return 1
    fi
}

# ============================================================================
# Section 1: Software Installation Checks
# ============================================================================

check_software_installation() {
    log_section "[1] Software Installation Checks"

    # Ghostty
    log_subsection "Ghostty Terminal"
    if command -v ghostty >/dev/null 2>&1; then
        local ghostty_version=$(ghostty --version 2>&1 | grep "version:" | awk '{print $3}' || echo "unknown")
        log_pass "Ghostty installed - version: $ghostty_version"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))

        # Check installation method
        local ghostty_path=$(command -v ghostty)
        if [[ "$ghostty_path" == *"/snap/"* ]]; then
            log_info "Ghostty installed via snap: $ghostty_path"
        elif [[ "$ghostty_path" == *"/usr/local/"* ]] || [[ "$ghostty_path" == *"/usr/bin/"* ]]; then
            log_info "Ghostty installed from source: $ghostty_path"
        fi
    else
        log_fail "Ghostty not found in PATH"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    # ZSH
    log_subsection "ZSH Shell"
    check_feature "ZSH" "command -v zsh" "zsh in PATH"
    if command -v zsh >/dev/null 2>&1; then
        local zsh_version=$(zsh --version | awk '{print $2}')
        log_info "ZSH version: $zsh_version"
    fi

    # Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_pass "Oh My Zsh installed"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))

        # Check plugins
        if [[ -f "$HOME/.zshrc" ]]; then
            local plugins=$(grep "^plugins=" "$HOME/.zshrc" | sed 's/plugins=(\(.*\))/\1/' || echo "")
            log_info "Oh My Zsh plugins: $plugins"
        fi
    else
        log_fail "Oh My Zsh not found"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    # Node.js
    log_subsection "Node.js & fnm"
    check_feature "Node.js" "command -v node" "node in PATH"
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version)
        log_info "Node.js version: $node_version"

        # Check if it's v25+
        local major_version=$(echo "$node_version" | sed 's/v\([0-9]*\).*/\1/')
        if [[ "$major_version" -ge 25 ]]; then
            log_pass "Node.js version is v25+ (constitutional compliance)"
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            log_warn "Node.js version is v$major_version (constitutional requires v25+)"
        fi
        MAX_SCORE=$((MAX_SCORE + 1))
    fi

    check_feature "fnm" "command -v fnm" "fnm in PATH"
    if command -v fnm >/dev/null 2>&1; then
        local fnm_version=$(fnm --version | awk '{print $2}')
        log_info "fnm version: $fnm_version"
    fi

    # npm
    check_feature "npm" "command -v npm" "npm in PATH"
    if command -v npm >/dev/null 2>&1; then
        local npm_version=$(npm --version)
        log_info "npm version: $npm_version"
    fi

    # AI CLIs
    log_subsection "AI Assistant CLIs"

    check_feature "Claude CLI" "command -v claude" "claude in PATH"
    if command -v claude >/dev/null 2>&1; then
        local claude_version=$(claude --version 2>&1 || echo "unknown")
        log_info "Claude CLI version: $claude_version"
    fi

    if command -v gemini >/dev/null 2>&1 || command -v gemini-cli >/dev/null 2>&1; then
        log_pass "Gemini CLI installed"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))
        local gemini_cmd=$(command -v gemini || command -v gemini-cli)
        log_info "Gemini CLI location: $gemini_cmd"
    else
        log_fail "Gemini CLI not found"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    if npm list -g @github/copilot >/dev/null 2>&1; then
        log_pass "GitHub Copilot CLI installed"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))
    else
        log_warn "GitHub Copilot CLI not found (optional)"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    # Python tools
    log_subsection "Python Tools"

    check_feature "uv" "command -v uv" "uv in PATH"
    if command -v uv >/dev/null 2>&1; then
        local uv_version=$(uv --version | awk '{print $2}')
        log_info "uv version: $uv_version"
    fi

    if command -v specify >/dev/null 2>&1; then
        log_pass "spec-kit installed"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))
        local speckit_version=$(specify --version 2>/dev/null | awk '{print $NF}' || echo "unknown")
        log_info "spec-kit version: $speckit_version"
    else
        log_warn "spec-kit not found (optional)"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    # GitHub CLI
    log_subsection "GitHub Tools"
    check_feature "GitHub CLI" "command -v gh" "gh in PATH"
    if command -v gh >/dev/null 2>&1; then
        local gh_version=$(gh --version | head -1 | awk '{print $3}')
        log_info "GitHub CLI version: $gh_version"

        # Check auth status
        if gh auth status >/dev/null 2>&1; then
            log_pass "GitHub CLI authenticated"
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            log_warn "GitHub CLI not authenticated"
        fi
        MAX_SCORE=$((MAX_SCORE + 1))
    fi
}

# ============================================================================
# Section 2: Constitutional Compliance Checks
# ============================================================================

check_constitutional_compliance() {
    log_section "[2] Constitutional Compliance Checks"

    # Node.js version check
    log_subsection "Node.js Version Requirements"
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version)
        local major_version=$(echo "$node_version" | sed 's/v\([0-9]*\).*/\1/')

        if [[ "$major_version" -ge 25 ]]; then
            log_pass "Node.js is v25+ ($node_version) - compliant"
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            log_fail "Node.js is v$major_version ($node_version) - should be v25+"
        fi
    else
        log_fail "Node.js not installed"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    # Check .node-version file
    log_subsection "Configuration Files"
    if [[ -f "$REPO_ROOT/.node-version" ]]; then
        local node_version_content=$(cat "$REPO_ROOT/.node-version")
        if [[ "$node_version_content" == "25" ]]; then
            log_pass ".node-version contains '25'"
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            log_fail ".node-version contains '$node_version_content', expected '25'"
        fi
    else
        log_fail ".node-version file not found"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    # Check start.sh NODE_VERSION
    if [[ -f "$REPO_ROOT/start.sh" ]]; then
        if grep -q 'NODE_VERSION="lts/latest"' "$REPO_ROOT/start.sh"; then
            log_warn "start.sh uses NODE_VERSION=\"lts/latest\" (constitutional prefers \"25\")"
        elif grep -q 'NODE_VERSION="25"' "$REPO_ROOT/start.sh"; then
            log_pass "start.sh uses NODE_VERSION=\"25\""
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            local current_value=$(grep 'NODE_VERSION=' "$REPO_ROOT/start.sh" | head -1 || echo "not found")
            log_warn "start.sh NODE_VERSION: $current_value"
        fi
    else
        log_fail "start.sh not found"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    # Check install_node.sh
    if [[ -f "$SCRIPT_DIR/install_node.sh" ]]; then
        if grep -q 'NODE_VERSION:=lts/latest' "$SCRIPT_DIR/install_node.sh"; then
            log_warn "install_node.sh uses :=lts/latest (constitutional prefers :=25)"
        elif grep -q 'NODE_VERSION:=25' "$SCRIPT_DIR/install_node.sh"; then
            log_pass "install_node.sh uses :=25"
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            local current_value=$(grep 'NODE_VERSION:=' "$SCRIPT_DIR/install_node.sh" | head -1 || echo "not found")
            log_info "install_node.sh: $current_value"
        fi
    else
        log_fail "install_node.sh not found"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    # Check daily-updates.sh for --latest flag
    log_subsection "Update Scripts"
    if [[ -f "$SCRIPT_DIR/daily-updates.sh" ]]; then
        if grep -q 'fnm install --lts' "$SCRIPT_DIR/daily-updates.sh"; then
            log_warn "daily-updates.sh uses --lts (constitutional prefers --latest)"
        elif grep -q 'fnm install --latest' "$SCRIPT_DIR/daily-updates.sh"; then
            log_pass "daily-updates.sh uses --latest flag"
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            log_info "daily-updates.sh fnm install command not using --latest or --lts"
        fi
    else
        log_fail "daily-updates.sh not found"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    # Check fnm shell integration
    log_subsection "fnm Integration"
    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -q "fnm env" "$HOME/.zshrc"; then
            log_pass "fnm shell integration configured in .zshrc"
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            log_fail "fnm shell integration not found in .zshrc"
        fi
    else
        log_warn ".zshrc not found"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))
}

# ============================================================================
# Section 3: Configuration Validation
# ============================================================================

check_configuration_validation() {
    log_section "[3] Configuration Validation"

    # Ghostty config
    log_subsection "Ghostty Configuration"
    if [[ -f "$HOME/.config/ghostty/config" ]]; then
        log_pass "Ghostty config file exists"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))

        # Validate config syntax
        if command -v ghostty >/dev/null 2>&1; then
            if ghostty +show-config >/dev/null 2>&1; then
                log_pass "Ghostty config syntax valid"
                HEALTH_SCORE=$((HEALTH_SCORE + 1))
            else
                log_fail "Ghostty config has syntax errors"
            fi
            MAX_SCORE=$((MAX_SCORE + 1))

            # Check for 2025 performance optimizations
            if grep -q "linux-cgroup = single-instance" "$HOME/.config/ghostty/config" 2>/dev/null; then
                log_pass "CGroup single-instance optimization enabled"
                HEALTH_SCORE=$((HEALTH_SCORE + 1))
            else
                log_warn "CGroup single-instance optimization not found"
            fi
            MAX_SCORE=$((MAX_SCORE + 1))
        fi
    else
        log_fail "Ghostty config file not found"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    # ZSH config
    log_subsection "Shell Configuration"
    if [[ -f "$HOME/.zshrc" ]]; then
        log_pass ".zshrc exists"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))

        # Validate syntax
        if command -v zsh >/dev/null 2>&1; then
            if zsh -n "$HOME/.zshrc" 2>/dev/null; then
                log_pass ".zshrc syntax valid"
                HEALTH_SCORE=$((HEALTH_SCORE + 1))
            else
                log_fail ".zshrc has syntax errors"
            fi
            MAX_SCORE=$((MAX_SCORE + 1))
        fi

        # Check for BSD stat (should not be on Linux)
        if uname -s | grep -q "Linux"; then
            if grep -q "stat -f" "$HOME/.zshrc" 2>/dev/null; then
                log_fail "BSD stat command found in .zshrc (Linux incompatible)"
            else
                log_pass "No BSD stat commands in .zshrc"
                HEALTH_SCORE=$((HEALTH_SCORE + 1))
            fi
            MAX_SCORE=$((MAX_SCORE + 1))
        fi

        # Check for duplicate Gemini CLI blocks
        local gemini_blocks=$(grep -c "Gemini CLI" "$HOME/.zshrc" 2>/dev/null || echo "0")
        if [[ "$gemini_blocks" -le 1 ]]; then
            log_pass "No duplicate Gemini CLI blocks in .zshrc"
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            log_fail "Duplicate Gemini CLI blocks found ($gemini_blocks instances)"
        fi
        MAX_SCORE=$((MAX_SCORE + 1))
    else
        log_fail ".zshrc not found"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))
}

# ============================================================================
# Section 4: File Integrity Checks
# ============================================================================

check_file_integrity() {
    log_section "[4] File Integrity Checks"

    # Critical scripts
    log_subsection "Critical Scripts"
    local critical_scripts=(
        "start.sh"
        "scripts/install_node.sh"
        "scripts/install_ghostty_config.sh"
        "scripts/check_updates.sh"
        "scripts/daily-updates.sh"
    )

    for script in "${critical_scripts[@]}"; do
        local script_path="$REPO_ROOT/$script"
        if [[ -f "$script_path" ]]; then
            if [[ -x "$script_path" ]]; then
                log_pass "$script exists and is executable"
                HEALTH_SCORE=$((HEALTH_SCORE + 1))
            else
                log_warn "$script exists but not executable"
            fi
        else
            log_fail "$script not found"
        fi
        MAX_SCORE=$((MAX_SCORE + 1))
    done

    # Configuration files
    log_subsection "Configuration Files"
    local config_files=(
        "$HOME/.config/ghostty/config"
        "$HOME/.zshrc"
        "$REPO_ROOT/.node-version"
        "$REPO_ROOT/CLAUDE.md"
    )

    for config in "${config_files[@]}"; do
        if [[ -f "$config" ]]; then
            log_pass "$(basename "$config") exists"
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            log_fail "$(basename "$config") not found"
        fi
        MAX_SCORE=$((MAX_SCORE + 1))
    done

    # Backup directories
    log_subsection "Backup & Log Directories"
    local directories=(
        "$HOME/.config/ghostty"
        "/tmp/ghostty-start-logs"
        "/tmp/daily-updates-logs"
    )

    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            if [[ -w "$dir" ]]; then
                log_pass "$(basename "$dir") exists and is writable"
                HEALTH_SCORE=$((HEALTH_SCORE + 1))
            else
                log_warn "$(basename "$dir") exists but not writable"
            fi
        else
            log_info "$(basename "$dir") does not exist (may be created on demand)"
        fi
        MAX_SCORE=$((MAX_SCORE + 1))
    done

    # Check for broken symlinks
    log_subsection "Symlink Integrity"
    local broken_symlinks=$(find "$REPO_ROOT" -maxdepth 2 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
    if [[ "$broken_symlinks" -eq 0 ]]; then
        log_pass "No broken symlinks found"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))
    else
        log_fail "$broken_symlinks broken symlink(s) found"
        find "$REPO_ROOT" -maxdepth 2 -type l ! -exec test -e {} \; -print 2>/dev/null | while read -r link; do
            log_info "Broken symlink: $link"
        done
    fi
    MAX_SCORE=$((MAX_SCORE + 1))
}

# ============================================================================
# Section 5: Performance Metrics
# ============================================================================

check_performance_metrics() {
    log_section "[5] Performance Metrics"

    # Shell startup time
    log_subsection "Shell Startup Performance"
    if command -v zsh >/dev/null 2>&1; then
        local start_time=$(date +%s%N)
        zsh -i -c exit 2>/dev/null
        local end_time=$(date +%s%N)
        local startup_ms=$(( (end_time - start_time) / 1000000 ))

        log_metric "ZSH startup time" "${startup_ms}ms"

        if [[ "$startup_ms" -lt 500 ]]; then
            log_pass "Shell startup time under 500ms ($startup_ms ms)"
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            log_warn "Shell startup time over 500ms ($startup_ms ms)"
        fi
        MAX_SCORE=$((MAX_SCORE + 1))
    fi

    # Node.js execution time
    log_subsection "Node.js Performance"
    if command -v node >/dev/null 2>&1; then
        local start_time=$(date +%s%N)
        node -e "console.log('test')" >/dev/null 2>&1
        local end_time=$(date +%s%N)
        local node_exec_ms=$(( (end_time - start_time) / 1000000 ))

        log_metric "Node.js execution time" "${node_exec_ms}ms"

        if [[ "$node_exec_ms" -lt 100 ]]; then
            log_pass "Node.js execution under 100ms ($node_exec_ms ms)"
            HEALTH_SCORE=$((HEALTH_SCORE + 1))
        else
            log_warn "Node.js execution over 100ms ($node_exec_ms ms)"
        fi
        MAX_SCORE=$((MAX_SCORE + 1))
    fi

    # fnm version switch time (if multiple versions installed)
    log_subsection "fnm Performance"
    if command -v fnm >/dev/null 2>&1; then
        local versions_count=$(fnm list 2>/dev/null | grep -c "v[0-9]" || echo "0")
        log_metric "fnm installed versions" "$versions_count"

        if [[ "$versions_count" -gt 0 ]]; then
            local start_time=$(date +%s%N)
            eval "$(fnm env --use-on-cd --version-file-strategy=recursive)" >/dev/null 2>&1
            local end_time=$(date +%s%N)
            local fnm_init_ms=$(( (end_time - start_time) / 1000000 ))

            log_metric "fnm initialization time" "${fnm_init_ms}ms"

            if [[ "$fnm_init_ms" -lt 50 ]]; then
                log_pass "fnm initialization under 50ms ($fnm_init_ms ms) - constitutional target met"
                HEALTH_SCORE=$((HEALTH_SCORE + 1))
            else
                log_warn "fnm initialization over 50ms ($fnm_init_ms ms)"
            fi
            MAX_SCORE=$((MAX_SCORE + 1))
        fi
    fi
}

# ============================================================================
# Section 6: Idempotency Testing
# ============================================================================

check_idempotency() {
    log_section "[6] Idempotency Tests"

    log_info "Testing installation script idempotency..."
    log_warn "Actual idempotency tests require running installation scripts"
    log_info "Skipping to avoid system modification during health check"
    log_info "Manual test: Run 'scripts/install_node.sh' twice and verify second run skips"

    # We can check if state tracking files exist
    log_subsection "State Tracking"

    # Check for npm cache
    if [[ -d "$HOME/.npm" ]]; then
        log_pass "npm cache directory exists"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))
    else
        log_info "npm cache directory not found (may not have run npm yet)"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))

    # Check for fnm data
    if [[ -d "$HOME/.local/share/fnm" ]]; then
        log_pass "fnm data directory exists"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))

        local fnm_versions=$(ls -1 "$HOME/.local/share/fnm/node-versions" 2>/dev/null | wc -l)
        log_info "fnm has $fnm_versions Node.js version(s) installed"
    else
        log_info "fnm data directory not found"
    fi
    MAX_SCORE=$((MAX_SCORE + 1))
}

# ============================================================================
# Report Generation
# ============================================================================

generate_health_report() {
    log_section "Health Report Summary"

    local percentage=0
    if [[ $MAX_SCORE -gt 0 ]]; then
        percentage=$(echo "scale=2; $HEALTH_SCORE * 100 / $MAX_SCORE" | bc)
    fi

    # Determine health status
    local health_status="CRITICAL"
    local status_color="$RED"
    if (( $(echo "$percentage >= 90" | bc -l) )); then
        health_status="EXCELLENT"
        status_color="$GREEN"
    elif (( $(echo "$percentage >= 75" | bc -l) )); then
        health_status="GOOD"
        status_color="$GREEN"
    elif (( $(echo "$percentage >= 60" | bc -l) )); then
        health_status="FAIR"
        status_color="$YELLOW"
    elif (( $(echo "$percentage >= 40" | bc -l) )); then
        health_status="POOR"
        status_color="$RED"
    fi

    # Text report
    cat > "$REPORT_TEXT" <<EOF
========================================================================
SYSTEM HEALTH REPORT
========================================================================
Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
System: $(uname -s) $(uname -r)
Hostname: $(hostname)

OVERALL HEALTH: ${health_status} (${percentage}%)
Score: ${HEALTH_SCORE} / ${MAX_SCORE}

========================================================================
SUMMARY
========================================================================

✅ Successes: ${#SUCCESSES[@]}
❌ Failures: ${#ISSUES[@]}
⚠️  Warnings: ${#WARNINGS[@]}

========================================================================
ISSUES FOUND (${#ISSUES[@]})
========================================================================
EOF

    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        printf '%s\n' "${ISSUES[@]}" | nl -w2 -s'. ' >> "$REPORT_TEXT"
    else
        echo "No critical issues found!" >> "$REPORT_TEXT"
    fi

    cat >> "$REPORT_TEXT" <<EOF

========================================================================
WARNINGS (${#WARNINGS[@]})
========================================================================
EOF

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        printf '%s\n' "${WARNINGS[@]}" | nl -w2 -s'. ' >> "$REPORT_TEXT"
    else
        echo "No warnings!" >> "$REPORT_TEXT"
    fi

    cat >> "$REPORT_TEXT" <<EOF

========================================================================
PERFORMANCE METRICS
========================================================================
EOF

    for metric in "${!PERF_METRICS[@]}"; do
        echo "  $metric: ${PERF_METRICS[$metric]}" >> "$REPORT_TEXT"
    done

    cat >> "$REPORT_TEXT" <<EOF

========================================================================
RECOMMENDATIONS
========================================================================
EOF

    # Generate recommendations based on issues
    if (( $(echo "$percentage < 100" | bc -l) )); then
        cat >> "$REPORT_TEXT" <<EOF

1. Review failed checks above and address critical issues
2. Run './scripts/fix_constitutional_violations.sh' to fix compliance issues
3. Re-run health check after fixes: './scripts/system_health_check.sh'
EOF

        if [[ ${#ISSUES[@]} -gt 0 ]]; then
            for issue in "${ISSUES[@]}"; do
                if [[ "$issue" =~ "Node.js" ]]; then
                    echo "4. Install/update Node.js: Run './scripts/install_node.sh 25'" >> "$REPORT_TEXT"
                    break
                fi
            done
        fi
    else
        echo "System is in excellent health! No recommendations at this time." >> "$REPORT_TEXT"
    fi

    cat >> "$REPORT_TEXT" <<EOF

========================================================================
REPORT FILES
========================================================================
Text Report: $REPORT_TEXT
JSON Report: $REPORT_FILE

========================================================================
EOF

    # JSON report
    cat > "$REPORT_FILE" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "system": {
    "os": "$(uname -s)",
    "kernel": "$(uname -r)",
    "hostname": "$(hostname)"
  },
  "health": {
    "score": $HEALTH_SCORE,
    "max_score": $MAX_SCORE,
    "percentage": $percentage,
    "status": "$health_status"
  },
  "summary": {
    "successes": ${#SUCCESSES[@]},
    "failures": ${#ISSUES[@]},
    "warnings": ${#WARNINGS[@]}
  },
  "issues": $(printf '%s\n' "${ISSUES[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "warnings": $(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "performance_metrics": {
$(for metric in "${!PERF_METRICS[@]}"; do
    echo "    \"$metric\": \"${PERF_METRICS[$metric]}\","
done | sed '$ s/,$//')
  },
  "software_versions": {
    "ghostty": "$(ghostty --version 2>&1 | grep -E 'version.*:' | head -1 | awk '{print $3}' | tr -d '\n' || echo 'not installed')",
    "node": "$(node --version 2>/dev/null || echo 'not installed')",
    "fnm": "$(fnm --version 2>/dev/null | awk '{print $2}' || echo 'not installed')",
    "npm": "$(npm --version 2>/dev/null || echo 'not installed')",
    "zsh": "$(zsh --version 2>/dev/null | awk '{print $2}' || echo 'not installed')",
    "gh": "$(gh --version 2>/dev/null | head -1 | awk '{print $3}' || echo 'not installed')",
    "claude": "$(claude --version 2>&1 || echo 'not installed')",
    "uv": "$(uv --version 2>/dev/null | awk '{print $2}' || echo 'not installed')"
  }
}
EOF

    # Display summary
    echo ""
    echo -e "${status_color}========================================================================${NC}"
    echo -e "${status_color}OVERALL HEALTH: ${health_status}${NC}"
    echo -e "${status_color}========================================================================${NC}"
    echo -e "Score: ${GREEN}$HEALTH_SCORE${NC} / $MAX_SCORE (${percentage}%)"
    echo ""
    echo -e "✅ Successes: ${GREEN}${#SUCCESSES[@]}${NC}"
    echo -e "❌ Failures:  ${RED}${#ISSUES[@]}${NC}"
    echo -e "⚠️  Warnings:  ${YELLOW}${#WARNINGS[@]}${NC}"
    echo ""
    echo -e "${CYAN}Report saved:${NC}"
    echo -e "  📄 Text: ${REPORT_TEXT}"
    echo -e "  📊 JSON: ${REPORT_FILE}"
    echo ""

    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        echo -e "${RED}Critical issues found:${NC}"
        printf '  %s\n' "${ISSUES[@]}" | head -5
        if [[ ${#ISSUES[@]} -gt 5 ]]; then
            echo "  ... and $((${#ISSUES[@]} - 5)) more (see report file)"
        fi
        echo ""
    fi

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Warnings:${NC}"
        printf '  %s\n' "${WARNINGS[@]}" | head -3
        if [[ ${#WARNINGS[@]} -gt 3 ]]; then
            echo "  ... and $((${#WARNINGS[@]} - 3)) more (see report file)"
        fi
        echo ""
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo -e "${BLUE}========================================================================${NC}"
    echo -e "${BLUE}          GHOSTTY CONFIG FILES - SYSTEM HEALTH CHECK${NC}"
    echo -e "${BLUE}========================================================================${NC}"
    echo ""
    echo "Repository: $REPO_ROOT"
    echo "Started: $(date)"
    echo ""

    # Run all checks
    check_software_installation
    check_constitutional_compliance
    check_configuration_validation
    check_file_integrity
    check_performance_metrics
    check_idempotency

    # Generate report
    generate_health_report

    # Return appropriate exit code
    local percentage=0
    if [[ $MAX_SCORE -gt 0 ]]; then
        percentage=$(echo "scale=0; $HEALTH_SCORE * 100 / $MAX_SCORE" | bc)
    fi

    if [[ $percentage -ge 90 ]]; then
        exit 0  # Perfect or near-perfect health
    elif [[ $percentage -ge 75 ]]; then
        exit 0  # Good health
    elif [[ $percentage -ge 60 ]]; then
        exit 1  # Fair health - issues found
    else
        exit 1  # Poor health - critical issues
    fi
}

# Run main function
main "$@"
