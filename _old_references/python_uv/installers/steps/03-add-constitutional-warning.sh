#!/usr/bin/env bash
#
# Module: Add Constitutional Compliance Warning
# Purpose: Add warning about UV-exclusive policy to shell RC files
# Prerequisites: Shell RC files exist
# Outputs: Updated .zshrc/.bashrc with constitutional warning
# Exit Codes:
#   0 - Warning added successfully
#   1 - Failed to add warning
#   2 - Already added (skip)
#
# Context7 Best Practices:
# - Document constitutional requirements in user environment
# - Provide clear usage examples
# - Remind users of prohibited commands
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Adding constitutional compliance warning..."

    local warning_block='
# ═══════════════════════════════════════════════════════════════
# CONSTITUTIONAL COMPLIANCE: UV EXCLUSIVE PYTHON PACKAGE MANAGER
# ═══════════════════════════════════════════════════════════════
# This project uses UV (Astral Systems) as the EXCLUSIVE Python package manager.
#
# PROHIBITED COMMANDS: pip, pip3, python -m pip, poetry, pipenv
#
# Usage:
#   uv pip install <package>     # Install package
#   uv pip uninstall <package>   # Remove package
#   uv pip list                  # List installed packages
#   uv pip freeze                # Generate requirements.txt
#   uv venv                      # Create virtual environment
#
# Documentation: https://github.com/astral-sh/uv
# ═══════════════════════════════════════════════════════════════
'

    local added_count=0

    for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [ ! -f "$rc_file" ]; then
            continue
        fi

        if grep -q "CONSTITUTIONAL COMPLIANCE: UV EXCLUSIVE" "$rc_file" 2>/dev/null; then
            log "INFO" "  ↷ Constitutional warning already in $rc_file"
        else
            echo "$warning_block" >> "$rc_file"
            log "INFO" "  ✓ Added constitutional warning to $rc_file"
            added_count=$((added_count + 1))
        fi
    done

    if [ $added_count -gt 0 ]; then
        log "SUCCESS" "✓ Constitutional compliance warnings added"
        exit 0
    else
        log "INFO" "↷ All warnings already present"
        exit 2
    fi
}

main "$@"
