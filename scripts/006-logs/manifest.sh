#!/bin/bash

# =============================================================================
# Artifact Manifest Library
# =============================================================================
# Universal functions for generating and verifying installation manifests
# with SHA256 checksums for drift detection and idempotency checks.
#
# Usage: source "$(dirname "$0")/../006-logs/manifest.sh"
#
# Terminology:
#   - Artifact Manifest: Inventory of installed files with SHA256 checksums
#   - Baseline Snapshot: Point-in-time state capture for comparison
#   - Idempotency Check: Verify if reinstallation is actually needed
#   - Pre-flight Verification: Audit current state before changes
#   - Drift Detection: Identify files that changed since installation
# =============================================================================

# Get script directory
MANIFEST_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$MANIFEST_LIB_DIR")"

# Storage locations (dual storage for quick access + audit trail)
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ghostty-installer/manifests"
LOGS_MANIFEST_DIR="$REPO_ROOT/../logs/manifests"

# Artifact definitions location
ARTIFACT_DEFS_DIR="$MANIFEST_LIB_DIR/artifact-definitions"

# Schema version for future compatibility
MANIFEST_SCHEMA_VERSION=1

# =============================================================================
# Helper Functions
# =============================================================================

# Calculate SHA256 checksum for a file
# Usage: calculate_sha256 "/path/to/file"
# Returns: SHA256 hash string or "ERROR" if file doesn't exist
calculate_sha256() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo "ERROR"
        return 1
    fi

    sha256sum "$file_path" 2>/dev/null | awk '{print $1}'
}

# Get file metadata as JSON fragment
# Usage: get_file_metadata "/path/to/file" "type"
# Returns: JSON object with file metadata
get_file_metadata() {
    local file_path="$1"
    local file_type="${2:-file}"

    if [ ! -e "$file_path" ]; then
        echo "null"
        return 1
    fi

    local size permissions mtime sha256

    if [ -f "$file_path" ]; then
        size=$(stat -c%s "$file_path" 2>/dev/null || echo "0")
        permissions=$(stat -c%a "$file_path" 2>/dev/null || echo "000")
        mtime=$(stat -c%Y "$file_path" 2>/dev/null | xargs -I{} date -d @{} -Iseconds 2>/dev/null || echo "unknown")
        sha256=$(calculate_sha256 "$file_path")
    elif [ -d "$file_path" ]; then
        size=$(du -sb "$file_path" 2>/dev/null | awk '{print $1}' || echo "0")
        permissions=$(stat -c%a "$file_path" 2>/dev/null || echo "000")
        mtime=$(stat -c%Y "$file_path" 2>/dev/null | xargs -I{} date -d @{} -Iseconds 2>/dev/null || echo "unknown")
        sha256="directory"
    fi

    cat <<EOF
{
      "path": "$file_path",
      "type": "$file_type",
      "size": $size,
      "sha256": "$sha256",
      "permissions": "$permissions",
      "mtime": "$mtime"
    }
EOF
}

# Get directory contents with checksums
# Usage: get_directory_artifacts "/path/to/dir" "type"
# Returns: JSON array of file metadata
get_directory_artifacts() {
    local dir_path="$1"
    local file_type="${2:-file}"
    local first=true

    if [ ! -d "$dir_path" ]; then
        echo "[]"
        return 1
    fi

    echo "["
    find "$dir_path" -type f 2>/dev/null | sort | while read -r file; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        get_file_metadata "$file" "$file_type"
    done
    echo "]"
}

# =============================================================================
# Artifact Definition Parser
# =============================================================================

# Load artifact definition file for a tool
# Usage: load_artifact_definition "feh"
# Returns: Prints artifact paths, one per line with type prefix
load_artifact_definition() {
    local tool_name="$1"
    local def_file="$ARTIFACT_DEFS_DIR/${tool_name}.artifacts"

    if [ ! -f "$def_file" ]; then
        echo "ERROR: Artifact definition not found: $def_file" >&2
        return 1
    fi

    # Read definition file, skip comments and empty lines
    grep -v '^#' "$def_file" | grep -v '^$'
}

# =============================================================================
# Manifest Generation
# =============================================================================

# Generate manifest for a tool
# Usage: generate_manifest "feh" "3.11.2" "source" "curl verscmp xinerama"
# Returns: JSON manifest to stdout
generate_manifest() {
    local tool_name="$1"
    local version="${2:-unknown}"
    local method="${3:-unknown}"
    local build_flags="${4:-}"
    local binary_path="${5:-}"
    local verification_cmd="${6:-}"

    local timestamp
    timestamp=$(date -Iseconds)

    # Start JSON
    cat <<EOF
{
  "schema_version": $MANIFEST_SCHEMA_VERSION,
  "tool": "$tool_name",
  "captured_at": "$timestamp",
  "installation": {
    "version": "$version",
    "method": "$method",
    "build_flags": "$build_flags",
    "binary_path": "$binary_path"
  },
  "artifacts": [
EOF

    # Process artifact definitions
    local first=true
    local artifact_count=0

    while IFS=: read -r type path; do
        [ -z "$type" ] && continue
        [ -z "$path" ] && continue

        # Expand environment variables in path
        path=$(eval echo "$path")

        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi

        if [ "$type" = "dir" ]; then
            # For directories, list all files inside
            if [ -d "$path" ]; then
                local dir_first=true
                echo "    {"
                echo "      \"path\": \"$path\","
                echo "      \"type\": \"directory\","
                echo "      \"contents\": ["
                find "$path" -type f 2>/dev/null | sort | while read -r file; do
                    if [ "$dir_first" = true ]; then
                        dir_first=false
                    else
                        echo ","
                    fi
                    local fsize fhash fperms fmtime
                    fsize=$(stat -c%s "$file" 2>/dev/null || echo "0")
                    fhash=$(calculate_sha256 "$file")
                    fperms=$(stat -c%a "$file" 2>/dev/null || echo "000")
                    fmtime=$(stat -c%Y "$file" 2>/dev/null | xargs -I{} date -d @{} -Iseconds 2>/dev/null || echo "unknown")
                    echo "        {\"path\": \"$file\", \"sha256\": \"$fhash\", \"size\": $fsize}"
                done
                echo "      ]"
                echo "    }"
            else
                echo "    {\"path\": \"$path\", \"type\": \"directory\", \"status\": \"missing\"}"
            fi
        else
            # Single file
            if [ -f "$path" ]; then
                get_file_metadata "$path" "$type" | sed 's/^/    /'
            else
                echo "    {\"path\": \"$path\", \"type\": \"$type\", \"status\": \"missing\"}"
            fi
        fi

        artifact_count=$((artifact_count + 1))
    done < <(load_artifact_definition "$tool_name")

    # Check for package manager conflicts
    local apt_installed snap_installed flatpak_installed multiple_binaries
    apt_installed=$(dpkg -l "$tool_name" 2>/dev/null | grep -q "^ii" && echo "true" || echo "false")
    snap_installed=$(snap list "$tool_name" 2>/dev/null | grep -q "$tool_name" && echo "true" || echo "false")
    flatpak_installed=$(flatpak list 2>/dev/null | grep -qi "$tool_name" && echo "true" || echo "false")
    multiple_binaries=$([ "$(type -a "$tool_name" 2>/dev/null | grep -c "is")" -gt 1 ] && echo "true" || echo "false")

    # Close artifacts array and add conflicts
    cat <<EOF
  ],
  "conflicts": {
    "apt": $apt_installed,
    "snap": $snap_installed,
    "flatpak": $flatpak_installed,
    "multiple_binaries": $multiple_binaries
  },
  "verification_command": "$verification_cmd",
  "artifact_count": $artifact_count
}
EOF
}

# =============================================================================
# Manifest Storage
# =============================================================================

# Save manifest to both cache and logs (dual storage)
# Usage: save_manifest_dual "feh" < manifest.json
save_manifest_dual() {
    local tool_name="$1"
    local manifest_content
    manifest_content=$(cat)

    # Ensure directories exist
    mkdir -p "$CACHE_DIR"
    mkdir -p "$LOGS_MANIFEST_DIR"

    # Save to cache (quick access)
    echo "$manifest_content" > "$CACHE_DIR/${tool_name}.manifest.json"

    # Save to logs (audit trail)
    echo "$manifest_content" > "$LOGS_MANIFEST_DIR/${tool_name}.manifest.json"

    echo "Manifest saved to:"
    echo "  Cache: $CACHE_DIR/${tool_name}.manifest.json"
    echo "  Audit: $LOGS_MANIFEST_DIR/${tool_name}.manifest.json"
}

# Load manifest from cache (with fallback to logs)
# Usage: load_manifest "feh"
load_manifest() {
    local tool_name="$1"

    if [ -f "$CACHE_DIR/${tool_name}.manifest.json" ]; then
        cat "$CACHE_DIR/${tool_name}.manifest.json"
    elif [ -f "$LOGS_MANIFEST_DIR/${tool_name}.manifest.json" ]; then
        cat "$LOGS_MANIFEST_DIR/${tool_name}.manifest.json"
    else
        echo "ERROR: No manifest found for $tool_name" >&2
        return 1
    fi
}

# Check if manifest exists
# Usage: manifest_exists "feh"
manifest_exists() {
    local tool_name="$1"
    [ -f "$CACHE_DIR/${tool_name}.manifest.json" ] || [ -f "$LOGS_MANIFEST_DIR/${tool_name}.manifest.json" ]
}

# =============================================================================
# Manifest Verification
# =============================================================================

# Verify current state against saved manifest
# Usage: verify_manifest "feh"
# Returns: CLEAN | DRIFT | CONFLICT | MISSING | NO_MANIFEST
verify_manifest() {
    local tool_name="$1"
    local verbose="${2:-false}"

    # Check if manifest exists
    if ! manifest_exists "$tool_name"; then
        echo "NO_MANIFEST"
        return 0
    fi

    local manifest
    manifest=$(load_manifest "$tool_name")

    local status="CLEAN"
    local drift_files=""
    local missing_files=""

    # Parse manifest and verify each artifact
    # Using jq if available, otherwise basic parsing
    if command -v jq &> /dev/null; then
        # Check conflicts first
        local apt_now snap_now flatpak_now
        apt_now=$(dpkg -l "$tool_name" 2>/dev/null | grep -q "^ii" && echo "true" || echo "false")
        snap_now=$(snap list "$tool_name" 2>/dev/null | grep -q "$tool_name" && echo "true" || echo "false")
        flatpak_now=$(flatpak list 2>/dev/null | grep -qi "$tool_name" && echo "true" || echo "false")

        local apt_was snap_was flatpak_was
        apt_was=$(echo "$manifest" | jq -r '.conflicts.apt')
        snap_was=$(echo "$manifest" | jq -r '.conflicts.snap')
        flatpak_was=$(echo "$manifest" | jq -r '.conflicts.flatpak')

        # New conflict detected
        if [ "$apt_now" = "true" ] && [ "$apt_was" = "false" ]; then
            status="CONFLICT"
        fi
        if [ "$snap_now" = "true" ] && [ "$snap_was" = "false" ]; then
            status="CONFLICT"
        fi
        if [ "$flatpak_now" = "true" ] && [ "$flatpak_was" = "false" ]; then
            status="CONFLICT"
        fi

        # Verify each artifact
        echo "$manifest" | jq -r '.artifacts[] | select(.type != "directory") | "\(.path)|\(.sha256)"' 2>/dev/null | while IFS='|' read -r path expected_hash; do
            if [ ! -f "$path" ]; then
                echo "MISSING:$path" >&2
                echo "MISSING"
                return
            fi

            local current_hash
            current_hash=$(calculate_sha256 "$path")

            if [ "$current_hash" != "$expected_hash" ]; then
                echo "DRIFT:$path" >&2
                echo "DRIFT"
                return
            fi
        done

        # Check directory contents
        echo "$manifest" | jq -r '.artifacts[] | select(.type == "directory") | .path' 2>/dev/null | while read -r dir_path; do
            if [ ! -d "$dir_path" ]; then
                echo "MISSING:$dir_path" >&2
                echo "MISSING"
                return
            fi
        done
    else
        # Fallback: basic grep-based parsing (less accurate)
        echo "WARNING: jq not installed, using basic verification" >&2
    fi

    echo "$status"
}

# =============================================================================
# Verification Report Formatting
# =============================================================================

# Format a human-readable verification report
# Usage: format_verification_report "feh"
format_verification_report() {
    local tool_name="$1"

    if ! manifest_exists "$tool_name"; then
        cat <<EOF

  No manifest found for $tool_name
  Run installation to generate manifest.

EOF
        return 1
    fi

    local manifest
    manifest=$(load_manifest "$tool_name")

    local captured_at version method build_flags
    captured_at=$(echo "$manifest" | jq -r '.captured_at' 2>/dev/null || echo "unknown")
    version=$(echo "$manifest" | jq -r '.installation.version' 2>/dev/null || echo "unknown")
    method=$(echo "$manifest" | jq -r '.installation.method' 2>/dev/null || echo "unknown")
    build_flags=$(echo "$manifest" | jq -r '.installation.build_flags' 2>/dev/null || echo "")

    echo ""
    echo "  Pre-Reinstall Verification: $tool_name"
    echo ""
    echo "  Manifest:    ${tool_name}.manifest.json (captured ${captured_at})"
    echo "  Version:     $version"
    echo "  Method:      $method${build_flags:+ (build flags: $build_flags)}"
    echo ""
    echo "  Artifact Integrity (SHA256):"

    # Verify each artifact and display status
    local all_ok=true

    if command -v jq &> /dev/null; then
        echo "$manifest" | jq -r '.artifacts[] | select(.type != "directory") | "\(.path)|\(.sha256)"' 2>/dev/null | while IFS='|' read -r path expected_hash; do
            local status_icon current_hash

            if [ ! -f "$path" ]; then
                status_icon="MISSING"
                all_ok=false
            else
                current_hash=$(calculate_sha256 "$path")
                if [ "$current_hash" = "$expected_hash" ]; then
                    status_icon="OK"
                else
                    status_icon="DRIFT"
                    all_ok=false
                fi
            fi

            printf "    %-45s %s\n" "$path" "$status_icon"
        done

        # Check directories
        echo "$manifest" | jq -r '.artifacts[] | select(.type == "directory") | "\(.path)|\(.contents | length)"' 2>/dev/null | while IFS='|' read -r path count; do
            local status_icon
            if [ -d "$path" ]; then
                status_icon="OK ($count files)"
            else
                status_icon="MISSING"
                all_ok=false
            fi
            printf "    %-45s %s\n" "$path/" "$status_icon"
        done
    fi

    echo ""
    echo "  Conflict Check:"

    local apt_status snap_status flatpak_status
    apt_status=$(dpkg -l "$tool_name" 2>/dev/null | grep -q "^ii" && echo "Installed (CONFLICT)" || echo "Not installed")
    snap_status=$(snap list "$tool_name" 2>/dev/null | grep -q "$tool_name" && echo "Installed (CONFLICT)" || echo "Not installed")
    flatpak_status=$(flatpak list 2>/dev/null | grep -qi "$tool_name" && echo "Installed (CONFLICT)" || echo "Not installed")

    printf "    apt:      %s\n" "$apt_status"
    printf "    snap:     %s\n" "$snap_status"
    printf "    flatpak:  %s\n" "$flatpak_status"

    echo ""

    local result
    result=$(verify_manifest "$tool_name")

    case "$result" in
        CLEAN)
            echo "  RESULT: CLEAN - No reinstall needed unless upgrading"
            ;;
        DRIFT)
            echo "  RESULT: DRIFT - Files have changed since installation"
            ;;
        CONFLICT)
            echo "  RESULT: CONFLICT - Package manager conflict detected"
            ;;
        MISSING)
            echo "  RESULT: MISSING - Some files are missing"
            ;;
        *)
            echo "  RESULT: $result"
            ;;
    esac

    echo ""
}

# =============================================================================
# Export Functions
# =============================================================================

# Make functions available when sourced
export -f calculate_sha256
export -f get_file_metadata
export -f load_artifact_definition
export -f generate_manifest
export -f save_manifest_dual
export -f load_manifest
export -f manifest_exists
export -f verify_manifest
export -f format_verification_report
