#!/bin/bash
# Health Dashboard Script
# Purpose: Display health check results in a dashboard format
# Author: Auto-generated for ghostty-config-files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     GHOSTTY CONFIG FILES HEALTH DASHBOARD     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Get latest report
LATEST_REPORT=$(ls -t "$REPO_ROOT"/system_health_report_*.json 2>/dev/null | head -1)

if [[ ! -f "$LATEST_REPORT" ]]; then
    echo -e "${RED}❌ No health reports found${NC}"
    echo "Run: ./scripts/system_health_check.sh"
    exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  jq not installed. Install with: sudo apt install jq${NC}"
    echo "Showing raw report instead:"
    echo ""
    cat "${LATEST_REPORT//.json/.txt}"
    exit 0
fi

# Parse report
TIMESTAMP=$(jq -r '.timestamp' "$LATEST_REPORT")
PERCENTAGE=$(jq -r '.health.percentage' "$LATEST_REPORT")
STATUS=$(jq -r '.health.status' "$LATEST_REPORT")
SCORE=$(jq -r '.health.score' "$LATEST_REPORT")
MAX_SCORE=$(jq -r '.health.max_score' "$LATEST_REPORT")
FAILURES=$(jq -r '.summary.failures' "$LATEST_REPORT")
WARNINGS=$(jq -r '.summary.warnings' "$LATEST_REPORT")

# Display status
echo "Last Check: $TIMESTAMP"
echo ""

# Color-coded status
case "$STATUS" in
    "EXCELLENT")
        echo -e "Status: ${GREEN}█████████${NC} $STATUS ($PERCENTAGE%)"
        ;;
    "GOOD")
        echo -e "Status: ${GREEN}███████${NC}${NC}  $STATUS ($PERCENTAGE%)"
        ;;
    "FAIR")
        echo -e "Status: ${YELLOW}█████${NC}${NC}    $STATUS ($PERCENTAGE%)"
        ;;
    "POOR")
        echo -e "Status: ${RED}███${NC}${NC}      $STATUS ($PERCENTAGE%)"
        ;;
    *)
        echo -e "Status: ${RED}█${NC}${NC}        $STATUS ($PERCENTAGE%)"
        ;;
esac

echo "Score: $SCORE / $MAX_SCORE"
echo ""

# Show issues if any
if [[ "$FAILURES" -gt 0 ]]; then
    echo -e "${RED}❌ Issues Found: $FAILURES${NC}"
    echo ""
    jq -r '.issues[]' "$LATEST_REPORT" | nl -w2 -s'. ' | sed 's/^/  /'
    echo ""
fi

# Show warnings if any
if [[ "$WARNINGS" -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
    echo ""
    jq -r '.warnings[]' "$LATEST_REPORT" | nl -w2 -s'. ' | sed 's/^/  /'
    echo ""
fi

# Software versions
echo -e "${CYAN}Software Versions:${NC}"
echo "━━━━━━━━━━━━━━━━━━"
jq -r '.software_versions | to_entries[] | "  \(.key | ascii_upcase): \(.value)"' "$LATEST_REPORT" | column -t
echo ""

# Performance metrics
echo -e "${CYAN}Performance Metrics:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━"
jq -r '.performance_metrics | to_entries[] | "  \(.key): \(.value)"' "$LATEST_REPORT"
echo ""

# Trend (if multiple reports exist)
REPORT_COUNT=$(ls -1 "$REPO_ROOT"/system_health_report_*.json 2>/dev/null | wc -l)
if [[ "$REPORT_COUNT" -gt 1 ]]; then
    echo -e "${CYAN}Health Trend (Last 5 Checks):${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for report in $(ls -t "$REPO_ROOT"/system_health_report_*.json | head -5); do
        local_time=$(jq -r '.timestamp' "$report" | cut -d'T' -f1,2 | tr 'T' ' ')
        local_pct=$(jq -r '.health.percentage' "$report")
        local_status=$(jq -r '.health.status' "$report")

        # Color code based on status
        case "$local_status" in
            "EXCELLENT")
                echo -e "  ${GREEN}●${NC} $local_time: $local_pct% ($local_status)"
                ;;
            "GOOD")
                echo -e "  ${GREEN}●${NC} $local_time: $local_pct% ($local_status)"
                ;;
            "FAIR")
                echo -e "  ${YELLOW}●${NC} $local_time: $local_pct% ($local_status)"
                ;;
            *)
                echo -e "  ${RED}●${NC} $local_time: $local_pct% ($local_status)"
                ;;
        esac
    done
    echo ""
fi

# Quick actions
echo -e "${CYAN}Quick Actions:${NC}"
echo "━━━━━━━━━━━━━━"
echo "  📊 View full text report: cat ${LATEST_REPORT//.json/.txt}"
echo "  📄 View JSON report:      cat $LATEST_REPORT"
echo "  🔄 Run new health check:  ./scripts/system_health_check.sh"
if [[ "$FAILURES" -gt 0 ]]; then
    echo "  🔧 Fix issues:            ./scripts/fix_constitutional_violations.sh"
fi
echo ""
