#!/usr/bin/env bash
# Detect orphaned systemd user services
# Finds services where the ExecStart target file/script no longer exists

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/issue_registry.sh"

# Check user-level systemd services
check_user_services() {
    local user_service_dir="$HOME/.config/systemd/user"

    [[ -d "$user_service_dir" ]] || return 0

    while IFS= read -r -d '' service_file; do
        [[ -z "$service_file" ]] && continue

        # Skip symlinks in .wants directories
        [[ "$service_file" == *".wants/"* ]] && continue

        # Extract ExecStart path
        local exec_line
        exec_line=$(grep "^ExecStart=" "$service_file" 2>/dev/null | head -1) || continue

        # Parse the executable path (handle = and potential whitespace)
        local exec_path
        exec_path=$(echo "$exec_line" | sed 's/^ExecStart=//' | awk '{print $1}')

        # Skip empty or special values
        [[ -z "$exec_path" ]] && continue
        [[ "$exec_path" == "-"* ]] && exec_path="${exec_path:1}"  # Remove leading -

        # Check if the target exists
        if [[ ! -e "$exec_path" ]]; then
            local service_name
            service_name=$(basename "$service_file" .service)

            # Build fix command
            local fix_cmd="systemctl --user stop $service_name.service 2>/dev/null; systemctl --user disable $service_name.service; rm '$service_file'; systemctl --user daemon-reload"

            format_issue \
                "$TYPE_ORPHANED_SERVICE" \
                "$SEVERITY_CRITICAL" \
                "$service_name" \
                "ExecStart target does not exist: $exec_path" \
                "YES" \
                "$fix_cmd"
        fi
    done < <(find "$user_service_dir" -maxdepth 1 -name "*.service" -type f -print0 2>/dev/null)
}

# Check system-level services for missing executables (less common but possible)
check_system_services() {
    # Only check services that are failing due to missing exec
    while read -r service_name; do
        [[ -z "$service_name" ]] && continue

        # Get the service file location
        local service_file
        service_file=$(systemctl show -p FragmentPath "$service_name" 2>/dev/null | cut -d= -f2)

        [[ -z "$service_file" || ! -f "$service_file" ]] && continue

        # Extract ExecStart
        local exec_path
        exec_path=$(grep "^ExecStart=" "$service_file" 2>/dev/null | head -1 | sed 's/^ExecStart=//' | awk '{print $1}')

        [[ -z "$exec_path" ]] && continue
        [[ "$exec_path" == "-"* ]] && exec_path="${exec_path:1}"

        # Check if target exists
        if [[ ! -e "$exec_path" ]]; then
            # This is a system service - needs investigation but can't auto-fix
            format_issue \
                "$TYPE_ORPHANED_SERVICE" \
                "$SEVERITY_CRITICAL" \
                "$service_name" \
                "System service ExecStart target missing: $exec_path" \
                "NO" \
                "Manual investigation required"
        fi
    done < <(systemctl --failed --no-legend 2>/dev/null | awk '{print $1}' | grep -v "^$")
}

# Main execution
check_user_services
# check_system_services  # Uncomment if you want to check system services too
