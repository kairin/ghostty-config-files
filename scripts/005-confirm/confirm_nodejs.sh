#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming Node.js installation..."

# We need to ensure fnm is available
export PATH="$HOME/.local/bin:$PATH"
if command -v fnm &> /dev/null; then
    eval "$(fnm env)"
fi

if command -v node &> /dev/null; then
    VERSION=$(node -v)
    log "SUCCESS" "Node.js is installed: $VERSION"
    
    if [[ "$VERSION" == v25* ]]; then
        log "SUCCESS" "Version check passed (v25)"
    else
        log "WARNING" "Version mismatch: Expected v25, got $VERSION"
    fi

    # Verify global packages if they were installed
    if [[ "${INSTALL_ASTRO_PACKAGES:-0}" == "1" ]]; then
        log "INFO" "Verifying global npm packages..."

        PKGS_OK=1

        if npm list -g tailwindcss &> /dev/null; then
            TW_VER=$(npm list -g tailwindcss --depth=0 2>/dev/null | grep tailwindcss | sed 's/.*@//')
            log "SUCCESS" "tailwindcss installed: $TW_VER"
        else
            log "WARNING" "tailwindcss not found globally"
            PKGS_OK=0
        fi

        if npm list -g daisyui &> /dev/null; then
            DAISY_VER=$(npm list -g daisyui --depth=0 2>/dev/null | grep daisyui | sed 's/.*@//')
            log "SUCCESS" "daisyui installed: $DAISY_VER"
        else
            log "WARNING" "daisyui not found globally"
            PKGS_OK=0
        fi

        if npm list -g @tailwindcss/vite &> /dev/null; then
            VITE_VER=$(npm list -g @tailwindcss/vite --depth=0 2>/dev/null | grep vite | sed 's/.*@//')
            log "SUCCESS" "@tailwindcss/vite installed: $VITE_VER"
        else
            log "WARNING" "@tailwindcss/vite not found globally"
            PKGS_OK=0
        fi
    fi

    # Generate artifact manifest for future verification
    SCRIPT_DIR="$(dirname "$0")"
    VERSION_NUM=$(echo "$VERSION" | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    "$SCRIPT_DIR/generate_manifest.sh" nodejs "$VERSION_NUM" fnm > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
    log "SUCCESS" "Artifact manifest generated for pre-reinstall verification"

    exit 0
else
    log "ERROR" "Node.js binary not found"
    exit 1
fi
