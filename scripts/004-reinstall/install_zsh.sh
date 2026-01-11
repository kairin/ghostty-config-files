#!/bin/bash
# install_zsh.sh - Install ZSH, Oh My Zsh, Powerlevel10k, and external plugins
source "$(dirname "$0")/../006-logs/logger.sh"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ==============================================================================
# Stage 1: Install ZSH
# ==============================================================================
log "INFO" "Checking ZSH installation..."

if ! command -v zsh &> /dev/null; then
    log "INFO" "Installing ZSH..."

    # Smart apt update - skip if cache is fresh (< 5 min)
    APT_LISTS="/var/lib/apt/lists"
    CACHE_AGE=$(($(date +%s) - $(stat -c%Y "$APT_LISTS" 2>/dev/null || echo 0)))
    if [[ $CACHE_AGE -gt 300 ]]; then
        sudo stdbuf -oL apt-get update
    else
        log "INFO" "APT cache fresh (${CACHE_AGE}s ago), skipping update"
    fi

    sudo stdbuf -oL apt-get install -y zsh

    if command -v zsh &> /dev/null; then
        log "SUCCESS" "ZSH installed: $(zsh --version)"
    else
        log "ERROR" "Failed to install ZSH"
        exit 1
    fi
else
    log "SUCCESS" "ZSH already installed: $(zsh --version)"
fi

# ==============================================================================
# Stage 2: Install Oh My Zsh
# ==============================================================================
log "INFO" "Checking Oh My Zsh installation..."

if [ -d "$HOME/.oh-my-zsh" ]; then
    log "INFO" "Oh My Zsh already installed. Updating..."
    if [ -d "$HOME/.oh-my-zsh/.git" ]; then
        git -C "$HOME/.oh-my-zsh" pull --quiet
        log "SUCCESS" "Oh My Zsh updated"
    else
        log "WARNING" "OMZ directory exists but not a git repo. Skipping update."
    fi
else
    log "INFO" "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    if [ -d "$HOME/.oh-my-zsh" ]; then
        log "SUCCESS" "Oh My Zsh installed"
    else
        log "ERROR" "Failed to install Oh My Zsh"
        exit 1
    fi
fi

# ==============================================================================
# Stage 3: Install Powerlevel10k Theme
# ==============================================================================
log "INFO" "Checking Powerlevel10k installation..."

P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"

if [ -d "$P10K_DIR" ]; then
    log "INFO" "Powerlevel10k already installed. Updating..."
    git -C "$P10K_DIR" pull --quiet 2>/dev/null || true
    log "SUCCESS" "Powerlevel10k updated"
else
    log "INFO" "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"

    if [ -d "$P10K_DIR" ]; then
        log "SUCCESS" "Powerlevel10k installed"
    else
        log "ERROR" "Failed to install Powerlevel10k"
        exit 1
    fi
fi

# ==============================================================================
# Stage 4: Install External Plugins
# ==============================================================================
log "INFO" "Installing external ZSH plugins..."

# Ensure custom plugins directory exists
mkdir -p "$ZSH_CUSTOM/plugins"

# 4a: zsh-autosuggestions
AUTOSUGG_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [ -d "$AUTOSUGG_DIR" ]; then
    log "INFO" "zsh-autosuggestions already installed. Updating..."
    git -C "$AUTOSUGG_DIR" pull --quiet 2>/dev/null || true
    log "SUCCESS" "zsh-autosuggestions updated"
else
    log "INFO" "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGG_DIR"

    if [ -d "$AUTOSUGG_DIR" ]; then
        log "SUCCESS" "zsh-autosuggestions installed"
    else
        log "ERROR" "Failed to install zsh-autosuggestions"
    fi
fi

# 4b: zsh-syntax-highlighting
SYNHL_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
if [ -d "$SYNHL_DIR" ]; then
    log "INFO" "zsh-syntax-highlighting already installed. Updating..."
    git -C "$SYNHL_DIR" pull --quiet 2>/dev/null || true
    log "SUCCESS" "zsh-syntax-highlighting updated"
else
    log "INFO" "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$SYNHL_DIR"

    if [ -d "$SYNHL_DIR" ]; then
        log "SUCCESS" "zsh-syntax-highlighting installed"
    else
        log "ERROR" "Failed to install zsh-syntax-highlighting"
    fi
fi

# 4c: fzf (Fuzzy Finder)
FZF_DIR="$HOME/.fzf"
if [ -d "$FZF_DIR" ]; then
    log "INFO" "fzf already installed. Updating..."
    git -C "$FZF_DIR" pull --quiet 2>/dev/null || true
    log "SUCCESS" "fzf updated"
else
    log "INFO" "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR"

    if [ -d "$FZF_DIR" ]; then
        log "INFO" "Running fzf installer..."
        "$FZF_DIR/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
        log "SUCCESS" "fzf installed"
    else
        log "ERROR" "Failed to install fzf"
    fi
fi

# ==============================================================================
# Summary
# ==============================================================================
log "SUCCESS" "ZSH environment installation complete!"
log "INFO" "Components installed:"
log "INFO" "  - ZSH: $(zsh --version | head -1)"
log "INFO" "  - Oh My Zsh: $HOME/.oh-my-zsh"
log "INFO" "  - Powerlevel10k: $P10K_DIR"
log "INFO" "  - zsh-autosuggestions: $AUTOSUGG_DIR"
log "INFO" "  - zsh-syntax-highlighting: $SYNHL_DIR"
log "INFO" "  - fzf: $FZF_DIR"
log "INFO" ""
log "INFO" "Next steps:"
log "INFO" "  1. Run 'Configure' to set up your .zshrc with plugins"
log "INFO" "  2. Run 'p10k configure' to customize your prompt"
log "INFO" "  3. Open a new terminal to apply changes"
