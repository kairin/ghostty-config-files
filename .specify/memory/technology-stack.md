# Technology Stack

Complete guide to terminal environment, AI integration, and local CI/CD tools.

## Terminal Environment

### Ghostty
- **Source**: Built from source (Zig 0.14.0)
- **Optimizations**: 2025 performance features
- **Version**: Latest (1.1.4+, 1.2.0 upgrade planned)
- **Features**: CGroup single-instance, shell integration, theme switching

### ZSH
- **Framework**: Oh My ZSH
- **Plugins**: Productivity-focused plugin set
- **Shell Integration**: Auto-detection with Ghostty

### Context Menu
- **Integration**: Nautilus file manager
- **Feature**: "Open in Ghostty" right-click option

---

## AI Integration

### Claude Code
- **Installation**: Latest CLI via npm
- **Package**: `@anthropic-ai/claude-code`
- **Integration File**: `CLAUDE.md` (symlink to AGENTS.md)

### Gemini CLI
- **Provider**: Google's AI assistant
- **Integration**: Ptyxis terminal integration
- **Integration File**: `GEMINI.md` (symlink to AGENTS.md)

### Context7 MCP
- **Purpose**: Up-to-date documentation server
- **Features**: Best practices synchronization
- **Configuration**: `.env` file with `CONTEXT7_API_KEY`

### Node.js
- **Version**: Latest (v25.2.0+) via fnm
- **Policy**: Always use latest (not LTS)
- **Version Manager**: fnm (Fast Node Manager) - 40x faster than NVM
- **Startup Impact**: <50ms

---

## Local CI/CD

### GitHub CLI
- **Purpose**: Workflow simulation and API access
- **Usage**: Repository operations, workflow monitoring, billing checks

### Local Runners
- **Type**: Shell-based workflow execution
- **Location**: `./.runners-local/workflows/`
- **Performance**: <2 minutes complete workflow

### Performance Monitoring
- **Tool**: `performance-monitor.sh`
- **Metrics**: Startup time, memory usage, system state
- **Analysis**: System state and timing reports

### Zero-Cost Strategy
- **Principle**: All CI/CD runs locally before GitHub
- **Target**: 0 GitHub Actions minutes consumed
- **Free Tier**: 2,000 minutes/month (preserved)

---

## Directory Color Configuration

### XDG Compliance
- **Location**: `~/.config/dircolors` (not `~/.dircolors`)
- **Standard**: XDG Base Directory Specification
- **Deployment**: Automatic via `start.sh`
- **Shell Integration**: Auto-configured for bash and zsh

### Readability Features
- Directories: Bold yellow (highly readable)
- World-writable: Black on yellow (clear contrast)
- Sticky+writable: Black on green

---

**Back to**: [constitution.md](constitution.md)
**Related**: [local-cicd.md](local-cicd.md)
**Version**: 1.0.0
**Last Updated**: 2025-11-16
