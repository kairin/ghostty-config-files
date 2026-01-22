#!/bin/bash
# configure_zsh.sh - Configure .zshrc with recommended plugins and completions
# Strategy: Backup existing .zshrc, then intelligently modify it
source "$(dirname "$0")/../006-logs/logger.sh"

ZSHRC="$HOME/.zshrc"
BACKUP_DIR="$HOME/.zshrc.backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs/zsh"

# ==============================================================================
# Pre-flight Checks
# ==============================================================================
if [ ! -f "$ZSHRC" ]; then
    log "ERROR" ".zshrc not found at $ZSHRC"
    log "INFO" "Please run 'Install' first to set up Oh My Zsh"
    exit 1
fi

# ==============================================================================
# Step 1: Create Backup
# ==============================================================================
log "INFO" "Creating backup of .zshrc..."
mkdir -p "$BACKUP_DIR"
cp "$ZSHRC" "$BACKUP_DIR/.zshrc.$TIMESTAMP"
log "SUCCESS" "Backed up to $BACKUP_DIR/.zshrc.$TIMESTAMP"

# ==============================================================================
# Step 2: Update ZSH Theme to Powerlevel10k
# ==============================================================================
log "INFO" "Configuring Powerlevel10k theme..."

if grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$ZSHRC"; then
    log "INFO" "Powerlevel10k theme already configured"
else
    # Replace any ZSH_THEME line with powerlevel10k
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
    log "SUCCESS" "Set ZSH_THEME to powerlevel10k"
fi

# ==============================================================================
# Step 2b: Add Powerlevel10k Instant Prompt (Performance)
# ==============================================================================
log "INFO" "Configuring P10k instant prompt..."

INSTANT_PROMPT_BLOCK='# Enable Powerlevel10k instant prompt (performance optimization)
# This MUST be near the top of .zshrc
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi'

if grep -q 'p10k-instant-prompt' "$ZSHRC"; then
    log "INFO" "P10k instant prompt already configured"
else
    # Insert at the very top of the file (after any shebang)
    TEMP_FILE=$(mktemp)
    if head -1 "$ZSHRC" | grep -q '^#!'; then
        head -1 "$ZSHRC" > "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        echo "$INSTANT_PROMPT_BLOCK" >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        tail -n +2 "$ZSHRC" >> "$TEMP_FILE"
    else
        echo "$INSTANT_PROMPT_BLOCK" > "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        cat "$ZSHRC" >> "$TEMP_FILE"
    fi
    mv "$TEMP_FILE" "$ZSHRC"
    log "SUCCESS" "Added P10k instant prompt at top of .zshrc"
fi

# ==============================================================================
# Step 2c: Configure Oh My Zsh Auto-Update
# ==============================================================================
log "INFO" "Configuring Oh My Zsh auto-update..."

if grep -q "zstyle ':omz:update' mode auto" "$ZSHRC"; then
    log "INFO" "Auto-update already configured"
else
    # Update or add auto-update settings
    if grep -q "zstyle ':omz:update' mode" "$ZSHRC"; then
        sed -i "s/zstyle ':omz:update' mode.*/zstyle ':omz:update' mode auto/" "$ZSHRC"
    else
        # Add after ZSH_THEME line
        sed -i '/^ZSH_THEME=/a \
\
# Oh My Zsh auto-update settings\
zstyle '"'"':omz:update'"'"' mode auto      # update automatically without asking\
zstyle '"'"':omz:update'"'"' frequency 1    # check daily' "$ZSHRC"
    fi
    log "SUCCESS" "Configured daily auto-updates"
fi

# ==============================================================================
# Step 3: Update Plugins Array
# ==============================================================================
log "INFO" "Updating plugins configuration..."

# Define the new plugins block
PLUGINS_BLOCK='plugins=(
  # Core
  git
  z
  sudo
  extract

  # Development
  docker
  docker-compose
  gh
  golang
  python
  pip

  # System (Ubuntu/Debian)
  debian
  systemd
  command-not-found

  # Productivity
  colored-man-pages
  aliases
  copypath

  # External (custom/plugins)
  zsh-autosuggestions
  zsh-syntax-highlighting
)'

# Create a temp file for the transformation
TEMP_FILE=$(mktemp)

# Use awk to replace the plugins=(...) block
awk -v new="$PLUGINS_BLOCK" '
  /^plugins=\(/ {
    in_plugins=1
    print new
    # Check if single-line: plugins=(git)
    if (/\)$/) {
      in_plugins=0
    }
    next
  }
  in_plugins {
    # Skip lines until we find the closing )
    if (/^\)/) {
      in_plugins=0
    }
    next
  }
  !in_plugins { print }
' "$ZSHRC" > "$TEMP_FILE"

# Check if the transformation was successful
if [ -s "$TEMP_FILE" ]; then
    mv "$TEMP_FILE" "$ZSHRC"
    log "SUCCESS" "Updated plugins array with 20 plugins"
else
    rm -f "$TEMP_FILE"
    log "ERROR" "Failed to update plugins array"
fi

# ==============================================================================
# Step 4: Add FZF Integration
# ==============================================================================
log "INFO" "Configuring fzf integration..."

if grep -q '\.fzf\.zsh' "$ZSHRC"; then
    log "INFO" "fzf already configured in .zshrc"
else
    # Find the p10k line and insert before it
    if grep -q '\[\[ ! -f ~/.p10k.zsh \]\]' "$ZSHRC"; then
        sed -i '/\[\[ ! -f ~\/.p10k.zsh \]\]/i \
# FZF - Fuzzy finder (Ctrl+R for history, Ctrl+T for files)\
[ -f ~/.fzf.zsh ] \&\& source ~/.fzf.zsh\
' "$ZSHRC"
        log "SUCCESS" "Added fzf source line"
    else
        # If no p10k line, append at the end
        echo '' >> "$ZSHRC"
        echo '# FZF - Fuzzy finder (Ctrl+R for history, Ctrl+T for files)' >> "$ZSHRC"
        echo '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh' >> "$ZSHRC"
        log "SUCCESS" "Added fzf source line (appended)"
    fi
fi

# ==============================================================================
# Step 5: Add Tool Completions
# ==============================================================================
log "INFO" "Configuring tool completions..."

if grep -q 'uv generate-shell-completion' "$ZSHRC"; then
    log "INFO" "Tool completions already configured"
else
    # Add completions for uv, gum, glow
    if grep -q '\[\[ ! -f ~/.p10k.zsh \]\]' "$ZSHRC"; then
        sed -i '/\[\[ ! -f ~\/.p10k.zsh \]\]/i \
# Tool completions (uv, gum, glow)\
command -v uv \&>/dev/null \&\& eval "$(uv generate-shell-completion zsh)"\
command -v gum \&>/dev/null \&\& eval "$(gum completion zsh)"\
command -v glow \&>/dev/null \&\& eval "$(glow completion zsh)"\
' "$ZSHRC"
        log "SUCCESS" "Added tool completions"
    else
        echo '' >> "$ZSHRC"
        echo '# Tool completions (uv, gum, glow)' >> "$ZSHRC"
        echo 'command -v uv &>/dev/null && eval "$(uv generate-shell-completion zsh)"' >> "$ZSHRC"
        echo 'command -v gum &>/dev/null && eval "$(gum completion zsh)"' >> "$ZSHRC"
        echo 'command -v glow &>/dev/null && eval "$(glow completion zsh)"' >> "$ZSHRC"
        log "SUCCESS" "Added tool completions (appended)"
    fi
fi

# ==============================================================================
# Step 6: Source Modern CLI Aliases
# ==============================================================================
log "INFO" "Configuring modern CLI aliases..."

ALIASES_FILE="$CONFIGS_DIR/.zshrc.aliases"
if [ -f "$ALIASES_FILE" ]; then
    if grep -q 'ghostty-config:aliases' "$ZSHRC"; then
        log "INFO" "Aliases already configured"
    else
        cat >> "$ZSHRC" << 'EOF'

# >>> ghostty-config:aliases >>>
# Modern CLI tool aliases (grc, bat, eza)
# Source the aliases file from ghostty-config-files
GHOSTTY_ALIASES="${GHOSTTY_CONFIG_DIR:-$HOME/Apps/ghostty-config-files}/configs/zsh/.zshrc.aliases"
[ -f "$GHOSTTY_ALIASES" ] && source "$GHOSTTY_ALIASES"
# <<< ghostty-config:aliases <<<
EOF
        log "SUCCESS" "Added modern CLI aliases block"
    fi
else
    log "WARNING" "Aliases file not found at $ALIASES_FILE"
fi

# ==============================================================================
# Step 7: Source Lazy Loading Patterns
# ==============================================================================
log "INFO" "Configuring lazy loading for slow tools..."

LAZY_FILE="$CONFIGS_DIR/.zshrc.lazy-loading"
if [ -f "$LAZY_FILE" ]; then
    if grep -q 'ghostty-config:lazy-loading' "$ZSHRC"; then
        log "INFO" "Lazy loading already configured"
    else
        cat >> "$ZSHRC" << 'EOF'

# >>> ghostty-config:lazy-loading >>>
# Lazy load slow tools (fnm, nvm, bun) for faster startup
GHOSTTY_LAZY="${GHOSTTY_CONFIG_DIR:-$HOME/Apps/ghostty-config-files}/configs/zsh/.zshrc.lazy-loading"
[ -f "$GHOSTTY_LAZY" ] && source "$GHOSTTY_LAZY"
# <<< ghostty-config:lazy-loading <<<
EOF
        log "SUCCESS" "Added lazy loading block"
    fi
else
    log "WARNING" "Lazy loading file not found at $LAZY_FILE"
fi

# ==============================================================================
# Step 8: Ensure ~/.local/bin is in PATH
# ==============================================================================
log "INFO" "Ensuring ~/.local/bin is in PATH..."

if grep -q 'ghostty-config:local-bin' "$ZSHRC"; then
    log "INFO" "~/.local/bin PATH already configured"
else
    cat >> "$ZSHRC" << 'EOF'

# >>> ghostty-config:local-bin >>>
# Ensure ~/.local/bin is in PATH (for fnm, pip packages, npm globals, etc.)
# This is critical for tools installed via the TUI to remain accessible
export PATH="$HOME/.local/bin:$PATH"
# <<< ghostty-config:local-bin <<<
EOF
    log "SUCCESS" "Added ~/.local/bin to PATH"
fi

# ==============================================================================
# Step 9: Install Default Powerlevel10k Configuration
# ==============================================================================
log "INFO" "Checking Powerlevel10k configuration..."

P10K_DEFAULT="$CONFIGS_DIR/.p10k.zsh"
P10K_USER="$HOME/.p10k.zsh"

if [ -f "$P10K_USER" ]; then
    log "INFO" "User already has ~/.p10k.zsh (keeping existing)"
else
    if [ -f "$P10K_DEFAULT" ]; then
        cp "$P10K_DEFAULT" "$P10K_USER"
        log "SUCCESS" "Installed default P10k configuration (rainbow theme)"
        log "INFO" "Customize with: p10k configure"
    else
        log "WARNING" "Default P10k config not found, run 'p10k configure' to create one"
    fi
fi

# ==============================================================================
# Summary
# ==============================================================================
log "SUCCESS" ".zshrc configuration complete!"
log "INFO" ""
log "INFO" "Changes made:"
log "INFO" "  - Set theme to Powerlevel10k"
log "INFO" "  - Added P10k instant prompt (faster startup)"
log "INFO" "  - Configured daily Oh My Zsh auto-updates"
log "INFO" "  - Updated plugins array (20 plugins)"
log "INFO" "  - Added fzf integration"
log "INFO" "  - Added completions for uv, gum, glow"
log "INFO" "  - Added modern CLI aliases (grc, bat, eza)"
log "INFO" "  - Added lazy loading for Node.js tools"
log "INFO" "  - Ensured ~/.local/bin is in PATH (fnm, pip, npm globals)"
log "INFO" "  - Installed default P10k config (if missing)"
log "INFO" ""
log "INFO" "Backup location: $BACKUP_DIR/.zshrc.$TIMESTAMP"
log "INFO" ""
log "INFO" "To apply changes, either:"
log "INFO" "  1. Run: source ~/.zshrc"
log "INFO" "  2. Open a new terminal"
log "INFO" ""
log "INFO" "To customize your prompt:"
log "INFO" "  p10k configure"
log "INFO" ""
log "INFO" "To restore previous config:"
log "INFO" "  cp $BACKUP_DIR/.zshrc.$TIMESTAMP ~/.zshrc"
