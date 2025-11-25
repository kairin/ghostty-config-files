#!/bin/bash
# pre-commit-local.sh - Pre-commit validation script (zero GitHub Actions consumption)
# Orchestrates validation using modular components from lib/workflows/pre-commit/

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$PROJECT_ROOT/.runners-local/logs/workflows"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="$LOG_DIR/pre-commit-$TIMESTAMP.log"

# Ensure logs directory exists
mkdir -p "$LOG_DIR"

# Source modular components
source "$PROJECT_ROOT/lib/workflows/pre-commit/validators.sh"
source "$PROJECT_ROOT/lib/workflows/pre-commit/formatters.sh"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Validate file changes
validate_file_changes() {
    log "Validating file changes..."

    local validation_errors=0
    local changed_files
    changed_files=$(get_changed_files)

    if [[ -z "$changed_files" ]]; then
        log "No staged changes detected"
        return 0
    fi

    log "Files to validate:"
    echo "$changed_files" | while read -r file; do
        [[ -n "$file" ]] && log "  - $file"
    done

    # Validate each changed file
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        if ! validate_file_by_extension "$file" "$PROJECT_ROOT"; then
            ((validation_errors++))
        fi
    done <<< "$changed_files"

    return $validation_errors
}

# Main validation function
run_pre_commit_validation() {
    local validation_type="${1:-full}"
    local commit_message="${2:-}"
    local total_errors=0

    log "Starting pre-commit validation (type: $validation_type)"
    log "Project root: $PROJECT_ROOT"
    log "Log file: $LOG_FILE"

    # Constitutional compliance validation (always run)
    local compliance_result=0
    validate_constitutional_compliance "$PROJECT_ROOT" || compliance_result=$?
    total_errors=$((total_errors + compliance_result))

    # File change validation
    if [[ "$validation_type" == "full" || "$validation_type" == "files" ]]; then
        local file_result=0
        validate_file_changes || file_result=$?
        total_errors=$((total_errors + file_result))
    fi

    # Commit message validation
    if [[ "$validation_type" == "full" || "$validation_type" == "commit" ]]; then
        local commit_result=0
        validate_commit_message "$commit_message" || commit_result=$?
        total_errors=$((total_errors + commit_result))
    fi

    # Performance impact validation
    if [[ "$validation_type" == "full" || "$validation_type" == "performance" ]]; then
        validate_performance_impact
    fi

    # GitHub status check
    check_github_status "$LOG_DIR" "$TIMESTAMP"

    # Generate validation report
    generate_validation_report "$total_errors" "$validation_type" "$LOG_DIR" "$TIMESTAMP" "$LOG_FILE"

    # Print summary
    print_validation_summary "$total_errors"

    return $total_errors
}

# Help function
show_help() {
    cat << EOF
Local CI/CD Pre-commit Validation Script
Implements /local-cicd/pre-commit endpoint from OpenAPI contract

Usage: $0 [OPTIONS] [COMMIT_MESSAGE]

Options:
    --type TYPE         Validation type: full, files, commit, performance (default: full)
    --help              Show this help message
    --version           Show version information

Validation Types:
    full                Run all validation checks (default)
    files               Validate file changes only
    commit              Validate commit message only
    performance         Check performance impact only

Constitutional Requirements:
    - Zero GitHub Actions consumption
    - uv-First Python management
    - Strict type checking compliance
    - File change validation
    - Performance impact assessment

Examples:
    $0                                  # Full validation
    $0 --type files                     # File validation only
    $0 --type commit "feat: add feature" # Commit message validation
    $0 "fix: resolve bug"               # Full validation with commit message

Output:
    - Human-readable logs: $LOG_DIR/pre-commit-*.log
    - JSON reports: $LOG_DIR/pre-commit-validation-*.json
    - Constitutional compliance status
    - Performance impact assessment
EOF
}

# Main execution
main() {
    local validation_type="full"
    local commit_message=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --type)
                validation_type="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            --version)
                echo "Pre-commit Validation Script v1.0.0"
                echo "Constitutional compliance enforced"
                exit 0
                ;;
            -*)
                log "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                commit_message="$1"
                shift
                ;;
        esac
    done

    # Validate validation type
    case "$validation_type" in
        full|files|commit|performance)
            ;;
        *)
            log "Invalid validation type: $validation_type"
            log "Valid types: full, files, commit, performance"
            exit 1
            ;;
    esac

    # Change to project root
    cd "$PROJECT_ROOT" || {
        log "Failed to change to project root: $PROJECT_ROOT"
        exit 1
    }

    # Run validation
    if run_pre_commit_validation "$validation_type" "$commit_message"; then
        exit 0
    else
        exit 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
