# Prohibited Actions & Bypass Restrictions

Complete list of absolute prohibitions and requirements that cannot be bypassed.

## Absolute Prohibitions

### DO NOT
- **NEVER REMOVE `docs/.nojekyll`** - This breaks ALL CSS/JS loading on GitHub Pages
- Delete branches without explicit user permission
- Use GitHub Actions for anything that consumes minutes
- Skip local CI/CD validation before GitHub deployment
- Ignore existing user customizations during updates
- Apply configuration changes without backup
- Commit sensitive data (API keys, passwords, personal information)
- Bypass the intelligent update system for configuration changes
- Remove Jekyll-related files without verifying `.nojekyll` preservation
- Convert CLAUDE.md or GEMINI.md from symlinks to regular files

### DO NOT BYPASS
- Branch preservation requirements
- Local CI/CD execution requirements
- Zero-cost operation constraints
- Configuration validation steps
- User customization preservation
- Logging and debugging requirements
- Agent file symlink integrity

---

## Consequences of Violations

### .nojekyll Deletion
**Impact**: Complete site failure - ALL CSS/JS returns 404
**Recovery**: Immediate recreation + force push to trigger rebuild

### Branch Deletion
**Impact**: Loss of configuration history, regression analysis capability
**Recovery**: Restore from remote if pushed, otherwise lost permanently

### Skipping Local CI/CD
**Impact**: Production failures, GitHub Actions consumption, broken deployments
**Recovery**: Rollback commits, fix locally, re-deploy

### Symlink Conversion
**Impact**: Divergent AI instructions, inconsistent project state
**Recovery**: Restore symlinks, verify content alignment

---

**Back to**: [constitution.md](constitution.md) | [core-principles.md](core-principles.md)
**Version**: 1.0.0
**Last Updated**: 2025-11-16
