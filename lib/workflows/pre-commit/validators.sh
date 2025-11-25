#!/usr/bin/env bash
# lib/workflows/pre-commit/validators.sh - Pre-commit validation utilities
# Extracted from .runners-local/workflows/pre-commit-local.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_PRECOMMIT_VALIDATORS_SOURCED:-}" ]] && return 0
readonly _PRECOMMIT_VALIDATORS_SOURCED=1

#######################################
# Validate constitutional compliance
# Arguments:
#   $1 - Project root directory
# Returns:
#   Number of compliance errors
#######################################
validate_constitutional_compliance() {
    local project_root="${1:-.}"
    local compliance_errors=0

    echo "Validating constitutional compliance..."

    # Check for forbidden GitHub Actions consumption
    if [[ -d "$project_root/.github/workflows" ]]; then
        local workflow_files
        workflow_files=$(find "$project_root/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
        if [[ "$workflow_files" -gt 0 ]]; then
            echo "CONSTITUTIONAL VIOLATION: GitHub Actions workflows found in .github/workflows/"
            echo "    Constitutional requirement: Zero GitHub Actions consumption"
            ((compliance_errors++))
        fi
    fi

    # Check for uv-First Python Management compliance
    if [[ -f "$project_root/requirements.txt" || -f "$project_root/setup.py" || \
          -f "$project_root/Pipfile" || -f "$project_root/poetry.lock" ]]; then
        echo "CONSTITUTIONAL VIOLATION: Non-uv package manager files found"
        echo "    Constitutional requirement: uv-First Python Management"
        ((compliance_errors++))
    fi

    # Verify pyproject.toml has constitutional settings
    if [[ -f "$project_root/pyproject.toml" ]]; then
        if ! grep -q 'requires-python = ">=3.12"' "$project_root/pyproject.toml"; then
            echo "CONSTITUTIONAL VIOLATION: Python version requirement not met"
            echo "    Constitutional requirement: Python >=3.12"
            ((compliance_errors++))
        fi

        if ! grep -q '\[tool.mypy\]' "$project_root/pyproject.toml" || \
           ! grep -q 'strict = true' "$project_root/pyproject.toml"; then
            echo "CONSTITUTIONAL VIOLATION: MyPy strict mode not enabled"
            echo "    Constitutional requirement: Strict type checking"
            ((compliance_errors++))
        fi
    fi

    return $compliance_errors
}

#######################################
# Validate Python file
# Arguments:
#   $1 - File path
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_python_file() {
    local file="$1"
    local errors=0

    echo "Validating Python file: $file"

    # Check for basic Python syntax
    if ! python3 -m py_compile "$file" 2>/dev/null; then
        echo "Python syntax error in: $file"
        ((errors++))
    fi

    # Check for uv usage if available
    if command -v uv >/dev/null 2>&1; then
        if ! uv run python -m py_compile "$file" 2>/dev/null; then
            echo "uv validation failed for: $file"
            ((errors++))
        fi
    fi

    return $errors
}

#######################################
# Validate TypeScript/JavaScript file
# Arguments:
#   $1 - File path
#   $2 - Project root (optional)
# Returns:
#   0 if valid, non-zero if issues (warnings are non-blocking)
#######################################
validate_typescript_file() {
    local file="$1"
    local project_root="${2:-.}"

    echo "Validating TypeScript/JavaScript file: $file"

    # Check for TypeScript compilation if tsconfig.json exists
    if [[ -f "$project_root/tsconfig.json" ]] && command -v npx >/dev/null 2>&1; then
        if ! npx tsc --noEmit --skipLibCheck "$file" 2>/dev/null; then
            echo "TypeScript validation issues in: $file (non-blocking)"
        fi
    fi

    return 0  # Non-blocking
}

#######################################
# Validate Astro component file
# Arguments:
#   $1 - File path
#   $2 - Project root (optional)
# Returns:
#   0 always (non-blocking validation)
#######################################
validate_astro_file() {
    local file="$1"
    local project_root="${2:-.}"

    echo "Validating Astro component: $file"

    # Check for Astro syntax if astro is available
    if command -v npx >/dev/null 2>&1 && [[ -f "$project_root/astro.config.mjs" ]]; then
        if ! npx astro check --minimumSeverity warning 2>/dev/null; then
            echo "Astro validation issues in: $file (non-blocking)"
        fi
    fi

    return 0  # Non-blocking
}

#######################################
# Validate JSON file
# Arguments:
#   $1 - File path
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_json_file() {
    local file="$1"

    echo "Validating JSON file: $file"

    # Check JSON syntax
    if ! jq empty "$file" 2>/dev/null; then
        echo "Invalid JSON syntax in: $file"
        return 1
    fi

    return 0
}

#######################################
# Validate YAML file
# Arguments:
#   $1 - File path
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_yaml_file() {
    local file="$1"

    echo "Validating YAML file: $file"

    # Check YAML syntax if python3 is available
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo "Invalid YAML syntax in: $file"
            return 1
        fi
    fi

    return 0
}

#######################################
# Validate Markdown file
# Arguments:
#   $1 - File path
# Returns:
#   0 always (just checks if empty)
#######################################
validate_markdown_file() {
    local file="$1"

    echo "Validating Markdown file: $file"

    # Check for basic markdown structure
    if [[ ! -s "$file" ]]; then
        echo "Empty markdown file: $file"
    fi

    return 0
}

#######################################
# Check file for sensitive data patterns
# Arguments:
#   $1 - File path
# Outputs:
#   Warning if sensitive patterns found
#######################################
check_sensitive_data() {
    local file="$1"

    if grep -lE "(api_key|password|secret|token)" "$file" 2>/dev/null; then
        echo "WARNING: Potential sensitive data in: $file"
        echo "    Please review for API keys, passwords, or secrets"
    fi
}

#######################################
# Check file size limits
# Arguments:
#   $1 - File path
#   $2 - Max size in bytes (optional, default 1MB)
#######################################
check_file_size() {
    local file="$1"
    local max_size="${2:-1048576}"  # 1MB default

    local file_size
    file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")

    if [[ "$file_size" -gt "$max_size" ]]; then
        echo "Large file detected: $file (${file_size} bytes)"
        echo "    Consider if this file should be in the repository"
    fi
}

#######################################
# Validate commit message format
# Arguments:
#   $1 - Commit message (optional, reads from .git/COMMIT_EDITMSG if not provided)
# Returns:
#   Number of validation errors
#######################################
validate_commit_message() {
    local commit_msg="${1:-}"
    local validation_errors=0

    echo "Validating commit message..."

    # Try to get commit message from various sources
    if [[ -z "$commit_msg" ]] && [[ -f ".git/COMMIT_EDITMSG" ]]; then
        commit_msg=$(head -n1 ".git/COMMIT_EDITMSG" 2>/dev/null || echo "")
    elif [[ -z "$commit_msg" ]]; then
        commit_msg=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")
    fi

    if [[ -z "$commit_msg" ]]; then
        echo "No commit message to validate"
        return 0
    fi

    echo "Commit message: '$commit_msg'"

    # Constitutional commit message requirements
    local msg_length=${#commit_msg}

    # Check minimum length
    if [[ "$msg_length" -lt 10 ]]; then
        echo "Commit message too short (${msg_length} chars, minimum 10)"
        ((validation_errors++))
    fi

    # Check maximum length for first line
    if [[ "$msg_length" -gt 72 ]]; then
        echo "Commit message first line is long (${msg_length} chars, recommended <72)"
    fi

    # Check for conventional commit format (recommended)
    if [[ "$commit_msg" =~ ^(feat|fix|docs|style|refactor|test|chore|ci|perf|build)(\(.+\))?: ]]; then
        echo "SUCCESS: Conventional commit format detected"
    else
        echo "INFO: Consider using conventional commit format: type(scope): description"
    fi

    return $validation_errors
}

# Export functions
export -f validate_constitutional_compliance
export -f validate_python_file validate_typescript_file validate_astro_file
export -f validate_json_file validate_yaml_file validate_markdown_file
export -f check_sensitive_data check_file_size validate_commit_message
