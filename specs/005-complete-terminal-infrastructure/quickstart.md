# Quick Start Guide: Complete Terminal Development Infrastructure

**Feature**: 005-complete-terminal-infrastructure
**Target**: Ubuntu 25.10 fresh installation
**Time**: ~10 minutes for complete setup
**Audience**: Developers setting up new development environments

---

## One-Command Installation

From a fresh Ubuntu 25.10 system:

```bash
cd /home/kkk/Apps/ghostty-config-files
./manage.sh install
```

That's it! The system will automatically install and configure:
- ✅ Ghostty terminal with 2025 performance optimizations
- ✅ ZSH + Oh My ZSH with productivity plugins
- ✅ Node.js (latest stable via fnm)
- ✅ AI tools (Claude Code, Gemini CLI)
- ✅ Modern Unix tools (bat, exa, ripgrep, fd, zoxide)
- ✅ Astro documentation site with GitHub Pages deployment
- ✅ Local CI/CD infrastructure (zero GitHub Actions cost)

---

## What Gets Installed

### Core Terminal Environment
- **Ghostty** (latest from source with Zig 0.14.0)
  - CGroup single-instance optimization
  - Enhanced shell integration
  - Auto theme switching (light/dark)
  - Context menu integration ("Open in Ghostty")

- **ZSH** (default shell)
  - Oh My ZSH framework
  - Productivity plugins
  - Optimized for <50ms startup time
  - Custom dircolors for readability

- **Node.js** (latest stable, currently v25.2.0+)
  - Installed via fnm (Fast Node Manager)
  - <50ms startup impact
  - Per-project version switching
  - Latest stable policy (constitutional requirement)

### AI Integration
- **Claude Code** (@anthropic-ai/claude-code)
  - Latest stable version via npm
  - Context-aware code assistance

- **Gemini CLI** (@google/gemini-cli)
  - Latest stable version via npm
  - Natural language command translation

- **GitHub Copilot CLI** (@github/copilot)
  - Latest stable version via npm
  - Command suggestions

- **zsh-codex** (optional)
  - AI-powered shell completions

### Modern Unix Tools
- **bat**: Better `cat` with syntax highlighting
- **exa**: Better `ls` with colors and icons
- **ripgrep**: Faster `grep` for code search
- **fd**: Better `find` with intuitive syntax
- **zoxide**: Smarter `cd` with directory jumping

### Web Development Stack
- **uv** (>=0.9.0): Python package manager (80-100x faster than pip)
- **Astro** (>=5.0): Static site generator
- **Tailwind CSS** (>=4.0): Utility-first CSS framework
- **DaisyUI** (latest): Component library
- **TypeScript** (>=5.9): Type-safe JavaScript

### Local CI/CD Infrastructure
- **nektos/act** (>=0.2.82): Run GitHub Actions locally
- **Lighthouse CI**: Performance and accessibility testing
- **axe-core**: Automated accessibility validation
- **npm audit**: Security vulnerability scanning

---

## First Steps After Installation

### 1. Verify Installation

```bash
# Check Ghostty configuration
ghostty +show-config

# Verify performance optimizations
ghostty +show-config | grep "linux-cgroup = single-instance"

# Check Node.js and npm
node --version  # Should be v25.2.0 or later
npm --version   # Should be v10.0.0 or later

# Verify AI tools
claude --version
gemini --version
gh copilot --version

# Check modern Unix tools
bat --version
exa --version
rg --version
fd --version
zoxide --version
```

### 2. Test Terminal Environment

```bash
# Open a new ZSH shell
zsh

# Check shell startup time (should be <50ms)
time zsh -i -c exit

# Test modern commands
bat README.md          # Syntax-highlighted file viewing
exa -la               # Enhanced directory listing
rg "pattern"          # Fast code search
fd "filename"         # Quick file finding
z ~/Documents         # Jump to directory (after using cd a few times)
```

### 3. Launch Documentation Site

```bash
# Build and preview documentation
./manage.sh docs build
./manage.sh docs dev

# View at http://localhost:4321
```

### 4. Run Local CI/CD

```bash
# Validate all configurations
./manage.sh validate

# Run complete CI/CD workflow locally
./manage.sh cicd run ci

# Check accessibility
./manage.sh validate accessibility

# Check security
./manage.sh validate security

# Check performance
./manage.sh validate performance
```

---

## Essential Configuration

### Update Ghostty Configuration

Edit `~/.config/ghostty/config`:

```ini
# Performance (already configured)
linux-cgroup = single-instance

# Shell Integration (already configured)
shell-integration = detect

# Theme Customization
theme = catppuccin-mocha  # or catppuccin-latte for light mode
auto-update-theme = true

# Font (customize to your preference)
font-family = "JetBrains Mono"
font-size = 12

# Your custom settings here...
```

Verify changes:
```bash
ghostty +show-config
```

### Customize ZSH Plugins

Edit `~/.zshrc`:

```bash
# Oh My ZSH plugins (already configured)
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  # Add more plugins as needed
)
```

Apply changes:
```bash
source ~/.zshrc
```

### Configure AI Tools

Set up API keys in `.env` (create if not exists):

```bash
# Claude Code
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxx

# Gemini CLI
GOOGLE_API_KEY=xxxxxxxxxxxxx

# GitHub Copilot (uses gh auth)
# No additional configuration needed
```

---

## Common Tasks

### Update Everything

```bash
# Smart update detection (only updates what's changed)
./manage.sh update all

# Force all updates (not recommended)
./manage.sh update all --force

# Update specific component
./manage.sh update node
./manage.sh update ghostty
./manage.sh update ai-tools
```

### Build and Deploy Documentation

```bash
# Development mode (hot reload)
./manage.sh docs dev

# Production build
./manage.sh docs build

# Deploy to GitHub Pages
./manage.sh docs deploy
```

### Run Quality Gates

```bash
# All quality gates
./manage.sh validate all

# Individual gates
./manage.sh validate accessibility
./manage.sh validate security
./manage.sh validate performance
```

### Manage Workflows

```bash
# List available workflows
./manage.sh cicd list

# Run specific workflow
./manage.sh cicd run <workflow-name>

# Test matrix builds
./manage.sh cicd matrix

# Check GitHub Actions usage (should be 0)
./manage.sh cicd billing
```

---

## Troubleshooting

### Installation Issues

**Problem**: Installation hangs or fails

**Solution**:
```bash
# Check logs
cat /tmp/ghostty-install-*.log

# View errors only
cat /tmp/ghostty-install-errors-*.log

# Retry installation
./manage.sh install --force
```

**Problem**: Passwordless sudo not configured

**Solution**:
```bash
# Configure passwordless sudo for apt
sudo visudo

# Add this line:
kkk ALL=(ALL) NOPASSWD: /usr/bin/apt

# Test
sudo -n apt update  # Should run without password prompt
```

### Performance Issues

**Problem**: Shell startup time >50ms

**Solution**:
```bash
# Profile ZSH startup
time zsh -i -c exit

# Disable slow plugins in ~/.zshrc
# Comment out plugins one by one to identify culprit

# Check for large history files
du -sh ~/.zsh_history

# Optimize startup (managed automatically)
./manage.sh update optimize
```

**Problem**: Ghostty not using CGroup optimization

**Solution**:
```bash
# Verify configuration
ghostty +show-config | grep linux-cgroup

# Should show:
# linux-cgroup = single-instance

# If not, reinstall:
./manage.sh install ghostty --force
```

### AI Tool Issues

**Problem**: AI tools not working

**Solution**:
```bash
# Verify installation
claude --version
gemini --version

# Check API keys
echo $ANTHROPIC_API_KEY
echo $GOOGLE_API_KEY

# Reinstall AI tools
./manage.sh install ai-tools --force
```

### Documentation Build Issues

**Problem**: Documentation site won't build

**Solution**:
```bash
# Check Node.js version (must be >=25.0.0)
node --version

# Verify dependencies
cd website
npm ci

# Run Astro check
npx astro check

# Clean build
./manage.sh docs clean
./manage.sh docs build
```

### CI/CD Issues

**Problem**: Local workflows fail

**Solution**:
```bash
# Verify act installation
act --version

# Check Docker
docker version
docker ps

# Start Docker if not running
sudo systemctl start docker

# Re-run workflow with verbose output
act push --verbose
```

---

## Advanced Configuration

### Custom Theme Installation

```bash
# Install Powerlevel10k
./manage.sh install theme powerlevel10k

# Or install Starship
./manage.sh install theme starship

# Configure
p10k configure  # For Powerlevel10k
# or edit ~/.config/starship.toml for Starship
```

### Team Configuration Sharing

```bash
# Export your configuration
./manage.sh config export my-config.tar.gz

# Share with team (via git or other means)

# Import on another machine
./manage.sh config import my-config.tar.gz
```

### Performance Monitoring

```bash
# Run performance benchmarks
./manage.sh benchmark all

# Generate performance report
./manage.sh benchmark report

# View performance dashboard
./manage.sh performance dashboard
```

---

## Next Steps

### Documentation
- Read full documentation at http://localhost:4321 (after running `./manage.sh docs dev`)
- User guides: Installation, Configuration, Daily usage
- Developer guides: Architecture, Contributing, CI/CD
- AI guidelines: Core principles, Git strategy, Slash commands

### Customization
- Explore Ghostty themes in `configs/ghostty/themes/`
- Add custom ZSH plugins to `~/.zshrc`
- Configure AI tool preferences
- Set up team configuration templates

### Development Workflow
- Create feature branches using constitutional naming: `YYYYMMDD-HHMMSS-type-description`
- Run local CI/CD before every commit
- Use quality gates to validate changes
- Deploy documentation updates to GitHub Pages

### Community
- Report issues via GitHub Issues
- Contribute improvements via Pull Requests
- Share configurations with team
- Document custom workflows

---

## Getting Help

### Documentation
- **User Guide**: http://localhost:4321/user-guide/
- **Developer Guide**: http://localhost:4321/developer/
- **AI Guidelines**: http://localhost:4321/ai-guidelines/
- **Specifications**: documentations/specifications/

### Commands
```bash
# General help
./manage.sh --help

# Command-specific help
./manage.sh install --help
./manage.sh docs --help
./manage.sh validate --help
./manage.sh cicd --help
```

### Logs
```bash
# Installation logs
ls -la /tmp/ghostty-install-logs/

# CI/CD logs
ls -la .runners-local/logs/

# View latest log
cat /tmp/ghostty-install-logs/start-*.log
```

### Support
- GitHub Issues: Report bugs and request features
- Discussions: Ask questions and share tips
- Pull Requests: Contribute improvements

---

## Success Metrics

After installation, you should achieve:

✅ **Performance**
- Shell startup: <50ms
- Ghostty startup: <500ms
- Documentation build: <2 minutes
- All quality gates pass

✅ **Functionality**
- All core components installed
- AI tools working
- Modern Unix tools available
- Documentation site builds and deploys
- Local CI/CD executes successfully

✅ **Quality**
- Lighthouse scores: 95+ across all metrics
- Zero accessibility violations (WCAG 2.1 Level AA)
- Zero high/critical security vulnerabilities
- All tests pass

✅ **Zero Cost**
- GitHub Actions minutes consumed: 0
- Local CI/CD handles all validation
- Self-contained development environment

---

**Ready to get started?**

```bash
cd /home/kkk/Apps/ghostty-config-files
./manage.sh install
```

Installation takes ~10 minutes. Sit back and watch the parallel task UI show real-time progress!

For detailed implementation guidance, see [plan.md](./plan.md).
