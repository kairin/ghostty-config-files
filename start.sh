#!/bin/bash

set -euo pipefail

# Comprehensive Start Script for Ghostty, Ptyxis, Claude Code, and Gemini CLI
# This script handles complete installation of all terminal tools and AI assistants

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/tmp/ghostty-start-logs"
LOG_FILE="$LOG_DIR/start-$(date +%s).log"
REAL_HOME="${SUDO_HOME:-$HOME}"
NVM_VERSION="v0.40.1"
NODE_VERSION="24.6.0"

# Directories
GHOSTTY_APP_DIR="$REAL_HOME/Apps/ghostty"
GHOSTTY_CONFIG_DIR="$REAL_HOME/.config/ghostty"
GHOSTTY_CONFIG_SOURCE="$SCRIPT_DIR/configs/ghostty"
NVM_DIR="$REAL_HOME/.nvm"
APPS_DIR="$REAL_HOME/Apps"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    
    case "$level" in
        "ERROR") color="$RED" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "INFO") color="$BLUE" ;;
        "STEP") color="$CYAN" ;;
    esac
    
    echo -e "${color}[$timestamp] [$level] $message${NC}" | tee -a "$LOG_FILE"
}

# Error handling
handle_error() {
    log "ERROR" "Script failed at line $1. Check $LOG_FILE for details."
    exit 1
}
trap 'handle_error $LINENO' ERR

# Show help
show_help() {
    echo -e "${CYAN}Comprehensive Terminal Tools Installer${NC}"
    echo ""
    echo "This script installs and configures:"
    echo "  • ZSH shell with Oh My ZSH and enhanced plugins"
    echo "  • Ghostty terminal emulator with optimized configuration"
    echo "  • Ptyxis terminal via Flatpak (latest version)"
    echo "  • Node.js (via NVM) with npm and development tools"
    echo "  • Claude Code CLI (latest version)"
    echo "  • Gemini CLI (latest version)"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --skip-deps    Skip system dependency installation"
    echo "  --skip-node    Skip Node.js/NVM installation"
    echo "  --skip-ai      Skip AI tools (Claude Code, Gemini CLI)"
    echo "  --skip-ptyxis  Skip Ptyxis installation"
    echo "  --verbose      Enable verbose logging"
    echo ""
    echo "Examples:"
    echo "  ./start.sh                    # Full installation"
    echo "  ./start.sh --skip-deps       # Skip system dependencies"
    echo "  ./start.sh --verbose         # Verbose output"
    echo ""
}

# Parse command line arguments
SKIP_DEPS=false
SKIP_NODE=false
SKIP_AI=false
SKIP_PTYXIS=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --skip-node)
            SKIP_NODE=true
            shift
            ;;
        --skip-ai)
            SKIP_AI=true
            shift
            ;;
        --skip-ptyxis)
            SKIP_PTYXIS=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check installation status and versions
check_installation_status() {
    log "STEP" "🔍 Checking current installation status..."
    
    # Check Ghostty installation
    local ghostty_installed=false
    local ghostty_version=""
    local ghostty_config_valid=false
    
    if command -v ghostty >/dev/null 2>&1; then
        ghostty_installed=true
        ghostty_version=$(ghostty --version 2>/dev/null | head -1 || echo "unknown")
        log "INFO" "✅ Ghostty installed: $ghostty_version"
        
        # Check configuration validity
        if ghostty +show-config >/dev/null 2>&1; then
            ghostty_config_valid=true
            log "INFO" "✅ Ghostty configuration is valid"
        else
            log "WARNING" "⚠️  Ghostty configuration has issues"
        fi
    else
        log "INFO" "❌ Ghostty not installed"
    fi
    
    # Check Ptyxis installation
    local ptyxis_installed=false
    local ptyxis_version=""
    
    if flatpak list 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
        ptyxis_installed=true
        ptyxis_version=$(flatpak info app.devsuite.Ptyxis 2>/dev/null | grep "Version:" | cut -d: -f2 | xargs || echo "unknown")
        log "INFO" "✅ Ptyxis installed: $ptyxis_version"
    else
        log "INFO" "❌ Ptyxis not installed"
    fi
    
    # Check for available updates
    check_available_updates "$ghostty_installed" "$ptyxis_installed"
    
    # Determine installation strategy
    determine_install_strategy "$ghostty_installed" "$ghostty_config_valid" "$ptyxis_installed"
}

# Check for available updates online
check_available_updates() {
    local ghostty_installed="$1"
    local ptyxis_installed="$2"
    
    log "INFO" "🌐 Checking for available updates..."
    
    # Check Ghostty updates (from Git repository)
    if $ghostty_installed && [ -d "$GHOSTTY_APP_DIR" ]; then
        cd "$GHOSTTY_APP_DIR"
        local current_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
        git fetch origin main >/dev/null 2>&1 || true
        local latest_commit=$(git rev-parse origin/main 2>/dev/null || echo "unknown")
        
        if [ "$current_commit" != "$latest_commit" ] && [ "$latest_commit" != "unknown" ]; then
            log "INFO" "🆕 Ghostty update available (new commits)"
        else
            log "INFO" "✅ Ghostty is up to date"
        fi
    fi
    
    # Check Ptyxis updates (Flatpak will handle this automatically)
    if $ptyxis_installed; then
        if flatpak remote-ls --updates 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
            log "INFO" "🆕 Ptyxis update available"
        else
            log "INFO" "✅ Ptyxis is up to date"
        fi
    fi
}

# Determine the best installation strategy
determine_install_strategy() {
    local ghostty_installed="$1"
    local ghostty_config_valid="$2"  
    local ptyxis_installed="$3"
    
    log "INFO" "🤔 Determining installation strategy..."
    
    # Ghostty strategy
    if $ghostty_installed; then
        if $ghostty_config_valid; then
            log "INFO" "📋 Ghostty: Will update existing installation"
            GHOSTTY_STRATEGY="update"
        else
            log "WARNING" "📋 Ghostty: Configuration invalid, will reinstall configuration"
            GHOSTTY_STRATEGY="reconfig"
        fi
    else
        log "INFO" "📋 Ghostty: Will perform fresh installation"
        GHOSTTY_STRATEGY="fresh"
    fi
    
    # Ptyxis strategy  
    if $ptyxis_installed; then
        log "INFO" "📋 Ptyxis: Will update existing installation"
        PTYXIS_STRATEGY="update"
    else
        log "INFO" "📋 Ptyxis: Will perform fresh installation"  
        PTYXIS_STRATEGY="fresh"
    fi
}

# Pre-authentication for sudo
pre_auth_sudo() {
    log "INFO" "🔑 Pre-authenticating sudo access..."
    if sudo -n true 2>/dev/null; then
        log "SUCCESS" "✅ Sudo already authenticated"
    else
        log "INFO" "🔐 Please enter your sudo password:"
        sudo echo "Sudo authenticated successfully" || {
            log "ERROR" "❌ Sudo authentication failed"
            exit 1
        }
        log "SUCCESS" "✅ Sudo authenticated"
    fi
}

# Install ZSH and Oh My ZSH
install_zsh() {
    log "STEP" "🐚 Setting up ZSH and Oh My ZSH..."
    
    # Check if ZSH is installed
    if ! command -v zsh >/dev/null 2>&1; then
        log "INFO" "📥 Installing ZSH..."
        if sudo apt install -y zsh >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ ZSH installed"
        else
            log "ERROR" "❌ Failed to install ZSH"
            return 1
        fi
    else
        log "SUCCESS" "✅ ZSH already installed"
    fi
    
    # Check if Oh My ZSH is installed
    if [ ! -d "$REAL_HOME/.oh-my-zsh" ]; then
        log "INFO" "📥 Installing Oh My ZSH..."
        # Download and install Oh My ZSH non-interactively
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Oh My ZSH installed"
        else
            log "ERROR" "❌ Failed to install Oh My ZSH"
            return 1
        fi
    else
        log "SUCCESS" "✅ Oh My ZSH already installed"
    fi
    
    # Check current default shell
    local current_shell=$(getent passwd "$USER" | cut -d: -f7)
    local zsh_path=$(which zsh)
    
    if [ "$current_shell" != "$zsh_path" ]; then
        log "INFO" "🔄 Setting ZSH as default shell..."
        if chsh -s "$zsh_path" >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ ZSH set as default shell (restart terminal to take effect)"
        else
            log "WARNING" "⚠️  Failed to set ZSH as default shell automatically"
            log "INFO" "💡 You can manually set it with: chsh -s $zsh_path"
        fi
    else
        log "SUCCESS" "✅ ZSH is already the default shell"
    fi
    
    # Update Ghostty config to use ZSH
    local ghostty_config="$GHOSTTY_CONFIG_DIR/config"
    if [ -f "$ghostty_config" ]; then
        if ! grep -q "shell-integration = zsh" "$ghostty_config"; then
            if grep -q "shell-integration" "$ghostty_config"; then
                sed -i 's/shell-integration = .*/shell-integration = zsh/' "$ghostty_config"
                log "SUCCESS" "✅ Updated Ghostty shell integration to ZSH"
            fi
        else
            log "SUCCESS" "✅ Ghostty already configured for ZSH"
        fi
    fi
    
    # Add useful ZSH plugins
    local zshrc="$REAL_HOME/.zshrc"
    if [ -f "$zshrc" ]; then
        # Update plugins in .zshrc if Oh My ZSH config exists
        if grep -q "plugins=(git)" "$zshrc"; then
            sed -i 's/plugins=(git)/plugins=(git npm node nvm docker docker-compose sudo history)/' "$zshrc"
            log "SUCCESS" "✅ Enhanced ZSH plugins configuration"
        fi
        
        # Add NVM configuration to .zshrc if not present
        if ! grep -q "export NVM_DIR" "$zshrc"; then
            cat >> "$zshrc" << 'EOF'

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

EOF
            log "SUCCESS" "✅ Added NVM configuration to .zshrc"
        fi
        
        # Add Gemini alias to .zshrc (handle conflicts)
        if grep -q "flatpak run app.devsuite.Ptyxis.*gemini" "$zshrc"; then
            log "SUCCESS" "✅ Ptyxis gemini integration already configured in .zshrc"
        else
            if grep -q "alias gemini=" "$zshrc"; then
                log "INFO" "🔄 Updating existing gemini alias in .zshrc"
                sed -i '/alias gemini=/s/^/# (replaced by Ptyxis integration) /' "$zshrc"
            fi
            
            cat >> "$zshrc" << 'EOF'

# Gemini CLI integration with Ptyxis
alias gemini='flatpak run app.devsuite.Ptyxis -d "$(pwd)" -- ~/.nvm/versions/node/v24.6.0/bin/gemini'

EOF
            log "SUCCESS" "✅ Added Ptyxis gemini integration to .zshrc"
        fi
    fi
}

# Install system dependencies
install_system_deps() {
    if $SKIP_DEPS; then
        log "INFO" "⏭️  Skipping system dependencies installation"
        return 0
    fi
    
    log "STEP" "🔧 Installing system dependencies..."
    
    # Update package list
    sudo apt update || {
        log "ERROR" "Failed to update package list"
        return 1
    }
    
    # Install essential dependencies (including ZSH)
    local deps=(
        "build-essential" "pkg-config" "gettext" "libxml2-utils" "pandoc"
        "git" "curl" "wget" "unzip" "software-properties-common" "zsh"
        "libgtk-4-dev" "libadwaita-1-dev" "blueprint-compiler" 
        "libgtk4-layer-shell-dev" "libfreetype-dev" "libharfbuzz-dev"
        "libfontconfig-dev" "libpng-dev" "libbz2-dev" "zlib1g-dev"
        "libglib2.0-dev" "libgio-2.0-dev" "libpango1.0-dev"
        "libgdk-pixbuf-2.0-dev" "libcairo2-dev" "libvulkan-dev"
        "libgraphene-1.0-dev" "libx11-dev" "libwayland-dev"
        "libonig-dev" "libxml2-dev" "flatpak"
    )
    
    log "INFO" "📦 Installing ${#deps[@]} essential packages..."
    if sudo apt install -y "${deps[@]}" >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "✅ System dependencies installed"
    else
        log "ERROR" "❌ Failed to install system dependencies"
        return 1
    fi
    
    # Add Flathub repository if not already added
    if ! flatpak remotes | grep -q flathub; then
        log "INFO" "🔗 Adding Flathub repository..."
        sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        log "SUCCESS" "✅ Flathub repository added"
    fi
}

# Install Zig
install_zig() {
    log "STEP" "⚡ Installing Zig 0.14.0..."
    
    if command -v zig >/dev/null 2>&1; then
        local current_version=$(zig version)
        if [[ "$current_version" == "0.14.0" ]]; then
            log "SUCCESS" "✅ Zig 0.14.0 already installed"
            return 0
        fi
    fi
    
    # Download and install Zig
    local zig_url="https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz"
    local zig_archive="/tmp/zig-linux-x86_64-0.14.0.tar.xz"
    local zig_dir="$APPS_DIR/zig"
    
    mkdir -p "$APPS_DIR"
    
    log "INFO" "📥 Downloading Zig 0.14.0..."
    if wget -O "$zig_archive" "$zig_url" >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "✅ Zig downloaded"
    else
        log "ERROR" "❌ Failed to download Zig"
        return 1
    fi
    
    log "INFO" "📂 Extracting Zig..."
    rm -rf "$zig_dir"
    mkdir -p "$zig_dir"
    tar -xf "$zig_archive" -C "$zig_dir" --strip-components=1
    rm "$zig_archive"
    
    # Create system-wide symlink
    sudo ln -sf "$zig_dir/zig" /usr/local/bin/zig
    
    # Verify installation
    if zig version | grep -q "0.14.0"; then
        log "SUCCESS" "✅ Zig 0.14.0 installed successfully"
    else
        log "ERROR" "❌ Zig installation verification failed"
        return 1
    fi
}

# Install or update Ghostty based on strategy
install_ghostty() {
    case "${GHOSTTY_STRATEGY:-fresh}" in
        "update")
            update_ghostty
            ;;
        "reconfig") 
            reconfigure_ghostty
            ;;
        "fresh"|*)
            fresh_install_ghostty
            ;;
    esac
}

# Fresh Ghostty installation
fresh_install_ghostty() {
    log "STEP" "👻 Fresh installation of Ghostty terminal emulator..."
    
    # Clone Ghostty repository
    if [ ! -d "$GHOSTTY_APP_DIR" ]; then
        log "INFO" "📥 Cloning Ghostty repository..."
        git clone https://github.com/ghostty-org/ghostty.git "$GHOSTTY_APP_DIR" >> "$LOG_FILE" 2>&1
        log "SUCCESS" "✅ Ghostty repository cloned"
    fi
    
    build_and_install_ghostty
    install_ghostty_configuration
}

# Update existing Ghostty installation
update_ghostty() {
    log "STEP" "🔄 Updating existing Ghostty installation..."
    
    # Update repository
    if [ -d "$GHOSTTY_APP_DIR" ]; then
        cd "$GHOSTTY_APP_DIR"
        log "INFO" "📥 Pulling latest changes..."
        git pull origin main >> "$LOG_FILE" 2>&1
        log "SUCCESS" "✅ Repository updated"
    else
        log "WARNING" "⚠️  Repository not found, performing fresh install"
        fresh_install_ghostty
        return
    fi
    
    # Check if rebuild is needed
    local needs_rebuild=false
    if [ ! -f "zig-out/bin/ghostty" ]; then
        needs_rebuild=true
        log "INFO" "🔨 Binary not found, rebuild required"
    else
        # Check if source is newer than binary
        if find . -name "*.zig" -newer "zig-out/bin/ghostty" | head -1 | grep -q .; then
            needs_rebuild=true
            log "INFO" "🔨 Source files updated, rebuild required"
        fi
    fi
    
    if $needs_rebuild; then
        build_and_install_ghostty
    else
        log "INFO" "✅ Ghostty binary is up to date"
    fi
    
    # Always update configuration to latest
    install_ghostty_configuration
}

# Reconfigure Ghostty (fix config issues)
reconfigure_ghostty() {
    log "STEP" "⚙️  Reconfiguring Ghostty (fixing configuration issues)..."
    
    # Backup existing config if it exists
    if [ -d "$GHOSTTY_CONFIG_DIR" ]; then
        local backup_dir="/tmp/ghostty-config-backup-$(date +%s)"
        cp -r "$GHOSTTY_CONFIG_DIR" "$backup_dir"
        log "INFO" "💾 Backed up existing config to $backup_dir"
    fi
    
    # Install fresh configuration
    install_ghostty_configuration
    
    # Verify the fix worked
    if ghostty +show-config >/dev/null 2>&1; then
        log "SUCCESS" "✅ Configuration issues resolved"
    else
        log "ERROR" "❌ Configuration issues persist"
        return 1
    fi
}

# Build and install Ghostty binary
build_and_install_ghostty() {
    cd "$GHOSTTY_APP_DIR"
    log "INFO" "🔨 Building Ghostty (this may take a while)..."
    
    # Clean previous build if it exists
    if [ -d "zig-out" ]; then
        rm -rf zig-out
    fi
    
    if zig build -Doptimize=ReleaseFast >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "✅ Ghostty built successfully"
    else
        log "ERROR" "❌ Ghostty build failed"
        return 1
    fi
    
    # Install Ghostty
    log "INFO" "📥 Installing Ghostty..."
    if sudo zig build install --prefix /usr/local >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "✅ Ghostty installed to /usr/local"
    else
        log "ERROR" "❌ Ghostty installation failed"
        return 1
    fi
}

# Install Ghostty configuration files
install_ghostty_configuration() {
    log "INFO" "⚙️  Installing Ghostty configuration..."
    mkdir -p "$GHOSTTY_CONFIG_DIR"
    
    # Copy configuration files from configs directory
    for config_file in config theme.conf scroll.conf layout.conf keybindings.conf; do
        if [ -f "$GHOSTTY_CONFIG_SOURCE/$config_file" ]; then
            cp "$GHOSTTY_CONFIG_SOURCE/$config_file" "$GHOSTTY_CONFIG_DIR/"
            log "SUCCESS" "✅ Copied $config_file"
        else
            log "WARNING" "⚠️  $config_file not found in $GHOSTTY_CONFIG_SOURCE"
        fi
    done
    
    # Validate configuration
    if ghostty +show-config >/dev/null 2>&1; then
        log "SUCCESS" "✅ Ghostty configuration is valid"
    else
        log "WARNING" "⚠️  Ghostty configuration validation failed"
        return 1
    fi
}

# Install or update Ptyxis based on strategy
install_ptyxis() {
    if $SKIP_PTYXIS; then
        log "INFO" "⏭️  Skipping Ptyxis installation"
        return 0
    fi
    
    case "${PTYXIS_STRATEGY:-fresh}" in
        "update")
            update_ptyxis
            ;;
        "fresh"|*)
            fresh_install_ptyxis
            ;;
    esac
}

# Fresh Ptyxis installation
fresh_install_ptyxis() {
    log "STEP" "🐚 Fresh installation of Ptyxis terminal via Flatpak..."
    
    log "INFO" "📥 Installing Ptyxis..."
    if flatpak install -y flathub app.devsuite.Ptyxis >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "✅ Ptyxis installed"
    else
        log "ERROR" "❌ Ptyxis installation failed"
        return 1
    fi
    
    configure_ptyxis
}

# Update existing Ptyxis installation
update_ptyxis() {
    log "STEP" "🔄 Updating existing Ptyxis installation..."
    
    log "INFO" "🔄 Updating Ptyxis..."
    if flatpak update -y app.devsuite.Ptyxis >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "✅ Ptyxis updated"
    else
        log "WARNING" "⚠️  Ptyxis update may have failed"
    fi
    
    configure_ptyxis
}

# Configure Ptyxis permissions and aliases
configure_ptyxis() {
    # Grant necessary permissions for file access
    log "INFO" "🔧 Configuring Ptyxis permissions..."
    flatpak override app.devsuite.Ptyxis --filesystem=home >> "$LOG_FILE" 2>&1
    
    # Create gemini alias in both bashrc and zshrc (handle conflicts)
    for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
        if [ -f "$shell_config" ]; then
            # Check if Ptyxis integration already exists
            if grep -q "flatpak run app.devsuite.Ptyxis.*gemini" "$shell_config"; then
                log "SUCCESS" "✅ Ptyxis gemini integration already configured in $(basename "$shell_config")"
            else
                # Check if any gemini alias exists
                if grep -q "alias gemini=" "$shell_config"; then
                    log "INFO" "🔄 Updating existing gemini alias in $(basename "$shell_config")"
                    # Comment out existing alias and add new one
                    sed -i '/alias gemini=/s/^/# (replaced by Ptyxis integration) /' "$shell_config"
                fi
                
                # Add the correct Ptyxis integration alias
                echo "" >> "$shell_config"
                echo "# Gemini CLI integration with Ptyxis" >> "$shell_config"
                echo 'alias gemini='"'"'flatpak run app.devsuite.Ptyxis -d "$(pwd)" -- ~/.nvm/versions/node/v24.6.0/bin/gemini'"'" >> "$shell_config"
                log "SUCCESS" "✅ Added Ptyxis gemini integration to $(basename "$shell_config")"
            fi
        fi
    done
}

# Install Node.js via NVM
install_nodejs() {
    if $SKIP_NODE; then
        log "INFO" "⏭️  Skipping Node.js installation"
        return 0
    fi
    
    log "STEP" "📦 Installing Node.js via NVM..."
    
    # Install NVM if not present
    if [ ! -d "$NVM_DIR" ]; then
        log "INFO" "📥 Installing NVM $NVM_VERSION..."
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash >> "$LOG_FILE" 2>&1
        log "SUCCESS" "✅ NVM installed"
    else
        log "INFO" "✅ NVM already present"
    fi
    
    # Source NVM
    export NVM_DIR="$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Install Node.js
    if ! command -v node >/dev/null 2>&1 || ! node --version | grep -q "v$NODE_VERSION"; then
        log "INFO" "📥 Installing Node.js $NODE_VERSION..."
        nvm install "$NODE_VERSION" >> "$LOG_FILE" 2>&1
        nvm use "$NODE_VERSION" >> "$LOG_FILE" 2>&1
        nvm alias default "$NODE_VERSION" >> "$LOG_FILE" 2>&1
        log "SUCCESS" "✅ Node.js $NODE_VERSION installed"
    else
        log "SUCCESS" "✅ Node.js $NODE_VERSION already installed"
    fi
    
    # Update npm to latest
    log "INFO" "🔄 Updating npm to latest version..."
    npm install -g npm@latest >> "$LOG_FILE" 2>&1
    log "SUCCESS" "✅ npm updated to $(npm --version)"
}

# Install Claude Code CLI
install_claude_code() {
    if $SKIP_AI; then
        log "INFO" "⏭️  Skipping Claude Code installation"
        return 0
    fi
    
    log "STEP" "🤖 Installing Claude Code CLI..."
    
    # Source NVM for npm access
    export NVM_DIR="$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Claude Code globally
    if npm list -g @anthropic-ai/claude-code >/dev/null 2>&1; then
        log "INFO" "🔄 Updating Claude Code..."
        npm update -g @anthropic-ai/claude-code >> "$LOG_FILE" 2>&1
    else
        log "INFO" "📥 Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code >> "$LOG_FILE" 2>&1
    fi
    
    # Verify installation
    if command -v claude-code >/dev/null 2>&1; then
        local version=$(claude-code --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✅ Claude Code installed (version: $version)"
    else
        log "WARNING" "⚠️  Claude Code installed but not in PATH"
    fi
}

# Install Gemini CLI
install_gemini_cli() {
    if $SKIP_AI; then
        log "INFO" "⏭️  Skipping Gemini CLI installation"
        return 0
    fi
    
    log "STEP" "💎 Installing Gemini CLI..."
    
    # Source NVM for npm access
    export NVM_DIR="$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Gemini CLI globally
    if npm list -g @google/generative-ai-cli >/dev/null 2>&1; then
        log "INFO" "🔄 Updating Gemini CLI..."
        npm update -g @google/generative-ai-cli >> "$LOG_FILE" 2>&1
    else
        log "INFO" "📥 Installing Gemini CLI..."
        npm install -g @google/generative-ai-cli >> "$LOG_FILE" 2>&1
    fi
    
    # Create symlink for easier access
    local gemini_path="$NVM_DIR/versions/node/v$NODE_VERSION/bin/gemini"
    if [ -f "$gemini_path" ]; then
        sudo ln -sf "$gemini_path" /usr/local/bin/gemini 2>/dev/null || true
        log "SUCCESS" "✅ Gemini CLI installed and linked"
    else
        log "WARNING" "⚠️  Gemini CLI installation may have issues"
    fi
}

# Final verification
verify_installation() {
    log "STEP" "🔍 Verifying installations..."
    
    local status=0
    
    # Check Ghostty
    if command -v ghostty >/dev/null 2>&1; then
        local version=$(ghostty --version 2>/dev/null | head -1)
        log "SUCCESS" "✅ Ghostty: $version"
    else
        log "ERROR" "❌ Ghostty not found"
        status=1
    fi
    
    # Check Ptyxis
    if ! $SKIP_PTYXIS; then
        if flatpak list | grep -q "app.devsuite.Ptyxis"; then
            log "SUCCESS" "✅ Ptyxis: Available via flatpak"
        else
            log "ERROR" "❌ Ptyxis not found"
            status=1
        fi
    fi
    
    # Check ZSH
    if command -v zsh >/dev/null 2>&1; then
        local current_shell=$(getent passwd "$USER" | cut -d: -f7)
        local zsh_path=$(which zsh)
        if [ "$current_shell" = "$zsh_path" ]; then
            log "SUCCESS" "✅ ZSH: Default shell with Oh My ZSH"
        else
            log "WARNING" "⚠️  ZSH: Installed but not default shell"
        fi
    else
        log "ERROR" "❌ ZSH not found"
        status=1
    fi
    
    # Check Node.js
    if ! $SKIP_NODE; then
        if command -v node >/dev/null 2>&1; then
            local version=$(node --version)
            log "SUCCESS" "✅ Node.js: $version"
        else
            log "ERROR" "❌ Node.js not found"
            status=1
        fi
    fi
    
    # Check AI tools
    if ! $SKIP_AI; then
        # Check Claude Code
        if command -v claude-code >/dev/null 2>&1; then
            log "SUCCESS" "✅ Claude Code: Available"
        else
            log "WARNING" "⚠️  Claude Code not in PATH (may need shell restart)"
        fi
        
        # Check Gemini CLI
        if command -v gemini >/dev/null 2>&1; then
            log "SUCCESS" "✅ Gemini CLI: Available"
        else
            log "WARNING" "⚠️  Gemini CLI not in PATH (may need shell restart)"
        fi
    fi
    
    return $status
}

# Show final instructions
show_final_instructions() {
    echo ""
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Restart your terminal to activate ZSH and new environment"
    echo "2. Test Ghostty: ghostty"
    if ! $SKIP_PTYXIS; then
        echo "3. Test Ptyxis: flatpak run app.devsuite.Ptyxis"
        echo "4. Use Gemini in Ptyxis: gemini (after restart)"
    fi
    if ! $SKIP_AI; then
        echo "5. Set up Claude Code: claude-code auth login"
        echo "6. Set up Gemini CLI with your API key"
    fi
    echo ""
    echo -e "${YELLOW}Configuration files:${NC}"
    echo "• Ghostty config: $GHOSTTY_CONFIG_DIR/"
    echo "• Logs: $LOG_FILE"
    echo ""
    if ! $SKIP_AI; then
        echo -e "${YELLOW}API Setup Required:${NC}"
        echo "• Claude Code: Get API key from https://console.anthropic.com"
        echo "• Gemini CLI: Get API key from https://makersuite.google.com/app/apikey"
        echo ""
    fi
}

# Main execution
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Comprehensive Terminal Tools Installer${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    log "INFO" "🚀 Starting comprehensive installation..."
    log "INFO" "📋 Log file: $LOG_FILE"
    
    # Create necessary directories
    mkdir -p "$APPS_DIR"
    
    # Pre-authenticate sudo if needed
    if ! $SKIP_DEPS || ! $SKIP_PTYXIS; then
        pre_auth_sudo
    fi
    
    # Check current installation status and determine strategies
    check_installation_status
    
    # Execute installation steps
    install_system_deps
    install_zsh
    install_zig
    install_ghostty
    install_ptyxis
    install_nodejs
    install_claude_code
    install_gemini_cli
    
    # Verify everything
    if verify_installation; then
        log "SUCCESS" "🎉 All installations completed successfully!"
        show_final_instructions
    else
        log "WARNING" "⚠️  Some installations may need attention. Check the log for details."
        echo "Log file: $LOG_FILE"
    fi
}

# Run main function
main "$@"