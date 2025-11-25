#!/bin/bash
# System Health Check & Validation Script (Orchestrator)
# Purpose: Comprehensive validation of ghostty-config-files installation
# Refactored: 2025-11-25 - Modularized to <300 lines (was 866 lines)
# Modules: lib/health/{disk_health,network_health,service_health,resource_health}.sh

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

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

# ============================================================================
# Source Modular Health Check Libraries
# ============================================================================

source_health_modules() {
    local lib_dir="${REPO_ROOT}/lib/health"

    for module in disk_health network_health service_health resource_health; do
        if [[ -f "${lib_dir}/${module}.sh" ]]; then
            source "${lib_dir}/${module}.sh"
        else
            echo -e "${YELLOW}WARN: Module not found: ${module}.sh${NC}" >&2
        fi
    done
}

# ============================================================================
# Logging Functions
# ============================================================================

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

log_pass() {
    echo -e "${GREEN}PASS${NC} - $1"
    SUCCESSES+=("$1")
    HEALTH_SCORE=$((HEALTH_SCORE + 1))
    MAX_SCORE=$((MAX_SCORE + 1))
}

log_fail() {
    echo -e "${RED}FAIL${NC} - $1"
    ISSUES+=("$1")
    MAX_SCORE=$((MAX_SCORE + 1))
}

log_warn() {
    echo -e "${YELLOW}WARN${NC} - $1"
    WARNINGS+=("$1")
}

# ============================================================================
# Software Installation Checks
# ============================================================================

check_software_installation() {
    log_section "[1] Software Installation Checks"

    # Ghostty
    if command -v ghostty >/dev/null 2>&1; then
        local ghostty_version
        ghostty_version=$(ghostty --version 2>&1 | grep "version:" | awk '{print $3}' || echo "unknown")
        log_pass "Ghostty installed - version: $ghostty_version"
    else
        log_fail "Ghostty not found in PATH"
    fi

    # ZSH
    if command -v zsh >/dev/null 2>&1; then
        log_pass "ZSH installed"
    else
        log_fail "ZSH not installed"
    fi

    # Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_pass "Oh My Zsh installed"
    else
        log_fail "Oh My Zsh not found"
    fi

    # Node.js
    if command -v node >/dev/null 2>&1; then
        local node_version
        node_version=$(node --version)
        local major_version
        major_version=$(echo "$node_version" | sed 's/v\([0-9]*\).*/\1/')
        if [[ "$major_version" -ge 25 ]]; then
            log_pass "Node.js v25+ installed ($node_version)"
        else
            log_warn "Node.js version is v$major_version (constitutional requires v25+)"
        fi
    else
        log_fail "Node.js not installed"
    fi

    # fnm
    if command -v fnm >/dev/null 2>&1; then
        log_pass "fnm installed"
    else
        log_fail "fnm not installed"
    fi

    # AI CLIs
    command -v claude >/dev/null 2>&1 && log_pass "Claude CLI installed" || log_warn "Claude CLI not found"
    command -v gemini >/dev/null 2>&1 && log_pass "Gemini CLI installed" || log_warn "Gemini CLI not found"

    # GitHub CLI
    if command -v gh >/dev/null 2>&1; then
        log_pass "GitHub CLI installed"
        gh auth status >/dev/null 2>&1 && log_pass "GitHub CLI authenticated" || log_warn "GitHub CLI not authenticated"
    else
        log_warn "GitHub CLI not found"
    fi
}

# ============================================================================
# Configuration Validation
# ============================================================================

check_configuration_validation() {
    log_section "[2] Configuration Validation"

    # Ghostty config
    if [[ -f "$HOME/.config/ghostty/config" ]]; then
        log_pass "Ghostty config file exists"
        if command -v ghostty >/dev/null 2>&1 && ghostty +show-config >/dev/null 2>&1; then
            log_pass "Ghostty config syntax valid"
        else
            log_warn "Cannot validate Ghostty config syntax"
        fi
    else
        log_fail "Ghostty config file not found"
    fi

    # ZSH config
    if [[ -f "$HOME/.zshrc" ]]; then
        log_pass ".zshrc exists"
        if command -v zsh >/dev/null 2>&1 && zsh -n "$HOME/.zshrc" 2>/dev/null; then
            log_pass ".zshrc syntax valid"
        fi
    else
        log_fail ".zshrc not found"
    fi
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

    local health_status="CRITICAL"
    if (( $(echo "$percentage >= 90" | bc -l) )); then
        health_status="EXCELLENT"
    elif (( $(echo "$percentage >= 75" | bc -l) )); then
        health_status="GOOD"
    elif (( $(echo "$percentage >= 60" | bc -l) )); then
        health_status="FAIR"
    fi

    echo ""
    echo -e "Score: ${GREEN}$HEALTH_SCORE${NC} / $MAX_SCORE (${percentage}%)"
    echo -e "Status: ${health_status}"
    echo -e "Successes: ${GREEN}${#SUCCESSES[@]}${NC}"
    echo -e "Failures: ${RED}${#ISSUES[@]}${NC}"
    echo -e "Warnings: ${YELLOW}${#WARNINGS[@]}${NC}"

    # Generate JSON report
    cat > "$REPORT_FILE" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
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
  }
}
EOF

    echo ""
    echo -e "${CYAN}Report saved: ${REPORT_FILE}${NC}"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    GHOSTTY CONFIG - SYSTEM HEALTH CHECK${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Repository: $REPO_ROOT"
    echo "Started: $(date)"
    echo ""

    # Source modular health check libraries
    source_health_modules

    # Run all checks
    check_software_installation
    check_configuration_validation

    # Run modular health checks if available
    if declare -f run_all_disk_checks &>/dev/null; then
        log_section "[3] Disk Health (Modular)"
        run_all_disk_checks && log_pass "Disk health OK" || log_warn "Disk health issues"
    fi

    if declare -f run_all_network_checks &>/dev/null; then
        log_section "[4] Network Health (Modular)"
        run_all_network_checks && log_pass "Network health OK" || log_warn "Network health issues"
    fi

    if declare -f run_all_service_checks &>/dev/null; then
        log_section "[5] Service Health (Modular)"
        run_all_service_checks && log_pass "Service health OK" || log_warn "Service health issues"
    fi

    if declare -f run_all_resource_checks &>/dev/null; then
        log_section "[6] Resource Health (Modular)"
        run_all_resource_checks && log_pass "Resource health OK" || log_warn "Resource health issues"
    fi

    # Generate report
    generate_health_report

    # Return appropriate exit code
    if [[ ${#ISSUES[@]} -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
