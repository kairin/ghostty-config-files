# Spec Directory Validation System

## Purpose

Prevent accumulation of duplicate or obsolete specification directories through automated validation.

## Problem Solved

**Issue**: After consolidating specifications (e.g., 001, 002, 004 → 005), old directories may remain in `specs/`, causing confusion and errors.

**Example**:
```
specs/
├── 005-apt-snap-migration/          # ❌ OLD (should be removed)
├── 005-complete-terminal-infrastructure/  # ✅ NEW (consolidated)
```

**Impact**:
- Spec-kit commands fail with "Multiple spec directories with prefix 005" errors
- Confusion about which spec is authoritative
- Wasted storage and cognitive load

---

## Solution: Automated Validation

### 1. Validation Script

**Location**: `.specify/scripts/bash/validate-spec-directory.sh`

**Rules Enforced**:
1. ✅ **No Duplicate Numeric Prefixes**: Only one spec per XXX- prefix
2. ✅ **Archived Feature Naming**: Archived features use `YYYYMMDD-HHMMSS-*` format
3. ✅ **No Orphaned Spec Files**: `spec.md` must be in proper directory structure
4. ✅ **Required Files Present**: Active specs have `spec.md`, `plan.md`, `tasks.md`

**Usage**:
```bash
# Manual validation
./.specify/scripts/bash/validate-spec-directory.sh

# Output example (success)
✅ ALL VALIDATIONS PASSED
Spec directory structure is valid.

# Output example (failure)
❌ VALIDATION FAILED
✗ ERROR: Duplicate prefix '005' found:
    005-apt-snap-migration
    005-complete-terminal-infrastructure
```

### 2. Git Pre-Commit Hook

**Location**: `.git/hooks/pre-commit`

**Behavior**:
- Runs automatically before every `git commit`
- Blocks commits if validation fails
- Can be bypassed with `git commit --no-verify` (not recommended)

**Example**:
```bash
$ git commit -m "Update spec"

Running spec directory validation...
❌ Commit blocked: Spec directory validation failed
   Fix issues above or bypass with: git commit --no-verify
```

---

## Workflow Integration

### During Spec Consolidation

**Step 1: Create Consolidated Spec**
```bash
# Consolidate 001, 002, 004 → 005
/speckit.specify  # Create 005-complete-terminal-infrastructure
```

**Step 2: Remove Old Specs**
```bash
# Remove superseded specs
rm -rf specs/001-old-spec/
rm -rf specs/002-old-spec/
rm -rf specs/004-old-spec/
```

**Step 3: Validate Before Commit**
```bash
# Automatic validation via pre-commit hook
git add specs/005-complete-terminal-infrastructure/
git commit -m "feat(spec): Consolidate specs 001/002/004 into 005"

# Hook runs validate-spec-directory.sh automatically
# ✅ Passes if no duplicates exist
```

### During Feature Archival

**When to Archive**: Feature complete and no longer actively developed

**Naming Convention**: `YYYYMMDD-HHMMSS-feat-description`

**Example**:
```bash
# Archive completed feature
mv specs/003-feature-name/ \
   specs/20251115-143000-feat-feature-name/

# Validation passes (timestamp prefix recognized as archived)
git commit -m "archive(spec): Archive completed feature 003"
```

---

## Validation Rules Details

### Rule 1: No Duplicate Numeric Prefixes

**Check**: Scans `specs/` for directories matching `XXX-*` pattern

**Valid**:
```
specs/
├── 001-feature-alpha/
├── 002-feature-beta/
├── 005-feature-gamma/  # ✅ Each prefix unique
```

**Invalid**:
```
specs/
├── 005-old-spec/        # ❌ Duplicate prefix
├── 005-new-spec/        # ❌ Duplicate prefix
```

**Resolution**:
```bash
# Keep newest, remove old
rm -rf specs/005-old-spec/
```

### Rule 2: Archived Feature Naming

**Check**: Archived features use `YYYYMMDD-HHMMSS-type-description` format

**Valid**:
```
specs/
├── 20251115-143000-feat-old-feature/  # ✅ Archived with timestamp
```

**Invalid**:
```
specs/
├── old-feature-archive/  # ❌ No timestamp
```

**Resolution**:
```bash
# Add timestamp prefix
mv specs/old-feature-archive/ \
   specs/$(date +"%Y%m%d-%H%M%S")-feat-old-feature/
```

### Rule 3: No Orphaned Spec Files

**Check**: `spec.md` must be inside `specs/XXX-name/spec.md`, not `specs/spec.md`

**Valid**:
```
specs/
└── 005-feature/
    └── spec.md  # ✅ Inside feature directory
```

**Invalid**:
```
specs/
└── spec.md  # ❌ Orphaned at root level
```

**Resolution**:
```bash
# Move to proper directory
mkdir -p specs/005-feature/
mv specs/spec.md specs/005-feature/
```

### Rule 4: Required Files Present

**Check**: Active specs (non-archived) must have `spec.md`, `plan.md`, `tasks.md`

**Valid**:
```
specs/005-feature/
├── spec.md   # ✅ All three required files
├── plan.md   # ✅
└── tasks.md  # ✅
```

**Invalid**:
```
specs/005-feature/
└── spec.md  # ❌ Missing plan.md and tasks.md
```

**Resolution**:
```bash
# Generate missing files
cd specs/005-feature/
/speckit.plan   # Generate plan.md
/speckit.tasks  # Generate tasks.md
```

---

## Bypassing Validation (Use Sparingly)

**When to Bypass**:
- Emergency fixes where validation incorrectly fails
- Work-in-progress commits (though `git stash` is preferred)
- Temporary experimental branches

**How to Bypass**:
```bash
# Skip pre-commit hook
git commit --no-verify -m "WIP: Experimental changes"
```

**Warning**: Bypassing validation defeats its purpose. Use only when absolutely necessary and fix issues in next commit.

---

## Troubleshooting

### Issue: "Duplicate prefix '005' found"

**Cause**: Multiple directories with same numeric prefix

**Solution**:
```bash
# List duplicates
ls -d specs/005-*

# Remove obsolete one (history preserved in git)
rm -rf specs/005-old-name/

# Verify fix
./.specify/scripts/bash/validate-spec-directory.sh
```

### Issue: "Missing required files"

**Cause**: Spec directory created manually without spec-kit workflow

**Solution**:
```bash
# Generate missing files
cd specs/XXX-feature-name/
/speckit.specify  # If spec.md missing
/speckit.plan     # If plan.md missing
/speckit.tasks    # If tasks.md missing
```

### Issue: Pre-commit hook not running

**Cause**: Hook file not executable

**Solution**:
```bash
# Make hook executable
chmod +x .git/hooks/pre-commit

# Verify
ls -la .git/hooks/pre-commit
# Should show: -rwxr-xr-x (executable)
```

---

## Maintenance

### Updating Validation Rules

**File**: `.specify/scripts/bash/validate-spec-directory.sh`

**Adding New Rule**:
```bash
# 1. Create new validation function
validate_new_rule() {
    echo "=== Rule N: Description ==="
    # Validation logic here
    return 0  # or 1 if invalid
}

# 2. Add to main() function
main() {
    # ... existing rules ...
    validate_new_rule || all_valid=1
    # ...
}
```

### Testing Changes

```bash
# Test validation script
./.specify/scripts/bash/validate-spec-directory.sh

# Test pre-commit hook
git commit --dry-run -m "Test commit"
```

---

## Integration with Spec-Kit Workflow

**Spec-Kit Commands** automatically benefit from validation:

```bash
# Step 1: Create new spec
/speckit.specify
# → Creates specs/006-new-feature/spec.md

# Step 2: Plan implementation
/speckit.plan
# → Generates specs/006-new-feature/plan.md

# Step 3: Generate tasks
/speckit.tasks
# → Generates specs/006-new-feature/tasks.md

# Step 4: Commit (validation runs automatically)
git add specs/006-new-feature/
git commit -m "feat(spec): Add new feature specification"
# ✅ Pre-commit hook validates:
#    - No duplicate '006' prefix
#    - All required files present
#    - Proper directory structure
```

---

## Constitutional Compliance

**Branch Preservation**: Validation prevents duplicate specs but **never deletes git history**. Removed directories are still accessible via:
```bash
# View deleted spec history
git log --all -- specs/005-old-spec/

# Restore deleted spec (if needed)
git checkout <commit-hash> -- specs/005-old-spec/
```

**Zero-Cost Operations**: Validation runs locally (pre-commit hook), consuming zero GitHub Actions minutes.

**Quality Gates**: Validation is a **mandatory quality gate** before commits, ensuring spec directory consistency.

---

## Summary

| Component | Purpose | When It Runs | Can Bypass? |
|-----------|---------|--------------|-------------|
| `validate-spec-directory.sh` | Check spec directory rules | Manual or pre-commit | Yes (manual) |
| `.git/hooks/pre-commit` | Automatic validation gate | Every `git commit` | Yes (`--no-verify`) |

**Best Practice**: Let validation run automatically. Fix issues immediately rather than bypassing.

**Emergency Bypass**: Use `git commit --no-verify` only for urgent fixes, then resolve issues in next commit.

---

**Version**: 1.0.0
**Created**: 2025-11-17
**Last Updated**: 2025-11-17
**Status**: ACTIVE - Prevents spec directory accumulation issues
