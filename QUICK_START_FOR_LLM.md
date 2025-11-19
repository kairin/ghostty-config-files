# Quick Start for New LLM - Ghostty Config Files

**Repository**: https://github.com/kairin/ghostty-config-files
**Current State**: Phase 7 Started (31/64 tasks - 48.4%)
**Latest Update**: T040 App Audit System Complete (2025-11-18)
**Your Mission**: Pick any task from Phase 5-10 and implement it following the constitutional workflow

---

## 🚀 30-Second Start

```bash
# 1. Read the full handoff guide first
cat LLM_HANDOFF_INSTRUCTIONS.md

# 2. Verify environment
cat .env  # Has GITHUB_TOKEN and CONTEXT7_API_KEY
git pull origin main

# 3. Pick your task
cat specs/001-modern-tui-system/tasks.md | grep "^\- \[ \]" | head -10

# 4. Create timestamped branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
git checkout -b "${DATETIME}-feat-your-feature-name"

# 5. Code → Test → Commit → Push → Merge → PRESERVE BRANCH
```

---

## 🎯 Available Tasks (Pick One)

### Phase 5: Progressive Summarization (3 tasks)
- **T031**: Implement lib/ui/collapsible.sh (Docker-like output)
- **T032**: Implement lib/ui/progress.sh (Progress bars)
- **T033**: Implement verbose mode toggle

### Phase 6: Orchestration (6 tasks)
- **T034**: Create task registry in new start.sh
- **T035**: Implement state management in orchestrator
- **T036**: Implement parallel task execution
- **T037**: Implement CLI argument parsing
- **T038**: Create new start.sh orchestrator
- **T039**: Add interrupt handling

### Phase 7: App Audit System (4 remaining tasks) - **T040 COMPLETE** ✅
- ~~**T040**: Implement lib/tasks/app_audit.sh (duplicate app detection)~~ ✅ **COMPLETE**
- **T041**: Implement duplicate categorization (HIGH/MEDIUM/LOW priority)
- **T042**: Implement safe cleanup commands
- **T043**: Create CLI for app audit
- **T044**: Desktop icon verification

### Phase 8: Context7 Integration (4 tasks)
- **T045**: Implement lib/tasks/context7_validation.sh
- **T046**: Implement installation method validation
- **T047**: Implement migration suggestions
- **T048**: Integrate Context7 into task modules

### Phase 9: Testing Infrastructure (6 tasks)
- **T049**: Create tests/test-fresh-install.sh
- **T050**: Create tests/test-idempotency.sh
- **T051**: Create tests/test-resume.sh
- **T052**: Create tests/test-cross-terminal.sh
- **T053**: Create tests/test-performance.sh
- **T054**: Create tests/test-error-recovery.sh

### Phase 10: Documentation (7 tasks)
- **T055**: Integrate with local CI/CD workflows
- **T056**: Update README.md with TUI highlights
- **T057**: Create ARCHITECTURE.md (already exists, needs TUI updates)
- **T058**: Update AGENTS.md with TUI references
- **T059**: Create MIGRATION-GUIDE.md
- **T060**: Update SPEC-KIT-TUI-INTEGRATION.md
- **T061**: Run complete test suite
- **T062**: Create conversation log
- **T063**: Constitutional branch workflow
- **T064**: Post-merge validation

---

## ⚡ Constitutional Workflow (COPY & PASTE)

```bash
# CREATE BRANCH
DATETIME=$(date +"%Y%m%d-%H%M%S")
FEATURE="your-feature-name"  # Example: app-audit-duplicate-detection
BRANCH_NAME="${DATETIME}-feat-${FEATURE}"
git checkout main
git pull origin main
git checkout -b "$BRANCH_NAME"

# IMPLEMENT YOUR CHANGES
# ... code here ...

# COMMIT
git add .
git commit -m "feat: Your descriptive message

Detailed changes:
- Change 1
- Change 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# PUSH FEATURE BRANCH
git push -u origin "$BRANCH_NAME"

# MERGE TO MAIN (--no-ff REQUIRED!)
git checkout main
git merge "$BRANCH_NAME" --no-ff -m "Merge feature branch: ${FEATURE}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# PUSH MAIN
git push origin main

# ❌ DO NOT DELETE BRANCH - Constitutional requirement to preserve all branches!
```

---

## 📋 Code Patterns (Follow These)

### Template: New Task Module
```bash
#!/usr/bin/env bash
#
# lib/tasks/your_module.sh - Description
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - FR-053: Idempotent operations
# - FR-026: Duplicate detection

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../verification/duplicate_detection.sh"

# Main installation function
task_install_your_feature() {
    log "INFO" "Installing your feature..."

    # 1. Duplicate detection
    if detect_your_feature; then
        log "SUCCESS" "↷ Your feature already installed (skipped)"
        return 0
    fi

    # 2. Installation
    # ... your code ...

    # 3. Verification
    verify_your_feature_installed
    verify_your_feature_functionality
}

# Verification functions
verify_your_feature_installed() {
    if ! command -v your-command &> /dev/null; then
        log "ERROR" "✗ Installation failed: command not found"
        return 1
    fi
    log "SUCCESS" "✓ Your feature installed successfully"
}

# Export functions
export -f task_install_your_feature
export -f verify_your_feature_installed
```

### Update tasks.md After Completion
```bash
# Mark task complete
sed -i 's/- \[ \] T040/- [X] T040/' specs/001-modern-tui-system/tasks.md

# Update progress (30→31 tasks, recalculate percentage)
sed -i 's/30\/64 tasks complete (46.9%)/31\/64 tasks complete (48.4%)/' \
    specs/001-modern-tui-system/tasks.md
```

---

## 🚨 CRITICAL: Never Do This

❌ **DELETE BRANCHES**: `git branch -d` or `git branch -D` (Constitutional violation)
❌ **USE LTS VERSIONS**: Always install `latest` (not LTS)
❌ **SKIP --no-ff**: Must use `git merge --no-ff` for all merges
❌ **HARD-CODE SUCCESS**: Must implement real verification tests
❌ **EDIT docs/**: Only edit `website/src/` (docs/ is build output)

---

## ✅ Pre-Flight Checklist

- [ ] Read LLM_HANDOFF_INSTRUCTIONS.md (full guide)
- [ ] Verified .env has GITHUB_TOKEN and CONTEXT7_API_KEY
- [ ] Ran `git pull origin main`
- [ ] Picked a task from specs/001-modern-tui-system/tasks.md
- [ ] Understand constitutional branch workflow
- [ ] Know to use timestamped branch names: `YYYYMMDD-HHMMSS-feat-description`
- [ ] Remember to use `--no-ff` when merging
- [ ] **NEVER DELETE BRANCHES** after merging

---

## 📚 Essential Reading

1. **LLM_HANDOFF_INSTRUCTIONS.md** ← Read this FIRST (comprehensive guide)
2. **CLAUDE.md** ← Constitutional requirements
3. **ARCHITECTURE.md** ← System design
4. **specs/001-modern-tui-system/spec.md** ← Feature requirements
5. **lib/tasks/gum.sh** ← Perfect code example (recently created)

---

## 🆘 Quick Help

**Git authentication issue?**
```bash
gh auth login
gh auth status
```

**Context7 MCP not working?**
```bash
cat .env | grep CONTEXT7_API_KEY
exit && claude  # Restart Claude Code
```

**Need code examples?**
```bash
# Best recent example
cat lib/tasks/gum.sh

# Other examples
ls -la lib/tasks/
```

**Verify your changes?**
```bash
bash -n lib/tasks/your_module.sh  # Syntax check
source lib/tasks/your_module.sh   # Load functions
type task_install_your_feature    # Verify export
```

---

**Ready?** → Read `LLM_HANDOFF_INSTRUCTIONS.md` → Pick a task → Follow the constitutional workflow → Ship it! 🚀
