# Troubleshooting & FAQ

## 🔧 Constitutional Troubleshooting Framework

This guide provides systematic troubleshooting procedures for all constitutional framework components with zero GitHub Actions consumption.

## 🚨 Emergency Procedures

### System Recovery Commands
```bash
# Constitutional system recovery
./scripts/emergency_recovery.sh

# Quick diagnostic check
./local-infra/runners/diagnostic-check.sh

# Validate all systems
./local-infra/runners/gh-workflow-local.sh validate
```

### Critical Issue Escalation
1. **Configuration Failure**: `ghostty +show-config` fails
2. **Build Failure**: Build time exceeds 30 seconds or fails
3. **Performance Regression**: Lighthouse score drops below 95
4. **Constitutional Violation**: GitHub Actions consumption detected

## 🏗️ Installation & Setup Issues

### Q: Installation fails on fresh Ubuntu system
**Symptoms**: `./start.sh` exits with errors, missing dependencies
**Constitutional Impact**: ❌ Blocks complete setup

**Solution**:
```bash
# 1. Check system requirements
lsb_release -a  # Ubuntu 22.04+ required
node --version  # Should show Node.js LTS

# 2. Clean previous installations
rm -rf ~/.config/ghostty/
rm -rf node_modules/
rm -rf .venv/

# 3. Force reinstall with verbose logging
./start.sh --verbose --force

# 4. Check logs for specific errors
tail -f /tmp/ghostty-start-logs/start-$(date +%Y%m%d)*.log
```

**Prevention**:
- Always run on supported Ubuntu versions (22.04+)
- Ensure adequate disk space (minimum 2GB free)
- Check internet connectivity for downloads

### Q: Ghostty configuration validation fails
**Symptoms**: `ghostty +show-config` returns errors
**Constitutional Impact**: ❌ Configuration integrity compromised

**Solution**:
```bash
# 1. Backup current config
cp ~/.config/ghostty/config ~/.config/ghostty/config.backup

# 2. Run configuration repair
./scripts/fix_config.sh

# 3. Validate repair
ghostty +show-config

# 4. If still failing, restore known-good config
cp configs/ghostty/config ~/.config/ghostty/config
ghostty +show-config
```

**Common Config Issues**:
- **Invalid syntax**: Check for typos in key names
- **Duplicate keys**: Remove duplicate configuration entries
- **Path issues**: Ensure all file paths exist and are accessible

### Q: Context menu integration not working
**Symptoms**: Right-click "Open in Ghostty" missing in file manager
**Constitutional Impact**: ⚠️ Reduced user experience

**Solution**:
```bash
# 1. Reinstall context menu
./scripts/install_context_menu.sh --force

# 2. Restart file manager
nautilus -q && nautilus &

# 3. Check desktop file
cat ~/.local/share/applications/ghostty.desktop

# 4. Verify integration
ls -la ~/.local/share/nautilus/scripts/
```

## 🏛️ Constitutional Compliance Issues

### Q: GitHub Actions consumption detected
**Symptoms**: Billing shows non-zero paid minutes
**Constitutional Impact**: 🚨 CRITICAL - Constitutional violation

**Solution**:
```bash
# 1. Immediate assessment
gh api user/settings/billing/actions | jq '.total_paid_minutes_used'

# 2. Identify source
gh run list --limit 50 --json name,status,conclusion,createdAt

# 3. Disable all workflows (if any exist)
find .github/workflows/ -name "*.yml" -exec mv {} {}.disabled \;

# 4. Validate zero consumption
./local-infra/runners/gh-workflow-local.sh billing

# 5. Document incident
echo "$(date): GitHub Actions consumption detected" >> constitutional-violations.log
```

**Prevention**:
- Never create `.github/workflows/*.yml` files with active triggers
- All CI/CD must run locally via `local-infra/runners/`
- Regular monitoring with `gh api user/settings/billing/actions`

### Q: Performance targets not meeting constitutional requirements
**Symptoms**: Lighthouse scores below 95, bundle sizes exceeding limits
**Constitutional Impact**: ❌ Performance degradation

**Solution**:
```bash
# 1. Run comprehensive performance audit
./local-infra/runners/benchmark-runner.sh --full

# 2. Identify performance bottlenecks
./local-infra/runners/performance-monitor.sh --diagnose

# 3. Check bundle sizes
npm run build:analyze

# 4. Validate constitutional targets
python3 scripts/constitutional_automation.py --performance

# 5. Apply performance optimizations
./scripts/performance_optimizer.sh --constitutional
```

**Common Performance Issues**:
- **Large bundles**: Remove unused dependencies, enable tree shaking
- **Slow images**: Convert to WebP/AVIF, implement lazy loading
- **Render blocking**: Inline critical CSS, defer non-essential JavaScript

## 🚀 Development Workflow Issues

### Q: Local CI/CD runners failing
**Symptoms**: `./local-infra/runners/*.sh` scripts exit with errors
**Constitutional Impact**: ❌ Development workflow blocked

**Solution**:
```bash
# 1. Check runner permissions
chmod +x local-infra/runners/*.sh

# 2. Validate dependencies
which gh || echo "GitHub CLI missing"
which node || echo "Node.js missing"
which python3 || echo "Python missing"

# 3. Test individual runners
./local-infra/runners/test-runner-local.sh --verbose
./local-infra/runners/benchmark-runner.sh --test

# 4. Check logs
ls -la local-infra/logs/
tail -f local-infra/logs/workflow-*.log
```

**Common Runner Issues**:
- **Permission denied**: Run `chmod +x` on all runner scripts
- **Missing dependencies**: Install GitHub CLI, Node.js, Python
- **Path issues**: Ensure scripts run from project root

### Q: Build process taking too long
**Symptoms**: Build time exceeds 30 seconds (constitutional limit)
**Constitutional Impact**: ❌ Performance target violation

**Solution**:
```bash
# 1. Measure build performance
time npm run build

# 2. Analyze build bottlenecks
npm run build -- --debug

# 3. Check for build optimization
grep -r "minify\|terser\|rollup" astro.config.mjs

# 4. Clear build cache
rm -rf .astro/ dist/ node_modules/.cache/

# 5. Optimize build process
npm install  # Fresh dependency installation
npm run build
```

**Build Optimization Strategies**:
- **Parallel processing**: Enable in `astro.config.mjs`
- **Cache optimization**: Configure TypeScript incremental builds
- **Dependency pruning**: Remove unused packages

### Q: TypeScript strict mode errors
**Symptoms**: TypeScript compilation fails with strict mode violations
**Constitutional Impact**: ❌ Code quality standards not met

**Solution**:
```bash
# 1. Check TypeScript configuration
cat tsconfig.json | jq '.compilerOptions.strict'

# 2. Run TypeScript compiler
npx tsc --noEmit

# 3. Fix common strict mode issues
npx tsc --noEmit --showConfig

# 4. Validate all files
find src/ -name "*.ts" -o -name "*.tsx" -o -name "*.astro" | xargs npx tsc --noEmit
```

**Common TypeScript Issues**:
- **Implicit any**: Add explicit type annotations
- **Null/undefined**: Use optional chaining and nullish coalescing
- **Unused variables**: Remove or prefix with underscore

## 🎨 Component & UI Issues

### Q: shadcn/ui components not rendering correctly
**Symptoms**: Components missing styles, not responsive
**Constitutional Impact**: ⚠️ User experience degradation

**Solution**:
```bash
# 1. Check component installation
ls -la src/components/ui/

# 2. Validate Tailwind CSS configuration
npx tailwindcss --init --dry-run

# 3. Check CSS imports
grep -r "@tailwind" src/styles/

# 4. Rebuild styles
npm run build:css

# 5. Test individual components
npm run dev
```

**Component Debugging Steps**:
1. Verify component imports and exports
2. Check CSS class names match Tailwind configuration
3. Validate component props and TypeScript interfaces
4. Test responsive breakpoints

### Q: Dark mode toggle not working
**Symptoms**: Theme switching doesn't persist, FOUC occurs
**Constitutional Impact**: ⚠️ Accessibility and UX issues

**Solution**:
```bash
# 1. Check theme implementation
grep -r "dark:" src/

# 2. Validate theme toggle component
cat src/components/ui/ThemeToggle.astro

# 3. Check localStorage persistence
# In browser console:
localStorage.getItem('theme')

# 4. Test theme system
npm run dev
# Test theme toggle functionality
```

**Theme System Debugging**:
- Verify CSS custom properties are defined
- Check theme class application on `<html>` element
- Validate JavaScript theme management
- Test system preference detection

## 📊 Performance & Monitoring Issues

### Q: Core Web Vitals failing constitutional targets
**Symptoms**: LCP > 2.5s, CLS > 0.1, FID > 100ms
**Constitutional Impact**: ❌ Performance requirements not met

**Solution**:
```bash
# 1. Measure current performance
./local-infra/runners/benchmark-runner.sh --core-vitals

# 2. Run Lighthouse audit
lighthouse http://localhost:4321 --view

# 3. Analyze performance bottlenecks
python3 scripts/performance_monitor.py --analyze

# 4. Apply specific optimizations
./scripts/optimize_core_vitals.sh

# 5. Validate improvements
./local-infra/runners/benchmark-runner.sh --compare
```

**Core Web Vitals Optimization**:
- **LCP**: Optimize images, preload critical resources
- **CLS**: Reserve space for dynamic content, avoid layout shifts
- **FID**: Minimize JavaScript execution time, defer non-critical scripts

### Q: Bundle size exceeding constitutional limits
**Symptoms**: JavaScript > 100KB, CSS > 20KB (gzipped)
**Constitutional Impact**: ❌ Performance budget violation

**Solution**:
```bash
# 1. Analyze bundle composition
npm run build:analyze

# 2. Check for large dependencies
npx bundlephobia-cli analyze package.json

# 3. Remove unused dependencies
npm uninstall <unused-package>

# 4. Enable code splitting
# Update astro.config.mjs with manual chunks

# 5. Validate bundle sizes
npm run build
ls -lh dist/assets/
```

**Bundle Size Optimization**:
- Tree shaking configuration
- Dynamic imports for non-critical code
- Bundle splitting strategies
- Dependency audit and removal

## 🔧 System Integration Issues

### Q: Accessibility validation failing
**Symptoms**: WCAG violations detected, screen reader issues
**Constitutional Impact**: ❌ Accessibility compliance not met

**Solution**:
```bash
# 1. Run comprehensive accessibility audit
npx @axe-core/cli http://localhost:4321

# 2. Check specific violations
npx pa11y http://localhost:4321 --standard WCAG2AA

# 3. Validate color contrast
# Use browser extension or manual testing

# 4. Test keyboard navigation
# Manual testing required

# 5. Run constitutional accessibility validation
python3 scripts/accessibility_validator.py --fix
```

**Accessibility Debugging Steps**:
1. Check semantic HTML structure
2. Validate ARIA labels and roles
3. Test keyboard navigation flow
4. Verify color contrast ratios
5. Test with actual screen readers

### Q: Local infrastructure scripts not executing
**Symptoms**: Permission denied, command not found errors
**Constitutional Impact**: ❌ Development workflow broken

**Solution**:
```bash
# 1. Check script permissions
ls -la local-infra/runners/

# 2. Make scripts executable
chmod +x local-infra/runners/*.sh
chmod +x scripts/*.py

# 3. Check script shebangs
head -1 local-infra/runners/*.sh
head -1 scripts/*.py

# 4. Validate shell compatibility
bash --version  # Ensure bash 4.0+

# 5. Test script execution
./local-infra/runners/test-runner-local.sh --version
```

## 📋 Common Error Messages & Solutions

### Error: `command not found: gh`
**Solution**: Install GitHub CLI
```bash
# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

# Authenticate
gh auth login
```

### Error: `Python module not found`
**Solution**: Set up Python environment
```bash
# Install uv if missing
curl -LsSf https://astral.sh/uv/install.sh | sh

# Recreate virtual environment
rm -rf .venv/
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

### Error: `Ghostty configuration invalid`
**Solution**: Reset to known-good configuration
```bash
# Backup current config
mv ~/.config/ghostty/config ~/.config/ghostty/config.broken

# Restore default config
cp configs/ghostty/config ~/.config/ghostty/config

# Validate
ghostty +show-config
```

### Error: `Build failed - out of memory`
**Solution**: Increase memory limits
```bash
# Increase Node.js memory
export NODE_OPTIONS="--max-old-space-size=4096"

# Build with increased memory
npm run build

# For persistent setting, add to .bashrc:
echo 'export NODE_OPTIONS="--max-old-space-size=4096"' >> ~/.bashrc
```

### Error: `Lighthouse audit failed`
**Solution**: Debug Lighthouse issues
```bash
# Run detailed Lighthouse audit
lighthouse http://localhost:4321 --chrome-flags="--no-sandbox" --verbose

# Check server status
curl -I http://localhost:4321

# Start fresh development server
npm run dev -- --host 0.0.0.0 --port 4321
```

## 🔍 Diagnostic Tools & Commands

### Quick Diagnostic Check
```bash
#!/bin/bash
# Quick system diagnostic

echo "🔍 Constitutional System Diagnostic"
echo "=================================="

# Check system requirements
echo "📋 System Requirements:"
lsb_release -d | grep -q "Ubuntu" && echo "✅ Ubuntu detected" || echo "❌ Ubuntu not detected"
node --version | grep -q "v" && echo "✅ Node.js installed" || echo "❌ Node.js missing"
python3 --version | grep -q "Python 3" && echo "✅ Python 3 installed" || echo "❌ Python 3 missing"
which gh > /dev/null && echo "✅ GitHub CLI installed" || echo "❌ GitHub CLI missing"

# Check Ghostty configuration
echo "🔧 Ghostty Configuration:"
ghostty +show-config > /dev/null 2>&1 && echo "✅ Configuration valid" || echo "❌ Configuration invalid"

# Check constitutional compliance
echo "🏛️ Constitutional Compliance:"
gh api user/settings/billing/actions --jq '.total_paid_minutes_used' | grep -q "^0$" && echo "✅ Zero GitHub Actions consumption" || echo "❌ GitHub Actions consumption detected"

# Check performance targets
echo "📊 Performance Status:"
npm run build > /dev/null 2>&1 && echo "✅ Build successful" || echo "❌ Build failed"

echo "=================================="
echo "Diagnostic complete"
```

### Performance Diagnostic
```bash
#!/bin/bash
# Performance diagnostic script

echo "📊 Performance Diagnostic"
echo "========================"

# Build performance
echo "🏗️ Build Performance:"
time npm run build 2>&1 | tee build-time.log

# Bundle size check
echo "📦 Bundle Analysis:"
ls -lh dist/assets/*.js | awk '{print $5, $9}' | while read size file; do
  echo "JavaScript: $file - $size"
done

ls -lh dist/assets/*.css | awk '{print $5, $9}' | while read size file; do
  echo "CSS: $file - $size"
done

# Lighthouse audit
echo "🔍 Lighthouse Audit:"
lighthouse http://localhost:4321 --output=json --quiet | jq '.categories.performance.score * 100'

echo "========================"
echo "Performance diagnostic complete"
```

## 📞 Support & Community

### Getting Help
1. **Check this troubleshooting guide** for common issues
2. **Run diagnostic scripts** to identify specific problems
3. **Review logs** in `local-infra/logs/` and `/tmp/ghostty-start-logs/`
4. **Validate constitutional compliance** with automated scripts
5. **Create issue report** with diagnostic output

### Issue Reporting Template
```markdown
## Issue Description
Brief description of the problem

## Constitutional Impact
- [ ] Configuration integrity compromised
- [ ] Performance targets not met
- [ ] GitHub Actions consumption detected
- [ ] Development workflow blocked
- [ ] User experience degraded

## Environment
- OS: Ubuntu XX.XX
- Node.js: vX.X.X
- Ghostty: vX.X.X
- Project version: vX.X.X

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Diagnostic Output
```bash
# Paste output from diagnostic commands
./local-infra/runners/diagnostic-check.sh
```

## Error Logs
```
# Paste relevant log entries
```

## Constitutional Compliance Check
```bash
# Paste output from compliance validation
python3 scripts/constitutional_automation.py --validate
```
```

### Emergency Contact Procedures
In case of critical constitutional violations:

1. **Immediate Actions**:
   - Stop all GitHub Actions if running
   - Validate zero consumption: `gh api user/settings/billing/actions`
   - Document incident with timestamp

2. **System Recovery**:
   - Run emergency recovery script
   - Validate all constitutional requirements
   - Generate compliance report

3. **Documentation**:
   - Record incident in constitutional violations log
   - Update prevention procedures
   - Review and strengthen monitoring

---

**Constitutional Troubleshooting Framework v2.0**
**Last Updated**: 2025-09-20
**Support Level**: ✅ Comprehensive coverage of all constitutional components
**Recovery Procedures**: ✅ Tested and validated emergency procedures