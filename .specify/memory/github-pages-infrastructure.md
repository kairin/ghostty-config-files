# GitHub Pages Infrastructure Protection

Complete guide to `.nojekyll` file requirements, protection layers, and GitHub Pages deployment.

## Critical Requirement

**`.nojekyll` File is ABSOLUTELY CRITICAL**. This file MUST exist in the Astro build output directory to disable Jekyll processing and allow `_astro/` directory assets to load correctly.

## Technical Details

### Location
`docs/.nojekyll` (empty file, no content needed)

### Impact Without This File
ALL CSS/JS assets return 404 errors, breaking the entire site.

### Why This Matters
- GitHub Pages defaults to Jekyll processing
- Jekyll ignores directories starting with underscore (`_`)
- Astro outputs assets to `_astro/` directory
- Without `.nojekyll`, GitHub Pages ignores all Astro assets
- Result: Complete site styling and functionality failure

## Protection Layers

### Primary: Astro Public Directory
```bash
# Location: website/public/.nojekyll
# Automatically copied to docs/.nojekyll during build
```

### Secondary: Vite Plugin Automation
```javascript
// astro.config.mjs
import { writeFileSync } from 'fs';

export default defineConfig({
  vite: {
    plugins: [{
      name: 'nojekyll-plugin',
      writeBundle() {
        writeFileSync('docs/.nojekyll', '');
      }
    }]
  }
});
```

### Tertiary: Post-Build Validation
```bash
# .runners-local/workflows/astro-build-local.sh
if [ ! -f "docs/.nojekyll" ]; then
  echo "CRITICAL: .nojekyll missing - creating now"
  touch docs/.nojekyll
fi
```

### Quaternary: Pre-Commit Git Hooks
```bash
# .git/hooks/pre-commit
if ! git diff --cached --name-only | grep -q "docs/.nojekyll"; then
  if [ -f "docs/.nojekyll" ]; then
    git add docs/.nojekyll
  fi
fi
```

## Validation Commands

### Check File Exists
```bash
ls -la docs/.nojekyll
```

### Verify in Git
```bash
git ls-files docs/.nojekyll
```

### Test GitHub Pages Locally
```bash
# Install GitHub Pages gem
gem install github-pages

# Serve locally
cd docs && jekyll serve --skip-initial-build
# Should work without Jekyll processing
```

## Common Issues

### Issue: File Missing After Build
**Cause**: Build process not copying from public/ directory
**Solution**: Add to Astro public/ directory and rebuild

### Issue: File Not Committed
**Cause**: .gitignore excluding .nojekyll
**Solution**: Explicitly add with `git add -f docs/.nojekyll`

### Issue: CSS/JS 404 on GitHub Pages
**Symptoms**: Site loads but no styling or interactivity
**Diagnosis**: `.nojekyll` missing or not deployed
**Fix**:
```bash
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "fix(pages): Restore .nojekyll for asset loading"
git push origin main
```

## Jekyll Cleanup Protection

### NEVER Remove During Cleanup
When cleaning up Jekyll-related files, ALWAYS preserve `.nojekyll`:

```bash
# WRONG (deletes .nojekyll)
rm -rf docs/.jekyll* docs/.nojekyll

# CORRECT (preserves .nojekyll)
rm -rf docs/.jekyll-cache docs/.jekyll-metadata
# Explicitly skip .nojekyll
```

### Verification Before Cleanup
```bash
# Before removing ANY Jekyll files:
ls -la docs/.nojekyll

# If missing, recreate immediately:
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "CRITICAL: Restore .nojekyll for GitHub Pages"
```

## GitHub Pages Configuration

### Repository Settings
1. Navigate to: Settings → Pages
2. Source: Deploy from branch
3. Branch: `main` (or your deployment branch)
4. Folder: `/docs`
5. Save

### Verification
```bash
# Check Pages configuration via GitHub CLI
gh api repos/:owner/:repo/pages

# Expected output should show:
# - "source": { "branch": "main", "path": "/docs" }
# - "status": "built"
# - "cname": null (unless custom domain)
```

### Deployment Status
```bash
# Monitor deployments
gh api repos/:owner/:repo/pages/builds/latest

# Check deployment logs
gh run list --workflow=pages-build-deployment --limit 5
```

## Alternative Solutions

### Q: Can I use a different directory name instead of `_astro/`?
**A**: No. Astro hardcodes the `_astro/` directory name for build output.

### Q: Can I disable Jekyll processing another way?
**A**: No. The `.nojekyll` file is the ONLY method to disable Jekyll on GitHub Pages.

### Q: Can I use a custom domain to bypass this?
**A**: No. Custom domains still require `.nojekyll` if using `_astro/` directory.

### Q: Can I rename assets to avoid underscore prefix?
**A**: No. This would require forking Astro and maintaining a custom build system.

## Rationale

The `.nojekyll` requirement is a GitHub Pages technical constraint with no alternatives:

1. **GitHub Pages Architecture**: Built on Jekyll by default
2. **Jekyll Conventions**: Ignores underscore-prefixed directories
3. **Astro Build Output**: Uses `_astro/` for all bundled assets
4. **Compatibility Layer**: `.nojekyll` is the ONLY bridge between these systems

This is not a project preference but a technical necessity imposed by GitHub Pages infrastructure.

---

**Back to**: [constitution.md](constitution.md) | [core-principles.md](core-principles.md)
**Version**: 1.0.0
**Last Updated**: 2025-11-16
