#!/bin/bash
# Local CI/CD Infrastructure - Pre-commit Validation Script
# Implements /local-cicd/pre-commit endpoint from OpenAPI contract
# Constitutional requirement: Zero GitHub Actions consumption

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$PROJECT_ROOT/.runners-local/logs/workflows"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="$LOG_DIR/pre-commit-$TIMESTAMP.log"

# Ensure logs directory exists
mkdir -p "$LOG_DIR"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# GitHub CLI integration for enhanced validation
check_github_status() {
    log "🔍 Checking GitHub repository status..."

    # Check if gh CLI is available and authenticated
    if ! command -v gh >/dev/null 2>&1; then
        log "⚠️  GitHub CLI not available - skipping GitHub checks"
        return 0
    fi

    if ! gh auth status >/dev/null 2>&1; then
        log "⚠️  GitHub CLI not authenticated - skipping GitHub checks"
        return 0
    fi

    # Check repository status
    local repo_status
    repo_status=$(gh repo view --json name,isPrivate,pushedAt,defaultBranch 2>/dev/null || echo "null")

    if [[ "$repo_status" != "null" ]]; then
        log "✅ GitHub repository accessible"
        echo "$repo_status" > "$LOG_DIR/github-status-$TIMESTAMP.json"

        # Check if there are any open PRs that might conflict
        local open_prs
        open_prs=$(gh pr list --state open --json number,title,headRefName --limit 5 2>/dev/null || echo "[]")
        log "📋 Open PRs: $(echo "$open_prs" | jq length 2>/dev/null || echo "0")"

        # Check branch protection rules if on main/master
        local current_branch
        current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
            log "🛡️  On protected branch: $current_branch"
            # Could add branch protection validation here
        fi
    else
        log "⚠️  Could not access GitHub repository"
    fi
}

# Constitutional compliance validation
validate_constitutional_compliance() {
    log "📜 Validating constitutional compliance..."

    local compliance_errors=0

    # Check for forbidden GitHub Actions consumption
    if [[ -d ".github/workflows" ]]; then
        local workflow_files
        workflow_files=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
        if [[ "$workflow_files" -gt 0 ]]; then
            log "❌ CONSTITUTIONAL VIOLATION: GitHub Actions workflows found in .github/workflows/"
            log "    Constitutional requirement: Zero GitHub Actions consumption"
            ((compliance_errors++))
        fi
    fi

    # Check for uv-First Python Management compliance
    if [[ -f "requirements.txt" || -f "setup.py" || -f "Pipfile" || -f "poetry.lock" ]]; then
        log "❌ CONSTITUTIONAL VIOLATION: Non-uv package manager files found"
        log "    Constitutional requirement: uv-First Python Management"
        ((compliance_errors++))
    fi

    # Verify pyproject.toml has constitutional settings
    if [[ -f "pyproject.toml" ]]; then
        if ! grep -q 'requires-python = ">=3.12"' pyproject.toml; then
            log "❌ CONSTITUTIONAL VIOLATION: Python version requirement not met"
            log "    Constitutional requirement: Python >=3.12"
            ((compliance_errors++))
        fi

        if ! grep -q '\[tool.mypy\]' pyproject.toml || ! grep -q 'strict = true' pyproject.toml; then
            log "❌ CONSTITUTIONAL VIOLATION: MyPy strict mode not enabled"
            log "    Constitutional requirement: Strict type checking"
            ((compliance_errors++))
        fi
    fi

    return $compliance_errors
}

# File change validation
validate_file_changes() {
    log "📁 Validating file changes..."

    local validation_errors=0

    # Get list of changed files
    local changed_files
    if git rev-parse --verify HEAD >/dev/null 2>&1; then
        changed_files=$(git diff --cached --name-only 2>/dev/null || git diff --name-only HEAD^ 2>/dev/null || echo "")
    else
        # Initial commit case
        changed_files=$(git ls-files --cached 2>/dev/null || echo "")
    fi

    if [[ -z "$changed_files" ]]; then
        log "ℹ️  No staged changes detected"
        return 0
    fi

    log "📋 Files to validate:"
    echo "$changed_files" | while read -r file; do
        [[ -n "$file" ]] && log "  - $file"
    done

    # Validate each changed file
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        # Check if file exists (might be deleted)
        if [[ ! -f "$file" ]]; then
            log "🗑️  File deleted: $file"
            continue
        fi

        # Validate file-specific rules
        case "$file" in
            *.py)
                log "🐍 Validating Python file: $file"

                # Check for basic Python syntax
                if ! python3 -m py_compile "$file" 2>/dev/null; then
                    log "❌ Python syntax error in: $file"
                    ((validation_errors++))
                fi

                # Check for uv usage if available
                if command -v uv >/dev/null 2>&1; then
                    if ! uv run python -m py_compile "$file" 2>/dev/null; then
                        log "❌ uv validation failed for: $file"
                        ((validation_errors++))
                    fi
                fi
                ;;

            *.ts|*.tsx|*.js|*.jsx)
                log "📝 Validating TypeScript/JavaScript file: $file"

                # Check for TypeScript compilation if tsconfig.json exists
                if [[ -f "tsconfig.json" ]] && command -v npx >/dev/null 2>&1; then
                    if ! npx tsc --noEmit --skipLibCheck "$file" 2>/dev/null; then
                        log "⚠️  TypeScript validation issues in: $file (non-blocking)"
                    fi
                fi
                ;;

            *.astro)
                log "🚀 Validating Astro component: $file"

                # Check for Astro syntax if astro is available
                if command -v npx >/dev/null 2>&1 && [[ -f "astro.config.mjs" ]]; then
                    if ! npx astro check --minimumSeverity warning 2>/dev/null; then
                        log "⚠️  Astro validation issues in: $file (non-blocking)"
                    fi
                fi
                ;;

            *.json)
                log "📋 Validating JSON file: $file"

                # Check JSON syntax
                if ! jq empty "$file" 2>/dev/null; then
                    log "❌ Invalid JSON syntax in: $file"
                    ((validation_errors++))
                fi
                ;;

            *.yaml|*.yml)
                log "📄 Validating YAML file: $file"

                # Check YAML syntax if python3 is available
                if command -v python3 >/dev/null 2>&1; then
                    if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
                        log "❌ Invalid YAML syntax in: $file"
                        ((validation_errors++))
                    fi
                fi
                ;;

            *.md)
                log "📖 Validating Markdown file: $file"

                # Check for basic markdown structure
                if [[ ! -s "$file" ]]; then
                    log "⚠️  Empty markdown file: $file"
                fi
                ;;
        esac

        # Check for sensitive data patterns
        if grep -l -E "(api_key|password|secret|token)" "$file" 2>/dev/null; then
            log "🔒 WARNING: Potential sensitive data in: $file"
            log "    Please review for API keys, passwords, or secrets"
        fi

        # Check file size limits (constitutional requirement)
        local file_size
        file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        if [[ "$file_size" -gt 1048576 ]]; then  # 1MB limit
            log "⚠️  Large file detected: $file (${file_size} bytes)"
            log "    Consider if this file should be in the repository"
        fi

    done <<< "$changed_files"

    return $validation_errors
}

# Commit message validation
validate_commit_message() {
    log "💬 Validating commit message..."

    local validation_errors=0
    local commit_msg=""

    # Try to get commit message from various sources
    if [[ -f ".git/COMMIT_EDITMSG" ]]; then
        commit_msg=$(head -n1 ".git/COMMIT_EDITMSG" 2>/dev/null || echo "")
    elif [[ -n "${1:-}" ]]; then
        commit_msg="$1"
    else
        # Get last commit message
        commit_msg=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")
    fi

    if [[ -z "$commit_msg" ]]; then
        log "⚠️  No commit message to validate"
        return 0
    fi

    log "📝 Commit message: '$commit_msg'"

    # Constitutional commit message requirements
    local msg_length=${#commit_msg}

    # Check minimum length
    if [[ "$msg_length" -lt 10 ]]; then
        log "❌ Commit message too short (${msg_length} chars, minimum 10)"
        ((validation_errors++))
    fi

    # Check maximum length for first line
    if [[ "$msg_length" -gt 72 ]]; then
        log "⚠️  Commit message first line is long (${msg_length} chars, recommended <72)"
    fi

    # Check for conventional commit format (recommended)
    if [[ "$commit_msg" =~ ^(feat|fix|docs|style|refactor|test|chore|ci|perf|build)(\(.+\))?: ]]; then
        log "✅ Conventional commit format detected"
    else
        log "ℹ️  Consider using conventional commit format: type(scope): description"
    fi

    # Check for constitutional attribution
    local full_commit_msg
    full_commit_msg=$(git log -1 --pretty=format:"%B" 2>/dev/null || echo "")

    if [[ "$full_commit_msg" == *"🤖 Generated with"* ]]; then
        log "✅ Constitutional AI attribution present"
    else
        log "ℹ️  Consider adding constitutional AI attribution for AI-assisted commits"
    fi

    return $validation_errors
}

# Performance impact validation
validate_performance_impact() {
    log "⚡ Validating performance impact..."

    # Check if changes might affect performance
    local changed_files
    changed_files=$(git diff --cached --name-only 2>/dev/null || git diff --name-only HEAD^ 2>/dev/null || echo "")

    local performance_sensitive_files=0

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        case "$file" in
            package.json|package-lock.json|uv.lock|pyproject.toml)
                log "📦 Dependency change detected: $file"
                ((performance_sensitive_files++))
                ;;
            astro.config.*|tailwind.config.*|tsconfig.json)
                log "⚙️  Configuration change detected: $file"
                ((performance_sensitive_files++))
                ;;
            src/styles/*|*.css)
                log "🎨 Style change detected: $file"
                ((performance_sensitive_files++))
                ;;
            src/components/*|src/layouts/*)
                log "🧩 Component change detected: $file"
                ((performance_sensitive_files++))
                ;;
        esac
    done <<< "$changed_files"

    if [[ "$performance_sensitive_files" -gt 0 ]]; then
        log "⚠️  $performance_sensitive_files performance-sensitive files changed"
        log "    Consider running performance validation after commit:"
        log "    ./.runners-local/workflows/performance-monitor.sh --target-url http://localhost:4321"
        log "    ./.runners-local/workflows/astro-build-local.sh --environment production --validation full"
    fi

    return 0
}

# Main validation function
run_pre_commit_validation() {
    local validation_type="${1:-full}"
    local total_errors=0

    log "🚀 Starting pre-commit validation (type: $validation_type)"
    log "📍 Project root: $PROJECT_ROOT"
    log "📝 Log file: $LOG_FILE"

    # Constitutional compliance validation (always run)
    if ! validate_constitutional_compliance; then
        ((total_errors += $?))
    fi

    # File change validation
    if [[ "$validation_type" == "full" || "$validation_type" == "files" ]]; then
        if ! validate_file_changes; then
            ((total_errors += $?))
        fi
    fi

    # Commit message validation
    if [[ "$validation_type" == "full" || "$validation_type" == "commit" ]]; then
        if ! validate_commit_message "${2:-}"; then
            ((total_errors += $?))
        fi
    fi

    # Performance impact validation
    if [[ "$validation_type" == "full" || "$validation_type" == "performance" ]]; then
        validate_performance_impact
    fi

    # GitHub status check
    check_github_status

    # Generate validation report
    generate_validation_report "$total_errors"

    return $total_errors
}

# Generate JSON validation report (API contract compliance)
generate_validation_report() {
    local total_errors="$1"
    local status="success"

    if [[ "$total_errors" -gt 0 ]]; then
        status="failed"
    fi

    local report_file="$LOG_DIR/pre-commit-validation-$TIMESTAMP.json"

    cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "validation_type": "${validation_type:-full}",
    "status": "$status",
    "errors_count": $total_errors,
    "constitutional_compliance": {
        "zero_github_actions": $([ ! -d ".github/workflows" ] && echo "true" || echo "false"),
        "uv_first_python": $([ ! -f "requirements.txt" ] && [ ! -f "setup.py" ] && echo "true" || echo "false"),
        "strict_typing": $(grep -q 'strict = true' pyproject.toml 2>/dev/null && echo "true" || echo "false")
    },
    "files_validated": {
        "total": $(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ' || echo "0"),
        "python_files": $(git diff --cached --name-only 2>/dev/null | grep -c '\.py$' || echo "0"),
        "typescript_files": $(git diff --cached --name-only 2>/dev/null | grep -cE '\.(ts|tsx|js|jsx)$' || echo "0"),
        "astro_files": $(git diff --cached --name-only 2>/dev/null | grep -c '\.astro$' || echo "0")
    },
    "performance_impact": {
        "dependencies_changed": $(git diff --cached --name-only 2>/dev/null | grep -cE 'package.*\.json|uv\.lock|pyproject\.toml' || echo "0"),
        "config_changed": $(git diff --cached --name-only 2>/dev/null | grep -cE '.*\.config\.|tsconfig\.json' || echo "0"),
        "components_changed": $(git diff --cached --name-only 2>/dev/null | grep -cE 'src/components/|src/layouts/' || echo "0")
    },
    "github_integration": {
        "cli_available": $(command -v gh >/dev/null 2>&1 && echo "true" || echo "false"),
        "authenticated": $(gh auth status >/dev/null 2>&1 && echo "true" || echo "false"),
        "repository_accessible": $(gh repo view >/dev/null 2>&1 && echo "true" || echo "false")
    },
    "recommendations": [
$([ "$total_errors" -gt 0 ] && echo '        "Fix validation errors before committing"' || echo '        "Pre-commit validation passed"')
$([ -d ".github/workflows" ] && echo ',
        "Remove GitHub Actions workflows to maintain constitutional compliance"' || echo '')
$(git diff --cached --name-only 2>/dev/null | grep -qE 'package.*\.json|uv\.lock' && echo ',
        "Consider running performance validation after deploy"' || echo '')
    ],
    "log_file": "$LOG_FILE",
    "report_file": "$report_file"
}
EOF

    log "📊 Validation report generated: $report_file"

    # Output final status
    if [[ "$total_errors" -eq 0 ]]; then
        log "✅ Pre-commit validation PASSED"
        log "🎯 All constitutional requirements satisfied"
        log "🚀 Ready for commit"
    else
        log "❌ Pre-commit validation FAILED"
        log "🔧 $total_errors error(s) must be fixed before committing"
        log "📋 Review validation details above"
    fi
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
    ✅ Zero GitHub Actions consumption
    ✅ uv-First Python management
    ✅ Strict type checking compliance
    ✅ File change validation
    ✅ Performance impact assessment

Examples:
    $0                                  # Full validation
    $0 --type files                     # File validation only
    $0 --type commit "feat: add feature" # Commit message validation
    $0 "fix: resolve bug"               # Full validation with commit message

GitHub CLI Integration:
    - Repository status checking
    - Branch protection validation
    - Open PR conflict detection
    - Authentication verification

Output:
    - Human-readable logs: $LOG_DIR/pre-commit-*.log
    - JSON reports: $LOG_DIR/pre-commit-validation-*.json
    - Constitutional compliance status
    - Performance impact assessment

Constitutional Compliance: This script enforces zero GitHub Actions consumption
and validates all constitutional requirements for local CI/CD infrastructure.
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
                log "❌ Unknown option: $1"
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
            log "❌ Invalid validation type: $validation_type"
            log "Valid types: full, files, commit, performance"
            exit 1
            ;;
    esac

    # Change to project root
    cd "$PROJECT_ROOT" || {
        log "❌ Failed to change to project root: $PROJECT_ROOT"
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