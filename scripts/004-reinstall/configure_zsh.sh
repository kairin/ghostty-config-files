#!/bin/bash
# configure_zsh.sh - Configure .zshrc with recommended plugins and completions
# Strategy: Backup existing .zshrc, then intelligently modify it
source "$(dirname "$0")/../006-logs/logger.sh"

ZSHRC="$HOME/.zshrc"
BACKUP_DIR="$HOME/.zshrc.backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

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
# Summary
# ==============================================================================
log "SUCCESS" ".zshrc configuration complete!"
log "INFO" ""
log "INFO" "Changes made:"
log "INFO" "  - Set theme to Powerlevel10k"
log "INFO" "  - Updated plugins array (20 plugins)"
log "INFO" "  - Added fzf integration"
log "INFO" "  - Added completions for uv, gum, glow"
log "INFO" ""
log "INFO" "Backup location: $BACKUP_DIR/.zshrc.$TIMESTAMP"
log "INFO" ""
log "INFO" "To apply changes, either:"
log "INFO" "  1. Run: source ~/.zshrc"
log "INFO" "  2. Open a new terminal"
log "INFO" ""
log "INFO" "To restore previous config:"
log "INFO" "  cp $BACKUP_DIR/.zshrc.$TIMESTAMP ~/.zshrc"
