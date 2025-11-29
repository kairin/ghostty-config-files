#!/usr/bin/env bash
#
# Module: Glow - Install via APT
# Purpose: Install glow from Charm's official APT repository
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Constants
readonly CHARM_GPG_URL="https://repo.charm.sh/apt/gpg.key"
readonly CHARM_GPG_KEYRING="/etc/apt/keyrings/charm.gpg"
readonly CHARM_REPO_LIST="/etc/apt/sources.list.d/charm.list"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="glow-install"
    register_task "$task_id" "Installing glow via APT"
    start_task "$task_id"

    log "INFO" "Installing glow from Charm repository..."

    # Remove old glow if it exists
    if command -v glow >/dev/null 2>&1; then
        log "INFO" "Removing old glow installation..."
        local old_path
        old_path=$(command -v glow)

        case "$old_path" in
            /usr/bin/glow)
                sudo apt-get remove -y glow 2>&1 | tee -a "$(get_log_file)" || true
                ;;
            /snap/bin/glow)
                sudo snap remove glow 2>&1 | tee -a "$(get_log_file)" || true
                ;;
            "$HOME/.local/bin/glow")
                rm -f "$HOME/.local/bin/glow"
                ;;
            /usr/local/bin/glow)
                sudo rm -f "/usr/local/bin/glow"
                ;;
        esac
    fi

    # Check if Charm repository is already configured
    if [ -f "$CHARM_REPO_LIST" ] && [ -f "$CHARM_GPG_KEYRING" ]; then
        log "INFO" "  ✓ Charm repository already configured"
    else
        log "INFO" "Adding Charm repository..."
        echo "  ⠋ Creating keyrings directory..."
        sudo mkdir -p /etc/apt/keyrings

        echo "  ⠋ Downloading GPG key..."
        # Remove existing keyring to avoid interactive prompt from gpg --dearmor
        if [ -f "$CHARM_GPG_KEYRING" ]; then
            sudo rm -f "$CHARM_GPG_KEYRING"
        fi
        if ! curl -fsSL "$CHARM_GPG_URL" | sudo gpg --dearmor -o "$CHARM_GPG_KEYRING" 2>&1 | tee -a "$(get_log_file)"; then
            log "ERROR" "Failed to download Charm GPG key"
            complete_task "$task_id" 1
            exit 1
        fi

        echo "  ⠋ Adding repository to sources..."
        echo "deb [signed-by=$CHARM_GPG_KEYRING] https://repo.charm.sh/apt/ * *" | sudo tee "$CHARM_REPO_LIST" >/dev/null

        log "SUCCESS" "  ✓ Charm repository configured"
    fi

    # Update package lists
    log "INFO" "Updating package lists..."
    echo "  ⠋ Running apt update..."
    if ! sudo apt-get update 2>&1 | tee -a "$(get_log_file)" | grep -E "Reading package lists|Building dependency tree|Get:"; then
        log "WARNING" "apt update completed with warnings (non-critical)"
    fi

    # Install glow
    log "INFO" "Installing glow package..."
    echo "  ⠋ Installing glow..."
    if sudo apt-get install -y glow 2>&1 | tee -a "$(get_log_file)" | grep -E "Unpacking|Setting up|Processing"; then
        log "SUCCESS" "✓ Installed glow via APT"
        complete_task "$task_id" 0
        exit 0
    else
        log "ERROR" "Failed to install glow via APT"
        complete_task "$task_id" 1
        exit 1
    fi
}

main "$@"
