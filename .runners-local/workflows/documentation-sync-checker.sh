#!/bin/bash

# Documentation Synchronization Checker
# Validates consistency across the three-tier documentation system
# Priority 4 Enhancement from Context7 MCP Assessment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
LOG_DIR="$SCRIPT_DIR/../logs"

# Temp file cleanup tracking
TEMP_FILES=()

cleanup_temp_files() {
    for temp_file in "${TEMP_FILES[@]}"; do
        [ -f "$temp_file" ] && rm -f "$temp_file" 2>/dev/null || true
    done
}
trap cleanup_temp_files EXIT ERR INT TERM

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
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/doc-sync-$(date +%Y%m%d).log"
}

# Initialize sync check report
init_report() {
    REPORT_FILE="$LOG_DIR/doc-sync-report-$(date +%Y%m%d-%H%M%S).json"
    cat > "$REPORT_FILE" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "checks": [],
  "summary": {
    "total": 0,
    "passed": 0,
    "failed": 0,
    "warnings": 0
  }
}
EOF
}

# Add check result to report
add_check_result() {
    local check_name="$1"
    local status="$2"  # pass, fail, warning
    local message="$3"

    # Create temporary JSON entry
    local temp_entry=$(mktemp)
    TEMP_FILES+=("$temp_entry")
    cat > "$temp_entry" <<EOF
{
  "name": "$check_name",
  "status": "$status",
  "message": "$message",
  "timestamp": "$(date -Iseconds)"
}
EOF

    # Append to report (basic JSON array manipulation)
    local temp_report=$(mktemp)
    TEMP_FILES+=("$temp_report")
    if command -v jq >/dev/null 2>&1; then
        jq --argjson entry "$(cat "$temp_entry")" '.checks += [$entry]' "$REPORT_FILE" > "$temp_report"
        mv "$temp_report" "$REPORT_FILE"
    fi
}

# Update summary counts
update_summary() {
    if command -v jq >/dev/null 2>&1; then
        local temp_report=$(mktemp)
        TEMP_FILES+=("$temp_report")
        jq '.summary.total = (.checks | length) |
            .summary.passed = ([.checks[] | select(.status == "pass")] | length) |
            .summary.failed = ([.checks[] | select(.status == "fail")] | length) |
            .summary.warnings = ([.checks[] | select(.status == "warning")] | length)' \
            "$REPORT_FILE" > "$temp_report"
        mv "$temp_report" "$REPORT_FILE"
    fi
}

# Check 1: Verify Tier 1 (docs/) is Astro build output
check_tier1_build_output() {
    log "STEP" "📁 Checking Tier 1 (docs/) build output..."

    local status="pass"
    local message="Tier 1 build output structure is valid"

    # Check critical files
    if [ ! -f "$REPO_DIR/docs/.nojekyll" ]; then
        status="fail"
        message="CRITICAL: docs/.nojekyll missing - GitHub Pages assets will fail"
        log "ERROR" "❌ $message"
    elif [ ! -f "$REPO_DIR/docs/index.html" ]; then
        status="fail"
        message="docs/index.html missing - no Astro build output"
        log "ERROR" "❌ $message"
    elif [ ! -d "$REPO_DIR/docs/_astro" ]; then
        status="warning"
        message="docs/_astro/ directory missing - assets may not be generated"
        log "WARNING" "⚠️ $message"
    else
        log "SUCCESS" "✅ Tier 1 build output structure is valid"
    fi

    add_check_result "tier1_build_output" "$status" "$message"
}

# Check 2: Verify Tier 2 (website/src/) source files exist
check_tier2_source_structure() {
    log "STEP" "📝 Checking Tier 2 (website/src/) source structure..."

    local status="pass"
    local message="Tier 2 source structure is valid"

    # Check critical source directories
    if [ ! -d "$REPO_DIR/website/src/src/pages" ]; then
        status="fail"
        message="website/src/src/pages/ missing - no Astro source content"
        log "ERROR" "❌ $message"
    elif [ ! -f "$REPO_DIR/website/src/astro.config.mjs" ]; then
        status="fail"
        message="website/src/astro.config.mjs missing - no Astro configuration"
        log "ERROR" "❌ $message"
    elif [ ! -f "$REPO_DIR/website/src/public/.nojekyll" ]; then
        status="warning"
        message="website/src/public/.nojekyll missing - primary protection layer missing"
        log "WARNING" "⚠️ $message"
    else
        log "SUCCESS" "✅ Tier 2 source structure is valid"
    fi

    add_check_result "tier2_source_structure" "$status" "$message"
}

# Check 3: Verify Tier 3 (documentations/) structure
check_tier3_documentation_hub() {
    log "STEP" "📚 Checking Tier 3 (documentations/) structure..."

    local status="pass"
    local message="Tier 3 documentation hub structure is valid"

    # Check expected directories
    local missing_dirs=()
    for dir in user developer specifications archive; do
        if [ ! -d "$REPO_DIR/documentations/$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done

    if [ ${#missing_dirs[@]} -gt 0 ]; then
        status="warning"
        message="documentations/ missing subdirectories: ${missing_dirs[*]}"
        log "WARNING" "⚠️ $message"
    else
        log "SUCCESS" "✅ Tier 3 documentation hub structure is valid"
    fi

    add_check_result "tier3_documentation_hub" "$status" "$message"
}

# Check 4: Verify Astro outDir configuration matches deployment
check_astro_outdir_config() {
    log "STEP" "⚙️ Checking Astro outDir configuration..."

    local status="pass"
    local message="Astro outDir correctly configured"

    # Check astro.config.mjs (use both possible locations)
    local astro_config=""
    if [ -f "$REPO_DIR/astro.config.mjs" ]; then
        astro_config="$REPO_DIR/astro.config.mjs"
    elif [ -f "$REPO_DIR/website/src/astro.config.mjs" ]; then
        astro_config="$REPO_DIR/website/src/astro.config.mjs"
    fi

    if [ -z "$astro_config" ]; then
        status="fail"
        message="astro.config.mjs not found in root or website/src/"
        log "ERROR" "❌ $message"
    else
        # Check outDir setting
        if grep -q "outDir:.*'\.\/docs'" "$astro_config"; then
            log "SUCCESS" "✅ Astro outDir correctly set to './docs'"
        elif grep -q "outDir:.*\"\.\/docs\"" "$astro_config"; then
            log "SUCCESS" "✅ Astro outDir correctly set to \"./docs\""
        elif grep -q "outDir:.*'\.\/docs-dist'" "$astro_config" || grep -q "outDir:.*\"\.\/docs-dist\"" "$astro_config"; then
            status="fail"
            message="Astro outDir incorrectly set to './docs-dist' - should be './docs'"
            log "ERROR" "❌ $message"
        else
            status="warning"
            message="Could not verify Astro outDir configuration"
            log "WARNING" "⚠️ $message"
        fi
    fi

    add_check_result "astro_outdir_config" "$status" "$message"
}

# Check 5: Verify AGENTS.md symlinks
check_agents_symlinks() {
    log "STEP" "🔗 Checking AGENTS.md symlinks..."

    local status="pass"
    local message="AGENTS.md symlinks are correct"

    # Check CLAUDE.md symlink
    if [ -L "$REPO_DIR/CLAUDE.md" ]; then
        local claude_target=$(readlink "$REPO_DIR/CLAUDE.md")
        if [ "$claude_target" != "AGENTS.md" ]; then
            status="warning"
            message="CLAUDE.md symlink points to $claude_target instead of AGENTS.md"
            log "WARNING" "⚠️ $message"
        else
            log "SUCCESS" "✅ CLAUDE.md symlink is correct"
        fi
    else
        status="fail"
        message="CLAUDE.md is not a symlink to AGENTS.md"
        log "ERROR" "❌ $message"
    fi

    # Check GEMINI.md symlink
    if [ -L "$REPO_DIR/GEMINI.md" ]; then
        local gemini_target=$(readlink "$REPO_DIR/GEMINI.md")
        if [ "$gemini_target" != "AGENTS.md" ]; then
            status="warning"
            message="GEMINI.md symlink points to $gemini_target instead of AGENTS.md"
            log "WARNING" "⚠️ $message"
        else
            log "SUCCESS" "✅ GEMINI.md symlink is correct"
        fi
    else
        status="fail"
        message="GEMINI.md is not a symlink to AGENTS.md"
        log "ERROR" "❌ $message"
    fi

    add_check_result "agents_symlinks" "$status" "$message"
}

# Check 6: Compare user guide content between Tier 2 and Tier 3
check_user_guide_sync() {
    log "STEP" "🔄 Checking user guide synchronization..."

    local status="pass"
    local message="User guides are synchronized"

    # Find user guide files in both tiers
    local tier2_guides=()
    local tier3_guides=()

    if [ -d "$REPO_DIR/website/src/src/pages/user-guide" ]; then
        mapfile -t tier2_guides < <(find "$REPO_DIR/website/src/src/pages/user-guide" -name "*.md" -type f 2>/dev/null | sort)
    fi

    if [ -d "$REPO_DIR/documentations/user" ]; then
        mapfile -t tier3_guides < <(find "$REPO_DIR/documentations/user" -name "*.md" -type f 2>/dev/null | sort)
    fi

    # Compare file counts
    local tier2_count=${#tier2_guides[@]}
    local tier3_count=${#tier3_guides[@]}

    if [ $tier2_count -eq 0 ] && [ $tier3_count -eq 0 ]; then
        status="warning"
        message="No user guides found in either tier"
        log "WARNING" "⚠️ $message"
    elif [ $tier2_count -ne $tier3_count ]; then
        status="warning"
        message="User guide count mismatch: Tier2=$tier2_count, Tier3=$tier3_count"
        log "WARNING" "⚠️ $message"
    else
        log "SUCCESS" "✅ User guide file counts match ($tier2_count files)"
    fi

    add_check_result "user_guide_sync" "$status" "$message"
}

# Check 7: Verify documentation strategy guide exists
check_documentation_strategy() {
    log "STEP" "📖 Checking documentation strategy guide..."

    local status="pass"
    local message="Documentation strategy guide exists"

    local strategy_file="$REPO_DIR/documentations/developer/guides/documentation-strategy.md"

    if [ ! -f "$strategy_file" ]; then
        status="warning"
        message="documentation-strategy.md not found in documentations/developer/guides/"
        log "WARNING" "⚠️ $message"
    else
        # Check if file has substantial content (> 1000 bytes)
        local file_size=$(stat -f%z "$strategy_file" 2>/dev/null || stat -c%s "$strategy_file" 2>/dev/null)
        if [ "$file_size" -lt 1000 ]; then
            status="warning"
            message="documentation-strategy.md exists but appears incomplete (< 1KB)"
            log "WARNING" "⚠️ $message"
        else
            log "SUCCESS" "✅ Documentation strategy guide exists and has content"
        fi
    fi

    add_check_result "documentation_strategy" "$status" "$message"
}

# Check 8: Verify Context7 MCP documentation in AGENTS.md
check_context7_documentation() {
    log "STEP" "🤖 Checking Context7 MCP documentation in AGENTS.md..."

    local status="pass"
    local message="Context7 MCP is documented in AGENTS.md"

    if [ ! -f "$REPO_DIR/AGENTS.md" ]; then
        status="fail"
        message="AGENTS.md not found"
        log "ERROR" "❌ $message"
    else
        # Check for Context7 MCP section
        if grep -qi "Context7 MCP" "$REPO_DIR/AGENTS.md"; then
            log "SUCCESS" "✅ Context7 MCP is documented in AGENTS.md"
        else
            status="warning"
            message="Context7 MCP not found in AGENTS.md - consider adding documentation"
            log "WARNING" "⚠️ $message"
        fi
    fi

    add_check_result "context7_documentation" "$status" "$message"
}

# Check 9: Detect configuration drift
check_configuration_drift() {
    log "STEP" "🔍 Checking for configuration drift..."

    local status="pass"
    local message="No configuration drift detected"
    local drift_issues=()

    # Check for docs-dist references (should be docs)
    if [ -f "$REPO_DIR/astro.config.mjs" ]; then
        if grep -q "docs-dist" "$REPO_DIR/astro.config.mjs"; then
            drift_issues+=("astro.config.mjs contains 'docs-dist' references")
        fi
    fi

    if [ -f "$REPO_DIR/README.md" ]; then
        if grep -q "docs-dist" "$REPO_DIR/README.md"; then
            drift_issues+=("README.md contains 'docs-dist' references")
        fi
    fi

    # Check for missing .nojekyll protection
    local nojekyll_count=0
    [ -f "$REPO_DIR/docs/.nojekyll" ] && ((nojekyll_count++))
    [ -f "$REPO_DIR/website/src/public/.nojekyll" ] && ((nojekyll_count++))

    if [ $nojekyll_count -lt 2 ]; then
        drift_issues+=("Incomplete .nojekyll protection layers ($nojekyll_count/2)")
    fi

    if [ ${#drift_issues[@]} -gt 0 ]; then
        status="warning"
        message="Configuration drift detected: ${drift_issues[*]}"
        log "WARNING" "⚠️ $message"
    else
        log "SUCCESS" "✅ No configuration drift detected"
    fi

    add_check_result "configuration_drift" "$status" "$message"
}

# Check 10: Verify local CI/CD integration
check_local_cicd_integration() {
    log "STEP" "🔧 Checking local CI/CD integration..."

    local status="pass"
    local message="Local CI/CD is properly configured"

    if [ ! -f "$REPO_DIR/.runners-local/workflows/gh-workflow-local.sh" ]; then
        status="fail"
        message="gh-workflow-local.sh not found"
        log "ERROR" "❌ $message"
    else
        # Check for Context7 integration
        if grep -q "validate_context7" "$REPO_DIR/.runners-local/workflows/gh-workflow-local.sh"; then
            log "SUCCESS" "✅ Local CI/CD includes Context7 validation"
        else
            status="warning"
            message="Local CI/CD missing Context7 validation integration"
            log "WARNING" "⚠️ $message"
        fi
    fi

    add_check_result "local_cicd_integration" "$status" "$message"
}

# Generate summary report
generate_summary_report() {
    log "STEP" "📊 Generating summary report..."

    update_summary

    if command -v jq >/dev/null 2>&1; then
        local total=$(jq -r '.summary.total' "$REPORT_FILE")
        local passed=$(jq -r '.summary.passed' "$REPORT_FILE")
        local failed=$(jq -r '.summary.failed' "$REPORT_FILE")
        local warnings=$(jq -r '.summary.warnings' "$REPORT_FILE")

        echo ""
        gum style \
            --border double \
            --border-foreground 212 \
            --align center \
            --width 70 \
            --margin "1 0" \
            --padding "1 2" \
            "Documentation Synchronization Report"$'\n\n'"Total Checks: $total"$'\n'"✅ Passed: $passed"$'\n'"❌ Failed: $failed"$'\n'"⚠️  Warnings: $warnings"$'\n\n'"Report File: $(basename "$REPORT_FILE")"
        echo ""

        if [ "$failed" -eq 0 ]; then
            log "SUCCESS" "🎉 All critical checks passed!"
            return 0
        else
            log "ERROR" "❌ $failed check(s) failed - review report for details"
            return 1
        fi
    fi
}

# Main execution
main() {
    log "INFO" "🚀 Starting documentation synchronization check..."
    echo ""

    init_report

    # Run all checks
    check_tier1_build_output
    check_tier2_source_structure
    check_tier3_documentation_hub
    check_astro_outdir_config
    check_agents_symlinks
    check_user_guide_sync
    check_documentation_strategy
    check_context7_documentation
    check_configuration_drift
    check_local_cicd_integration

    echo ""
    generate_summary_report
    local exit_code=$?

    log "INFO" "📄 Full report available at: $REPORT_FILE"

    exit $exit_code
}

# Execute if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
