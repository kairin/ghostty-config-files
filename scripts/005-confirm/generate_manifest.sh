#!/bin/bash

# =============================================================================
# Universal Manifest Generator
# =============================================================================
# Generates artifact manifests for any tool after successful installation.
# Saves to both cache (quick access) and logs (audit trail).
#
# Usage: generate_manifest.sh <tool_name> [version] [method] [build_flags]
#
# Example:
#   generate_manifest.sh feh 3.11.2 source "curl verscmp xinerama"
#   generate_manifest.sh ghostty 1.2.3 source
#   generate_manifest.sh gum 0.14.0 go-install
# =============================================================================

set -e

# Source the manifest library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/manifest.sh"
source "$SCRIPT_DIR/../006-logs/logger.sh"

# =============================================================================
# Main
# =============================================================================

main() {
    local tool_name="${1:-}"
    local version="${2:-unknown}"
    local method="${3:-unknown}"
    local build_flags="${4:-}"

    # Validate arguments
    if [ -z "$tool_name" ]; then
        log "ERROR" "Usage: generate_manifest.sh <tool_name> [version] [method] [build_flags]"
        exit 1
    fi

    # Check if artifact definition exists
    local def_file="$ARTIFACT_DEFS_DIR/${tool_name}.artifacts"
    if [ ! -f "$def_file" ]; then
        log "ERROR" "Artifact definition not found: $def_file"
        log "INFO" "Available tools:"
        ls -1 "$ARTIFACT_DEFS_DIR"/*.artifacts 2>/dev/null | xargs -I{} basename {} .artifacts | sed 's/^/  - /'
        exit 1
    fi

    log "INFO" "Generating manifest for $tool_name..."

    # Try to auto-detect version if not provided
    if [ "$version" = "unknown" ]; then
        case "$tool_name" in
            feh)
                version=$(feh --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
                ;;
            ghostty)
                version=$(ghostty --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
                ;;
            gum)
                version=$(gum --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
                ;;
            glow)
                version=$(glow --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
                ;;
            vhs)
                version=$(vhs --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
                ;;
            go)
                version=$(go version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
                ;;
            nodejs)
                version=$(node --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
                ;;
            python_uv)
                version=$(uv --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
                ;;
            zsh)
                version=$(zsh --version 2>/dev/null | grep -oP '\d+\.\d+' || echo "unknown")
                ;;
            fastfetch)
                version=$(fastfetch --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
                ;;
        esac
        log "INFO" "Auto-detected version: $version"
    fi

    # Try to auto-detect binary path
    local binary_path
    binary_path=$(command -v "$tool_name" 2>/dev/null || echo "")

    # Try to auto-detect build flags for feh
    if [ "$tool_name" = "feh" ] && [ -z "$build_flags" ]; then
        build_flags=$(feh --version 2>/dev/null | grep -i "compile-time" | sed 's/.*: //' || echo "")
    fi

    # Generate verification command
    local verification_cmd="${tool_name} --version"

    # Generate the manifest
    local manifest
    manifest=$(generate_manifest "$tool_name" "$version" "$method" "$build_flags" "$binary_path" "$verification_cmd")

    # Validate JSON (if jq available)
    if command -v jq &> /dev/null; then
        if ! echo "$manifest" | jq . > /dev/null 2>&1; then
            log "ERROR" "Generated manifest is not valid JSON"
            echo "$manifest"
            exit 1
        fi
    fi

    # Save to both locations
    echo "$manifest" | save_manifest_dual "$tool_name"

    # Count artifacts
    local artifact_count
    if command -v jq &> /dev/null; then
        artifact_count=$(echo "$manifest" | jq '.artifact_count' 2>/dev/null || echo "unknown")
    else
        artifact_count="unknown"
    fi

    log "SUCCESS" "Manifest generated for $tool_name"
    log "INFO" "  Version: $version"
    log "INFO" "  Method: $method"
    log "INFO" "  Artifacts: $artifact_count"

    # Print summary
    echo ""
    echo "Manifest Summary:"
    echo "  Tool:      $tool_name"
    echo "  Version:   $version"
    echo "  Method:    $method"
    echo "  Artifacts: $artifact_count items tracked"
    echo ""
}

# Run main
main "$@"
