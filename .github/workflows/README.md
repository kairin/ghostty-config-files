# GitHub Actions Workflows - Constitutional Zero-Cost CI/CD

This directory contains GitHub Actions workflows for automated deployment and validation of the ghostty-config-files repository. All workflows follow constitutional requirements for zero-cost operation and branch preservation.

## Workflow Overview

### 1. deploy-pages.yml

**Purpose**: Automated GitHub Pages deployment
**Trigger**: Push to `main` branch or manual dispatch
**Duration**: ~5-10 minutes

**Jobs**:
- **build**: Builds Astro documentation site with TypeScript validation
  - Checks Node.js dependencies (Astro, TypeScript, @astrojs/check)
  - Runs `npm run check` for TypeScript validation
  - Builds with `npm run build`
  - **CRITICAL**: Verifies `.nojekyll` file presence
  - Validates build artifacts (`docs/index.html`, `docs/_astro/`)

- **deploy**: Deploys to GitHub Pages environment
  - Uses `actions/deploy-pages@v4` for reliable deployment
  - Only runs on main branch
  - Sets environment URL for verification

**Critical Validations**:
```
✓ .nojekyll file must exist (CRITICAL for CSS/JS assets)
✓ docs/index.html must be generated
✓ docs/_astro/ directory must contain compiled assets
✓ Build must complete without errors
```

**Cost**: ~2-3 GitHub Actions minutes per deployment

### 2. validation-tests.yml

**Purpose**: Pull request and configuration validation
**Trigger**: Pull requests, push to feature branches, or manual dispatch
**Duration**: ~10-15 minutes

**Jobs**:
- **shellcheck**: Validates shell script syntax and best practices
  - Runs ShellCheck on all .sh files
  - Excludes node_modules and .git directories
  - Fails on critical issues, warns on style violations

- **config-validation**: Validates Ghostty configuration
  - Checks syntax of `configs/ghostty/config`
  - Validates critical settings (linux-cgroup, font-size, theme)
  - Validates dircolors configuration syntax

- **typescript-check**: Validates TypeScript in website
  - Runs `npm run check` in website directory
  - Verifies strict mode configuration
  - Catches compilation errors early

- **performance-check**: Validates performance optimizations
  - Checks for CGroup single-instance optimization
  - Validates font size configuration
  - Checks shell integration settings
  - Verifies installation script robustness

- **critical-files-check**: Ensures critical files are preserved
  - Verifies `.nojekyll` file exists
  - Checks documentation directory structure
  - Validates backup mechanisms

**Cost**: ~4-5 GitHub Actions minutes per pull request

### 3. build-feature-branches.yml

**Purpose**: Validates feature branch builds
**Trigger**: Push to `feature/**` or `fix/**` branches, or PRs to main
**Duration**: ~10-15 minutes

**Jobs**:
- **build-astro**: Complete Astro build with artifact validation
  - Installs dependencies with `npm ci`
  - Runs TypeScript check
  - Builds with `npm run build`
  - Verifies `.nojekyll` preservation
  - Reports build metrics

- **deployment-check**: Pre-deployment readiness verification
  - Checks GitHub Pages configuration
  - Verifies build directory structure
  - Reports deployment readiness

- **code-quality**: Code quality and linting checks
  - TypeScript error detection
  - Ghostty config formatting validation
  - JSON file validation for configs
  - Configuration syntax checking

**Cost**: ~5-6 GitHub Actions minutes per feature branch push

### 4. zero-cost-compliance.yml

**Purpose**: Constitutional compliance monitoring
**Trigger**: Monthly schedule (1st of month) or manual dispatch
**Duration**: ~5 minutes

**Jobs**:
- **actions-usage-check**: Monitors GitHub Actions consumption
  - Verifies zero-cost compliance
  - Documents trigger analysis
  - Confirms local CI/CD priority

- **critical-files-protection**: Verifies critical file safety
  - Ensures `.nojekyll` is present and intact
  - Checks documentation structure
  - Prevents forbidden deletions

- **branch-preservation-check**: Verifies branch strategy compliance
  - Confirms no destructive branch operations
  - Validates commit history integrity
  - Ensures audit trail preservation

- **local-cicd-enforcement**: Verifies local CI/CD infrastructure
  - Checks for required workflow scripts
  - Validates script availability
  - Confirms mandatory scripts present

**Cost**: ~2 GitHub Actions minutes per monthly check

## Constitutional Requirements

### Zero-Cost Operation

All workflows follow these principles:

1. **Local Execution First**: Development and testing via `.runners-local/workflows/`
2. **Minimal GitHub Actions Usage**: Only deployment and PR validation on GitHub
3. **No Redundant Runs**: Single workflow per event type
4. **Cost Monitoring**: Monthly compliance checks

### Critical File Protection

The `.nojekyll` file in `docs/` is ABSOLUTELY CRITICAL:

- **Without it**: All CSS/JS assets return 404 errors on GitHub Pages
- **Must be preserved**: In every deployment and build
- **Automatic validation**: All workflows verify its presence
- **Protected from deletion**: Compliance checks prevent removal

### Branch Preservation

All workflows preserve branch history:

- **No auto-delete**: Branches are never automatically deleted
- **Merge strategy**: Use `git merge BRANCH --no-ff` for history
- **Branch naming**: Follow `YYYYMMDD-HHMMSS-type-description` format
- **Audit trail**: Complete history preserved for troubleshooting

### Local CI/CD Enforcement

Developers must run local CI/CD before GitHub deployment:

```bash
# 1. Run complete local workflow
./.runners-local/workflows/gh-workflow-local.sh all

# 2. Create feature branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
git checkout -b "$DATETIME-feat-description"

# 3. Make changes and commit
git add .
git commit -m "Description

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# 4. Push to GitHub
git push -u origin "$DATETIME-feat-description"

# 5. Create PR and merge to main
git checkout main
git merge "$DATETIME-feat-description" --no-ff
git push origin main
```

## Workflow Triggers

### On Push to Main (Deploy)
- **Workflow**: `deploy-pages.yml`
- **Action**: Builds and deploys to GitHub Pages
- **Condition**: Always deployment-ready (validated by previous PR)

### On Pull Request (Validate)
- **Workflows**: `validation-tests.yml`, `build-feature-branches.yml`
- **Action**: Comprehensive validation
- **Condition**: Must pass all checks before merge

### On Push to Feature Branch (Build)
- **Workflow**: `build-feature-branches.yml`
- **Action**: Validates build and TypeScript
- **Condition**: Provides feedback for ongoing development

### Monthly Schedule (Compliance)
- **Workflow**: `zero-cost-compliance.yml`
- **Action**: Verifies constitutional compliance
- **Condition**: Ensures zero-cost operation maintained

## Workflow Status

Check workflow status in GitHub Actions:

```bash
# List recent workflow runs
gh run list --limit 10 --json status,conclusion,name,createdAt

# Watch workflow progress
gh run watch WORKFLOW_ID

# Get workflow logs
gh run view WORKFLOW_ID --log
```

## Troubleshooting

### Build Fails with Missing .nojekyll

**Error**: "docs/.nojekyll missing - CRITICAL for GitHub Pages"

**Solution**:
```bash
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "Fix: Restore critical .nojekyll file"
```

### Asset 404 Errors on GitHub Pages

**Cause**: `.nojekyll` file missing (Jekyll is processing Astro files)

**Solution**: Ensure file exists and is committed to main branch

### TypeScript Validation Fails

**Error**: TypeScript compilation errors in website

**Solution**:
```bash
cd website
npm install
npm run check
```

### ShellCheck Fails on Scripts

**Error**: Shell syntax or style issues

**Solution**:
```bash
shellcheck scripts/your-script.sh
# Fix issues as suggested
```

## Cost Analysis

**Monthly GitHub Actions Cost** (estimated):

| Workflow | Trigger | Frequency | Cost/Month |
|----------|---------|-----------|-----------|
| deploy-pages.yml | Main push | ~2-4x/month | 4-12 min |
| validation-tests.yml | PRs | ~10-20x/month | 40-100 min |
| build-feature-branches.yml | Feature push | ~20-30x/month | 100-180 min |
| zero-cost-compliance.yml | Monthly | 1x/month | 2 min |
| **Total** | | | **150-300 min/month** |

**Free Tier**: 2,000 minutes/month → **Well within free limits**

## Related Documentation

- [Local CI/CD Infrastructure](.runners-local/README.md)
- [GitHub Pages Setup](.runners-local/workflows/gh-pages-setup.sh)
- [Constitutional Requirements](CLAUDE.md)
- [Performance Monitoring](.runners-local/workflows/performance-monitor.sh)

## Adding New Workflows

When creating new workflows:

1. Follow naming convention: `{purpose}-{trigger}.yml`
2. Validate against constitutional requirements
3. Include `.nojekyll` verification if deploying to Pages
4. Document in this README
5. Ensure zero-cost compliance
6. Test with `gh workflow run`

## Questions or Issues?

Refer to:
- [CLAUDE.md](CLAUDE.md) - Constitutional requirements
- [README.md](../../README.md) - Project overview
- [Local CI/CD](../../.runners-local/README.md) - Local testing guide
