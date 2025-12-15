#!/bin/bash

# =============================================================================
# Universal Manifest Verifier (Pre-flight Check)
# =============================================================================
# Verifies current installation state against saved manifest.
# Use before reinstall to determine if action is needed.
#
# Usage: verify_manifest.sh <tool_name> [--verbose]
#
# Return codes:
#   0 = CLEAN (no reinstall needed)
#   1 = DRIFT (files changed)
#   2 = CONFLICT (package manager conflict)
#   3 = MISSING (files missing)
#   4 = NO_MANIFEST (no manifest exists)
#   5 = ERROR
#
# Output (pipe-delimited for scripting):
#   STATUS|TOOL|VERSION|DETAILS
#
# Example:
#   verify_manifest.sh feh
#   verify_manifest.sh feh --verbose
# =============================================================================

set -e

# Source the manifest library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/manifest.sh"

# =============================================================================
# Detailed Verification
# =============================================================================

verify_artifacts_detailed() {
    local tool_name="$1"
    local manifest="$2"

    local status="CLEAN"
    local drift_count=0
    local missing_count=0
    local ok_count=0

    # Process each artifact
    if command -v jq &> /dev/null; then
        # Get non-directory artifacts
        while IFS='|' read -r path expected_hash artifact_type; do
            [ -z "$path" ] && continue

            if [ ! -f "$path" ]; then
                echo "MISSING|$path" >&2
                missing_count=$((missing_count + 1))
                continue
            fi

            local current_hash
            current_hash=$(sha256sum "$path" 2>/dev/null | awk '{print $1}')

            if [ "$current_hash" != "$expected_hash" ]; then
                echo "DRIFT|$path|expected:${expected_hash:0:12}...|actual:${current_hash:0:12}..." >&2
                drift_count=$((drift_count + 1))
            else
                ok_count=$((ok_count + 1))
            fi
        done < <(echo "$manifest" | jq -r '.artifacts[] | select(.type != "directory") | select(.status != "missing") | "\(.path)|\(.sha256)|\(.type)"' 2>/dev/null)

        # Check directories
        while read -r dir_path; do
            [ -z "$dir_path" ] && continue

            if [ ! -d "$dir_path" ]; then
                echo "MISSING|$dir_path (directory)" >&2
                missing_count=$((missing_count + 1))
            else
                ok_count=$((ok_count + 1))
            fi
        done < <(echo "$manifest" | jq -r '.artifacts[] | select(.type == "directory") | .path' 2>/dev/null)
    fi

    # Determine overall status
    if [ $missing_count -gt 0 ]; then
        status="MISSING"
    elif [ $drift_count -gt 0 ]; then
        status="DRIFT"
    fi

    echo "$status|$ok_count|$drift_count|$missing_count"
}

check_conflicts() {
    local tool_name="$1"

    local conflicts=""

    # Check apt
    if dpkg -l "$tool_name" 2>/dev/null | grep -q "^ii"; then
        conflicts="${conflicts}apt,"
    fi

    # Check snap
    if snap list "$tool_name" 2>/dev/null | grep -q "$tool_name"; then
        conflicts="${conflicts}snap,"
    fi

    # Check flatpak
    if flatpak list 2>/dev/null | grep -qi "$tool_name"; then
        conflicts="${conflicts}flatpak,"
    fi

    # Check multiple binaries
    local bin_count
    bin_count=$(type -a "$tool_name" 2>/dev/null | grep -c "is" || echo "0")
    if [ "$bin_count" -gt 1 ]; then
        conflicts="${conflicts}multiple_binaries,"
    fi

    # Remove trailing comma
    echo "${conflicts%,}"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local tool_name="${1:-}"
    local verbose=false

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --verbose|-v)
                verbose=true
                ;;
        esac
    done

    # Validate arguments
    if [ -z "$tool_name" ] || [ "$tool_name" = "--verbose" ] || [ "$tool_name" = "-v" ]; then
        echo "Usage: verify_manifest.sh <tool_name> [--verbose]" >&2
        echo "" >&2
        echo "Available tools:" >&2
        ls -1 "$ARTIFACT_DEFS_DIR"/*.artifacts 2>/dev/null | xargs -I{} basename {} .artifacts | sed 's/^/  /' >&2
        exit 5
    fi

    # Check if manifest exists
    if ! manifest_exists "$tool_name"; then
        if [ "$verbose" = true ]; then
            echo ""
            echo "  No manifest found for $tool_name"
            echo "  Install the tool first to generate a manifest."
            echo ""
        fi
        echo "NO_MANIFEST|$tool_name||No manifest found"
        exit 4
    fi

    # Load manifest
    local manifest
    manifest=$(load_manifest "$tool_name")

    # Get manifest metadata
    local version captured_at method
    if command -v jq &> /dev/null; then
        version=$(echo "$manifest" | jq -r '.installation.version' 2>/dev/null || echo "unknown")
        captured_at=$(echo "$manifest" | jq -r '.captured_at' 2>/dev/null || echo "unknown")
        method=$(echo "$manifest" | jq -r '.installation.method' 2>/dev/null || echo "unknown")
    else
        version="unknown"
        captured_at="unknown"
        method="unknown"
    fi

    # Check for conflicts
    local conflicts
    conflicts=$(check_conflicts "$tool_name")

    if [ -n "$conflicts" ]; then
        if [ "$verbose" = true ]; then
            echo ""
            echo "  CONFLICT DETECTED for $tool_name"
            echo "  Conflicting installations: $conflicts"
            echo ""
        fi
        echo "CONFLICT|$tool_name|$version|Conflicts: $conflicts"
        exit 2
    fi

    # Verify artifacts
    local verification_result
    verification_result=$(verify_artifacts_detailed "$tool_name" "$manifest" 2>/dev/null)

    local status ok_count drift_count missing_count
    IFS='|' read -r status ok_count drift_count missing_count <<< "$verification_result"

    # Verbose output
    if [ "$verbose" = true ]; then
        echo ""
        echo "  Pre-Reinstall Verification: $tool_name"
        echo ""
        echo "  Manifest:    ${tool_name}.manifest.json"
        echo "  Captured:    $captured_at"
        echo "  Version:     $version"
        echo "  Method:      $method"
        echo ""
        echo "  Artifact Integrity (SHA256):"
        echo "    OK:      $ok_count files"
        echo "    Drift:   $drift_count files"
        echo "    Missing: $missing_count files"
        echo ""

        # Show conflict status
        echo "  Conflict Check:"
        local apt_status snap_status flatpak_status
        apt_status=$(dpkg -l "$tool_name" 2>/dev/null | grep -q "^ii" && echo "INSTALLED" || echo "Not installed")
        snap_status=$(snap list "$tool_name" 2>/dev/null | grep -q "$tool_name" && echo "INSTALLED" || echo "Not installed")
        flatpak_status=$(flatpak list 2>/dev/null | grep -qi "$tool_name" && echo "INSTALLED" || echo "Not installed")
        echo "    apt:      $apt_status"
        echo "    snap:     $snap_status"
        echo "    flatpak:  $flatpak_status"
        echo ""

        # Result message
        case "$status" in
            CLEAN)
                echo "  RESULT: CLEAN - No reinstall needed unless upgrading"
                ;;
            DRIFT)
                echo "  RESULT: DRIFT - $drift_count file(s) have changed since installation"
                ;;
            MISSING)
                echo "  RESULT: MISSING - $missing_count file(s) are missing"
                ;;
        esac
        echo ""
    fi

    # Output result
    case "$status" in
        CLEAN)
            echo "CLEAN|$tool_name|$version|All $ok_count artifacts verified"
            exit 0
            ;;
        DRIFT)
            echo "DRIFT|$tool_name|$version|$drift_count files changed"
            exit 1
            ;;
        MISSING)
            echo "MISSING|$tool_name|$version|$missing_count files missing"
            exit 3
            ;;
        *)
            echo "ERROR|$tool_name|$version|Unknown status: $status"
            exit 5
            ;;
    esac
}

# Run main
main "$@"
