#!/usr/bin/env bash
#
# Module: Gum - Install Latest Version
# Purpose: Install latest gum from apt or GitHub releases
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Constants
readonly GUM_BINARY_URL="https://github.com/charmbracelet/gum/releases/latest/download/gum_Linux_x86_64.tar.gz"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="gum-install"
    register_task "$task_id" "Installing latest gum"
    start_task "$task_id"

    log "INFO" "Installing latest gum TUI framework..."

    # Remove old gum if it exists
    # Remove old gum if it exists
    if command -v gum >/dev/null 2>&1; then
        log "INFO" "Removing old gum installation..."
        local old_path
        old_path=$(command -v gum)

        case "$old_path" in
            /usr/bin/gum)
                sudo apt-get remove -y gum 2>&1 | tee -a "$(get_log_file)" || true
                ;;
            /snap/bin/gum)
                sudo snap remove gum 2>&1 | tee -a "$(get_log_file)" || true
                ;;
            "$HOME/.local/bin/gum")
                rm -f "$HOME/.local/bin/gum"
                ;;
            "/usr/local/bin/gum")
                sudo rm -f "/usr/local/bin/gum"
                ;;
        esac
    fi
    
    # Explicitly check for snap even if not in PATH
    if snap list gum >/dev/null 2>&1; then
        log "INFO" "Removing gum snap..."
        sudo snap remove gum 2>&1 | tee -a "$(get_log_file)" || true
    fi

    # Try apt first (official package)
    log "INFO" "Attempting installation via apt..."
    echo "  ⠋ Updating package lists..."

    if sudo apt-get update 2>&1 | tee -a "$(get_log_file)" | grep -E "Reading package lists|Building dependency tree|Get:"; then
        :
    fi

    echo "  ⠋ Installing gum package..."
    if sudo apt-get install -y gum 2>&1 | tee -a "$(get_log_file)" | grep -E "Unpacking|Setting up|Processing"; then
        log "SUCCESS" "✓ Installed latest gum via apt"
        complete_task "$task_id" 0
        exit 0
    fi

    # Fallback: Binary installation
    log "WARNING" "apt installation failed, using binary download..."
    echo "  ⠋ Downloading latest gum from GitHub releases..."

    local temp_dir
    temp_dir=$(mktemp -d)
    local tar_file="$temp_dir/gum.tar.gz"

    if ! curl -fL --progress-bar "$GUM_BINARY_URL" -o "$tar_file" 2>&1; then
        log "ERROR" "Failed to download gum binary"
        complete_task "$task_id" 1
        exit 1
    fi

    # Extract binary
    echo "  ⠋ Extracting gum binary..."
    if ! tar -xzf "$tar_file" -C "$temp_dir"; then
        log "ERROR" "Failed to extract gum binary"
        rm -rf "$temp_dir"
        complete_task "$task_id" 1
        exit 1
    fi

    # Install to ~/.local/bin
    echo "  ⠋ Installing binary to ~/.local/bin..."
    mkdir -p "$HOME/.local/bin"
    if ! cp "$temp_dir/gum" "$HOME/.local/bin/gum"; then
        log "ERROR" "Failed to install gum binary"
        rm -rf "$temp_dir"
        complete_task "$task_id" 1
        exit 1
    fi

    chmod +x "$HOME/.local/bin/gum"
    rm -rf "$temp_dir"

    log "SUCCESS" "✓ Installed latest gum via binary download"

    # Add to PATH if not already
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"

        for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
            if [ -f "$rc_file" ] && ! grep -q "\.local/bin" "$rc_file"; then
                {
                    echo ""
                    echo "# gum TUI framework (added by installer)"
                    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
                } >> "$rc_file"
                log "INFO" "  ✓ Updated $rc_file"
            fi
        done
    fi

    complete_task "$task_id" 0
    exit 0
}

main "$@"
