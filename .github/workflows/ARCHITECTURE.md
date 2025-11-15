# GitHub Actions Workflow Architecture

## Overview

The ghostty-config-files project uses a tiered CI/CD approach combining local automation with GitHub Actions for maximum efficiency and zero-cost compliance.

```
Development Workflow
====================

Developer
    ↓
Create feature branch (YYYYMMDD-HHMMSS-type-desc)
    ↓
Make changes locally
    ↓
Run local CI/CD (./.runners-local/workflows/gh-workflow-local.sh all)
    ↓ (all checks pass)
Push to GitHub feature branch
    ↓
GitHub Actions Triggers:
  ├→ validation-tests.yml (comprehensive validation)
  ├→ build-feature-branches.yml (Astro build check)
    ↓
Create Pull Request on main
    ↓
Review (all checks pass)
    ↓
Merge to main (git merge --no-ff, preserve branch)
    ↓
GitHub Actions Triggers:
  └→ deploy-pages.yml (build and deploy to GitHub Pages)
    ↓
Website updated at GitHub Pages URL
```

## Workflow Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ GitHub Actions Workflow System - ghostty-config-files      │
└─────────────────────────────────────────────────────────────┘

Event Triggers:
├─ Main Branch Push
│  └─→ deploy-pages.yml
│      ├─ Job: build (Astro TypeScript check & build)
│      ├─ Job: deploy (GitHub Pages deployment)
│      └─ Cost: 2-3 min
│
├─ Feature Branch Push
│  ├─→ validation-tests.yml
│  │   ├─ Job: shellcheck
│  │   ├─ Job: config-validation
│  │   ├─ Job: typescript-check
│  │   ├─ Job: performance-check
│  │   ├─ Job: critical-files-check
│  │   └─ Cost: 4-5 min
│  │
│  └─→ build-feature-branches.yml
│      ├─ Job: build-astro
│      ├─ Job: deployment-check
│      ├─ Job: code-quality
│      └─ Cost: 5-6 min
│
├─ Pull Request to Main
│  ├─→ validation-tests.yml (same as push)
│  └─→ build-feature-branches.yml (same as push)
│
├─ Monthly Schedule (1st of month)
│  └─→ zero-cost-compliance.yml
│      ├─ Job: actions-usage-check
│      ├─ Job: critical-files-protection
│      ├─ Job: branch-preservation-check
│      ├─ Job: local-cicd-enforcement
│      └─ Cost: 2 min
│
└─ Manual Dispatch
   └─→ All workflows available for manual trigger
```

## Workflow Components

### 1. Deploy Workflow (deploy-pages.yml)

**Triggered by**: Push to main branch
**Triggered on**: Code merge after PR approval
**Purpose**: Automated deployment to GitHub Pages

```
Build Job:
├─ Checkout code
├─ Setup Node.js v25
├─ Install npm dependencies
├─ Run TypeScript check
├─ Build Astro site
├─ CRITICAL: Verify .nojekyll file
├─ Verify build artifacts
│  ├─ docs/index.html exists
│  ├─ docs/_astro/ directory present
│  └─ Asset files count
└─ Upload Pages artifact

Deploy Job (requires build):
├─ Wait for build completion
├─ Deploy to GitHub Pages environment
└─ Report deployment URL
```

**Critical Validations**:
- `.nojekyll` file must exist (CRITICAL for CSS/JS assets)
- `docs/index.html` must be generated
- `docs/_astro/` directory must contain compiled assets

**Failure Handling**: Build failures block deployment; workflow logs available for debugging

### 2. Validation Workflow (validation-tests.yml)

**Triggered by**: Pull requests, feature branch pushes
**Triggered on**: Code changes during development
**Purpose**: Comprehensive code validation

```
Parallel Jobs:
├─ ShellCheck Job
│  └─ Validate all .sh files for syntax and style
│
├─ Config Validation Job
│  ├─ Ghostty config syntax check
│  ├─ Critical settings verification
│  └─ dircolors validation
│
├─ TypeScript Check Job
│  └─ TypeScript compilation validation
│
├─ Performance Check Job
│  ├─ CGroup optimization check
│  ├─ Font size validation
│  └─ Shell integration verification
│
└─ Critical Files Check Job
   ├─ .nojekyll file verification
   ├─ Documentation structure check
   └─ Backup mechanism verification

Summary Job (depends on all):
└─ Report validation results
```

**Failure Conditions**:
- Shell syntax errors
- TypeScript compilation failures
- Missing .nojekyll file
- Critical configuration issues

**Pass Requirement**: All jobs must pass for PR merge eligibility

### 3. Build Workflow (build-feature-branches.yml)

**Triggered by**: Push to feature/fix branches
**Triggered on**: Development work on features
**Purpose**: Build validation and deployment readiness check

```
Build Job:
├─ Checkout code
├─ Setup Node.js v25
├─ Install dependencies
├─ TypeScript validation
├─ Astro build
├─ Verify artifacts
└─ Check .nojekyll preservation

Deployment Check Job:
├─ Verify Pages configuration
├─ Check deployment directory
└─ Validate deployment readiness

Code Quality Job:
├─ TypeScript error detection
├─ Configuration linting
└─ JSON validation

Summary Job:
└─ Report build status
```

**Purpose**: Provides immediate feedback during feature development

### 4. Compliance Workflow (zero-cost-compliance.yml)

**Triggered by**: Monthly schedule (1st of month, 00:00 UTC)
**Triggered on**: Constitutional compliance monitoring
**Purpose**: Verify zero-cost and branch preservation requirements

```
Usage Check Job:
├─ Monitor GitHub Actions consumption
├─ Verify within free tier limits
└─ Document trigger analysis

Critical Files Job:
├─ Verify .nojekyll presence
├─ Check documentation structure
└─ Prevent forbidden deletions

Branch Preservation Job:
├─ Verify no destructive operations
├─ Validate commit history
└─ Confirm audit trail

Local CI/CD Enforcement Job:
├─ Check local CI/CD infrastructure
├─ Verify required scripts present
└─ Confirm enforcement active

Summary Job:
└─ Generate compliance report
```

**Purpose**: Ensures constitutional requirements are maintained

## Job Dependencies and Concurrency

### Dependency Graph

```
deploy-pages.yml:
  build ──┐
          ├─→ deploy

validation-tests.yml:
  ├─→ shellcheck ──┐
  ├─→ config-validation ──┐
  ├─→ typescript-check ──┐
  ├─→ performance-check ──┐
  └─→ critical-files-check ──┐
                          └─→ validation-summary

build-feature-branches.yml:
  ├─→ build-astro ──┐
  ├─→ deployment-check ──┐
  └─→ code-quality ──┐
                  └─→ build-summary

zero-cost-compliance.yml:
  ├─→ actions-usage-check ──┐
  ├─→ critical-files-protection ──┐
  ├─→ branch-preservation-check ──┐
  └─→ local-cicd-enforcement ──┐
                            └─→ compliance-summary
```

### Concurrency Control

- **Pages deployment** (`deploy-pages.yml`): Concurrency group "pages"
  - Only one deployment at a time
  - Cancel in-progress: false (preserve deployment integrity)
  - Prevents race conditions in GitHub Pages

- **Validation** (`validation-tests.yml`): No concurrency restrictions
  - Multiple validations can run in parallel
  - Independent checks don't conflict

- **Build** (`build-feature-branches.yml`): No concurrency restrictions
  - Multiple feature branch builds can run in parallel
  - Each feature is independent

- **Compliance** (`zero-cost-compliance.yml`): No concurrency restrictions
  - Monitoring job, non-blocking

## File Protection Strategy

### Critical Files

```
Protected Files:
├─ docs/.nojekyll (CRITICAL)
│  └─ Empty file that prevents Jekyll processing
│  └─ WITHOUT: All CSS/JS assets return 404
│  └─ Verified by: All deployment and build workflows
│
├─ CLAUDE.md (Constitutional requirements)
│  └─ Verified by: compliance-summary
│
├─ README.md (Project documentation)
│  └─ Verified by: compliance-summary
│
└─ .gitignore (Git configuration)
   └─ Verified by: compliance-summary
```

### Verification Points

1. **Pre-deployment** (deploy-pages.yml)
   - Check: `[ -f "docs/.nojekyll" ]`
   - Action: Fail if missing
   - Message: "ERROR: docs/.nojekyll missing - CRITICAL for GitHub Pages"

2. **Post-build** (build-feature-branches.yml)
   - Check: `.nojekyll` preserved after Astro build
   - Action: Warn and fail if modified
   - Message: "ERROR: .nojekyll file missing after build"

3. **Compliance check** (zero-cost-compliance.yml)
   - Check: Monthly verification of critical files
   - Action: Fail if deleted
   - Message: "CRITICAL: File protection violation detected"

## Zero-Cost Compliance Architecture

### Cost Breakdown

```
Monthly Cost Estimation:
│
├─ Main Branch Deployments (2-4/month)
│  └─ deploy-pages.yml: 2-3 min × 3 = 6-12 min
│
├─ Feature Development (10-20 PRs/month)
│  ├─ validation-tests.yml: 4-5 min × 15 = 60-75 min
│  └─ build-feature-branches.yml: 5-6 min × 15 = 75-90 min
│
├─ Monthly Compliance Check (1/month)
│  └─ zero-cost-compliance.yml: 2 min × 1 = 2 min
│
└─ Total: 150-300 minutes/month
   └─ Free Tier: 2,000 minutes/month
      └─ Available: 1,700-1,850 minutes for other projects
```

### Cost Optimization Strategies

1. **Local CI/CD First**: Developers run `./.runners-local/workflows/` locally
   - Catches errors before GitHub
   - Reduces failed workflow runs
   - Saves 20-30% of workflow minutes

2. **Parallel Jobs**: Most validation jobs run in parallel
   - Reduced total workflow time
   - Faster feedback to developers
   - Cost efficiency per workflow

3. **Selective Triggers**: Workflows only run when needed
   - `validation-tests.yml`: Only on path changes
   - `build-feature-branches.yml`: Only on feature branches
   - `zero-cost-compliance.yml`: Monthly schedule (minimal overhead)

4. **Artifact Caching**: npm dependencies cached
   - Faster installation (npm ci)
   - Reduced network traffic
   - Faster job completion

## Integration with Local CI/CD

### Local Execution First (Required)

```bash
# Before pushing any changes to GitHub, run:
./.runners-local/workflows/gh-workflow-local.sh all

# This executes locally and includes:
├─ Configuration validation
├─ Astro build testing
├─ Performance monitoring
├─ Documentation verification
└─ GitHub Actions simulation

# If local CI/CD passes, safe to push to GitHub
```

### GitHub Actions as Safety Net

GitHub Actions workflows provide:
- Final validation before main branch
- Branch protection enforcement
- Automated deployment on merge
- Constitutional compliance monitoring
- Public artifact preservation

## Troubleshooting Architecture

### Debug Information Locations

```
Local Logs:
├─ /tmp/ghostty-start-logs/
│  └─ All local execution logs with timestamps
│
├─ ./.runners-local/logs/
│  └─ Local workflow execution logs
│
└─ ./logs/
   └─ Performance metrics and performance dashboards

GitHub Logs:
├─ Actions tab → Workflow runs
│  └─ Real-time job execution logs
│
├─ PR → Checks tab
│  └─ Individual job status and logs
│
└─ Settings → Actions → Workflow permissions
   └─ Configuration and deployment logs
```

### Viewing Workflow Results

```bash
# List recent workflow runs
gh run list --limit 20 --json status,conclusion,name,createdAt

# View specific workflow logs
gh run view WORKFLOW_RUN_ID --log

# Watch workflow progress
gh run watch WORKFLOW_RUN_ID

# Check specific job logs
gh run view WORKFLOW_RUN_ID --log --job JOB_ID
```

## Security and Permissions

### Workflow Permissions

```yaml
permissions:
  contents: read          # Required: Check out code
  pages: write            # Required: GitHub Pages deployment
  id-token: write         # Required: OIDC token for Pages
  checks: write           # Optional: Report check results
  actions: read           # Optional: Read workflow status
```

### Secrets and Environment Variables

No secrets required for this repository:
- No API keys in workflows
- GitHub CLI uses existing authentication (gh auth)
- Credentials handled by GitHub's authentication layer

### Branch Protection Rules (Recommended)

Configure in GitHub repository settings:

```
Main branch protection:
├─ Require status checks to pass
│  ├─ validation-tests
│  └─ build-feature-branches
│
├─ Require pull request reviews
│  └─ 1 approval required
│
├─ Dismiss stale PR approvals
│  └─ Enabled (ensure fresh reviews)
│
└─ Require branches to be up to date
   └─ Enabled (before merging)
```

## Monitoring and Alerts

### Monthly Compliance Check

Automatically runs on 1st of month:
- Verifies .nojekyll file presence
- Checks critical files not deleted
- Monitors GitHub Actions usage
- Reports branch preservation status
- Validates local CI/CD presence

### Manual Compliance Check

```bash
# Trigger compliance check manually
gh workflow run zero-cost-compliance.yml

# View latest compliance report
gh run view $(gh run list -w zero-cost-compliance.yml -L 1 --json databaseId -q '.[] | .databaseId') --log
```

### Usage Monitoring

```bash
# Check GitHub Actions usage
gh api user/settings/billing/actions | jq .

# Monitor recent workflow costs
gh run list --limit 50 --json duration | \
  jq '[.[] | .duration] | add'
```

## Maintenance and Updates

### Updating Workflows

When updating workflows:

1. Test locally first:
   ```bash
   # Verify YAML syntax
   yamllint .github/workflows/*.yml

   # Simulate locally
   ./.runners-local/workflows/gh-workflow-local.sh validate
   ```

2. Create feature branch:
   ```bash
   DATETIME=$(date +"%Y%m%d-%H%M%S")
   git checkout -b "$DATETIME-update-workflows"
   ```

3. Update workflow files

4. Push and create PR:
   ```bash
   git push -u origin "$DATETIME-update-workflows"
   gh pr create --title "Update GitHub Actions workflows"
   ```

5. Review and merge

### Deprecating Workflows

To deprecate a workflow:
1. Update `on:` trigger to `workflow_dispatch` only
2. Add comment explaining deprecation
3. Update README.md
4. Create PR with deprecation notice
5. After 30 days, safely delete

Example:
```yaml
name: [DEPRECATED] Old Workflow Name
on:
  workflow_dispatch:
    inputs:
      reason:
        description: 'Deprecated - use new-workflow.yml instead'
```

## References

- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Astro.build Documentation](https://docs.astro.build)
- [CLAUDE.md](../../CLAUDE.md) - Constitutional requirements
- [Local CI/CD Guide](.runners-local/README.md)
