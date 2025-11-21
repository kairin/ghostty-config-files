#!/usr/bin/env bash
#
# Module: Ghostty - Configure
# Purpose: Configure Ghostty
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
    local task_id="configure-ghostty"
    register_task "$task_id" "Configuring Ghostty"
    start_task "$task_id"

    local config_dir="$HOME/.config/ghostty"
    mkdir -p "$config_dir"

    # Copy configuration from repository if available
    local repo_config="${REPO_ROOT}/configs/ghostty/config"
    
    if [ -f "$repo_config" ]; then
        cp "$repo_config" "$config_dir/config"
        log "SUCCESS" "Configuration copied from repository"
    else
        # Create basic configuration
        cat > "$config_dir/config" <<EOF
# Ghostty Configuration (Generated)
# Performance optimizations (2025)
linux-cgroup = single-instance

# Shell integration
shell-integration = detect
shell-integration-features = true

# Theme
theme = catppuccin-mocha

# Font
font-family = "JetBrains Mono"
font-size = 12

# Scrollback
scrollback-limit = 999999999

# Clipboard
clipboard-paste-protection = true
EOF
        log "SUCCESS" "Basic configuration created"
    fi

    complete_task "$task_id"
    exit 0
}

main "$@"
