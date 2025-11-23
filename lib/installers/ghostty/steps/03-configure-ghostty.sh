#!/usr/bin/env bash
#
# Module: Ghostty - Configure Settings
# Purpose: Apply Ghostty configuration from repository
#
set -eo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="ghostty-configure"
    register_task "$task_id" "Configuring Ghostty"
    start_task "$task_id"

    # Create config directory if it doesn't exist
    if [ ! -d "$GHOSTTY_CONFIG_DIR" ]; then
        log "INFO" "Creating Ghostty config directory: $GHOSTTY_CONFIG_DIR"
        mkdir -p "$GHOSTTY_CONFIG_DIR"
    fi

    # Copy configuration files from repository
    local repo_config_dir="${REPO_ROOT}/configs/ghostty"

    if [ ! -d "$repo_config_dir" ]; then
        log "ERROR" "Repository config directory not found: $repo_config_dir"
        fail_task "$task_id" "config directory missing"
        exit 1
    fi

    log "INFO" "Applying Ghostty configuration from repository..."

    # Copy all config files
    local copied=0
    for config_file in "$repo_config_dir"/*.conf; do
        if [ -f "$config_file" ]; then
            local filename
            filename=$(basename "$config_file")

            log "INFO" "Copying $filename..."
            if cp "$config_file" "$GHOSTTY_CONFIG_DIR/$filename" 2>/dev/null; then
                log "SUCCESS" "Applied $filename"
                ((copied++))
            else
                log "WARNING" "Could not copy $filename"
            fi
        fi
    done

    if [ $copied -gt 0 ]; then
        log "SUCCESS" "Applied $copied configuration files"
        complete_task "$task_id"
        exit 0
    else
        log "WARNING" "No configuration files were copied"
        skip_task "$task_id" "no files copied"
        exit 2
    fi
}

main "$@"
