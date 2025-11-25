#!/bin/bash
# Constitutional GitHub CLI Integration - Zero GitHub Actions consumption
# Orchestrates GitHub CLI operations using modular components from lib/workflows/gh-cli/

set -euo pipefail

# Constitutional configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/.update_cache/gh_cli_logs"
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly LOG_FILE="${LOG_DIR}/gh_cli_${TIMESTAMP}.log"
readonly MAX_WORKFLOW_TIME=300  # 5 minutes max

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Source modular components
source "${PROJECT_ROOT}/lib/workflows/gh-cli/auth.sh"
source "${PROJECT_ROOT}/lib/workflows/gh-cli/api.sh"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

# Constitutional logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"

    case "${level}" in
        "ERROR")   echo -e "${RED}[ERROR] ${message}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}[OK] ${message}${NC}" ;;
        "WARNING") echo -e "${YELLOW}[WARN] ${message}${NC}" ;;
        "INFO")    echo -e "${BLUE}[INFO] ${message}${NC}" ;;
        "CONSTITUTIONAL") echo -e "${PURPLE}[CONST] ${message}${NC}" ;;
    esac
}

# Repository status and information
check_repository_status() {
    log "INFO" "Checking repository status..."
    echo ""
    get_repo_status_summary
    echo ""

    # Check workflow runs
    local workflow_count
    workflow_count=$(get_workflow_runs 10 | jq 'length')

    if [[ "${workflow_count}" -gt 0 ]]; then
        log "WARNING" "Found ${workflow_count} recent workflow runs"
        log "INFO" "Recent workflow runs:"
        get_workflow_runs 5 | jq -r '.[] | "  - \(.name): \(.status) (\(.conclusion // "in_progress"))"'
    else
        log "SUCCESS" "No recent workflow runs (constitutional compliance)"
    fi
}

# Issue and pull request management
manage_issues_and_prs() {
    log "INFO" "Checking issues and pull requests..."

    local open_issues open_prs
    open_issues=$(get_open_issues 10)
    open_prs=$(get_open_prs 10)

    local issue_count pr_count
    issue_count=$(echo "$open_issues" | jq 'length')
    pr_count=$(echo "$open_prs" | jq 'length')

    if [[ "${issue_count}" -gt 0 ]]; then
        log "INFO" "Open issues: ${issue_count}"
        echo "$open_issues" | jq -r '.[] | "  - #\(.number): \(.title)"'
    else
        log "INFO" "No open issues"
    fi

    if [[ "${pr_count}" -gt 0 ]]; then
        log "INFO" "Open pull requests: ${pr_count}"
        echo "$open_prs" | jq -r '.[] | "  - #\(.number): \(.title)"'
    else
        log "INFO" "No open pull requests"
    fi
}

# Release management
manage_releases() {
    log "INFO" "Checking release status..."

    local latest_release
    latest_release=$(get_latest_release)

    if [[ "${latest_release}" != "[]" && "${latest_release}" != "null" ]]; then
        local tag_name published_at is_prerelease
        tag_name=$(echo "${latest_release}" | jq -r '.[0].tagName // "No releases"')
        published_at=$(echo "${latest_release}" | jq -r '.[0].publishedAt // ""')
        is_prerelease=$(echo "${latest_release}" | jq -r '.[0].isPrerelease // false')

        log "INFO" "Latest release: ${tag_name}"
        log "INFO" "Published: ${published_at}"
        log "INFO" "Prerelease: ${is_prerelease}"
    else
        log "INFO" "No releases found"
    fi
}

# Local workflow integration
integrate_local_workflows() {
    log "INFO" "Integrating with local workflows..."

    local runner_scripts=(
        "astro-build-local.sh"
        "gh-workflow-local.sh"
        "performance-monitor.sh"
        "pre-commit-local.sh"
    )

    local available_runners=0
    for runner in "${runner_scripts[@]}"; do
        if [[ -f "${SCRIPT_DIR}/${runner}" ]]; then
            available_runners=$((available_runners + 1))
            log "SUCCESS" "Found: .runners-local/workflows/${runner}"
        else
            log "WARNING" "Missing: .runners-local/workflows/${runner}"
        fi
    done

    log "INFO" "Available runner scripts: ${available_runners}/${#runner_scripts[@]}"
}

# Main workflow coordination
run_github_workflow() {
    local workflow_type="$1"

    case "${workflow_type}" in
        "status")
            check_repository_status
            manage_branches log
            manage_issues_and_prs
            manage_releases
            ;;
        "validate")
            validate_gh_compliance log
            validate_zero_consumption log
            check_workflow_files "${PROJECT_ROOT}" log
            ;;
        "integrate")
            integrate_local_workflows
            monitor_gh_performance
            ;;
        "full")
            validate_gh_compliance log
            check_repository_status
            manage_branches log
            manage_issues_and_prs
            manage_releases
            integrate_local_workflows
            monitor_gh_performance
            validate_zero_consumption log
            check_workflow_files "${PROJECT_ROOT}" log
            ;;
        *)
            log "ERROR" "Unknown workflow type: ${workflow_type}"
            log "INFO" "Available workflows: status, validate, integrate, full"
            return 1
            ;;
    esac
}

# Usage function
show_usage() {
    cat << EOF
Constitutional GitHub CLI Integration

USAGE:
    $0 <command> [options]

COMMANDS:
    status      - Check repository status, branches, issues, PRs
    validate    - Validate constitutional compliance and zero consumption
    integrate   - Integrate with local workflows and monitor performance
    full        - Run complete GitHub CLI integration workflow
    branch      - Create constitutional branch (requires description)
    pr          - Create constitutional pull request (requires title and body)

EXAMPLES:
    $0 status                           # Check repository status
    $0 validate                         # Validate constitutional compliance
    $0 full                            # Run complete workflow
    $0 branch "feat-new-feature"       # Create constitutional branch
    $0 pr "Add feature" "Description"  # Create constitutional PR

CONSTITUTIONAL REQUIREMENTS:
    - Zero GitHub Actions consumption
    - Local workflow execution only
    - Branch preservation strategy
    - Performance monitoring
    - Constitutional compliance validation
EOF
}

# Main execution
main() {
    local command="${1:-}"

    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    log "INFO" "Starting Constitutional GitHub CLI Integration"
    log "INFO" "Command: ${command}"
    log "INFO" "Timestamp: ${TIMESTAMP}"

    case "${command}" in
        "status"|"validate"|"integrate"|"full")
            run_github_workflow "${command}"
            ;;
        "branch")
            if [[ $# -lt 2 ]]; then
                log "ERROR" "Branch description required"
                show_usage
                exit 1
            fi
            create_constitutional_branch "$2"
            ;;
        "pr")
            if [[ $# -lt 3 ]]; then
                log "ERROR" "PR title and body required"
                show_usage
                exit 1
            fi
            local current_branch=$(git branch --show-current)
            create_constitutional_pr "$2" "$3" "${current_branch}"
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log "ERROR" "Unknown command: ${command}"
            show_usage
            exit 1
            ;;
    esac

    log "SUCCESS" "Constitutional GitHub CLI Integration completed"
    log "INFO" "Log file: ${LOG_FILE}"
}

# Execute main function with all arguments
main "$@"
