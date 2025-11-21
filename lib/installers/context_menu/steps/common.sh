#!/usr/bin/env bash
set -euo pipefail
if [ -z "${REPO_ROOT:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")" /../../init.sh"
fi

export NAUTILUS_SCRIPTS_DIR="${HOME}/.local/share/nautilus/scripts"
export GHOSTTY_SCRIPT="${NAUTILUS_SCRIPTS_DIR}/Open in Ghostty"

verify_nautilus_installed() { command_exists "nautilus"; }
verify_context_menu_script() { [ -f "$GHOSTTY_SCRIPT" ] && [ -x "$GHOSTTY_SCRIPT" ]; }
verify_context_menu_works() { verify_nautilus_installed && verify_context_menu_script; }

export -f verify_nautilus_installed verify_context_menu_script verify_context_menu_works
