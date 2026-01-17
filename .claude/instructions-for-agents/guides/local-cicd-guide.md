# Local CI/CD Guide

Quick reference for daily local CI/CD operations.

## Common Commands

### Full Workflow

Run the complete local CI/CD pipeline:

```bash
./.runners-local/workflows/gh-workflow-local.sh all
```

### Individual Steps

```bash
# Validate configuration
./.runners-local/workflows/gh-workflow-local.sh validate

# Check Ghostty config
ghostty +show-config

# Check GitHub Actions billing
./.runners-local/workflows/gh-workflow-local.sh billing

# Initialize CI/CD environment
./.runners-local/workflows/gh-workflow-local.sh init
```

## Troubleshooting

### Workflow Fails

1. Check error output for specific failure
2. Fix configuration issues in the reported file
3. Re-run affected stage

### Configuration Invalid

1. Run `ghostty +show-config` to see validation errors
2. Check for syntax errors in `configs/ghostty/config`
3. Validate against Ghostty configuration schema

### GitHub Actions Cost Concerns

- Always run local validation **before** pushing
- Check billing with `.runners-local/workflows/gh-workflow-local.sh billing`
- Goal: Zero GitHub Actions cost through local-first testing

## See Also

- [Local CI/CD Operations](../requirements/local-cicd-operations.md) - Full requirements and policy
- [Git Strategy](../requirements/git-strategy.md) - Branch workflow and commit guidelines
