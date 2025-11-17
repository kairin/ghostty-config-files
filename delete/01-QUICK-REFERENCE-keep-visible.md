# 📋 Spec-Kit Quick Reference Checklist

**Keep this visible during spec-kit workflow execution**

---

## 🚨 CRITICAL: Reconciliation Matrix (Apply After EVERY Command)

| Find This | Replace With | Why |
|-----------|--------------|-----|
| `local-infra/` | `.runners-local/` | Directory was renamed |
| `shadcn/ui` | `DaisyUI` | Using DaisyUI not shadcn |
| `Node.js 18+` | `Node.js latest (v25.2.0+)` | Using latest not LTS |
| Missing `.nojekyll` | Add to `docs/.nojekyll` | CRITICAL for GitHub Pages |

---

## ✅ Before Each Spec-Kit Command

```bash
# 1. Verify critical files exist
ls docs/.nojekyll              # ✅ Must exist
ls .runners-local/             # ✅ Must exist (not local-infra/)
grep "daisyui" website/package.json  # ✅ Must be present

# 2. Check git status
git status                     # Should be clean or known changes

# 3. Run MCP health checks (if making major changes)
./scripts/check_context7_health.sh
./scripts/check_github_mcp_health.sh
```

---

## 🔄 After Each Spec-Kit Command (MANDATORY)

### Step 1: Apply Reconciliation Matrix
```bash
# For generated file (e.g., constitution.md, spec.md, plan.md, tasks.md)
FILE="[path-to-generated-file]"

sed -i 's|local-infra/|.runners-local/|g' "$FILE"
sed -i 's|shadcn/ui|DaisyUI|g' "$FILE"
sed -i 's|Node\.js 18|Node.js latest (v25.2.0+)|g' "$FILE"
```

### Step 2: Verify Critical Files
```bash
# Run verification script
./delete/verify-prerequisites.sh

# Manual checks
ls docs/.nojekyll || echo "❌ CRITICAL: .nojekyll missing!"
grep -q "daisyui" website/package.json || echo "❌ DaisyUI missing!"
ls .runners-local/ || echo "❌ .runners-local/ missing!"
```

### Step 3: Review Generated Content
- [ ] Check for `local-infra/` references → Should be `.runners-local/`
- [ ] Check for `shadcn/ui` references → Should be `DaisyUI`
- [ ] Check for `Node.js 18+` references → Should be `latest (v25.2.0+)`
- [ ] Verify `.nojekyll` is mentioned/preserved
- [ ] Confirm Context7 and GitHub MCP integration mentioned

### Step 4: Commit with Constitutional Branch Workflow
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-docs-speckit-[command-name]"

git checkout -b "$BRANCH_NAME"
git add .
git commit -m "docs: Update from /speckit.[command]

Applied reconciliation matrix to ensure accuracy.

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin "$BRANCH_NAME"
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main
# ⚠️ NEVER delete branch (constitutional requirement)
```

---

## 📝 Spec-Kit Command Sequence

### 1. `/speckit.constitution` - Establish Principles
**Before**: Read `delete/constitutional-principles-reference.md`

**Execute with UPDATED prompt**:
```
I need to establish the project constitution for ghostty-config-files.

CRITICAL CORRECTIONS (current repository reality):
- Use .runners-local/ NOT local-infra/
- Use DaisyUI NOT shadcn/ui
- Use Node.js latest (v25.2.0+) NOT Node.js 18+
- docs/.nojekyll is CRITICAL and must be preserved
- Context7 MCP and GitHub MCP are operational
- All configs follow XDG Base Directory Specification

Core principles to establish:
- Branch preservation (NEVER delete branches)
- Local CI/CD first (zero GitHub Actions cost)
- Constitutional branch workflow (YYYYMMDD-HHMMSS-type-description)
- GitHub Pages infrastructure (.nojekyll CRITICAL)
- Zero-cost operations
- Technology stack mandates
- Passwordless sudo for automation
```

**After**: Apply reconciliation matrix, verify `.nojekyll` exists

---

### 2. `/speckit.specify` - Create Baseline Spec
**Before**:
- Constitution committed and reviewed
- Read `delete/spec-005-lessons-learned.md`

**Execute with context**:
```
Create specification for [feature description].

Reference constitution.md for non-negotiable principles.

CRITICAL: Use .runners-local/ (not local-infra/), DaisyUI (not shadcn/ui),
Node.js latest v25.2.0+ (not 18+), and preserve docs/.nojekyll.
```

**After**: Apply reconciliation matrix, validate against constitution

---

### 3. `/speckit.plan` - Create Implementation Plan
**Before**:
- Specification committed and reviewed
- Optional: `/speckit.clarify` to resolve ambiguities

**Execute**:
```
Create implementation plan for spec.md.

CRITICAL: Reference .runners-local/ workflows, DaisyUI components,
Node.js v25.2.0+ features. Ensure .nojekyll preservation in all steps.
```

**After**: Apply reconciliation matrix, check dependency order

---

### 4. `/speckit.tasks` - Generate Tasks
**Before**:
- Plan committed and reviewed
- Optional: `/speckit.checklist` for quality gates

**Execute**:
```
Generate tasks from plan.md.

CRITICAL: Use .runners-local/ paths, DaisyUI components, Node.js latest.
Include validation steps to check .nojekyll existence.
```

**After**:
- Apply reconciliation matrix
- Archive tasks.md immediately to prevent regeneration
- Optional: `/speckit.analyze` for consistency check

---

### 5. `/speckit.implement` - Execute Tasks
**Before**:
- Tasks committed and reviewed
- All prerequisites verified

**Execute**: Follow tasks.md with continuous validation

**During implementation**:
```bash
# After each task completion
./delete/verify-prerequisites.sh  # Ensure nothing broke
ls docs/.nojekyll                 # Verify critical file
```

---

## 🚨 Red Flags (STOP Immediately)

- ❌ `local-infra/` appears in generated output
- ❌ `shadcn/ui` mentioned instead of DaisyUI
- ❌ `Node.js 18` or LTS versions mentioned
- ❌ `docs/.nojekyll` missing or deleted
- ❌ Branch deletion suggested
- ❌ GitHub Actions workflow consuming minutes
- ❌ XDG compliance violated (e.g., `~/.dircolors` instead of `~/.config/dircolors`)

## ✅ Green Lights (Proceed)

- ✅ `.runners-local/` used consistently
- ✅ `DaisyUI` mentioned for UI components
- ✅ `Node.js latest (v25.2.0+)` specified
- ✅ `docs/.nojekyll` preserved and mentioned
- ✅ Constitutional branch workflow followed
- ✅ Local CI/CD validation before GitHub deployment
- ✅ MCP servers (Context7, GitHub) operational

---

## 🔧 Emergency Recovery

### If .nojekyll Gets Deleted
```bash
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "CRITICAL: Restore .nojekyll for GitHub Pages"
git push
```

### If Wrong Directory Name Used
```bash
# If local-infra/ accidentally created
rm -rf local-infra/
# Verify .runners-local/ still exists
ls .runners-local/
```

### If Wrong Component Library Installed
```bash
cd website
npm uninstall shadcn-ui @shadcn/ui
npm install daisyui@latest
# Verify
grep "daisyui" package.json
```

---

## 📚 Reference Documents (in delete/)

1. **START HERE**: `speckit-constitution-reference-MASTER.md` (comprehensive guide)
2. **Constitutional Principles**: `constitutional-principles-reference.md`
3. **Reversion Analysis**: `reversion-issues-analysis.md`
4. **Workflow Guide**: `speckit-workflow-execution-guide.md`
5. **Lessons Learned**: `spec-005-lessons-learned.md`
6. **This Checklist**: `QUICK-REFERENCE-CHECKLIST.md`

---

## 🎯 Success Criteria

- [ ] All spec-kit outputs use correct directory names (`.runners-local/`)
- [ ] All spec-kit outputs use correct component library (`DaisyUI`)
- [ ] All spec-kit outputs use correct Node.js version (`latest v25.2.0+`)
- [ ] `docs/.nojekyll` exists and is never deleted
- [ ] Constitutional branch workflow followed for all commits
- [ ] Local CI/CD validation passes before GitHub deployment
- [ ] No GitHub Actions minutes consumed
- [ ] Context7 and GitHub MCP operational throughout

---

**Remember**: Apply reconciliation matrix IMMEDIATELY after EVERY spec-kit command execution. Do not batch corrections - fix as you go!

**Delete this folder**: Once implementation is complete and successful, delete the entire `delete/` folder to confirm the workflow succeeded.
