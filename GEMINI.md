# Gemini CLI Integration Guide

For comprehensive AI agent instructions and project guidelines, see **[AGENTS.md](./AGENTS.md)** - the single source of truth for all AI assistants working with this project.

## Quick Start with Gemini CLI

Gemini CLI is automatically installed by the `start.sh` script. After installation:

1. **Set up API Key:**
   ```bash
   # Get API key from https://makersuite.google.com/app/apikey
   export GEMINI_API_KEY="your-api-key-here"
   
   # Or add to your shell profile for persistence
   echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.bashrc
   ```

2. **Use with Ghostty Configuration:**
   ```bash
   # From project directory  
   gemini "help me optimize this ghostty configuration"
   ```

3. **Use with Ptyxis Integration:**
   ```bash
   # Use the convenient alias (after shell restart)
   ptyxis-gemini
   ```

## Key Commands

- `gemini --help` - Show all available commands
- `gemini --version` - Check installed version
- `gemini "your prompt here"` - Interactive AI assistance

## Ptyxis Integration

The installation creates a seamless integration by aliasing the `gemini` command to automatically launch in Ptyxis terminal:

```bash
# Alias automatically added to shell configuration:
alias gemini='flatpak run app.devsuite.Ptyxis -d "$(pwd)" -- ~/.nvm/versions/node/v24.6.0/bin/gemini'
```

This provides:
- Seamless `gemini` command usage that automatically launches in Ptyxis
- Current working directory context preserved with `-d "$(pwd)"`
- Proper command execution syntax using `--` separator for reliable argument passing
- Integration with both ZSH and Bash shells

## Project-Specific Usage

When using Gemini CLI with this Ghostty configuration project:

- **Configuration Changes**: Always validate with `ghostty +show-config`
- **Follow Modularity**: Add settings to appropriate config files  
- **Backup First**: Configurations are automatically backed up
- **Test Thoroughly**: Run the complete `start.sh` script to verify changes

For complete guidelines, workflows, and troubleshooting information, refer to **[AGENTS.md](./AGENTS.md)**.