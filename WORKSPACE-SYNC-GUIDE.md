# VS Code Workspace Synchronization Guide

This guide provides multiple solutions to ensure all your VS Code workspaces have consistent tools, settings, and extensions.

## 🎯 Quick Solutions

### 1. **VS Code Settings Sync (Recommended)**
The easiest built-in solution:

1. **Enable Settings Sync:**
   - `Ctrl+Shift+P` → "Settings Sync: Turn On"
   - Sign in with Microsoft/GitHub account
   - Choose what to sync (Settings, Extensions, Keybindings, etc.)

2. **What it syncs:**
   - User settings
   - Extensions
   - Keybindings
   - Snippets
   - UI state

### 2. **Use the Sync Script**
For manual control and custom setups:

```bash
# Make script executable (already done)
chmod +x sync-workspaces.sh

# Sync one workspace to another
./sync-workspaces.sh sync /path/to/template-workspace /path/to/target-workspace

# Sync to all workspaces in a directory
./sync-workspaces.sh sync-all /path/to/template-workspace ~/Projects

# Install recommended extensions
./sync-workspaces.sh install-extensions
```

## 📁 Files Created

### `template-settings.json`
Contains common VS Code settings that work well across projects:
- Formatting on save
- Git auto-fetch
- Terminal preferences
- Language-specific formatters

### `.vscode/extensions.json`
Recommends essential extensions for any workspace:
- Language support (Python, JavaScript, TypeScript)
- Code formatting (Prettier)
- Git integration
- GitHub Copilot

### `sync-workspaces.sh`
Bash script to automate workspace synchronization.

## 🔧 Usage Examples

### Sync Current Workspace to Another Project
```bash
./sync-workspaces.sh sync . ~/Projects/my-other-project
```

### Sync All Projects in Your Development Folder
```bash
./sync-workspaces.sh sync-all . ~/Projects
```

### Install All Recommended Extensions
```bash
./sync-workspaces.sh install-extensions
```

## 🎨 Customization

### Add More Extensions
Edit `.vscode/extensions.json` and add extension IDs:
```json
{
    "recommendations": [
        "existing.extension",
        "new.extension-id"
    ]
}
```

### Modify Default Settings
Edit `template-settings.json` to include your preferred settings.

### Global vs Workspace Settings
- **Global settings** (User): Apply to all VS Code instances
- **Workspace settings** (`.vscode/settings.json`): Apply only to specific workspace
- Workspace settings override global settings

## 🚀 Best Practices

1. **Use Settings Sync** for personal preferences
2. **Use workspace files** for project-specific configurations
3. **Version control** your `.vscode` folder for team consistency
4. **Document** project-specific requirements in README files

## 🔍 Manual Alternative

If you prefer manual setup, copy these files to any new workspace:
1. Copy `template-settings.json` to `.vscode/settings.json`
2. Copy `.vscode/extensions.json`
3. Run `code --install-extension <extension-id>` for each extension

## 📋 Extension Recommendations

Essential extensions included in the template:
- **Python**: Full Python development support
- **Prettier**: Code formatting
- **Live Server**: Local development server
- **GitHub Copilot**: AI-powered coding assistance
- **YAML/JSON**: Configuration file support

---

This setup ensures all your workspaces start with a solid foundation of tools and settings! 🎉
