# Ghostty Configuration Files - Constitutional Framework

> 🏛️ **Constitutional Compliance**: Zero GitHub Actions consumption • Local CI/CD only • Performance validated • User customization preserved

## 🚀 Quick Start

### One-Command Installation (Ubuntu)
```bash
# Clone repository
git clone https://github.com/yourusername/ghostty-config-files.git
cd ghostty-config-files

# Install everything (Ghostty + optimizations + AI tools)
./start.sh
```

### What Gets Installed
- **Ghostty Terminal**: Latest from source with 2025 optimizations
- **Context Menu Integration**: Right-click "Open in Ghostty" in file manager
- **AI Tools**: Claude Code + Gemini CLI for development assistance
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
- **Terminal**: Ghostty 1.2.0+ with Linux CGroup optimizations
- **Frontend**: Astro.build v5.13.9 • TypeScript strict mode • Tailwind CSS
- **Components**: shadcn/ui design system with accessibility compliance
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

### Logs & Debugging
```bash
# View system logs
ls -la /tmp/ghostty-start-logs/

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

Generated with Constitutional Documentation Generator v2.0
Last Updated: 2025-09-20 12:10:41
