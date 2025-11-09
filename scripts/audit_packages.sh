#!/bin/bash
# Module: audit_packages.sh
# Purpose: Audit installed apt packages and identify snap/App Center alternatives
# Dependencies: apt, dpkg, snapd, jq, systemd
# Modules Required: common.sh, progress.sh
# Exit Codes: 0=success, 1=general failure, 2=invalid argument, 3=missing dependency

set -euo pipefail

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/progress.sh"

# ============================================================
# CONFIGURATION
# ============================================================

# Cache settings
CACHE_DIR="${HOME}/.config/package-migration/cache"
AUDIT_CACHE_FILE="${CACHE_DIR}/audit-cache.json"
CACHE_TTL_SECONDS="${CACHE_TTL:-3600}"  # Default 1 hour

# Snap API settings
SNAPD_SOCKET="/run/snapd.socket"
SNAPD_API_VERSION="v2"

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: audit_installed_packages
# Purpose: Detect all installed apt packages with metadata
# Args: None
# Returns: 0 on success, non-zero on failure
# Side Effects: Prints JSON array of PackageInstallationRecord objects to stdout
audit_installed_packages() {
    log_event INFO "Starting package audit..."

    require_command "dpkg-query" "dpkg is required for package auditing" || return 3

    local packages_json="[]"

    # Query all installed packages
    local package_list
    package_list=$(dpkg-query -W -f='${Package}\t${Version}\t${Installed-Size}\t${Architecture}\t${Status}\n' 2>/dev/null)

    log_event DEBUG "Found $(echo "$package_list" | wc -l) total package entries"

    # Filter only installed packages (Status = install ok installed)
    local installed_packages
    installed_packages=$(echo "$package_list" | grep "install ok installed$" || true)

    log_event INFO "Processing $(echo "$installed_packages" | wc -l) installed packages"

    # Build JSON array
    packages_json=$(echo "$installed_packages" | while IFS=$'\t' read -r pkg version size arch status; do
        # Get installation method (apt, snap, or manual)
        local install_method="apt"

        # Get configuration files
        local conffiles
        conffiles=$(dpkg-query -W -f='${Conffiles}\n' "$pkg" 2>/dev/null | grep -v "^$" | awk '{print $1}' | jq -R . | jq -s . 2>/dev/null || echo "[]")

        # Build package record
        cat <<EOF
{
  "name": "$pkg",
  "version": "$version",
  "install_method": "$install_method",
  "size_kb": ${size:-0},
  "architecture": "$arch",
  "config_files": $conffiles
}
EOF
    done | jq -s .)

    echo "$packages_json"
    return 0
}

# Function: detect_dependencies
# Purpose: Build full dependency graph for installed packages
# Args: $1=package_name
# Returns: 0 on success, non-zero on failure
# Side Effects: Prints JSON dependency tree to stdout
detect_dependencies() {
    local package_name="$1"

    require_command "dpkg-query" "dpkg is required for dependency analysis" || return 3
    require_command "apt-cache" "apt-cache is required for dependency analysis" || return 3

    log_event DEBUG "Analyzing dependencies for: $package_name"

    # Get direct dependencies
    local depends
    depends=$(dpkg-query -W -f='${Depends}\n' "$package_name" 2>/dev/null | tr ',' '\n' | awk '{print $1}' | grep -v "^$" || echo "")

    # Get reverse dependencies
    local rdepends
    rdepends=$(apt-cache rdepends "$package_name" 2>/dev/null | grep -v "^  " | grep -v "^$package_name" | tr -d ' ' || echo "")

    # Build dependency JSON
    local dep_json
    dep_json=$(cat <<EOF
{
  "package": "$package_name",
  "depends": $(echo "$depends" | jq -R . | jq -s . 2>/dev/null || echo "[]"),
  "rdepends": $(echo "$rdepends" | jq -R . | jq -s . 2>/dev/null || echo "[]")
}
EOF
)

    echo "$dep_json"
    return 0
}

# Function: detect_essential_services
# Purpose: Identify if package provides essential services or boot dependencies
# Args: $1=package_name
# Returns: 0=non-essential, 1=essential
# Side Effects: Prints JSON with essential status and reasons
detect_essential_services() {
    local package_name="$1"

    require_command "systemctl" "systemd is required for essential service detection" || return 3

    local is_essential=false
    local reasons=()

    # Check if package provides systemd services
    local service_files
    service_files=$(dpkg-query -L "$package_name" 2>/dev/null | grep ".service$" || true)

    if [[ -n "$service_files" ]]; then
        while IFS= read -r service_file; do
            local service_name
            service_name=$(basename "$service_file")

            # Check if service is enabled
            if systemctl is-enabled "$service_name" >/dev/null 2>&1; then
                is_essential=true
                reasons+=("provides enabled systemd service: $service_name")
            fi
        done <<< "$service_files"
    fi

    # Check if package is marked as essential by dpkg
    local essential_flag
    essential_flag=$(dpkg-query -W -f='${Essential}\n' "$package_name" 2>/dev/null || echo "no")

    if [[ "$essential_flag" == "yes" ]]; then
        is_essential=true
        reasons+=("marked as Essential by dpkg")
    fi

    # Check if package is in critical package list (init, kernel, bootloader)
    local critical_packages=("systemd" "linux-image" "grub" "gdm3" "network-manager" "dbus")
    for critical_pkg in "${critical_packages[@]}"; do
        if [[ "$package_name" == *"$critical_pkg"* ]]; then
            is_essential=true
            reasons+=("critical system package: $critical_pkg")
            break
        fi
    done

    # Build result JSON
    local reasons_json
    reasons_json=$(printf '%s\n' "${reasons[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")

    cat <<EOF
{
  "package": "$package_name",
  "is_essential": $is_essential,
  "reasons": $reasons_json
}
EOF

    [[ "$is_essential" == "true" ]] && return 1 || return 0
}

# Function: search_snap_alternatives
# Purpose: Query snapd API to find snap alternatives for apt package
# Args: $1=package_name
# Returns: 0 on success, non-zero on failure
# Side Effects: Prints JSON array of snap alternative candidates
search_snap_alternatives() {
    local package_name="$1"

    require_command "curl" "curl is required for snapd API access" || return 3

    log_event DEBUG "Searching snap alternatives for: $package_name"

    # Query snapd REST API via Unix socket
    local snap_search_result
    snap_search_result=$(curl -s --unix-socket "$SNAPD_SOCKET" "http://localhost/${SNAPD_API_VERSION}/find?q=${package_name}" 2>/dev/null || echo '{"result":[]}')

    # Extract results
    local snap_alternatives
    snap_alternatives=$(echo "$snap_search_result" | jq '.result // []')

    echo "$snap_alternatives"
    return 0
}

# Function: verify_snap_publisher
# Purpose: Verify snap publisher trust level (verified/starred/unverified)
# Args: $1=snap_data (JSON object from snapd API)
# Returns: 0=verified, 1=unverified
# Side Effects: Prints JSON with publisher validation status
verify_snap_publisher() {
    local snap_data="$1"

    # Extract publisher information
    local publisher_id
    publisher_id=$(echo "$snap_data" | jq -r '.publisher.id // "unknown"')

    local publisher_username
    publisher_username=$(echo "$snap_data" | jq -r '.publisher.username // "unknown"')

    local publisher_validation
    publisher_validation=$(echo "$snap_data" | jq -r '.publisher.validation // "unverified"')

    local is_verified=false
    if [[ "$publisher_validation" == "verified" ]] || [[ "$publisher_validation" == "starred" ]]; then
        is_verified=true
    fi

    cat <<EOF
{
  "publisher_id": "$publisher_id",
  "publisher_username": "$publisher_username",
  "validation_status": "$publisher_validation",
  "is_verified": $is_verified
}
EOF

    [[ "$is_verified" == "true" ]] && return 0 || return 1
}

# Function: calculate_equivalence_score
# Purpose: Calculate weighted equivalence score between apt and snap package
# Args: $1=apt_package_name, $2=apt_version, $3=snap_data (JSON)
# Returns: 0 on success
# Side Effects: Prints JSON with equivalence score and breakdown
calculate_equivalence_score() {
    local apt_pkg="$1"
    local apt_version="$2"
    local snap_data="$3"

    local snap_name
    snap_name=$(echo "$snap_data" | jq -r '.name // ""')

    local snap_version
    snap_version=$(echo "$snap_data" | jq -r '.version // ""')

    # Name matching score (20%)
    local name_score=0
    if [[ "$apt_pkg" == "$snap_name" ]]; then
        name_score=20  # Exact match
    elif [[ "$snap_name" == *"$apt_pkg"* ]] || [[ "$apt_pkg" == *"$snap_name"* ]]; then
        name_score=15  # Partial match
    else
        name_score=5   # Different names (might still be equivalent)
    fi

    # Version compatibility score (30%)
    local version_score=0
    if [[ "$apt_version" == "$snap_version" ]]; then
        version_score=30  # Exact version match
    elif [[ -n "$snap_version" ]]; then
        version_score=20  # Different version but snap exists
    else
        version_score=5   # No version info
    fi

    # Feature parity score (30%) - placeholder, will implement command checking later
    local feature_score=15  # Default medium score

    # Config compatibility score (20%) - placeholder
    local config_score=10  # Default medium score

    # Total equivalence score (0-100)
    local total_score=$((name_score + version_score + feature_score + config_score))

    cat <<EOF
{
  "apt_package": "$apt_pkg",
  "snap_name": "$snap_name",
  "total_score": $total_score,
  "breakdown": {
    "name_match": $name_score,
    "version_compat": $version_score,
    "feature_parity": $feature_score,
    "config_compat": $config_score
  }
}
EOF

    return 0
}

# Function: run_audit
# Purpose: Main audit function - orchestrates all audit operations
# Args: $1=output_format (text|json), $2=use_cache (true|false)
# Returns: 0 on success, non-zero on failure
# Side Effects: Prints audit report to stdout
run_audit() {
    local output_format="${1:-text}"
    local use_cache="${2:-true}"

    log_event INFO "Starting package migration audit..."

    # Check cache
    if [[ "$use_cache" == "true" ]] && [[ -f "$AUDIT_CACHE_FILE" ]]; then
        local cache_age
        cache_age=$(( $(date +%s) - $(stat -c %Y "$AUDIT_CACHE_FILE" 2>/dev/null || echo 0) ))

        if [[ $cache_age -lt $CACHE_TTL_SECONDS ]]; then
            log_event INFO "Using cached audit results (age: ${cache_age}s)"
            cat "$AUDIT_CACHE_FILE"
            return 0
        else
            log_event DEBUG "Cache expired (age: ${cache_age}s, TTL: ${CACHE_TTL_SECONDS}s)"
        fi
    fi

    # Perform fresh audit
    log_event INFO "Performing fresh package audit..."

    local packages
    packages=$(audit_installed_packages)

    log_event INFO "Package audit complete. Found $(echo "$packages" | jq 'length') packages"

    # Cache results
    mkdir -p "$CACHE_DIR"
    echo "$packages" > "$AUDIT_CACHE_FILE"

    # Output results
    if [[ "$output_format" == "json" ]]; then
        echo "$packages"
    else
        # Text format (TODO: implement pretty table formatting)
        echo "$packages" | jq -r '.[] | "\(.name)\t\(.version)\t\(.install_method)"'
    fi

    return 0
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # Parse command-line arguments
    output_format="text"
    use_cache="true"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                output_format="json"
                shift
                ;;
            --no-cache)
                use_cache="false"
                shift
                ;;
            --help|-h)
                cat <<EOF
Usage: $0 [OPTIONS]

Audit installed apt packages and identify snap/App Center alternatives.

OPTIONS:
    --json        Output results in JSON format (default: text)
    --no-cache    Force fresh audit, ignore cache
    --help, -h    Show this help message

EXAMPLES:
    $0                    # Run audit with text output
    $0 --json             # Run audit with JSON output
    $0 --no-cache --json  # Force fresh audit, output JSON

EOF
                exit 0
                ;;
            *)
                echo "ERROR: Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                exit 2
                ;;
        esac
    done

    # Run audit
    run_audit "$output_format" "$use_cache"
    exit $?
fi
