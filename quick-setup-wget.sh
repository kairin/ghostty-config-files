#!/bin/bash

# Quick Setup Script using wget
# Downloads VS Code configuration files using wget with resume support

echo "🚀 Quick VS Code Setup (wget version)"
echo "====================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Base URL for raw files
BASE_URL="https://raw.githubusercontent.com/kairin/ghostty-config-files/main"

# Function to download a file with wget
download_file() {
    local url="$1"
    local output="$2"
    local description="$3"
    
    echo -e "Downloading ${YELLOW}$description${NC}..."
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output")"
    
    # Download with wget (with resume support)
    if wget -c "$url" -O "$output"; then
        echo -e "${GREEN}✓${NC} Downloaded: $output"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to download: $description"
        return 1
    fi
}

# Function to setup a single workspace
setup_workspace() {
    local target_dir="${1:-.}"
    
    echo -e "\n${BLUE}Setting up workspace in:${NC} $target_dir"
    echo "========================================"
    
    cd "$target_dir" || exit 1
    
    # Download main configuration files
    download_file "$BASE_URL/template-settings.json" ".vscode/settings.json" "VS Code settings"
    download_file "$BASE_URL/.vscode/extensions.json" ".vscode/extensions.json" "Extension recommendations"
    
    # Optional: Download utility scripts
    if [[ "$2" == "--with-scripts" ]]; then
        download_file "$BASE_URL/sync-workspaces.sh" "sync-workspaces.sh" "Sync script"
        download_file "$BASE_URL/dual-setup.sh" "dual-setup.sh" "Dual setup script"
        chmod +x sync-workspaces.sh dual-setup.sh 2>/dev/null
        echo -e "${GREEN}✓${NC} Made scripts executable"
    fi
    
    echo -e "\n${GREEN}✓ Workspace setup complete!${NC}"
}

# Function to setup multiple workspaces
setup_multiple() {
    local base_dir="$1"
    
    echo -e "\n${BLUE}Setting up all workspaces in:${NC} $base_dir"
    echo "============================================="
    
    if [[ ! -d "$base_dir" ]]; then
        echo -e "${RED}✗${NC} Directory does not exist: $base_dir"
        exit 1
    fi
    
    local count=0
    for dir in "$base_dir"/*; do
        if [[ -d "$dir" ]]; then
            echo -e "\n${YELLOW}Processing:${NC} $(basename "$dir")"
            setup_workspace "$dir"
            ((count++))
        fi
    done
    
    echo -e "\n${GREEN}✓ Processed $count workspaces!${NC}"
}

# Function to just download template files for manual setup
download_templates() {
    local target_dir="${1:-./vscode-templates}"
    
    echo -e "\n${BLUE}Downloading templates to:${NC} $target_dir"
    echo "==========================================="
    
    mkdir -p "$target_dir"
    cd "$target_dir" || exit 1
    
    # Download all template files
    download_file "$BASE_URL/template-settings.json" "template-settings.json" "Settings template"
    download_file "$BASE_URL/.vscode/extensions.json" "extensions.json" "Extensions template"
    download_file "$BASE_URL/sync-workspaces.sh" "sync-workspaces.sh" "Sync script"
    download_file "$BASE_URL/dual-setup.sh" "dual-setup.sh" "Dual setup script"
    download_file "$BASE_URL/COMPLETE-SETUP-GUIDE.md" "COMPLETE-SETUP-GUIDE.md" "Setup guide"
    
    # Make scripts executable
    chmod +x sync-workspaces.sh dual-setup.sh 2>/dev/null
    
    echo -e "\n${GREEN}✓ Templates downloaded!${NC}"
    echo -e "Use: ${YELLOW}cp template-settings.json /path/to/project/.vscode/settings.json${NC}"
}

# Show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  setup [directory]              - Setup current directory (or specified directory)"
    echo "  setup --with-scripts          - Include utility scripts"
    echo "  setup-all <base-directory>    - Setup all subdirectories"
    echo "  download [target-directory]   - Download templates for manual use"
    echo "  quick                         - Quick setup current directory"
    echo ""
    echo "Examples:"
    echo "  $0 quick                      # Setup current directory"
    echo "  $0 setup ~/Projects/my-app    # Setup specific project"
    echo "  $0 setup --with-scripts       # Setup with utility scripts"
    echo "  $0 setup-all ~/Projects       # Setup all projects"
    echo "  $0 download ~/templates       # Download templates"
    echo ""
    echo "Advantages of using wget:"
    echo "  - Resume interrupted downloads with -c flag"
    echo "  - Better error handling"
    echo "  - More reliable on slow connections"
    echo "  - Progress indicators"
}

# Check if wget is available
check_dependencies() {
    if ! command -v wget &> /dev/null; then
        echo -e "${RED}✗${NC} wget is not installed!"
        echo "Please install wget:"
        echo "  Ubuntu/Debian: sudo apt install wget"
        echo "  CentOS/RHEL: sudo yum install wget"
        echo "  Arch: sudo pacman -S wget"
        echo "  macOS: brew install wget"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} wget is available"
}

# Main script logic
case "$1" in
    "setup")
        check_dependencies
        if [[ "$2" == "--with-scripts" ]]; then
            setup_workspace "." "--with-scripts"
        else
            setup_workspace "$2"
        fi
        ;;
    "setup-all")
        check_dependencies
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error:${NC} Please provide base directory"
            show_usage
            exit 1
        fi
        setup_multiple "$2"
        ;;
    "download")
        check_dependencies
        download_templates "$2"
        ;;
    "quick")
        check_dependencies
        setup_workspace "."
        ;;
    *)
        show_usage
        ;;
esac

echo -e "\n${GREEN}Done!${NC} 🎉"
echo ""
echo "Next steps:"
echo "1. Open VS Code in your workspace"
echo "2. Install recommended extensions when prompted"
echo "3. Enable Settings Sync for personal preferences"
