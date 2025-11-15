# Documentation Structure

Complete guide to the centralized documentation hierarchy and organization principles.

## Centralized Documentation Hierarchy

**Last Updated**: 2025-11-09

### Directory Layout
```
/home/kkk/Apps/ghostty-config-files/
├── docs/                         # Astro.build output ONLY (DO NOT manually edit)
│   └── .nojekyll                 # CRITICAL for GitHub Pages
├── website/src/                  # Astro source files (editable documentation)
│   ├── user-guide/              # User documentation
│   ├── ai-guidelines/           # AI assistant guidelines  
│   └── developer/               # Developer documentation
├── documentations/               # Centralized documentation hub
│   ├── user/                    # End-user docs (installation, configuration, troubleshooting)
│   ├── developer/               # Developer docs (architecture, analysis)
│   ├── specifications/          # Active feature specifications with planning artifacts
│   └── archive/                 # Historical/obsolete documentation (preserved)
└── spec-kit/guides/             # Spec-kit methodology guides
```

### Directory Purposes

#### docs/ (Astro Build Output)
- **Purpose**: GitHub Pages deployment
- **Source**: Generated from `website/src/` via Astro build
- **Edit Policy**: DO NOT manually edit (changes will be overwritten)
- **Critical File**: `.nojekyll` (MUST exist for asset loading)

#### website/src/ (Astro Source)
- **Purpose**: Editable documentation for Astro site
- **Format**: Markdown files with frontmatter
- **Build**: `npm run build` → generates `docs/`
- **Categories**: user-guide/, ai-guidelines/, developer/

#### documentations/ (Centralized Hub)
- **Purpose**: Single source for all non-website documentation
- **Structure**:
  - `user/`: Installation guides, setup instructions, troubleshooting
  - `developer/`: Architecture docs, contribution guides, analysis
  - `specifications/`: Active feature specs (Spec 001, 002, 004)
  - `archive/`: Historical documentation (preserved for reference)

#### spec-kit/guides/
- **Purpose**: Spec-kit methodology and usage guides
- **Audience**: Developers using spec-kit commands
- **Content**: How-to guides for /constitute, /specify, /plan, /tasks, /implement

---

## Documentation Workflows

### Adding User Documentation
```bash
# 1. Create in website/src/user-guide/
vim website/src/user-guide/new-feature.md

# 2. Add frontmatter
---
title: "New Feature Guide"
description: "How to use new feature"
---

# 3. Build website
cd website && npm run build

# 4. Verify in docs/
ls -la ../docs/user-guide/new-feature/index.html
```

### Adding Developer Documentation
```bash
# 1. Create in documentations/developer/
vim documentations/developer/new-architecture.md

# 2. Write content (standard markdown)

# 3. No build required (direct consumption)
```

### Adding Feature Specification
```bash
# 1. Use spec-kit command
/speckit.specify "feature description"

# 2. Files created in:
documentations/specifications/00X-feature-name/
├── spec.md
├── plan.md
└── tasks.md
```

---

## Directory Nesting Limit

**Maximum**: 2 levels of nesting from repository root

**Rationale**: Maintains simplicity for configuration projects

**Top-Level Directories**: Limited to 4-5 to prevent organizational complexity

---

## Removed Features

### Screenshot Functionality (Removed 2025-11-09)
**Reason**: Installation hangs, unnecessary complexity, no user benefit

**Removed Artifacts**:
- `.screenshot-tools/` directory
- `docs/assets/screenshots/` directory  
- `docs/assets/diagrams/` directory
- Screenshot capture scripts
- Gallery generation scripts
- Related tests

**Impact**: Update feature specs to remove screenshot command references

---

**Back to**: [constitution.md](constitution.md) | [core-principles.md](core-principles.md)
**Version**: 1.0.0
**Last Updated**: 2025-11-16
