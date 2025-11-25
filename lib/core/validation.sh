#!/usr/bin/env bash
# lib/core/validation.sh - Common validation utilities (Orchestrator)
# Provides unified validation API by sourcing specialized modules
#
# This file acts as an orchestrator, sourcing modular components:
# - lib/core/validation/files.sh - File and directory validation
# - lib/core/validation/input.sh - Input and data validation

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_CORE_VALIDATION_SOURCED:-}" ]] && return 0
readonly _CORE_VALIDATION_SOURCED=1

# Determine script directory for relative sourcing
SCRIPT_DIR="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="${SCRIPT_DIR%/*}"

# Source modular components
# shellcheck source=lib/core/validation/files.sh
if [[ -f "${SCRIPT_DIR}/validation/files.sh" ]]; then
    source "${SCRIPT_DIR}/validation/files.sh"
fi

# shellcheck source=lib/core/validation/input.sh
if [[ -f "${SCRIPT_DIR}/validation/input.sh" ]]; then
    source "${SCRIPT_DIR}/validation/input.sh"
fi

# Re-export all functions from sourced modules for backward compatibility
# This ensures existing code that sources validation.sh continues to work

# File validation functions (from validation/files.sh)
export -f require_file 2>/dev/null || true
export -f require_dir 2>/dev/null || true
export -f ensure_dir 2>/dev/null || true
export -f is_writable 2>/dev/null || true
export -f is_readable 2>/dev/null || true
export -f is_executable 2>/dev/null || true
export -f path_exists 2>/dev/null || true
export -f is_symlink 2>/dev/null || true
export -f get_file_size 2>/dev/null || true
export -f get_file_mtime 2>/dev/null || true
export -f is_file_newer 2>/dev/null || true
export -f validate_shell_syntax 2>/dev/null || true

# Input validation functions (from validation/input.sh)
export -f command_exists 2>/dev/null || true
export -f require_command 2>/dev/null || true
export -f validate_dependencies 2>/dev/null || true
export -f validate_json 2>/dev/null || true
export -f validate_yaml 2>/dev/null || true
export -f is_integer 2>/dev/null || true
export -f is_positive_integer 2>/dev/null || true
export -f is_non_negative_integer 2>/dev/null || true
export -f is_boolean 2>/dev/null || true
export -f is_valid_url 2>/dev/null || true
export -f is_valid_email 2>/dev/null || true
export -f is_valid_semver 2>/dev/null || true
export -f is_valid_ipv4 2>/dev/null || true
export -f is_not_empty 2>/dev/null || true
export -f matches_pattern 2>/dev/null || true
