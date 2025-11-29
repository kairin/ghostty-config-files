# System Health Check Script

## Quick Start

```bash
# Run the health check
./scripts/system_health_check.sh

# View results
cat system_health_report_*.txt
```

## What It Does

Performs 45+ comprehensive checks across 6 categories:

1. **Software Installation** (14 checks) - Ghostty, ZSH, Node.js, AI CLIs, Python tools
2. **Constitutional Compliance** (6 checks) - Node.js v25+, configuration files
3. **Configuration Validation** (8 checks) - Ghostty config, .zshrc, optimizations
4. **File Integrity** (12 checks) - Critical scripts, configs, directories, symlinks
5. **Performance Metrics** (4 checks) - Startup times, execution speed
6. **Idempotency Tests** (2 checks) - State tracking, installation verification

## Output

### Text Report
- Human-readable summary
- Issues and warnings listed
- Performance metrics
- Recommendations

### JSON Report
- Machine-parsable format
- For automation/CI/CD
- Includes all metrics and versions

## Score Interpretation

| Score | Status | Meaning |
|-------|--------|---------|
| 90-100% | EXCELLENT | System in excellent health |
| 75-89% | GOOD | Minor issues |
| 60-74% | FAIR | Some issues need attention |
| 40-59% | POOR | Multiple issues |
| 0-39% | CRITICAL | Serious problems |

## Common Issues

### Node.js v24 (Should be v25+)
```bash
fnm install 25
fnm default 25
fnm use 25
```

### Duplicate Configuration Blocks
```bash
# Edit .zshrc and remove duplicates
nano ~/.zshrc
```

### Configuration Syntax Errors
```bash
# Test configs
ghostty +show-config
zsh -n ~/.zshrc
```

## Documentation

- **User Guide**: `documentations/user/health-check-guide.md`
- **Test Scenarios**: `documentations/developer/health-check-test-scenarios.md`
- **CLAUDE.md**: Constitutional requirements

## Integration

### Cron (Daily Check)
```bash
crontab -e
# Add: 0 9 * * * cd /path/to/repo && ./scripts/system_health_check.sh
```

### CI/CD
```bash
./scripts/system_health_check.sh
LATEST_REPORT=$(ls -t system_health_report_*.json | head -1)
PERCENTAGE=$(jq -r '.health.percentage' "$LATEST_REPORT")
if (( $(echo "$PERCENTAGE < 90" | bc -l) )); then
    echo "Health check failed"
    exit 1
fi
```

## Exit Codes

- `0` - Health >= 75% (excellent or good)
- `1` - Health < 75% (fair, poor, or critical)

## Related Scripts

- `scripts/fix_constitutional_violations.sh` - Fix compliance issues
- `scripts/check_updates.sh` - Check for updates
- `scripts/daily-updates.sh` - Automated updates
