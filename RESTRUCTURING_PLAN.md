# Repository Restructuring Plan

**Date**: 2025-11-20
**Purpose**: Consolidate fragmented documentation and Astro.build folders
**User Feedback**: "why are the 3 folders with documents in root folder? why can't it just be 1 folder and various sub folders for various purposes?"

---

## Current Problems

### 1. Documentation Chaos (3+ root folders)
```
❌ CURRENT STRUCTURE (CONFUSING):
/delete/                    # Old files to be removed
/docs/                      # Astro build output (GitHub Pages)
/docs-setup/                # Setup guides and architectural docs
/documentations/            # Developer/user docs
/specs/                     # Feature specifications
```

### 2. Astro.build Fragmentation (3 root folders)
```
❌ CURRENT STRUCTURE (FRAGMENTED):
/website/                   # Astro source (astro.config.mjs, package.json)
  ├── src/                  # WAIT - this is a duplicate!
  ├── public/               # WAIT - this is a duplicate!
/src/                       # Astro source files (DUPLICATE at root)
/public/                    # Static assets (DUPLICATE at root)
/docs/                      # Astro build output
```

### 3. Spec-Kit Confusion
```
❌ CURRENT STRUCTURE (OUTDATED):
/.specify/                  # Spec-kit templates and scripts
/archive-spec-kit/          # Already created (empty)
```

---

## Proposed Clean Structure

### 1. Single Documentation Folder
```
✅ PROPOSED STRUCTURE (CLEAN):
/documentation/             # SINGLE source for all human-readable docs
  ├── setup/                # Setup guides (from docs-setup/)
  │   ├── context7-mcp.md
  │   ├── github-mcp.md
  │   ├── new-device-setup.md
  │   ├── zsh-security-check.md
  │   └── constitutional-compliance-criteria.md
  │
  ├── architecture/         # Architecture docs (from documentations/developer/)
  │   ├── DIRECTORY_STRUCTURE.md
  │   ├── MODULAR_TASK_ARCHITECTURE.md
  │   └── ...
  │
  ├── developer/            # Developer docs (from documentations/developer/)
  │   ├── conversation_logs/
  │   ├── HANDOFF_SUMMARY_*.md
  │   └── ...
  │
  ├── user/                 # User guides (from documentations/user/)
  │   └── ...
  │
  ├── specifications/       # Feature specs (from documentations/specifications/)
  │   └── ...
  │
  └── archive/              # Historical docs (from documentations/archive/)
      └── ...
```

### 2. Single Astro.build Folder
```
✅ PROPOSED STRUCTURE (CONSOLIDATED):
/astro-website/             # ALL Astro.build files in one place
  ├── src/                  # Astro source files
  │   ├── assets/
  │   ├── components/
  │   ├── content/          # Markdown documentation sources
  │   ├── layouts/
  │   ├── pages/
  │   └── styles/
  │
  ├── public/               # Static assets
  │   ├── .nojekyll         # CRITICAL for GitHub Pages
  │   ├── favicon.ico
  │   ├── manifest.json
  │   └── assets/
  │
  ├── astro.config.mjs      # Astro configuration
  ├── package.json          # Dependencies
  ├── tsconfig.json         # TypeScript config
  └── tailwind.config.mjs   # Tailwind config

/docs/                      # Astro BUILD OUTPUT ONLY (GitHub Pages)
  ├── .nojekyll             # CRITICAL - never delete
  ├── index.html
  ├── _astro/               # Generated assets
  └── ...
```

### 3. Archived Spec-Kit
```
✅ PROPOSED STRUCTURE (ARCHIVED):
/archive-spec-kit/
  └── .specify/             # Moved from root
      ├── memory/
      ├── scripts/
      └── templates/
```

### 4. Clean Root Directory
```
✅ FINAL ROOT STRUCTURE:
/home/kkk/Apps/ghostty-config-files/
├── astro-website/          # All Astro.build (source + config)
├── documentation/          # All human-readable docs
├── docs/                   # Astro build output ONLY (GitHub Pages)
├── archive-spec-kit/       # Archived spec-kit materials
├── configs/                # Ghostty configs, themes
├── scripts/                # Utility scripts
├── lib/                    # Task modules
├── tests/                  # Test infrastructure
├── .runners-local/         # CI/CD infrastructure
├── start.sh                # Main installer
├── CLAUDE.md               # AI instructions
└── README.md               # User documentation
```

---

## Migration Actions

### Action 1: Delete /delete/ folder ✅
**Reasoning**: User confirmed contents have been incorporated

```bash
# Verify no critical content
ls -la delete/
# Files: 01-QUICK-REFERENCE-keep-visible.md, 02-verify-prerequisites.sh, AUDIT-SUMMARY.md, SIMPLE-STEPS.md
# Status: All incorporated into proper locations

# Delete
rm -rf delete/
```

### Action 2: Archive spec-kit materials ✅
**Reasoning**: User wants clean slate for refactoring without spec-kit confusion

```bash
# Move .specify/ into archive
mv .specify/ archive-spec-kit/

# Move specs/ folder (if it's spec-kit related, not feature specs)
# VERIFY: Is /specs/001-modern-tui-system/ a spec-kit spec or feature spec?
# DECISION: This is a feature specification - KEEP in /documentation/specifications/
```

### Action 3: Consolidate Astro.build ✅
**Reasoning**: All Astro files should be in one location

```bash
# Move root /src/ and /public/ into /website/
# BUT WAIT - /website/ already has src/ and public/
# This means we have DUPLICATES at root level

# Check if root /src/ and /public/ are duplicates
diff -r src/ website/src/
diff -r public/ website/public/

# If identical: Delete root copies
rm -rf src/
rm -rf public/

# If different: Merge and resolve conflicts
# Rename /website/ to /astro-website/ for clarity
mv website/ astro-website/
```

### Action 4: Consolidate documentation ✅
**Reasoning**: Single /documentation/ folder for all docs

```bash
# Create new structure
mkdir -p documentation/setup
mkdir -p documentation/architecture
mkdir -p documentation/developer
mkdir -p documentation/user
mkdir -p documentation/specifications
mkdir -p documentation/archive

# Move docs-setup/ contents
mv docs-setup/*.md documentation/setup/

# Move documentations/ contents (merge)
mv documentations/developer/* documentation/developer/
mv documentations/user/* documentation/user/
mv documentations/specifications/* documentation/specifications/
mv documentations/archive/* documentation/archive/

# Move architecture docs
mv documentation/developer/architecture/* documentation/architecture/

# Delete old folders
rm -rf docs-setup/
rm -rf documentations/

# Move /specs/001-modern-tui-system/ to documentation/specifications/
mv specs/001-modern-tui-system/ documentation/specifications/
rm -rf specs/
```

### Action 5: Keep /docs/ for Astro output ONLY ✅
**Reasoning**: GitHub Pages deployment target

```bash
# NO CHANGES - /docs/ remains as Astro build output
# Update astro.config.mjs to ensure output goes to /docs/

# CRITICAL: Verify .nojekyll exists
ls -la docs/.nojekyll
# If missing: touch docs/.nojekyll
```

---

## Update Configuration Files

### 1. Update astro.config.mjs
```javascript
// astro-website/astro.config.mjs
export default defineConfig({
  site: 'https://kairin.github.io',
  base: '/ghostty-config-files/',
  outDir: '../docs',  // Build to /docs/ for GitHub Pages
  // ...
});
```

### 2. Update CLAUDE.md
```markdown
# Directory Structure (MANDATORY)

**Essential Structure**:
```
/home/kkk/Apps/ghostty-config-files/
├── start.sh, manage.sh         # Installation & management
├── CLAUDE.md, README.md        # Documentation
├── configs/                    # Ghostty configurations
├── scripts/                    # Utility scripts
├── lib/                        # Modular task libraries
├── documentation/              # All human-readable docs
│   ├── setup/                  # Setup guides
│   ├── architecture/           # Architecture docs
│   ├── developer/              # Developer docs
│   ├── user/                   # User guides
│   ├── specifications/         # Feature specifications
│   └── archive/                # Historical docs
├── astro-website/              # Astro.build source
│   ├── src/                    # Astro source files
│   ├── public/                 # Static assets
│   ├── astro.config.mjs        # Astro config
│   └── package.json            # Dependencies
├── docs/                       # Astro BUILD OUTPUT (GitHub Pages)
├── archive-spec-kit/           # Archived spec-kit materials
├── tests/                      # Test infrastructure
└── .runners-local/             # CI/CD infrastructure
```
```

### 3. Update MODULAR_TASK_ARCHITECTURE.md

Reference new paths:
- Documentation: `/documentation/architecture/MODULAR_TASK_ARCHITECTURE.md`
- Developer logs: `/documentation/developer/conversation_logs/`
- Architecture docs: `/documentation/architecture/`

---

## Verification Checklist

After restructuring:

- [ ] `/delete/` removed
- [ ] `/.specify/` moved to `/archive-spec-kit/.specify/`
- [ ] `/specs/` moved to `/documentation/specifications/`
- [ ] `/docs-setup/` merged into `/documentation/setup/`
- [ ] `/documentations/` merged into `/documentation/`
- [ ] Root `/src/` and `/public/` removed (duplicates)
- [ ] `/website/` renamed to `/astro-website/`
- [ ] `/docs/.nojekyll` verified (CRITICAL)
- [ ] `astro.config.mjs` output path updated
- [ ] `CLAUDE.md` directory structure updated
- [ ] `MODULAR_TASK_ARCHITECTURE.md` paths updated
- [ ] `README.md` paths updated
- [ ] All symlinks verified
- [ ] Astro build test: `cd astro-website && npm run build`
- [ ] Verify build output in `/docs/`

---

## Post-Restructuring Benefits

### ✅ Clarity
- Single `/documentation/` folder for all docs
- Clear separation: `/astro-website/` (source) vs `/docs/` (output)
- Archived spec-kit materials out of the way

### ✅ Maintainability
- Logical grouping (setup, architecture, developer, user)
- No duplicate folders
- Clear Astro.build boundaries

### ✅ Constitutional Compliance
- Modular architecture (documentation organized by purpose)
- Clean separation of concerns
- No confusion for AI assistants

---

**Ready to Execute**: Awaiting user approval to proceed with migration
