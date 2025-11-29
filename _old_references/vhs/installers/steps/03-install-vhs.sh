#!/usr/bin/env bash
#
# Module: VHS - Install VHS
# Purpose: Install VHS terminal recorder from Charm repository
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
    local task_id="vhs-install"
    register_task "$task_id" "Installing VHS"
    start_task "$task_id"

    log "INFO" "Installing VHS from Charm repository..."

    # Remove old VHS if it exists
    if command -v vhs >/dev/null 2>&1; then
        log "INFO" "Removing old VHS installation..."
        local old_path
        old_path=$(command -v vhs)

        case "$old_path" in
            /usr/bin/vhs)
                sudo apt-get remove -y vhs 2>&1 | tee -a "$(get_log_file)" || true
                ;;
            /snap/bin/vhs)
                sudo snap remove vhs 2>&1 | tee -a "$(get_log_file)" || true
                ;;
            "$HOME/.local/bin/vhs")
                rm -f "$HOME/.local/bin/vhs"
                ;;
            /usr/local/bin/vhs)
                sudo rm -f "/usr/local/bin/vhs"
                ;;
        esac
    fi

    # Check if Charm repository is already configured
    if [ -f "$CHARM_REPO_LIST" ]; then
        log "INFO" "  ✓ Charm repository already configured"
    else
        log "INFO" "Adding Charm repository..."
        echo "  ⠋ Creating keyrings directory..."
        sudo mkdir -p /etc/apt/keyrings

        echo "  ⠋ Downloading GPG key..."
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

    # Install VHS
    log "INFO" "Installing VHS package..."
    echo "  ⠋ Installing vhs..."
    if sudo apt-get install -y vhs 2>&1 | tee -a "$(get_log_file)" | grep -E "Unpacking|Setting up|Processing"; then
        log "SUCCESS" "✓ Installed VHS via APT"
        complete_task "$task_id" 0
        exit 0
    else
        log "ERROR" "Failed to install VHS via APT"
        complete_task "$task_id" 1
        exit 1
    fi
}

main "$@"
