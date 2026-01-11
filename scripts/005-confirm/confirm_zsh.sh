#!/bin/bash
# confirm_zsh.sh - Verify ZSH, Oh My Zsh, Powerlevel10k, plugins, and configuration
source "$(dirname "$0")/../006-logs/logger.sh"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
ZSHRC="$HOME/.zshrc"
ERRORS=0

log "INFO" "Confirming ZSH environment installation..."
log "INFO" ""

# ==============================================================================
# 1. Check ZSH Binary
# ==============================================================================
log "INFO" "[1/7] Checking ZSH binary..."
if command -v zsh &> /dev/null; then
    VERSION=$(zsh --version 2>/dev/null | head -1)
    PATH_LOC=$(command -v zsh)
    log "SUCCESS" "ZSH installed at $PATH_LOC"
    log "INFO" "        Version: $VERSION"
else
    log "ERROR" "ZSH is NOT installed"
    ((ERRORS++))
fi

# ==============================================================================
# 2. Check Oh My Zsh
# ==============================================================================
log "INFO" "[2/7] Checking Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    log "SUCCESS" "Oh My Zsh installed at $HOME/.oh-my-zsh"

    # Check if it's a git repo (for updates)
    if [ -d "$HOME/.oh-my-zsh/.git" ]; then
        OMZ_COMMIT=$(git -C "$HOME/.oh-my-zsh" rev-parse --short HEAD 2>/dev/null)
        log "INFO" "        Git commit: $OMZ_COMMIT"
    fi
else
    log "ERROR" "Oh My Zsh is NOT installed"
    ((ERRORS++))
fi

# ==============================================================================
# 3. Check Powerlevel10k
# ==============================================================================
log "INFO" "[3/7] Checking Powerlevel10k theme..."
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
    log "SUCCESS" "Powerlevel10k installed at $P10K_DIR"

    # Check version
    if [ -f "$P10K_DIR/powerlevel10k.zsh-theme" ]; then
        P10K_VERSION=$(grep -m1 'typeset -g POWERLEVEL9K_VERSION' "$P10K_DIR/internal/p10k.zsh" 2>/dev/null | grep -oP "[\d.]+" || echo "unknown")
        log "INFO" "        Version: $P10K_VERSION"
    fi
else
    log "WARNING" "Powerlevel10k is NOT installed"
fi

# ==============================================================================
# 4. Check External Plugins
# ==============================================================================
log "INFO" "[4/7] Checking external plugins..."

# zsh-autosuggestions
AUTOSUGG_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [ -d "$AUTOSUGG_DIR" ]; then
    log "SUCCESS" "zsh-autosuggestions installed"
else
    log "WARNING" "zsh-autosuggestions is NOT installed"
fi

# zsh-syntax-highlighting
SYNHL_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
if [ -d "$SYNHL_DIR" ]; then
    log "SUCCESS" "zsh-syntax-highlighting installed"
else
    log "WARNING" "zsh-syntax-highlighting is NOT installed"
fi

# fzf
FZF_DIR="$HOME/.fzf"
if [ -d "$FZF_DIR" ]; then
    FZF_VERSION=$("$FZF_DIR/bin/fzf" --version 2>/dev/null | awk '{print $1}' || echo "unknown")
    log "SUCCESS" "fzf installed (v$FZF_VERSION)"
else
    log "WARNING" "fzf is NOT installed"
fi

# ==============================================================================
# 5. Check .zshrc Configuration
# ==============================================================================
log "INFO" "[5/7] Checking .zshrc configuration..."
if [ -f "$ZSHRC" ]; then
    log "SUCCESS" ".zshrc exists"

    # Check theme
    if grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$ZSHRC"; then
        log "SUCCESS" "Theme set to Powerlevel10k"
    else
        log "WARNING" "Theme is NOT set to Powerlevel10k"
    fi

    # Check plugins in .zshrc
    if grep -q "zsh-autosuggestions" "$ZSHRC"; then
        log "SUCCESS" "zsh-autosuggestions enabled in plugins"
    else
        log "WARNING" "zsh-autosuggestions NOT in plugins array"
    fi

    if grep -q "zsh-syntax-highlighting" "$ZSHRC"; then
        log "SUCCESS" "zsh-syntax-highlighting enabled in plugins"
    else
        log "WARNING" "zsh-syntax-highlighting NOT in plugins array"
    fi

    # Check fzf source
    if grep -q '\.fzf\.zsh' "$ZSHRC"; then
        log "SUCCESS" "fzf sourced in .zshrc"
    else
        log "WARNING" "fzf NOT sourced in .zshrc"
    fi
else
    log "ERROR" ".zshrc does NOT exist"
    ((ERRORS++))
fi

# ==============================================================================
# 6. Check p10k Configuration
# ==============================================================================
log "INFO" "[6/7] Checking Powerlevel10k configuration..."
if [ -f "$HOME/.p10k.zsh" ]; then
    log "SUCCESS" "p10k configuration exists at ~/.p10k.zsh"
else
    log "INFO" "p10k not configured yet (run 'p10k configure' to set up)"
fi

# ==============================================================================
# 7. Check Default Shell
# ==============================================================================
log "INFO" "[7/7] Checking default shell..."
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [[ "$CURRENT_SHELL" == *"zsh"* ]]; then
    log "SUCCESS" "Default shell is ZSH ($CURRENT_SHELL)"
else
    log "INFO" "Default shell is $CURRENT_SHELL (not ZSH)"
    log "INFO" "        Run 'chsh -s $(which zsh)' to change"
fi

# ==============================================================================
# Summary
# ==============================================================================
log "INFO" ""
log "INFO" "=========================================="
if [ $ERRORS -eq 0 ]; then
    log "SUCCESS" "ZSH environment verification complete!"
    log "INFO" ""
    log "INFO" "Quick test commands:"
    log "INFO" "  - Type a previous command to see autosuggestions"
    log "INFO" "  - Press Ctrl+R for fuzzy history search"
    log "INFO" "  - Press Ctrl+T for fuzzy file finder"
    log "INFO" "  - Type 'z <partial>' to jump to directories"
else
    log "ERROR" "Verification completed with $ERRORS error(s)"
    exit 1
fi

# Generate artifact manifest for future verification
SCRIPT_DIR="$(dirname "$0")"
VERSION_NUM=$(zsh --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1 || echo "unknown")
"$SCRIPT_DIR/generate_manifest.sh" zsh "$VERSION_NUM" apt > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
