# System Health Check Guide

## Overview

The `system_health_check.sh` script provides comprehensive validation of your ghostty-config-files installation. It performs 45+ checks across 6 categories to ensure your system is properly configured and meets constitutional requirements.

## Quick Start

```bash
# Run the health check
./scripts/system_health_check.sh

# View the report
cat system_health_report_*.txt

# View JSON report (for automation)
cat system_health_report_*.json
```

## What Gets Checked

### 1. Software Installation (14 checks)

Validates that all required software is installed and accessible:

- **Ghostty Terminal**: Version, installation method (snap/source), binary location
- **ZSH Shell**: Version, Oh My Zsh installation, configured plugins
- **Node.js & fnm**: Version compliance (v25+), fnm installation
- **npm**: Version and global packages
- **AI CLIs**: Claude Code, Gemini CLI, GitHub Copilot CLI
- **Python Tools**: uv, spec-kit
- **GitHub CLI**: Version and authentication status

### 2. Constitutional Compliance (6 checks)

Ensures configuration meets project constitutional requirements:

- **Node.js v25+**: Validates current version is v25 or higher
- **.node-version file**: Contains "25" (not "lts/latest")
- **start.sh**: Uses `NODE_VERSION="25"`
- **install_node.sh**: Uses `:=25` default
- **daily-updates.sh**: Uses `--latest` flag (not `--lts`)
- **fnm integration**: Shell configuration in .zshrc

### 3. Configuration Validation (8 checks)

Verifies configuration files are valid and optimized:

- **Ghostty config**: File exists, syntax valid, CGroup single-instance enabled
- **.zshrc**: Exists, syntax valid, no BSD stat commands, no duplicate blocks
- **Shell integration**: Proper fnm, Gemini CLI configuration

### 4. File Integrity (12 checks)

Ensures all critical files and directories are present:

- **Critical scripts**: Executable permissions on start.sh, install scripts
- **Configuration files**: Ghostty config, .zshrc, .node-version, CLAUDE.md
- **Directories**: Log directories writable, backup directories accessible
- **Symlinks**: No broken symlinks in repository

### 5. Performance Metrics (4 checks)

Measures and validates performance targets:

- **ZSH startup time**: Target <500ms (constitutional requirement)
- **Node.js execution**: Target <100ms
- **fnm initialization**: Target <50ms (constitutional requirement)
- **fnm versions**: Count of installed Node.js versions

### 6. Idempotency Tests (2 checks)

Validates state tracking for installation scripts:

- **npm cache**: Exists and functional
- **fnm data**: Node.js versions tracked correctly

## Health Score Interpretation

### Scoring System

- **Score**: Checks passed / Total checks (e.g., 42/45)
- **Percentage**: (Checks passed / Total) × 100

### Health Status Levels

| Percentage | Status | Color | Meaning |
|------------|--------|-------|---------|
| 90-100% | EXCELLENT | Green | System is in excellent health |
| 75-89% | GOOD | Green | Minor issues, generally healthy |
| 60-74% | FAIR | Yellow | Some issues need attention |
| 40-59% | POOR | Red | Multiple issues found |
| 0-39% | CRITICAL | Red | Serious problems, immediate action needed |

### Exit Codes

- **0**: Health >= 75% (excellent or good)
- **1**: Health < 75% (fair, poor, or critical)

## Understanding the Report

### Text Report Structure

```
========================================================================
SYSTEM HEALTH REPORT
========================================================================
Generated: 2025-11-13 13:29:20 UTC
System: Linux 6.17.0-6-generic
Hostname: kkk

OVERALL HEALTH: EXCELLENT (93.33%)
Score: 42 / 45

========================================================================
SUMMARY
========================================================================

✅ Successes: 42
❌ Failures: 1
⚠️  Warnings: 1

========================================================================
ISSUES FOUND (1)
========================================================================
 1. Duplicate Gemini CLI blocks found (8 instances)

========================================================================
WARNINGS (1)
========================================================================
 1. Actual idempotency tests require running installation scripts

========================================================================
PERFORMANCE METRICS
========================================================================
  fnm installed versions: 2
  fnm initialization time: 30ms
  ZSH startup time: 333ms
  Node.js execution time: 38ms

========================================================================
RECOMMENDATIONS
========================================================================

1. Review failed checks above and address critical issues
2. Run './scripts/fix_constitutional_violations.sh' to fix compliance issues
3. Re-run health check after fixes: './scripts/system_health_check.sh'
```

### JSON Report Structure

```json
{
  "timestamp": "2025-11-13T13:29:20Z",
  "system": {
    "os": "Linux",
    "kernel": "6.17.0-6-generic",
    "hostname": "kkk"
  },
  "health": {
    "score": 42,
    "max_score": 45,
    "percentage": 93.33,
    "status": "EXCELLENT"
  },
  "summary": {
    "successes": 42,
    "failures": 1,
    "warnings": 1
  },
  "issues": [
    "Duplicate Gemini CLI blocks found (8 instances)"
  ],
  "warnings": [
    "Actual idempotency tests require running installation scripts"
  ],
  "performance_metrics": {
    "fnm installed versions": "2",
    "fnm initialization time": "30ms",
    "ZSH startup time": "333ms",
    "Node.js execution time": "38ms"
  },
  "software_versions": {
    "ghostty": "1.2.3",
    "node": "v25.2.0",
    "fnm": "1.38.1",
    "npm": "11.6.2",
    "zsh": "5.9",
    "gh": "2.83.0",
    "claude": "2.0.37 (Claude Code)",
    "uv": "0.9.9"
  }
}
```

## Common Issues and Solutions

### Node.js Version Issues

**Issue**: "Node.js is v24 (v24.x.x) - should be v25+"

**Solution**:
```bash
# Install Node.js v25
fnm install 25
fnm default 25
fnm use 25

# Verify
node --version  # Should show v25.x.x

# Re-run health check
./scripts/system_health_check.sh
```

### Configuration File Issues

**Issue**: "start.sh uses NODE_VERSION=\"lts/latest\""

**Solution**:
```bash
# Run the constitutional compliance fixer
./scripts/fix_constitutional_violations.sh

# Or manually edit
# Edit start.sh and change NODE_VERSION="lts/latest" to NODE_VERSION="25"
```

### Duplicate Gemini CLI Blocks

**Issue**: "Duplicate Gemini CLI blocks found (8 instances)"

**Solution**:
```bash
# Backup .zshrc
cp ~/.zshrc ~/.zshrc.backup

# Remove duplicate blocks manually
# Keep only ONE instance of the Gemini CLI configuration block
nano ~/.zshrc

# Test
zsh -n ~/.zshrc

# Re-run health check
./scripts/system_health_check.sh
```

### Ghostty Config Invalid

**Issue**: "Ghostty config has syntax errors"

**Solution**:
```bash
# Test config manually
ghostty +show-config

# Review errors and fix
nano ~/.config/ghostty/config

# Verify fix
ghostty +show-config

# Re-run health check
./scripts/system_health_check.sh
```

### Performance Issues

**Issue**: "Shell startup time over 500ms (650 ms)"

**Diagnosis**:
```bash
# Profile ZSH startup
zsh -i -c exit

# Check for slow plugins
# Edit .zshrc and disable plugins one by one
```

**Common causes**:
- Too many Oh My Zsh plugins
- Slow Node.js version manager initialization
- Network calls during shell startup

**Solutions**:
```bash
# Use fnm instead of nvm (40x faster)
# Already implemented in this repo

# Disable unused Oh My Zsh plugins
# Edit .zshrc, remove plugins from plugins=()

# Use lazy loading for heavy tools
```

## Test Scenarios

### Scenario 1: Fresh System (No Software)

**Expected results**:
- Score: ~0/45 (0%)
- Status: CRITICAL
- Issues: All software checks fail
- Warnings: Missing configuration files

**Action**: Run `./start.sh` to install everything

### Scenario 2: Fully Installed System

**Expected results**:
- Score: 42-45/45 (93-100%)
- Status: EXCELLENT
- Issues: 0-3 minor issues
- Warnings: Idempotency test warnings (safe to ignore)

**Action**: Address any remaining issues shown in report

### Scenario 3: Partially Installed System

**Expected results**:
- Score: 15-35/45 (33-78%)
- Status: FAIR to GOOD
- Issues: Missing software, configuration errors
- Warnings: Multiple warnings about incomplete setup

**Action**: Review issues, run relevant install scripts

### Scenario 4: After Running Fixes

**Expected results**:
- Score: Improved by 3-10 points
- Status: One level improvement
- Issues: Reduced count
- Warnings: Fewer warnings

**Action**: Verify fixes worked, commit changes

## Automation Examples

### Daily Health Check (Cron)

```bash
# Add to crontab (crontab -e)
0 9 * * * cd /home/kkk/Apps/ghostty-config-files && ./scripts/system_health_check.sh > /tmp/daily-health.log 2>&1
```

### CI/CD Integration

```bash
#!/bin/bash
# In your CI/CD pipeline

# Run health check
./scripts/system_health_check.sh

# Get exit code
EXIT_CODE=$?

# Parse JSON report
LATEST_REPORT=$(ls -t system_health_report_*.json | head -1)
HEALTH_PERCENTAGE=$(jq -r '.health.percentage' "$LATEST_REPORT")

# Enforce threshold
if (( $(echo "$HEALTH_PERCENTAGE < 90" | bc -l) )); then
    echo "Health check failed: $HEALTH_PERCENTAGE%"
    exit 1
fi

echo "Health check passed: $HEALTH_PERCENTAGE%"
exit 0
```

### Monitoring Script

```bash
#!/bin/bash
# Monitor health trends over time

REPORTS_DIR="/home/kkk/Apps/ghostty-config-files"

echo "Health Trend Analysis"
echo "===================="

for report in $(ls -t "$REPORTS_DIR"/system_health_report_*.json | head -10); do
    TIMESTAMP=$(jq -r '.timestamp' "$report")
    PERCENTAGE=$(jq -r '.health.percentage' "$report")
    STATUS=$(jq -r '.health.status' "$report")
    echo "$TIMESTAMP: $PERCENTAGE% ($STATUS)"
done
```

## Best Practices

1. **Run before major changes**: Always run health check before modifying configuration
2. **Run after installations**: Verify all software installed correctly
3. **Regular checks**: Run weekly to catch configuration drift
4. **Track reports**: Keep historical reports to identify trends
5. **Fix issues promptly**: Don't let issues accumulate

## Troubleshooting

### Script Fails to Run

```bash
# Check permissions
ls -la scripts/system_health_check.sh

# Make executable if needed
chmod +x scripts/system_health_check.sh

# Run with bash explicitly
bash scripts/system_health_check.sh
```

### bc Command Not Found

```bash
# Install bc calculator
sudo apt install bc
```

### jq Command Not Found

```bash
# Install jq JSON processor
sudo apt install jq

# Note: JSON report will still be created, just may have formatting issues
```

### Reports Not Generated

```bash
# Check disk space
df -h

# Check permissions
ls -la /home/kkk/Apps/ghostty-config-files/

# Run with verbose output
bash -x scripts/system_health_check.sh
```

## Related Scripts

- `scripts/fix_constitutional_violations.sh` - Fixes compliance issues
- `scripts/check_updates.sh` - Checks for software updates
- `scripts/daily-updates.sh` - Automated update system
- `start.sh` - Complete system installation

## Support

For issues or questions:

1. Review the health report carefully
2. Check the issues and warnings sections
3. Follow recommendations in the report
4. Consult this guide for common solutions
5. Review CLAUDE.md for constitutional requirements
