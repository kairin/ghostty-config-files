# Context7 MCP Best Practices - Quick Action Items

**Generated**: 2025-11-11
**Full Report**: `context7_best_practices_verification_20251111.md`

---

## High Priority Actions (Complete First - ~2.5 hours total)

### 1. Add Cleanup Functions with Trap Handlers (~1-2 hours)

**Files to Update**:
- `scripts/check_updates.sh`
- `scripts/install_node.sh`
- `local-infra/runners/gh-workflow-local.sh`

**Template to Add**:
```bash
# Cleanup function
cleanup() {
    log "INFO" "Cleaning up..."
    # Add cleanup tasks here (remove temp files, restore state, etc.)
}

# Register cleanup on exit
trap cleanup EXIT
```

**Why**: Ensures proper resource cleanup on script failure or interruption.

---

### 2. Integrate ShellCheck into Local CI/CD (~30 minutes)

**File**: `local-infra/runners/gh-workflow-local.sh`

**Add to `validate_config()` function** (around line 104):
```bash
# ShellCheck validation
if command -v shellcheck >/dev/null 2>&1; then
    log "STEP" "🔍 Running ShellCheck on scripts..."
    start_timer

    local shellcheck_failed=0
    while IFS= read -r script; do
        if ! shellcheck "$script" 2>&1 | tee -a "$LOG_DIR/shellcheck-$(date +%s).log"; then
            shellcheck_failed=$((shellcheck_failed + 1))
        fi
    done < <(find "$REPO_DIR/scripts" "$REPO_DIR/local-infra" -type f -name "*.sh")

    if [ $shellcheck_failed -eq 0 ]; then
        log "SUCCESS" "✅ All scripts passed ShellCheck"
    else
        log "ERROR" "❌ $shellcheck_failed script(s) failed ShellCheck"
        end_timer "ShellCheck validation"
        return 1
    fi

    end_timer "ShellCheck validation"
else
    log "WARNING" "⚠️ ShellCheck not found, skipping validation"
fi
```

**Why**: Catches shell script issues before deployment, prevents common Bash errors.

---

### 3. Create/Verify astro.config.mjs (~15 minutes)

**File**: `astro.config.mjs` (root directory)

**Verify it contains**:
```javascript
import { defineConfig } from 'astro/config';

export default defineConfig({
  // CRITICAL for GitHub Pages
  outDir: './docs',

  // Update these to match your GitHub setup
  site: 'https://yourusername.github.io',
  base: '/ghostty-config-files',

  // Recommended
  output: 'static',

  // Performance
  build: {
    format: 'directory',
    concurrency: 1  // Recommended default
  }
});
```

**Action**: If file doesn't exist, create it. If it exists, verify `outDir: './docs'` is set.

**Why**: Ensures Astro builds to correct directory for GitHub Pages deployment.

---

### 4. Add npm audit to Local Workflow (~15 minutes)

**File**: `local-infra/runners/gh-workflow-local.sh`

**Add to `validate_config()` function** (around line 104):
```bash
# npm security audit
if [ -f "$REPO_DIR/package.json" ]; then
    log "STEP" "🔒 Running npm security audit..."
    start_timer

    cd "$REPO_DIR"
    if npm audit --production 2>&1 | tee "$LOG_DIR/npm-audit-$(date +%s).log"; then
        log "SUCCESS" "✅ No security vulnerabilities found"
    else
        log "WARNING" "⚠️ Security vulnerabilities detected (see log for details)"
        log "INFO" "💡 Run 'npm audit fix' to auto-fix compatible issues"
    fi

    end_timer "npm audit"
fi
```

**Why**: Identifies vulnerable dependencies before deployment, improves security posture.

---

## Quick Verification Commands

After implementing high priority items, run these to verify:

```bash
# 1. Test cleanup functions (should not leave temp files)
./scripts/check_updates.sh --help
ls /tmp/ghostty-*  # Should be clean after script exits

# 2. Verify ShellCheck integration
./local-infra/runners/gh-workflow-local.sh validate

# 3. Verify Astro config
npx astro build  # Should output to docs/
ls -la docs/index.html  # Should exist

# 4. Verify npm audit
./local-infra/runners/gh-workflow-local.sh validate
# Look for "🔒 Running npm security audit..." in output
```

---

## Medium Priority Enhancements (Next Sprint)

1. **Standardize Exit Codes** - Document conventions, update all scripts (2-3 hours)
2. **Pre-Commit Hooks** - Create `.pre-commit-config.yaml` with shellcheck (30 min)
3. **Astro Image Optimization** - Add Sharp service to `astro.config.mjs` (1 hour)
4. **Root User Prevention** - Add checks to remaining scripts (30 min)
5. **Context7 Timeout Optimization** - Make configurable, increase default (15 min)
6. **Markdown Linting** - Add to CI/CD workflow (30 min)

---

## Context7 MCP Integration Status

✅ **Connected**: `https://mcp.context7.com/mcp`
✅ **Operational**: Successfully queried 6 technology areas
✅ **Integrated**: Already in `gh-workflow-local.sh` as `validate_context7()` function

**To Use**:
```bash
# Run Context7 validation standalone
./local-infra/runners/gh-workflow-local.sh context7

# Run complete workflow (includes Context7)
./local-infra/runners/gh-workflow-local.sh all
```

---

## Quick Reference: Context7 Queries

Use these commands to query Context7 for best practices:

```bash
# Bash scripting best practices
claude ask "What are Bash 5.x production script best practices?" < your-script.sh

# npm security audit best practices
claude ask "Review this package.json for npm security best practices" < package.json

# Astro GitHub Pages deployment
claude ask "Review this Astro config for GitHub Pages best practices" < astro.config.mjs

# Documentation structure
claude ask "Review this documentation strategy for completeness" < docs/guide.md
```

---

## Success Metrics

After completing high priority actions:

- ✅ All scripts clean up resources on exit
- ✅ ShellCheck passes with 0 warnings on all scripts
- ✅ Astro builds successfully to `docs/` directory
- ✅ npm audit shows 0 high-severity vulnerabilities
- ✅ Local CI/CD workflow completes in <2 minutes
- ✅ Context7 validation passes for all technology areas

---

**Full Analysis**: See `context7_best_practices_verification_20251111.md` for detailed findings and recommendations.
