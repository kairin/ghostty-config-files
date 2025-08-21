# AI Agent Instructions for Ghostty Configuration Project

This document serves as the unified source of truth for all AI agents (Claude Code, Gemini CLI, and others) working with this Ghostty configuration repository.

## Project Overview

This repository contains a modular and minimalist Ghostty terminal emulator configuration with automated installation and setup scripts. The project emphasizes simplicity, cross-platform compatibility, and comprehensive tooling integration.

## Guiding Principles

### 1. Modularity
The configuration is split into multiple files for better organization:
- `theme.conf`: Theme and appearance settings
- `scroll.conf`: Scrollback and history settings  
- `layout.conf`: Font, padding, and window layout settings
- `keybindings.conf`: All keybindings
- Main `config` file: Contains only includes to these files

### 2. Minimalism
- Keep configuration clean and simple
- Avoid unnecessary settings or complexity
- Focus on essential functionality
- Use clear, self-documenting code

### 3. Cross-Platform Compatibility
- Primary target: Linux (Ubuntu/Debian)
- Configuration should work across different environments
- Installation scripts handle various system configurations gracefully
- Robust error handling and recovery mechanisms

### 4. Comprehensive Tooling
The project includes complete installation for:
- **ZSH Shell**: Modern shell with Oh My ZSH and enhanced plugins
- **Ghostty**: Latest version built from source with Zig 0.14.0
- **Ptyxis**: Latest version via Flatpak with proper permissions
- **Node.js Environment**: Via NVM with latest LTS and npm
- **Claude Code**: Latest version via npm global install
- **Gemini CLI**: Latest version via npm global install
- **System Dependencies**: All required development libraries and tools

## Installation Architecture

### Primary Installation Script: `start.sh`
- **Purpose**: Single command for complete environment setup
- **Intelligence**: Automatic detection of existing installations
- **Smart Logic**: Optimal upgrade vs reinstall decision making
- **Version Monitoring**: Online update checking and compatibility testing
- **Features**: Comprehensive logging, error handling, dependency management
- **Options**: Modular installation with skip flags for different components
- **Safety**: Configuration backup and validation throughout process

### Configuration Protection
- **Automatic Backup**: Before any git operations, configurations are backed up with timestamps
- **Configuration Validation**: All changes tested using `ghostty +show-config`
- **Safe Recovery**: Automatic restoration of last known working configuration
- **Compatibility Testing**: New Ghostty versions tested against existing configuration

### Dependency Management
The installation process handles all required dependencies:
- **Build Tools**: build-essential, pkg-config, gettext, msgfmt, xmllint
- **GTK4 Development**: Complete GTK4 and libadwaita packages
- **Graphics Libraries**: freetype, harfbuzz, fontconfig, png, cairo, vulkan
- **System Libraries**: X11, Wayland, glib, system integration libraries
- **Zig 0.14.0**: Downloaded and installed from source with system-wide linking

## Agent Workflow Guidelines

### For Code Changes
1. **Read Before Writing**: Always use Read tool before making any edits
2. **Configuration Validation**: Test changes with `ghostty +show-config`
3. **Modular Organization**: Add new settings to appropriate files in `configs/ghostty/`
4. **Structured Layout**: Maintain clean separation between configs, scripts, and docs
5. **No New Scripts**: Resolve issues within existing scripts, don't create new ones
6. **Documentation**: Update relevant documentation for significant changes

### For Git Operations
- **Commit Messages**: Use conventional commit format (`feat:`, `fix:`, `docs:`)
- **Branch Strategy**: Work on `main` branch
- **Testing**: Always run configuration validation before commits
- **Backup First**: Configuration backup happens automatically

### For Troubleshooting
1. **Check Logs**: Installation logs stored in `/tmp/ghostty-start-logs/`
2. **Validate Config**: Use `ghostty +show-config` for configuration issues
3. **Smart Diagnosis**: Script automatically determines upgrade vs reinstall strategy
4. **Dependency Check**: Verify all required packages are installed
5. **Permission Issues**: Check file permissions and ownership
6. **Fallback Process**: Use automatic backup restoration when needed

## Terminal Integration Workflows

### Ptyxis Integration
Based on the ptyxis flatpak command execution guidance:
- **Correct Usage**: `flatpak run app.devsuite.Ptyxis -d "$(pwd)" -- [COMMAND]`
- **Working Directory**: Use `-d "$(pwd)"` for current directory context
- **Command Separation**: Use `--` separator for reliable argument passing
- **Permissions**: Home directory access granted via flatpak override
- **Seamless Integration**: `gemini` command aliased to automatically run in Ptyxis
- **Shell Support**: Aliases configured for both ZSH and Bash

### Claude Code Integration
- **Installation**: Via npm global install from @anthropic-ai/claude-code
- **Authentication**: Requires API key setup via `claude-code auth login`
- **Usage**: Available system-wide after shell restart
- **Configuration**: Follows standard Claude Code CLI patterns

### Gemini CLI Integration  
- **Installation**: Via npm global install from @google/generative-ai-cli
- **System Linking**: Symlinked to `/usr/local/bin/gemini` for easy access
- **API Setup**: Requires Google AI Studio API key configuration
- **Integration**: Works seamlessly with ptyxis terminal launcher

## File Structure Standards

```
ghostty-config-files/
├── start.sh              # Primary installation script with smart upgrade logic
├── README.md             # User-facing documentation  
├── AGENTS.md            # This file - AI agent instructions (single source of truth)
├── CLAUDE.md            # Claude Code setup guide
├── GEMINI.md            # Gemini CLI setup guide
├── configs/             # Configuration files organized by category
│   ├── ghostty/         # Ghostty terminal configuration
│   │   ├── config       # Main configuration file
│   │   ├── theme.conf   # Theme settings
│   │   ├── scroll.conf  # Scrollback settings
│   │   ├── layout.conf  # Layout and font settings
│   │   └── keybindings.conf # Keybinding configuration
│   └── workspace/       # Development workspace files
│       └── ghostty.code-workspace # VS Code workspace
└── scripts/             # Additional utility scripts
    ├── install_ghostty_config.sh
    ├── update_ghostty.sh
    ├── fix_config.sh
    └── agent_functions.sh
```

## Error Handling Protocols

### Configuration Errors
1. **Detect**: Use `ghostty +show-config` for validation
2. **Backup**: Automatic backup before any changes
3. **Restore**: Automatic restoration if validation fails  
4. **Report**: Clear error messages with resolution steps
5. **Verify**: Confirm restored configuration works

### Build Errors
1. **Dependency Check**: Verify all required packages installed
2. **Zig Version**: Ensure Zig 0.14.0 is available
3. **Clean Build**: Remove build artifacts and retry
4. **Log Analysis**: Parse build logs for specific error patterns
5. **Fallback**: Provide manual installation steps

### Installation Errors
1. **Sudo Authentication**: Pre-authenticate to avoid mid-process failures
2. **Network Issues**: Handle download failures gracefully
3. **Permission Problems**: Check and fix file ownership
4. **Partial Installs**: Clean up incomplete installations
5. **Recovery**: Provide clear recovery instructions

## Security Considerations

### Safe Installation Practices
- **Privilege Escalation**: Sudo only when necessary, pre-authenticated
- **Download Verification**: Checksums where available
- **Permission Management**: Proper file ownership and permissions
- **Sandbox Compliance**: Flatpak permission management
- **Secret Handling**: No secrets or keys in configuration files

### Log Security
- **Sensitive Data**: Filter passwords, tokens, keys from logs
- **User Information**: Redact personal paths and email addresses
- **API Keys**: Never log authentication credentials
- **Network URLs**: Remove embedded credentials from URLs
- **File Paths**: Generalize user-specific paths in logs

## Agent Behavioral Guidelines

### Communication Style
- **Concise Responses**: Brief, direct answers unless detail requested
- **Task Focus**: Address specific queries without unnecessary elaboration
- **Error Clarity**: Clear error messages with actionable solutions
- **Status Updates**: Regular progress updates for long-running operations

### Code Quality Standards
- **Security First**: Never introduce vulnerabilities or expose secrets
- **Idiomatic Code**: Follow existing patterns and conventions
- **Error Handling**: Comprehensive error checking and recovery
- **Documentation**: Self-documenting code, minimal comments
- **Testing**: Validate all changes before finalizing

### Problem-Solving Approach
1. **Understand**: Thoroughly analyze the problem and context
2. **Research**: Use existing codebase patterns and documentation  
3. **Plan**: Break complex tasks into manageable steps
4. **Implement**: Make minimal, targeted changes
5. **Validate**: Test thoroughly before marking complete
6. **Document**: Update relevant documentation for significant changes

## Version Management

### Ghostty Updates
- **Source**: Always build from latest Ghostty repository
- **Configuration Compatibility**: Test configuration after updates
- **Backup Strategy**: Automatic backup before version changes
- **Rollback Process**: Clear rollback procedure if issues arise

### Tool Updates
- **Node.js**: Use NVM for version management, LTS versions preferred
- **npm Packages**: Regular updates for Claude Code and Gemini CLI
- **System Dependencies**: Keep development libraries updated
- **Zig**: Pin to 0.14.0 for Ghostty compatibility

This document should be referenced by all AI agents working on this project to ensure consistent behavior and maintain the project's quality standards.