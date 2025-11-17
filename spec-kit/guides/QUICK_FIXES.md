# SPEC-KIT QUICK FIXES (Ready to Apply)

**Generated**: 2025-11-17
**Status**: Ready for implementation

---

## FIX 1: Path Replacement (CRITICAL)

Run this to fix all `local-infra/` → `.runners-local/` references:

```bash
#!/bin/bash
cd spec-kit/guides

# Replace all local-infra paths with .runners-local paths
sed -i 's|./local-infra/runners/|./.runners-local/workflows/|g' *.md
sed -i 's|./local-infra/|./.runners-local/|g' *.md
sed -i 's|local-infra/runners|.runners-local/workflows|g' *.md
sed -i 's|local-infra/|.runners-local/|g' *.md

# Verify replacements
echo "Checking for remaining 'local-infra' references..."
grep -r "local-infra" . || echo "✓ All local-infra references removed"

# Verify .runners-local references exist
echo "Verifying .runners-local references..."
grep -c "\.runners-local" *.md | grep -v ":0$" || echo "✓ Replacements successful"
```

**Affected lines**: 100+ across 7 files

---

## FIX 2: Component Library Updates (CRITICAL)

### In `2-spec-kit-specify.md`:

**Remove** (lines 40-46):
```markdown
SHADCN/UI SPECIFICATION:
- Component library: shadcn/ui (latest)
- Base components: Button, Card, Input, Select, Dialog, Toast
- Styling: Tailwind CSS integration
- Accessibility: ARIA compliance for all components
- Theming: CSS variables for consistent design tokens
- Icon system: Lucide React icons
```

**Replace with**:
```markdown
DAISYUI SPECIFICATION:
- Component library: DaisyUI (latest stable)
- Integration: Direct Tailwind CSS integration
- Base components: Button, Card, Input, Select, Modal, Toast
- Styling: Tailwind utility classes + DaisyUI data attributes
- Accessibility: Built-in ARIA compliance
- Theming: CSS variables from Tailwind custom properties
- Icon system: Heroicons via DaisyUI components
- Note: shadcn/ui reserved for future if deeper customization needed
```

### In `4-spec-kit-tasks.md`:

**Remove** (lines 69-77):
```markdown
TASK 5: shadcn/ui Component Setup
- Initialize shadcn/ui: `npx shadcn-ui@latest init`
- Configure components.json with project settings
- Install core components: `npx shadcn-ui@latest add button card input`
- Create component examples in Astro pages
- Set up theming with CSS variables
- Test component functionality and accessibility
- MANDATORY: Component integration validation via local CI/CD
Deliverable: Working shadcn/ui component library with accessibility validation
```

**Replace with**:
```markdown
TASK 5: DaisyUI Component Setup
- Install DaisyUI: `npm install -D daisyui`
- Add to tailwind.config.mjs: `plugins: [require('daisyui')]`
- Configure components.json with DaisyUI settings
- Create component examples in Astro pages (using DaisyUI classes)
- Set up theming with Tailwind CSS custom properties
- Test component functionality and accessibility
- MANDATORY: Component integration validation via local CI/CD
Deliverable: Working DaisyUI component library with accessibility validation
```

**Total changes needed**: 2 major sections in 2 files

---

## FIX 3: Node.js Guidance (MODERATE)

### In `3-spec-kit-plan.md` (line 169):

**Change from**:
```
- Node.js 18+: Required for Astro and npm packages
```

**Change to**:
```
- Node.js: Latest stable (currently v25.2.0+) via fnm (Fast Node Manager)
  - Note: Always use latest, not LTS, for cutting-edge features
  - Project-specific versions managed via .nvmrc when required
```

### In `5-spec-kit-implement.md` (line 26):

**Change from**:
```
- Verify system requirements: Python 3.12+, Node.js 18+, Git, GitHub CLI
```

**Change to**:
```
- Verify system requirements: Python 3.12+, Node.js latest (v25+) via fnm, Git, GitHub CLI
- IMPORTANT: Use `fnm default node` to ensure latest Node.js version
```

---

## FIX 4: Add Critical Prerequisites (NEW FILE)

Create: `spec-kit/guides/0-spec-kit-prerequisites.md`

```markdown
# Spec-Kit Prerequisites & Current Project State (2025-11-17)

> ⚠️ **READ THIS FIRST** - Important updates to spec-kit guidance

## CRITICAL UPDATES TO SPEC-KIT GUIDANCE

This repository has evolved since original spec-kit guides were created.
**You MUST be aware of these differences** before following spec-kit commands.

### Directory Structure Update
- **Spec-kit says**: Create `local-infra/` directory
- **Actual project**: Uses `.runners-local/` (already exists)
- **Action**: Replace all `local-infra/` with `.runners-local/` in examples

### Component Library Update
- **Spec-kit says**: Use shadcn/ui
- **Current project**: Uses DaisyUI (shadcn/ui reserved for future)
- **Action**: Follow DaisyUI setup instead of shadcn/ui tutorials

### Node.js Version Policy
- **Spec-kit says**: Node.js 18+ is sufficient
- **Current project**: Requires latest Node.js (v25+) via fnm
- **Action**: Run `fnm default node` after fnm installation

### Missing: Terminal Configuration Scope
- **Spec-kit covers**: Web development stack (Astro, uv, GitHub Pages)
- **Project also includes**: Ghostty terminal, AI tools, modern Unix tools
- **Action**: See CLAUDE.md for complete project requirements

## Prerequisites Before Starting

### 1. Configure Context7 MCP (MANDATORY)
```bash
cp .env.example .env  # Add CONTEXT7_API_KEY
./scripts/check_context7_health.sh
```

### 2. Setup GitHub MCP (MANDATORY)
```bash
gh auth status  # Verify authentication
./scripts/check_github_mcp_health.sh
```

### 3. Understand .runners-local Infrastructure (CRITICAL)
The project ALREADY has `.runners-local/` CI/CD infrastructure:
- Do NOT create `local-infra/` (contradicts existing setup)
- DO use `.runners-local/workflows/` for all CI/CD commands
- Existing scripts: `gh-workflow-local.sh`, `astro-build-local.sh`, `performance-monitor.sh`

## When to Use Spec-Kit

✅ USE SPEC-KIT FOR:
- Learning Astro.build framework architecture
- Understanding component-driven development
- Building modern static sites with Tailwind CSS
- GitHub Pages deployment strategy

⚠️ DO NOT USE SPEC-KIT FOR:
- Directory structure decisions (use actual project structure)
- Component library choices (use DaisyUI, not shadcn/ui)
- Node.js version decisions (use latest, not 18+)
- Terminal/Ghostty configuration (not covered by spec-kit)
- GitHub MCP integration patterns (not covered by spec-kit)

## Full Project Documentation

For complete project requirements including Ghostty terminal configuration:
- **Terminal focus**: See CLAUDE.md (main project instructions)
- **Web development**: See spec-kit guides (with fixes applied)
- **Specifications**: See specs/005-complete-terminal-infrastructure/
- **Architecture**: See documentations/development/

---

✓ After reading this guide, proceed to spec-kit `/constitution` command
```

---

## FIX 5: Add .nojekyll Critical File Warning (NEW SECTION)

Add to `5-spec-kit-implement.md` before "GitHub Integration" section:

```markdown
### CRITICAL: .nojekyll File for GitHub Pages

**BEFORE deploying to GitHub Pages, you MUST have an empty `.nojekyll` file:**

```bash
# Verify .nojekyll exists in docs/ directory
ls -la docs/.nojekyll

# If missing, create immediately
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "CRITICAL: Add .nojekyll for GitHub Pages asset loading"
```

**Why this matters**: 
Without `.nojekyll`, GitHub Pages treats your site as a Jekyll site and ignores the `_astro/` directory containing your CSS/JS assets. This causes ALL styling and JavaScript to fail with 404 errors, making your site appear completely broken.

**This is NOT optional** - it's required for Astro + GitHub Pages.
```

---

## FIX 6: Add Branch Strategy Clarification (NEW SECTION)

Add to `4-spec-kit-tasks.md` in "Branch Strategy for Tasks" section:

```markdown
### IMPORTANT: Branch Naming Convention

Spec-kit shows: `DATETIME-task-X-description`

**Actual project convention** (from CLAUDE.md):
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-type-short-description"
# where type is: feat, fix, docs, refactor, test, chore
```

**Examples**:
- ✓ Correct: `20251117-183000-feat-astro-integration`
- ✓ Correct: `20251117-183015-fix-node-version`
- ✓ Correct: `20251117-183030-docs-spec-kit-update`
- ✗ Incorrect: `20251117-183000-task-1-astro` (task-focused)
```

---

## IMPLEMENTATION CHECKLIST

- [ ] Run Fix 1 script (path replacement)
- [ ] Manually apply Fix 2 (component library in 2 files)
- [ ] Manually apply Fix 3 (Node.js guidance in 2 files)
- [ ] Create new file: `0-spec-kit-prerequisites.md` (Fix 4)
- [ ] Add section to implement guide (Fix 5 - .nojekyll)
- [ ] Add section to tasks guide (Fix 6 - branch naming)
- [ ] Verify all changes:
  ```bash
  grep -r "local-infra" spec-kit/  # Should be empty
  grep -r "shadcn" spec-kit/       # Check usage context
  grep -r "Node.js 18" spec-kit/   # Should be minimal
  ```

---

**Status**: Ready to apply
**Estimated time**: 30 minutes
**Testing required**: Yes - verify path replacements work

