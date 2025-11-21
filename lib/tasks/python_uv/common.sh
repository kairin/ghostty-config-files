#!/usr/bin/env bash
#
# Module: Python UV Common
# Purpose: Shared variables and functions for Python UV tasks
#
# Context7 Best Practices (2025):
# - UV is 10-100x faster than pip (Astral Systems)
# - Constitutional requirement: UV EXCLUSIVE (no pip/poetry/pipenv)
# - XDG-compliant installation (~/.local/bin/uv)
# - Official installer: https://astral.sh/uv/install.sh
#
set -euo pipefail

# Source core libraries if not already sourced
if [ -z "${REPO_ROOT:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../../init.sh"
fi

# Installation constants
export UV_INSTALL_URL="https://astral.sh/uv/install.sh"
export UV_BIN_DIR="${HOME}/.local/bin"
export UV_BINARY="${UV_BIN_DIR}/uv"

# Conflicting package managers (constitutional prohibition)
export PYTHON_CONFLICTING_MANAGERS=(
    "pip"
    "pip3"
    "poetry"
    "pipenv"
    "pdm"
)

# Verification functions
verify_uv_not_installed() {
    [ ! -f "$UV_BINARY" ]
}

verify_uv_binary() {
    [ -f "$UV_BINARY" ] && [ -x "$UV_BINARY" ]
}

verify_uv_version() {
    command_exists "uv" && uv --version &>/dev/null
}

verify_python_uv() {
    verify_uv_binary && verify_uv_version
}

# Export verification functions
export -f verify_uv_not_installed
export -f verify_uv_binary
export -f verify_uv_version
export -f verify_python_uv
