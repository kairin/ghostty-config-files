# Claude Code Integration Guide

For comprehensive AI agent instructions and project guidelines, see **[AGENTS.md](./AGENTS.md)** - the single source of truth for all AI assistants working with this project.

## Quick Start with Claude Code

Claude Code is automatically installed by the `start.sh` script. After installation:

1. **Authenticate Claude Code:**
   ```bash
   claude-code auth login
   ```
   Get your API key from: https://console.anthropic.com

2. **Use with Ghostty Configuration:**
   ```bash
   # From project directory
   claude-code
   ```

3. **Integration with Ptyxis:**
   ```bash
   # Use the installed alias (after shell restart)
   ptyxis-gemini
   ```

## Key Commands

- `claude-code --help` - Show all available commands
- `claude-code auth status` - Check authentication status  
- `claude-code auth logout` - Remove stored credentials

## Project-Specific Usage

When using Claude Code with this Ghostty configuration project:

- **Configuration Changes**: Always validate with `ghostty +show-config`
- **Follow Modularity**: Add settings to appropriate config files
- **Backup First**: Configurations are automatically backed up
- **Test Thoroughly**: Run the complete `start.sh` script to verify changes

For complete guidelines, workflows, and troubleshooting information, refer to **[AGENTS.md](./AGENTS.md)**.