#!/usr/bin/env bash
#
# Module: Ghostty - Create Desktop Entry
# Purpose: Create desktop entry for Ghostty
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="create-desktop-entry"
    register_task "$task_id" "Creating desktop entry"
    start_task "$task_id"

    local desktop_dir="$HOME/.local/share/applications"
    mkdir -p "$desktop_dir"

    cat > "$desktop_dir/ghostty.desktop" <<EOF
[Desktop Entry]
Name=Ghostty
Comment=Fast, native, feature-rich terminal emulator
Exec=$GHOSTTY_INSTALL_DIR/bin/ghostty
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
StartupNotify=true
EOF

    chmod +x "$desktop_dir/ghostty.desktop"
    log "SUCCESS" "Desktop entry created at $desktop_dir/ghostty.desktop"

    complete_task "$task_id"
    exit 0
}

main "$@"
