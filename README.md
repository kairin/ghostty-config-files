# Ghostty Configuration + VS Code Workspace Templates

This repository contains:
- Personal Ghostty terminal emulator configuration  
- VS Code workspace templates and sync tools
- Cross-device development environment setup
- **Automatic MCP app and extension tracking system**

## � **IMPORTANT: Fix VS Code Settings Sync First!**

If your settings sync is restoring old versions, **read `SETTINGS-SYNC-FIX.md` immediately** to fix profile conflicts and ensure proper syncing.

## �🚀 Quick VS Code Setup (wget method)

### **Single Workspace Setup (Copy & Paste)**
```bash
# Ultimate one-liner - works anywhere
mkdir -p .vscode && wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/template-settings.json -O .vscode/settings.json && wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/.vscode/extensions.json -O .vscode/extensions.json && echo "✅ VS Code workspace configured!"
```

### **Automated Setup Script**
```bash
# Download and run the quick setup script
wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/quick-setup-wget.sh
chmod +x quick-setup-wget.sh

# Setup current directory
./quick-setup-wget.sh quick

# Setup multiple projects at once
./quick-setup-wget.sh setup-all ~/Projects

# Download templates for manual use
./quick-setup-wget.sh download ~/vscode-templates
```

## 🤖 **Auto-Tracking MCP Apps & Extensions**

When you install new MCP apps, Claude Desktop integrations, or any VS Code extensions:

```bash
# Automatically update this repository with your latest settings
./auto-update-repo.sh
```

This captures:
- ✅ New MCP extensions (Model Context Protocol apps)
- ✅ All VS Code extensions and settings  
- ✅ Keybindings and snippets
- ✅ Commits and pushes changes automatically

### **Set Up Daily Auto-Sync (Optional)**
```bash
# Automatically sync every day at 6 PM
./setup-cron.sh
```

## 📁 Ghostty Terminal Installation

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git ~/.config/ghostty
    ```
    (Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your actual GitHub username and repository name.)

2.  **Ensure `less` is installed:**
    This configuration uses `less` to display the keybindings file on startup. If you don't have it installed, you can usually install it via your distribution's package manager (e.g., `sudo apt install less` on Debian/Ubuntu, `sudo pacman -S less` on Arch Linux).

## Usage

When you open Ghostty, the first tab will display a list of keybindings. To exit this view and get to a shell prompt, press `q`.

To open a new tab for your work, press `Ctrl+Shift+T`.

## Configuration Files

*   `config`: The main configuration file, which includes other configuration files.
*   `theme.conf`: Contains theme and background opacity settings.
*   `scroll.conf`: Contains scrollback limit settings.
*   `layout.conf`: Contains font, padding, window decoration, and other layout-related settings.
*   `keybindings.conf`: Contains custom keybindings.
*   `keybindings.md`: The Markdown file containing the list of keybindings, displayed on startup.
