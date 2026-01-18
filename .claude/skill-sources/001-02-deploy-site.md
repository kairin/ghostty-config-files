---
description: "Build and deploy Astro website to GitHub Pages"
handoffs:
  - label: "Git Sync"
    prompt: "Run /001-03-git-sync to synchronize the repository with remote"
---

# Deploy Site

Build the Astro website and deploy to GitHub Pages with comprehensive validation.

## Instructions

When the user invokes `/deploy-site`, execute the deployment workflow below. This skill only works in the ghostty-config-files project.

## Project Detection

```bash
# Verify we're in the correct project
if [ ! -d ".runners-local" ] && [ ! -f "AGENTS.md" ]; then
  echo "ERROR: /deploy-site only works in the ghostty-config-files project"
  echo "Current directory: $(pwd)"
  exit 1
fi
```

If not in ghostty-config-files, report:
```
=====================================
DEPLOY SITE - NOT AVAILABLE
=====================================
This skill requires the ghostty-config-files project.

Current directory: [pwd]
Expected markers: .runners-local/ or AGENTS.md

Please navigate to the ghostty-config-files repository.
=====================================
```

## Deployment Workflow

### Step 1: Install Dependencies

```bash
(cd astro-website && npm install)
```

Report any dependency installation issues.

### Step 2: Build Site

```bash
# Run the Astro build (subshell isolates directory change)
(cd astro-website && npm run build)

# Or use the local workflow script (runs from repo root)
# ./.runners-local/workflows/astro-build-local.sh
```

Capture build output for metrics.

### Step 3: Verify .nojekyll

**CRITICAL**: This file MUST exist for GitHub Pages to serve _astro/ assets correctly.

```bash
# Check for .nojekyll in docs/ (from repo root)
if [ ! -f "docs/.nojekyll" ]; then
  echo "WARNING: .nojekyll missing - creating it now"
  touch docs/.nojekyll
  echo "PASS: .nojekyll created"
else
  echo "PASS: .nojekyll exists"
fi
```

### Step 4: Collect Build Metrics

```bash
# Count files
FILE_COUNT=$(find docs/ -type f | wc -l)

# Total size
TOTAL_SIZE=$(du -sh docs/ | cut -f1)

# Asset breakdown
ASTRO_SIZE=$(du -sh docs/_astro/ 2>/dev/null | cut -f1 || echo "N/A")
```

### Step 5: Deploy

The site deploys to GitHub Pages automatically when pushed to main branch. Alternatively, run:

```bash
# If using the complete workflow script
./.runners-local/workflows/astro-complete-workflow.sh
```

## Output Format

```
=====================================
DEPLOY SITE REPORT
=====================================
Project: ghostty-config-files
Build: SUCCESS

Build Metrics:
--------------
| Metric        | Value           |
|---------------|-----------------|
| File Count    | 42              |
| Total Size    | 1.2M            |
| Build Time    | 12.3s           |

Validation:
-----------
| Check         | Status          |
|---------------|-----------------|
| .nojekyll     | PASS            |
| HTML valid    | PASS            |

Deployment URL:
https://kairin.github.io/ghostty-config-files/

Result: SUCCESS
=====================================
```

## Error Handling

- **Build errors**: Show TypeScript/Astro errors with file locations
- **Missing dependencies**: Suggest `npm install`
- **Permission errors**: Check file ownership
- **.nojekyll missing**: Auto-create and warn

## Constitutional Compliance

- **NEVER delete docs/.nojekyll** - This breaks all CSS/JS on GitHub Pages
- **Local validation** before any push operations

## Next Steps

After successful deployment:
- Suggest `/001-03-git-sync` to push changes to remote
- Provide deployment URL for verification

**Always include this in your output:**
```
Next Skill:
-----------
→ /001-03-git-sync - Synchronize repository with remote safely
```
