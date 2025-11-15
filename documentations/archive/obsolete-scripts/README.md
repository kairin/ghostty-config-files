# Obsolete & Archived Scripts

This directory contains disabled and obsolete scripts that have been superseded by newer implementations or functionality consolidation.

## Archived Scripts

### astro-pages-setup.sh.DISABLED

**Status**: Archived 2025-11-16
**Reason**: Superseded by `gh-pages-setup.sh`
**Location**: `documentations/archive/obsolete-scripts/astro-pages-setup.sh.DISABLED`

#### Why It Was Archived

1. **Functionality Consolidation**: The `gh-pages-setup.sh` script in `.runners-local/workflows/` provides superior implementation with:
   - Better error handling and dependency checking
   - Cleaner workflow options (`--verify`, `--configure`, `--build`)
   - More robust GitHub Pages configuration via GitHub CLI
   - Comprehensive logging with colored output
   - Manual setup fallback instructions

2. **Code Quality**: The disabled script had:
   - Less robust error handling
   - More verbose implementation
   - Fewer configuration options
   - No manual fallback instructions
   - Stronger GitHub CLI dependency without graceful degradation

3. **No Active References**: Comprehensive search found:
   - ✅ No references in active workflow scripts
   - ✅ No references in documentation (except CHANGELOG historical entry)
   - ✅ No dependencies from other scripts
   - ✅ Safe to archive without impact

#### Functionality Comparison

| Feature | `astro-pages-setup.sh.DISABLED` | `gh-pages-setup.sh` (Active) |
|---------|--------------------------------|----------------------------|
| Build Output Verification | ✅ | ✅ |
| .nojekyll File Handling | ✅ | ✅ (Critical) |
| GitHub CLI Integration | ✅ (Required) | ✅ (Optional with manual fallback) |
| Configuration Modes | Limited | Enhanced (--verify, --configure, --build, full) |
| Error Handling | Basic | Comprehensive |
| Manual Setup Instructions | ❌ | ✅ |
| Colored Output | ❌ | ✅ |
| Dependency Checking | ❌ | ✅ |
| Exit Codes | Basic | Detailed (0 = success, 1 = error) |

#### How to Use the Active Version

```bash
# Verify Astro build and .nojekyll file (no changes)
./.runners-local/workflows/gh-pages-setup.sh --verify

# Run Astro build and verify output
./.runners-local/workflows/gh-pages-setup.sh --build

# Configure GitHub Pages deployment
./.runners-local/workflows/gh-pages-setup.sh --configure

# Complete setup (verify, build if needed, configure)
./.runners-local/workflows/gh-pages-setup.sh

# Get help
./.runners-local/workflows/gh-pages-setup.sh --help
```

## Archive Policy

Scripts in this directory:
- Are NOT part of active workflows
- Should NOT be referenced by new code
- Are preserved for historical reference
- May be permanently deleted after 2 constitutional versions
- Can be restored from git history if needed

## Git History

The disabled script remains in git history and can be restored:

```bash
# View complete history
git log --oneline -- .runners-local/workflows/astro-pages-setup.sh.DISABLED

# Restore previous version if needed
git show <commit>:.runners-local/workflows/astro-pages-setup.sh.DISABLED > restored-script.sh
```

---

**Archive Date**: 2025-11-16
**Reason**: Consolidation cleanup - functionality now in `.runners-local/workflows/gh-pages-setup.sh`
**Approved**: Constitutional cleanup process per CLAUDE.md/AGENTS.md
