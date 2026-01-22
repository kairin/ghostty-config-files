#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Installing fnm (Fast Node Manager)..."

# Install fnm
curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell

# Add to PATH temporarily for this script
export PATH="$HOME/.local/bin:$PATH"

if ! command -v fnm &> /dev/null; then
    log "ERROR" "fnm installation failed"
    exit 1
fi

log "SUCCESS" "fnm installed"

# Initialize fnm
eval "$(fnm env)"

log "INFO" "Installing Node.js v25..."
fnm install 25

log "INFO" "Setting Node.js v25 as default..."
fnm use 25
fnm default 25

NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)

log "SUCCESS" "Installed Node.js $NODE_VERSION"
log "SUCCESS" "Installed npm $NPM_VERSION"

# Optional Global npm Packages (DaisyUI/Tailwind)
# Set INSTALL_ASTRO_PACKAGES=1 to install global packages
if [[ "${INSTALL_ASTRO_PACKAGES:-0}" == "1" ]]; then
    log "INFO" "Installing global npm packages (DaisyUI + Tailwind)..."

    log "INFO" "Installing tailwindcss@latest..."
    npm install -g tailwindcss@latest

    log "INFO" "Installing @tailwindcss/vite@latest..."
    npm install -g @tailwindcss/vite@latest

    log "INFO" "Installing daisyui@latest..."
    npm install -g daisyui@latest

    # Verify installations
    GLOBAL_TW=$(npm list -g tailwindcss --depth=0 2>/dev/null | grep tailwindcss | sed 's/.*@//' || echo "failed")
    GLOBAL_DAISY=$(npm list -g daisyui --depth=0 2>/dev/null | grep daisyui | sed 's/.*@//' || echo "failed")
    GLOBAL_VITE=$(npm list -g @tailwindcss/vite --depth=0 2>/dev/null | grep vite | sed 's/.*@//' || echo "failed")

    if [[ "$GLOBAL_TW" != "failed" ]] && [[ "$GLOBAL_DAISY" != "failed" ]]; then
        log "SUCCESS" "Global packages installed:"
        log "SUCCESS" "  - tailwindcss: $GLOBAL_TW"
        log "SUCCESS" "  - daisyui: $GLOBAL_DAISY"
        log "SUCCESS" "  - @tailwindcss/vite: $GLOBAL_VITE"
    else
        log "WARNING" "Some global packages may not have installed correctly"
    fi
fi

# Configure shell (idempotent)
SHELL_CONFIG="$HOME/.zshrc"
if [ -f "$HOME/.bashrc" ]; then SHELL_CONFIG="$HOME/.bashrc"; fi

if ! grep -q "fnm env" "$SHELL_CONFIG"; then
    log "INFO" "Adding fnm to $SHELL_CONFIG..."
    echo '' >> "$SHELL_CONFIG"
    echo '# fnm' >> "$SHELL_CONFIG"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
    echo 'eval "$(fnm env --use-on-cd)"' >> "$SHELL_CONFIG"
fi

# ==============================================================================
# Verify PATH configuration
# ==============================================================================
log "INFO" "Verifying PATH configuration..."

# Ensure ~/.local/bin is in PATH for future sessions
if ! grep -q 'export PATH="\$HOME/.local/bin' "$SHELL_CONFIG"; then
    log "WARNING" "~/.local/bin not explicitly in PATH, ensuring it's added..."
    # Check if it's in a ghostty-config block (from configure_zsh.sh)
    if ! grep -q 'ghostty-config:local-bin' "$SHELL_CONFIG"; then
        echo '' >> "$SHELL_CONFIG"
        echo '# Ensure ~/.local/bin is in PATH' >> "$SHELL_CONFIG"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
        log "SUCCESS" "Added ~/.local/bin to PATH in $SHELL_CONFIG"
    fi
fi

log "SUCCESS" "Node.js installation complete!"
log "INFO" "  - fnm: $(fnm --version)"
log "INFO" "  - Node.js: $NODE_VERSION"
log "INFO" "  - npm: $NPM_VERSION"
log "INFO" ""
log "INFO" "To use in a new terminal, either:"
log "INFO" "  1. Run: source $SHELL_CONFIG"
log "INFO" "  2. Open a new terminal"
