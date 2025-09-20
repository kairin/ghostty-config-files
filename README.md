# Ghostty Configuration Files - Constitutional Framework

> 🏛️ **Constitutional Compliance**: Zero GitHub Actions consumption • Local CI/CD only • Performance validated • User customization preserved

## 🚀 Quick Start

### One-Command Installation (Ubuntu)
```bash
# Clone repository
git clone https://github.com/yourusername/ghostty-config-files.git
cd ghostty-config-files

# Install everything (Ghostty + optimizations + AI tools)
# Features intelligent detection, real-time logging, and progress display
./start.sh

# Options for selective installation
./start.sh --skip-deps      # Skip system dependencies
./start.sh --skip-node      # Skip Node.js/NVM installation
./start.sh --skip-ai        # Skip AI tools (Claude Code, Gemini CLI)
./start.sh --skip-ptyxis    # Skip Ptyxis installation
./start.sh --verbose        # Show detailed real-time output
```

### Advanced Installation Features
- **Intelligent Detection**: Automatically detects existing installations (snap, APT, source)
- **Real-Time Progress**: See actual command output with progressive disclosure
- **Session Logging**: Complete logs saved with git-style naming (`YYYYMMDD-HHMMSS-*)
- **Smart Updates**: Only updates what's needed, preserves existing configurations
- **Graceful Handling**: Continues installation even if individual components fail

### What Gets Installed
- **Ghostty Terminal**: Intelligent detection of snap/APT/source installations with 2025 optimizations
- **Ptyxis Terminal**: Smart detection (apt → snap → flatpak preference order)
- **ZSH + Oh My ZSH**: Latest versions with automatic updates and intelligent configuration preservation
- **uv Python Manager**: Latest version with virtual environment support and PATH management
- **Node.js via NVM**: Latest LTS with automatic version management and dependency validation
- **AI Tools**: Claude Code + Gemini CLI with proper dependency checking and error handling
- **Context Menu Integration**: Right-click "Open in Ghostty" in file manager
- **Advanced Logging System**: Git-style session management with real-time command streaming
- **Performance Monitoring**: Local CI/CD with constitutional validation
- **Zero-Cost Infrastructure**: All workflows run locally, zero GitHub Actions consumption

## 🏗️ Constitutional Architecture

### Core Principles
1. **Zero GitHub Actions Consumption**: All CI/CD runs locally
2. **Performance First**: Lighthouse 95+ • <100KB JS • <2.5s LCP
3. **User Preservation**: Never overwrite customizations
4. **Branch Preservation**: Constitutional naming • No branch deletion
5. **Local Validation**: Test everything locally before deployment

### Technology Stack
- **Terminal**: Ghostty 1.2.0+ with Linux CGroup optimizations • Ptyxis terminal support
- **Shell**: ZSH with Oh My ZSH (latest versions, auto-updated)
- **Package Management**: uv for Python • NVM for Node.js • apt/snap preferred over flatpak
- **Intelligent Detection**: Smart tool recognition (snap/APT/source) with appropriate update strategies
- **Advanced Logging**: Git-style session management with real-time command streaming
- **Frontend**: Astro.build v5.13.9 • TypeScript strict mode • Tailwind CSS
- **Components**: shadcn/ui design system with accessibility compliance
- **AI Integration**: Claude Code + Gemini CLI with automatic updates
- **Automation**: Python 3.12+ with uv-first approach • Constitutional compliance
- **CI/CD**: Local shell runners • Zero GitHub Actions consumption

## 📊 Performance Targets (Constitutional)

### Core Web Vitals
- **First Contentful Paint (FCP)**: <1.8 seconds
- **Largest Contentful Paint (LCP)**: <2.5 seconds
- **Cumulative Layout Shift (CLS)**: <0.1
- **First Input Delay (FID)**: <100 milliseconds

### Build Performance
- **Build Time**: <30 seconds
- **JavaScript Bundle**: <100KB (gzipped)
- **CSS Bundle**: <20KB (gzipped)
- **Lighthouse Performance**: 95+

### System Performance
- **Ghostty Startup**: <500ms
- **Memory Usage**: <100MB baseline
- **CI/CD Execution**: <2 minutes complete workflow

## 🔍 Intelligent Detection System

### Smart Tool Recognition
The installation system automatically detects existing tools and their installation sources:

```bash
# Installation Source Detection
- **Ghostty**: Detects snap, APT, or source installations
- **Ptyxis**: Prefers apt → snap → flatpak (in order)
- **System Packages**: Only installs missing dependencies
- **Node.js Tools**: Validates npm dependencies before installation
```

### Installation Strategies
Based on detection, the system chooses optimal strategies:

```bash
# Strategy Examples
- **Snap/APT Installations**: Configuration updates only (no rebuilding)
- **Source Installations**: Repository updates and rebuilds when needed
- **Missing Tools**: Fresh installation with dependency validation
- **Update Management**: Smart version comparison and targeted updates
```

### Error Handling
Comprehensive dependency checking and graceful failures:

```bash
# Dependency Validation
- **Node.js Tools**: Checks for Node.js and npm before installation
- **Python Tools**: Validates curl and other dependencies
- **Build Tools**: Ensures all required packages before compilation
- **Configuration**: Validates settings before applying changes
```

## 🛠️ Development Commands

### Local CI/CD
```bash
# Complete local workflow
./local-infra/runners/gh-workflow-local.sh all

# Individual components
./local-infra/runners/test-runner-local.sh           # Run tests
./local-infra/runners/benchmark-runner.sh           # Performance benchmarks
./local-infra/runners/performance-monitor.sh        # Monitor performance

# Documentation generation
python scripts/doc_generator.py                     # Generate all docs
```

### Configuration Management
```bash
# Intelligent updates (preserves customizations)
./scripts/check_updates.sh

# Validate configuration
ghostty +show-config

# Install context menu
./scripts/install_context_menu.sh
```

### Performance Monitoring
```bash
# Monitor Core Web Vitals
python scripts/performance_monitor.py --url http://localhost:4321

# Check constitutional compliance
python scripts/constitutional_automation.py --validate

# Benchmark system performance
./local-infra/runners/benchmark-runner.sh --full
```

## 🏛️ Constitutional Compliance

### Branch Management
All branches follow constitutional naming: `YYYYMMDD-HHMMSS-type-description`

```bash
# Constitutional branch creation
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-enhancement"
git checkout -b "$BRANCH_NAME"
# Work on changes
git add .
git commit -m "Descriptive commit message

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
git push -u origin "$BRANCH_NAME"
```

### Zero-Cost Validation
```bash
# Check GitHub Actions usage
gh api user/settings/billing/actions | jq '.total_paid_minutes_used'

# Validate local workflows
./local-infra/runners/gh-workflow-local.sh validate
```

## 📚 Documentation

### Core Documentation
- [Constitutional Requirements](docs/constitutional/README.md)
- [Performance Guide](docs/performance/README.md)
- [API Documentation](docs/api/README.md)
- [Development Guide](docs/guides/development.md)

### Generated Documentation
- [Component Documentation](docs/api/components/)
- [Script Documentation](docs/api/scripts/)
- [Performance Reports](docs/performance/)

## 🔧 Troubleshooting

### Common Issues
```bash
# Configuration validation fails
ghostty +show-config                   # Check configuration
./scripts/fix_config.sh                # Automatic repair

# Performance issues
./local-infra/runners/benchmark-runner.sh --diagnose

# Update failures
./scripts/check_updates.sh --force      # Force updates
```

### Advanced Logging & Debugging

#### Git-Style Session Logs
Each installation creates a complete log session with timestamped files:
```bash
# View all logs from a session (replace with your timestamp)
ls -la /tmp/ghostty-start-logs/20250921-040238-ghostty-install*

# Main installation log (human-readable)
cat /tmp/ghostty-start-logs/20250921-040238-ghostty-install.log

# Complete command outputs (detailed debugging)
cat /tmp/ghostty-start-logs/20250921-040238-ghostty-install-commands.log

# Errors and warnings only
cat /tmp/ghostty-start-logs/20250921-040238-ghostty-install-errors.log

# Structured JSON data for parsing
jq '.' /tmp/ghostty-start-logs/20250921-040238-ghostty-install.json

# Performance metrics
jq '.' /tmp/ghostty-start-logs/20250921-040238-ghostty-install-performance.json
```

#### Quick Log Access
```bash
# Find latest session logs
ls -la /tmp/ghostty-start-logs/ | head -10

# View most recent installation
LOG_SESSION=$(ls -t /tmp/ghostty-start-logs/*.log | head -1 | sed 's/.*\///; s/\.log//')
echo "Latest session: $LOG_SESSION"
cat "/tmp/ghostty-start-logs/${LOG_SESSION}.log"

# Check for recent errors
cat /tmp/ghostty-start-logs/*errors.log | tail -20
```

#### Legacy CI/CD Logs
```bash
# View CI/CD logs
ls -la ./local-infra/logs/

# Performance metrics
jq '.' ./local-infra/logs/performance-*.json
```

## 🤝 Contributing

### Constitutional Requirements
- All changes must pass local CI/CD validation
- Performance targets must be maintained
- User customizations must be preserved
- Zero GitHub Actions consumption
- Complete documentation required

### Development Workflow
1. Run `./local-infra/runners/gh-workflow-local.sh all` before starting
2. Create constitutional branch with timestamp naming
3. Implement changes with constitutional compliance
4. Validate performance targets locally
5. Generate documentation updates
6. Commit with constitutional format
7. Merge to main preserving branch

## 📋 Constitutional Checklist

### Before Deployment
- [ ] Local CI/CD passes (`./local-infra/runners/gh-workflow-local.sh all`)
- [ ] Configuration validates (`ghostty +show-config`)
- [ ] Performance targets met (Lighthouse 95+, <100KB JS, <2.5s LCP)
- [ ] Zero GitHub Actions consumption confirmed
- [ ] User customizations preserved
- [ ] Documentation updated
- [ ] Constitutional branch naming used

### Quality Gates
- [ ] Build time <30 seconds
- [ ] Bundle size <100KB (JS) + <20KB (CSS)
- [ ] Core Web Vitals targets met
- [ ] Accessibility compliance (WCAG 2.1 AA)
- [ ] Constitutional compliance validated
- [ ] Complete test coverage

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

## 🏛️ Constitutional Framework

This project operates under a Constitutional Framework ensuring:
- **Performance**: Lighthouse 95+ scores maintained
- **Efficiency**: Zero GitHub Actions consumption
- **Preservation**: User customizations protected
- **Quality**: Comprehensive local validation
- **Accessibility**: WCAG 2.1 AA compliance

Generated with Constitutional Documentation Generator v2.1
Last Updated: 2025-09-21 04:15:00
Recent Updates: Intelligent Detection System • Git-Style Session Logging • Progressive Disclosure
