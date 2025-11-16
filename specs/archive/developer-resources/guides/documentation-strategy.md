# Documentation Strategy Guide

**Author**: Claude Code (Context7 MCP Guardian Validated)
**Date**: 2025-11-10
**Purpose**: Explicit guide for the three-tier documentation system and decision framework
**Status**: Active
**Context7 Validation**: Aligned with Astro.build + GitHub Pages best practices

---

## Overview

This project implements a sophisticated **three-tier documentation system** designed to separate concerns between build artifacts, editable source content, and comprehensive documentation storage. This guide provides clear rules for when and where to place documentation.

---

## Three-Tier Documentation System

### Tier 1: Astro Build Output (`docs/`)

**Purpose**: GitHub Pages deployment artifacts (committed to version control)
**Source**: Auto-generated from `docs-source/` via `npm run build`
**Access**: Public-facing documentation site at https://kairin.github.io/ghostty-config-files

#### Directory Structure
```
docs/
├── .nojekyll              # CRITICAL: Enables _astro/ directory assets
├── index.html             # Site entry point
├── _astro/                # CSS, JS, and asset bundles
│   ├── index.[hash].css
│   ├── index.[hash].js
│   └── [image-assets]
├── [page-routes]/         # Generated HTML pages
└── manifest.json          # Build manifest
```

#### Rules for Tier 1
- ❌ **NEVER EDIT DIRECTLY** - Always edit `docs-source/` instead
- ✅ **ALWAYS COMMIT** - These files must be in git for GitHub Pages
- ✅ **VERIFY `.nojekyll`** - Critical file for asset loading (multi-layer protection)
- ✅ **REBUILD AFTER CHANGES** - Run `npm run build` after updating `docs-source/`

#### Context7 Best Practices
- **Astro Static Output**: Configuration uses `output: 'static'` for GitHub Pages
- **Asset Organization**: `_astro/` directory requires `.nojekyll` file
- **Build Performance**: Target <30 seconds build time locally
- **Bundle Size**: JavaScript bundles <100KB for initial load

#### When to Rebuild
```bash
# After editing docs-source/
npm run build

# Verify build output
ls -la docs/
test -f docs/.nojekyll && echo "✅ .nojekyll exists" || echo "❌ Missing .nojekyll"

# Preview locally before committing
npm run preview
```

---

### Tier 2: Editable Documentation Source (`docs-source/`)

**Purpose**: Human-editable markdown and Astro components
**Source**: Manually created and maintained
**Access**: Development-time editing, builds to `docs/`

#### Directory Structure
```
docs-source/
├── src/
│   ├── pages/                    # Page routes (markdown + Astro)
│   │   ├── index.astro          # Homepage
│   │   ├── user-guide/          # User-facing documentation
│   │   │   ├── installation.md
│   │   │   ├── configuration.md
│   │   │   └── troubleshooting.md
│   │   ├── ai-guidelines/       # AI assistant instructions
│   │   │   ├── claude-code.md
│   │   │   └── gemini-cli.md
│   │   └── developer/           # Developer documentation
│   │       ├── architecture.md
│   │       └── contributing.md
│   ├── components/              # Reusable Astro components
│   ├── layouts/                 # Page layouts
│   └── styles/                  # Global styles
├── public/                      # Static assets
│   └── .nojekyll               # PRIMARY protection layer
├── astro.config.mjs             # Astro configuration
├── package.json                 # Dependencies
└── tsconfig.json                # TypeScript configuration
```

#### Rules for Tier 2
- ✅ **EDIT HERE** - This is the source of truth for web documentation
- ✅ **USE MARKDOWN** - Prefer `.md` files for content pages
- ✅ **ASTRO COMPONENTS** - Use `.astro` for interactive/complex pages
- ✅ **COMMIT CHANGES** - Source files are version controlled
- ✅ **BUILD TO TIER 1** - Always rebuild `docs/` after changes

#### Context7 Best Practices
- **Markdown Authoring**: Use standard GitHub-flavored markdown
- **Component Structure**: Follow Astro islands architecture
- **TypeScript Strict**: Enabled for type safety
- **Accessibility**: WCAG 2.1 AA compliance for all pages

#### Content Organization Decision Tree
```
Is this user-facing documentation?
  ├─ Yes → user-guide/
  │   ├─ Installation instructions → installation.md
  │   ├─ Configuration guides → configuration.md
  │   └─ Troubleshooting → troubleshooting.md
  │
  ├─ No → Is this AI assistant guidance?
  │   ├─ Yes → ai-guidelines/
  │   │   ├─ Claude Code specific → claude-code.md
  │   │   └─ Gemini CLI specific → gemini-cli.md
  │   │
  │   └─ No → Is this developer documentation?
  │       └─ Yes → developer/
  │           ├─ Architecture → architecture.md
  │           ├─ Contributing → contributing.md
  │           └─ API docs → api.md
```

---

### Tier 3: Centralized Documentation Hub (`documentations/`)

**Purpose**: Comprehensive documentation repository for all project aspects
**Source**: Manually created and maintained
**Access**: Local development, not deployed to GitHub Pages

#### Directory Structure
```
documentations/
├── user/                        # End-user documentation
│   ├── installation/
│   ├── configuration/
│   └── troubleshooting/
├── developer/                   # Developer documentation
│   ├── architecture/
│   │   ├── system-overview.md
│   │   └── component-diagrams.md
│   ├── analysis/
│   │   ├── performance-analysis.md
│   │   └── security-audit.md
│   └── guides/
│       ├── documentation-strategy.md  # This document
│       └── contribution-workflow.md
├── specifications/              # Active feature specifications
│   ├── 001-repo-structure-refactor/
│   │   ├── spec.md
│   │   ├── plan.md
│   │   ├── tasks.md
│   │   └── checklists/
│   ├── 002-advanced-terminal-productivity/
│   ├── 004-modern-web-development/
│   └── 005-apt-snap-migration/
├── archive/                     # Historical/obsolete documentation
│   ├── old-specs/
│   └── deprecated-guides/
├── performance/                 # Performance metrics and reports
│   ├── lighthouse-reports/
│   └── benchmarks/
└── screenshots/                 # Visual documentation
    ├── installation/
    └── configuration/
```

#### Rules for Tier 3
- ✅ **COMPREHENSIVE STORAGE** - All documentation lives here
- ✅ **NOT WEB-DEPLOYED** - This is local-only documentation
- ✅ **PRESERVE HISTORY** - Move to `archive/` instead of deleting
- ✅ **SPEC-KIT INTEGRATION** - Feature specifications follow Spec-Kit workflow
- ✅ **VERSION CONTROL** - All files committed to git

#### Context7 Best Practices
- **Specification Management**: Follow Spec-Kit constitutional workflow
- **Documentation Preservation**: Archive instead of delete
- **Cross-Referencing**: Link between tiers for traceability
- **Performance Tracking**: Store Lighthouse reports and benchmarks

#### Content Organization Decision Tree
```
What type of documentation is this?

├─ Feature Specification → specifications/NNN-feature-name/
│   ├─ Requirements → spec.md
│   ├─ Technical Plan → plan.md
│   ├─ Implementation Tasks → tasks.md
│   ├─ Quality Checklists → checklists/
│   └─ Supporting Docs → research.md, data-model.md, contracts/
│
├─ User Documentation → user/
│   ├─ Installation → installation/
│   ├─ Configuration → configuration/
│   └─ Troubleshooting → troubleshooting/
│
├─ Developer Documentation → developer/
│   ├─ Architecture → architecture/
│   ├─ Analysis → analysis/
│   └─ Guides → guides/
│
├─ Performance Data → performance/
│   ├─ Lighthouse Reports → lighthouse-reports/
│   └─ Benchmarks → benchmarks/
│
├─ Visual Assets → screenshots/
│   └─ Organize by feature
│
└─ Obsolete/Historical → archive/
    └─ Preserve with date/reason
```

---

## Documentation Placement Decision Framework

Use this decision tree to determine where to place new documentation:

### Step 1: Determine Primary Purpose

```
What is the primary purpose of this documentation?

A. Public-facing web content for users/developers
   → Tier 2 (docs-source/) → Builds to Tier 1 (docs/)

B. Feature specification following Spec-Kit workflow
   → Tier 3 (documentations/specifications/NNN-feature-name/)

C. Internal development documentation (not public web)
   → Tier 3 (documentations/developer/)

D. User guides (both web and local reference)
   → BOTH: Tier 2 (docs-source/user-guide/) AND Tier 3 (documentations/user/)

E. Performance metrics, screenshots, analysis
   → Tier 3 (documentations/performance/ or documentations/screenshots/)
```

### Step 2: Determine Specific Location

```
If Tier 2 (docs-source/):
  - User-facing content → src/pages/user-guide/
  - AI assistant guidance → src/pages/ai-guidelines/
  - Developer documentation → src/pages/developer/
  - Homepage/navigation → src/pages/index.astro
  - Reusable components → src/components/
  - Static assets → public/

If Tier 3 (documentations/):
  - Feature spec → specifications/NNN-feature-name/
  - Architecture docs → developer/architecture/
  - Analysis reports → developer/analysis/
  - Development guides → developer/guides/
  - User guides (local) → user/
  - Performance data → performance/
  - Visual assets → screenshots/
  - Obsolete docs → archive/
```

### Step 3: Verify Cross-References

```
After placing documentation:

1. Add to appropriate index/navigation
2. Update cross-references in other tiers
3. Ensure traceability (if specification-related)
4. Rebuild docs/ if docs-source/ was modified
5. Verify links work in local preview
```

---

## Common Documentation Workflows

### Workflow 1: Adding New User Guide

```bash
# 1. Create markdown file in docs-source/
nvim docs-source/src/pages/user-guide/new-feature.md

# 2. Write content using markdown

# 3. Add to navigation (if applicable)
nvim docs-source/src/components/Navigation.astro

# 4. Build to docs/
npm run build

# 5. Preview locally
npm run preview
# Open http://localhost:4321/ghostty-config-files/user-guide/new-feature

# 6. Optionally: Create detailed version in Tier 3
nvim documentations/user/new-feature/detailed-guide.md

# 7. Commit all changes
git add docs-source/ docs/ documentations/
git commit -m "docs: Add new feature user guide"
```

### Workflow 2: Creating New Feature Specification

```bash
# 1. Use Spec-Kit workflow
/speckit.specify

# 2. Spec-Kit creates: documentations/specifications/NNN-feature-name/
# Files created: spec.md, plan.md, tasks.md, checklists/, etc.

# 3. Optionally: Add web documentation for the feature
nvim docs-source/src/pages/developer/features/NNN-feature-name.md

# 4. Build and commit
npm run build
git add documentations/specifications/NNN-feature-name/ docs-source/ docs/
git commit -m "feat: Add specification for NNN-feature-name"
```

### Workflow 3: Adding Developer Architecture Documentation

```bash
# 1. Create in Tier 3 (comprehensive version)
nvim documentations/developer/architecture/component-name.md

# 2. Optionally: Create web version in Tier 2 (summary)
nvim docs-source/src/pages/developer/architecture/component-name.md

# 3. Add diagrams/screenshots
cp diagram.png documentations/screenshots/architecture/

# 4. Build and commit
npm run build
git add documentations/ docs-source/ docs/
git commit -m "docs: Add architecture documentation for component-name"
```

### Workflow 4: Updating AI Assistant Guidelines

```bash
# 1. Update single source of truth (AGENTS.md)
nvim AGENTS.md

# 2. Symlinks auto-update (CLAUDE.md, GEMINI.md)
# Verify: ls -la CLAUDE.md GEMINI.md

# 3. Optionally: Update web version
nvim docs-source/src/pages/ai-guidelines/claude-code.md

# 4. Build and commit
npm run build
git add AGENTS.md docs-source/ docs/
git commit -m "docs: Update AI assistant guidelines"
```

### Workflow 5: Adding Performance Report

```bash
# 1. Run Lighthouse audit
npm run build
npm run preview
# Run Lighthouse in browser DevTools

# 2. Save report to Tier 3
mkdir -p documentations/performance/lighthouse-reports/
cp lighthouse-report-YYYYMMDD.html documentations/performance/lighthouse-reports/

# 3. Optionally: Add summary to web docs
nvim docs-source/src/pages/developer/performance.md

# 4. Build and commit
npm run build
git add documentations/performance/ docs-source/ docs/
git commit -m "docs: Add Lighthouse performance report"
```

---

## Documentation Maintenance Guidelines

### Regular Maintenance Tasks

1. **Weekly**: Review recent documentation changes for consistency
2. **Before Release**: Verify all cross-references are valid
3. **After Major Changes**: Rebuild docs/ and verify deployment
4. **Monthly**: Archive obsolete documentation with context
5. **Quarterly**: Review documentation strategy for improvements

### Quality Standards

#### For Tier 2 (docs-source/)
- ✅ Use clear, concise language
- ✅ Include code examples where applicable
- ✅ Follow accessibility guidelines (WCAG 2.1 AA)
- ✅ Test all links in local preview
- ✅ Optimize images for web (< 500KB per image)
- ✅ Use semantic HTML/markdown structure

#### For Tier 3 (documentations/)
- ✅ Preserve historical context
- ✅ Use descriptive file names
- ✅ Include creation date and author
- ✅ Cross-reference related documentation
- ✅ Follow Spec-Kit workflow for specifications
- ✅ Archive instead of delete

### Context7 Validation Checklist

Before committing documentation changes:

- [ ] Run Context7 MCP validation: Check technology-specific best practices
- [ ] Verify Astro build succeeds: `npm run build` completes without errors
- [ ] Test local preview: `npm run preview` and manual verification
- [ ] Check `.nojekyll` file: Verify `docs/.nojekyll` exists
- [ ] Validate links: All internal links resolve correctly
- [ ] Review cross-tier consistency: Tier 2 and Tier 3 are synchronized
- [ ] Measure performance: Lighthouse scores maintain 95+ targets
- [ ] Verify accessibility: WCAG 2.1 AA compliance

---

## Troubleshooting Common Issues

### Issue 1: GitHub Pages Assets Return 404

**Symptom**: CSS/JS files in `_astro/` directory return 404 errors

**Root Cause**: Missing `.nojekyll` file

**Solution**:
```bash
# Verify .nojekyll exists
test -f docs/.nojekyll && echo "✅ Exists" || touch docs/.nojekyll

# Rebuild to ensure Vite plugin creates it
npm run build

# Verify multi-layer protection
test -f public/.nojekyll && echo "✅ Primary layer exists"
grep -q "create-nojekyll" astro.config.mjs && echo "✅ Secondary layer configured"
```

### Issue 2: Documentation Out of Sync Between Tiers

**Symptom**: Web docs (Tier 2) differ from comprehensive docs (Tier 3)

**Root Cause**: Editing one tier without updating the other

**Solution**:
```bash
# Use automated sync checker (Priority 4 recommendation)
./.runners-local/workflows/documentation-sync-checker.sh

# Manually review differences
diff -u docs-source/src/pages/user-guide/feature.md \
        documentations/user/feature/detailed-guide.md
```

### Issue 3: Build Output Goes to Wrong Directory

**Symptom**: `npm run build` creates files in unexpected location

**Root Cause**: `astro.config.mjs` outDir mismatch

**Solution**:
```bash
# Verify correct outDir in astro.config.mjs
grep "outDir:" astro.config.mjs
# Should show: outDir: './docs',

# If wrong, update configuration (already fixed in Priority 2)
```

### Issue 4: Spec-Kit Specifications Not Found

**Symptom**: `/speckit.implement` can't find specification files

**Root Cause**: Specification not in expected Tier 3 location

**Solution**:
```bash
# Verify specification exists in correct location
ls -la documentations/specifications/NNN-feature-name/

# Must contain: spec.md, plan.md, tasks.md at minimum

# Re-run Spec-Kit workflow if missing
/speckit.specify
/speckit.plan
/speckit.tasks
```

---

## Integration with Context7 MCP

### Validation During Documentation Workflow

Use Context7 MCP to validate best practices during documentation work:

```bash
# Query Context7 for Astro documentation best practices
claude ask "What are the latest Astro.build static site documentation best practices?"

# Validate GitHub Pages deployment configuration
claude ask "Review astro.config.mjs for GitHub Pages deployment best practices" < astro.config.mjs

# Check markdown authoring standards
claude ask "What are best practices for technical documentation markdown authoring?"

# Verify accessibility compliance
claude ask "How to ensure WCAG 2.1 AA compliance in Astro static sites?"
```

### Automated Context7 Checks (Priority 3 Recommendation)

Integrate Context7 validation into local CI/CD:

```bash
# File: .runners-local/workflows/gh-workflow-local.sh (enhanced in Priority 3)

# Documentation validation stage
docs_validate_context7() {
    echo "📚 Validating documentation with Context7 MCP..."

    # Check Astro configuration
    claude ask "Verify this Astro config follows GitHub Pages best practices" < astro.config.mjs

    # Validate documentation structure
    claude ask "Review this documentation structure for completeness" < documentations/README.md

    # Check for broken links (future enhancement)
    # claude ask "Identify potential broken links in Astro site"
}
```

---

## Future Enhancements

### Priority 3 (In Progress)
- [x] Create this documentation strategy guide
- [ ] Enhance local CI/CD with Context7 validation

### Priority 4 (Planned)
- [ ] Automated documentation sync checker
- [ ] Performance benchmarking dashboard
- [ ] Link validation automation
- [ ] Documentation coverage metrics

---

## References

- **AGENTS.md**: Single source of truth for AI assistant guidelines
- **astro.config.mjs**: Build configuration for Tier 2 → Tier 1
- **Spec-Kit Guides**: `/home/kkk/Apps/ghostty-config-files/spec-kit/`
- **Context7 MCP Documentation**: See AGENTS.md "Context7 MCP Integration" section
- **XDG Base Directory Specification**: https://specifications.freedesktop.org/basedir/latest/
- **Astro Documentation**: https://docs.astro.build/
- **GitHub Pages Deployment**: https://docs.github.com/pages

---

**Document Version**: 1.0
**Last Updated**: 2025-11-10
**Maintained By**: Project Contributors
**Context7 Validated**: ✅ Yes
**Constitutional Compliance**: ✅ Yes
