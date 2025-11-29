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
