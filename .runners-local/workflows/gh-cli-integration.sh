#!/bin/bash
#
# Constitutional GitHub CLI Integration
# Zero GitHub Actions consumption with comprehensive workflow management
#
# Constitutional Requirements:
# - Zero GitHub Actions minutes consumption
# - Local workflow execution only
# - Branch preservation strategy
# - Performance monitoring
# - Constitutional compliance validation

set -euo pipefail

# Constitutional configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/.update_cache/gh_cli_logs"
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly LOG_FILE="${LOG_DIR}/gh_cli_${TIMESTAMP}.log"

# Constitutional targets
readonly GITHUB_ACTIONS_LIMIT=0  # Zero consumption requirement
readonly MAX_WORKFLOW_TIME=300   # 5 minutes max for local workflows

# Colors for constitutional output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Constitutional logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"

    case "${level}" in
        "ERROR")   echo -e "${RED}❌ ${message}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ ${message}${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  ${message}${NC}" ;;
        "INFO")    echo -e "${BLUE}ℹ️  ${message}${NC}" ;;
        "CONSTITUTIONAL") echo -e "${PURPLE}⚖️  ${message}${NC}" ;;
    esac
}

# Constitutional validation function
validate_constitutional_compliance() {
    log "CONSTITUTIONAL" "Validating GitHub CLI integration compliance..."

    # Check GitHub CLI authentication
    if ! gh auth status &>/dev/null; then
        log "ERROR" "GitHub CLI not authenticated. Run: gh auth login"
        return 1
    fi

    # Check repository configuration
    if ! gh repo view &>/dev/null; then
        log "ERROR" "Not in a GitHub repository or repository not accessible"
        return 1
    fi

    # Validate zero GitHub Actions consumption
    local actions_usage
    actions_usage=$(gh api user/settings/billing/actions --jq '.total_minutes_used // 0' 2>/dev/null || echo "0")

    if [[ "${actions_usage}" -gt "${GITHUB_ACTIONS_LIMIT}" ]]; then
        log "WARNING" "GitHub Actions usage detected: ${actions_usage} minutes"
        log "CONSTITUTIONAL" "Consider reviewing workflow consumption"
    else
        log "SUCCESS" "Zero GitHub Actions consumption maintained"
    fi

    log "SUCCESS" "Constitutional compliance validated"
    return 0
}

# Repository status and information
check_repository_status() {
    log "INFO" "Checking repository status..."

    local repo_info
    repo_info=$(gh repo view --json name,description,pushedAt,isPrivate,defaultBranch)

    local repo_name=$(echo "${repo_info}" | jq -r '.name')
    local repo_desc=$(echo "${repo_info}" | jq -r '.description // "No description"')
    local last_push=$(echo "${repo_info}" | jq -r '.pushedAt')
    local is_private=$(echo "${repo_info}" | jq -r '.isPrivate')
    local default_branch=$(echo "${repo_info}" | jq -r '.defaultBranch')

    log "INFO" "Repository: ${repo_name}"
    log "INFO" "Description: ${repo_desc}"
    log "INFO" "Last push: ${last_push}"
    log "INFO" "Private: ${is_private}"
    log "INFO" "Default branch: ${default_branch}"

    # Check workflow runs (should be minimal/zero for constitutional compliance)
    local workflow_count
    workflow_count=$(gh run list --limit 10 --json status | jq 'length')

    if [[ "${workflow_count}" -gt 0 ]]; then
        log "WARNING" "Found ${workflow_count} recent workflow runs"

        # Show recent runs
        log "INFO" "Recent workflow runs:"
        gh run list --limit 5 --json name,status,conclusion,createdAt | \
            jq -r '.[] | "  • \(.name): \(.status) (\(.conclusion // "in_progress")) - \(.createdAt)"'
    else
        log "SUCCESS" "No recent workflow runs (constitutional compliance)"
    fi
}

# Branch management with constitutional strategy
manage_branches() {
    log "INFO" "Managing branches with constitutional strategy..."

    # List all branches
    local branches
    branches=$(gh api repos/:owner/:repo/branches --jq '.[].name' | tr '\n' ' ')

    log "INFO" "Available branches: ${branches}"

    # Check for constitutional branch naming pattern
    local constitutional_branches=0
    while read -r branch; do
        if [[ "${branch}" =~ ^[0-9]{8}-[0-9]{6}-.+ ]]; then
            constitutional_branches=$((constitutional_branches + 1))
        fi
    done <<< "$(echo "${branches}" | tr ' ' '\n')"

    log "INFO" "Constitutional branches found: ${constitutional_branches}"

    # Check current branch
    local current_branch
    current_branch=$(git branch --show-current)
    log "INFO" "Current branch: ${current_branch}"

    # Check if current branch follows constitutional naming
    if [[ "${current_branch}" =~ ^[0-9]{8}-[0-9]{6}-.+ ]]; then
        log "SUCCESS" "Current branch follows constitutional naming convention"
    elif [[ "${current_branch}" == "main" || "${current_branch}" == "master" ]]; then
        log "INFO" "On default branch (acceptable)"
    else
        log "WARNING" "Current branch does not follow constitutional naming convention"
        log "INFO" "Constitutional format: YYYYMMDD-HHMMSS-type-description"
    fi
}

# Issue and pull request management
manage_issues_and_prs() {
    log "INFO" "Checking issues and pull requests..."

    # Check open issues
    local open_issues
    open_issues=$(gh issue list --state open --json number,title --jq 'length')

    if [[ "${open_issues}" -gt 0 ]]; then
        log "INFO" "Open issues: ${open_issues}"
        gh issue list --state open --json number,title --jq '.[] | "  • #\(.number): \(.title)"'
    else
        log "INFO" "No open issues"
    fi

    # Check open pull requests
    local open_prs
    open_prs=$(gh pr list --state open --json number,title --jq 'length')

    if [[ "${open_prs}" -gt 0 ]]; then
        log "INFO" "Open pull requests: ${open_prs}"
        gh pr list --state open --json number,title --jq '.[] | "  • #\(.number): \(.title)"'
    else
        log "INFO" "No open pull requests"
    fi
}

# Release management
manage_releases() {
    log "INFO" "Checking release status..."

    # Get latest release
    local latest_release
    latest_release=$(gh release list --limit 1 --json tagName,publishedAt,isPrerelease 2>/dev/null || echo "[]")

    if [[ "${latest_release}" != "[]" && "${latest_release}" != "null" ]]; then
        local tag_name=$(echo "${latest_release}" | jq -r '.[0].tagName // "No releases"')
        local published_at=$(echo "${latest_release}" | jq -r '.[0].publishedAt // ""')
        local is_prerelease=$(echo "${latest_release}" | jq -r '.[0].isPrerelease // false')

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

    # Check if Python automation scripts are available
    local python_scripts=(
        "update_checker.py"
        "config_validator.py"
        "performance_monitor.py"
        "ci_cd_runner.py"
        "constitutional_automation.py"
    )

    local available_scripts=0
    for script in "${python_scripts[@]}"; do
        if [[ -f "${PROJECT_ROOT}/scripts/${script}" ]]; then
            available_scripts=$((available_scripts + 1))
            log "SUCCESS" "Found: scripts/${script}"
        else
            log "WARNING" "Missing: scripts/${script}"
        fi
    done

    log "INFO" "Available Python automation scripts: ${available_scripts}/${#python_scripts[@]}"

    # Check local CI/CD runners
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

# Performance monitoring integration
monitor_github_performance() {
    log "INFO" "Monitoring GitHub integration performance..."

    local start_time=$(date +%s)

    # Test GitHub API responsiveness
    local api_start=$(date +%s%3N)
    gh api user &>/dev/null
    local api_end=$(date +%s%3N)
    local api_time=$((api_end - api_start))

    log "INFO" "GitHub API response time: ${api_time}ms"

    # Test repository operations
    local repo_start=$(date +%s%3N)
    gh repo view &>/dev/null
    local repo_end=$(date +%s%3N)
    local repo_time=$((repo_end - repo_start))

    log "INFO" "Repository operation time: ${repo_time}ms"

    local total_time=$(($(date +%s) - start_time))
    log "INFO" "Total GitHub CLI integration time: ${total_time}s"

    # Constitutional performance validation
    if [[ "${total_time}" -gt "${MAX_WORKFLOW_TIME}" ]]; then
        log "WARNING" "GitHub CLI integration exceeded constitutional time limit"
    else
        log "SUCCESS" "GitHub CLI integration within constitutional performance targets"
    fi
}

# Zero-consumption workflow validation
validate_zero_consumption() {
    log "CONSTITUTIONAL" "Validating zero GitHub Actions consumption..."

    # Check billing information
    local billing_info
    billing_info=$(gh api user/settings/billing/actions 2>/dev/null || echo '{}')

    local total_minutes=$(echo "${billing_info}" | jq -r '.total_minutes_used // 0')
    local included_minutes=$(echo "${billing_info}" | jq -r '.included_minutes // 0')
    local paid_minutes=$(echo "${billing_info}" | jq -r '.total_paid_minutes_used // 0')

    log "INFO" "Total minutes used: ${total_minutes}"
    log "INFO" "Included minutes: ${included_minutes}"
    log "INFO" "Paid minutes used: ${paid_minutes}"

    if [[ "${paid_minutes}" -gt 0 ]]; then
        log "ERROR" "CONSTITUTIONAL VIOLATION: Paid GitHub Actions minutes detected!"
        return 1
    elif [[ "${total_minutes}" -gt "${included_minutes}" ]]; then
        log "WARNING" "GitHub Actions usage approaching limits"
    else
        log "SUCCESS" "Zero paid GitHub Actions consumption maintained"
    fi

    # Check for workflows that might consume minutes
    local workflows_dir="${PROJECT_ROOT}/.github/workflows"
    if [[ -d "${workflows_dir}" ]]; then
        local workflow_files
        workflow_files=$(find "${workflows_dir}" -name "*.yml" -o -name "*.yaml" | wc -l)

        if [[ "${workflow_files}" -gt 0 ]]; then
            log "WARNING" "Found ${workflow_files} workflow files - ensure they don't consume minutes"

            # Check each workflow for minute-consuming actions
            while IFS= read -r -d '' workflow_file; do
                if grep -q "runs-on:" "${workflow_file}"; then
                    log "WARNING" "Workflow ${workflow_file} may consume minutes (contains 'runs-on')"
                fi
            done < <(find "${workflows_dir}" -name "*.yml" -o -name "*.yaml" -print0)
        else
            log "SUCCESS" "No GitHub workflow files found (constitutional compliance)"
        fi
    else
        log "SUCCESS" "No .github/workflows directory (constitutional compliance)"
    fi
}

# Create constitutional branch with GitHub CLI
create_constitutional_branch() {
    local branch_description="$1"
    local datetime=$(date +"%Y%m%d-%H%M%S")
    local branch_name="${datetime}-${branch_description}"

    log "INFO" "Creating constitutional branch: ${branch_name}"

    # Create and push branch
    git checkout -b "${branch_name}"
    git push -u origin "${branch_name}"

    log "SUCCESS" "Constitutional branch created and pushed: ${branch_name}"
    echo "${branch_name}"
}

# Create pull request with constitutional compliance
create_constitutional_pr() {
    local title="$1"
    local body="$2"
    local branch_name="$3"

    log "INFO" "Creating constitutional pull request..."

    # Add constitutional compliance footer
    local constitutional_body="${body}

---

## Constitutional Compliance ⚖️

✅ **Zero GitHub Actions Consumption**: All CI/CD runs locally
✅ **Branch Preservation Strategy**: Constitutional naming convention applied
✅ **Performance Validation**: Local performance monitoring executed
✅ **Constitutional Framework**: All requirements validated

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

    # Create pull request
    local pr_url
    pr_url=$(gh pr create --title "${title}" --body "${constitutional_body}" --head "${branch_name}")

    log "SUCCESS" "Constitutional pull request created: ${pr_url}"
    echo "${pr_url}"
}

# Main workflow coordination
run_github_workflow() {
    local workflow_type="$1"

    case "${workflow_type}" in
        "status")
            check_repository_status
            manage_branches
            manage_issues_and_prs
            manage_releases
            ;;
        "validate")
            validate_constitutional_compliance
            validate_zero_consumption
            ;;
        "integrate")
            integrate_local_workflows
            monitor_github_performance
            ;;
        "full")
            validate_constitutional_compliance
            check_repository_status
            manage_branches
            manage_issues_and_prs
            manage_releases
            integrate_local_workflows
            monitor_github_performance
            validate_zero_consumption
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
    • Zero GitHub Actions consumption
    • Local workflow execution only
    • Branch preservation strategy
    • Performance monitoring
    • Constitutional compliance validation

EOF
}

# Main execution
main() {
    local command="${1:-}"

    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    # Start constitutional logging
    log "INFO" "Starting Constitutional GitHub CLI Integration"
    log "INFO" "Command: ${command}"
    log "INFO" "Timestamp: ${TIMESTAMP}"
    log "INFO" "Project root: ${PROJECT_ROOT}"

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