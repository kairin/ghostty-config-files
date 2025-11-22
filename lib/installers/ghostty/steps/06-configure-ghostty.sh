#!/usr/bin/env bash
#
# Module: Ghostty - Configure
# Purpose: Configure Ghostty
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

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

    # Copy all configuration files from repository
    local repo_config_dir="${REPO_ROOT}/configs/ghostty"

    if [ -d "$repo_config_dir" ]; then
        log "INFO" "Copying Ghostty configurations from repository..."

        # List of config files to copy
        local config_files=(
            "config"
            "theme.conf"
            "scroll.conf"
            "layout.conf"
            "keybindings.conf"
        )

        local copied_count=0
        for config_file in "${config_files[@]}"; do
            if [ -f "$repo_config_dir/$config_file" ]; then
                cp "$repo_config_dir/$config_file" "$config_dir/$config_file"
                log "SUCCESS" "Copied: $config_file"
                copied_count=$((copied_count + 1))
            else
                log "WARNING" "Template not found: $config_file (will use defaults)"
            fi
        done

        log "SUCCESS" "Copied $copied_count configuration files from repository"
    else
        # Fallback: Create minimal configurations if repo templates don't exist
        log "WARNING" "Repository config templates not found, creating minimal configs..."

        # Main config
        cat > "$config_dir/config" <<'EOF'
# Ghostty Configuration (Generated)
# Performance optimizations (2025)
linux-cgroup = single-instance

# Shell integration
shell-integration = detect
shell-integration-features = sudo,title,ssh-env

# Security
clipboard-paste-protection = true

# Modular configuration
config-file = theme.conf
config-file = scroll.conf
config-file = layout.conf
config-file = keybindings.conf
EOF

        # Theme
        cat > "$config_dir/theme.conf" <<'EOF'
# Theme
theme = catppuccin-mocha
background-opacity = 0.75
EOF

        # Scroll
        cat > "$config_dir/scroll.conf" <<'EOF'
# Scrollback
scrollback-limit = 10000
EOF

        # Layout
        cat > "$config_dir/layout.conf" <<'EOF'
# Font
font-family = monospace
font-size = 14

# Padding
window-padding-x = 10
window-padding-y = 10
EOF

        # Keybindings
        cat > "$config_dir/keybindings.conf" <<'EOF'
# Custom Keybindings
keybind = ctrl+shift+t=new_tab
keybind = ctrl+alt+d=new_split:right
EOF

        log "SUCCESS" "Created minimal configuration files"
    fi

    complete_task "$task_id"
    exit 0
}

main "$@"
