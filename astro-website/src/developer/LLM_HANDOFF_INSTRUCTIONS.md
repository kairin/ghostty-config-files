---
title: "LLM Handoff Instructions - Ghostty Config Files Repository"
description: "**Date**: 2025-11-18 (Updated)"
pubDate: 2025-11-25
author: "Ghostty Config Team"
tags: ['developer', 'technical']
---

# LLM Handoff Instructions - Ghostty Config Files Repository

**Date**: 2025-11-18 (Updated)
**Repository**: https://github.com/kairin/ghostty-config-files
**Current Status**: Phase 7 Started (31/64 tasks - 48.4%)
**Main Branch**: `main` (commit: `fdcc050`)
**Active Branch**: `claude/ghostty-config-development-01EgBPaP4jUVfqvbdVjjFQ9o` (commit: `995b681`)
**Feature Branch**: `001-modern-tui-system` (preserved, not deleted)

---

## 🎯 Current Repository State

### Branch Structure
```
main (78ef342) - SYNCED WITH REMOTE ✅
  ├── Latest merge: "Modern TUI MVP completion (gum.sh + documentation)"
  └── Ready for new feature branches

001-modern-tui-system (04643cb) - PRESERVED ON REMOTE ✅
  └── Contains all MVP implementation work
  └── DO NOT DELETE (constitutional requirement)
```

### What's Complete (31/64 tasks)
- ✅ **Phase 1**: Repository structure and backup system (4/4 tasks)
- ✅ **Phase 2**: Core infrastructure (logging, state, errors, utils) (9/9 tasks)
- ✅ **Phase 3**: UI components and verification framework (11/11 tasks)
- ✅ **Phase 4**: Task modules (ghostty, zsh, python_uv, nodejs_fnm, ai_tools, context_menu, **gum**) (7/7 tasks)
- ✅ **Phase 7 (Started)**: App Audit System - **T040 Complete** (1/5 tasks)
  - ✅ **NEW**: lib/tasks/app_audit.sh - Duplicate detection with disk usage calculation
  - ✅ Scan APT packages (dpkg -l) with installed size
  - ✅ Scan Snap packages (snap list --all) with du -sh disk usage
  - ✅ Detect duplicates (same app via snap + apt)
  - ✅ Detect disabled snaps with total disk usage
  - ✅ Browser installation analysis
  - ✅ Generate markdown report (/tmp/ubuntu-apps-audit.md)
- ✅ **Documentation**: ARCHITECTURE.md (700+ lines), README.md enhancements

### What's Outstanding (33/64 tasks)
- ⏳ **Phase 5**: Progressive Summarization & Collapsible Output (3 tasks - T031-T033)
- ⏳ **Phase 6**: Orchestration & Main Entry Point (6 tasks - T034-T039)
- ⏳ **Phase 7**: App Audit System (4 tasks remaining - T041-T044) - **T040 COMPLETE** ✅
- ⏳ **Phase 8**: Context7 Integration (4 tasks - T045-T048)
- ⏳ **Phase 9**: Testing Infrastructure (6 tasks - T049-T054)
- ⏳ **Phase 10**: Documentation & Deployment (7 tasks - T055-T064)

---

## 📝 Recent Updates (2025-11-18)

### T040: App Audit Duplicate Detection System ✅ COMPLETE

**File Created**: `lib/tasks/app_audit.sh` (651 lines)

**Commit**: `995b681` - "feat: Implement app audit duplicate detection system (T040)"

**Key Features Implemented**:
1. **APT Package Scanning** (`scan_apt_packages`)
   - Uses `dpkg -l` to list installed packages
   - Calculates disk usage with `dpkg-query -W -f='${Installed-Size}'`
   - Returns JSON array with name, version, size, method

2. **Snap Package Scanning** (`scan_snap_packages`)
   - Uses `snap list --all` to include disabled packages
   - Calculates disk usage with `du -sh /snap/<package>/<rev>`
   - Identifies disabled snaps for cleanup recommendations
   - Returns JSON array with disabled flag

3. **Desktop File Scanning** (`scan_desktop_files`)
   - Scans system and user desktop file locations
   - Extracts Name, Exec, Icon from .desktop files
   - Supports duplicate icon detection

4. **Duplicate Detection** (`detect_duplicates`)
   - Cross-references snap and apt packages
   - Common app name mappings (firefox, chromium, etc.)
   - Calculates total disk usage (snap + apt)
   - Returns JSON array of duplicates with recommendations

5. **Disabled Snap Detection** (`detect_disabled_snaps`)
   - Filters disabled snaps from scan results
   - Aggregates total disk usage in MB
   - Provides cleanup commands

6. **Browser Analysis** (`detect_browsers`)
   - Detects common browsers (Firefox, Chrome, Chromium, Edge, etc.)
   - Warns if >3 browsers installed
   - Recommendations to keep 1-2 browsers

7. **Report Generation** (`generate_audit_report`)
   - Creates markdown report at `/tmp/ubuntu-apps-audit.md`
   - Summary table with counts and status indicators
   - Three priority sections: HIGH (duplicates), MEDIUM (disabled), LOW (browsers)
   - Cleanup commands for each category
   - Total reclaimable disk space calculation

**Constitutional Compliance**:
- ✅ Modular Architecture (Principle V)
- ✅ FR-026: Duplicate detection framework
- ✅ FR-064: Application audit system
- ✅ FR-066: Disk usage calculation per category
- ✅ FR-053: Idempotent operations
- ✅ Real verification tests (actual system scanning)

**Testing**:
- ✅ Syntax validation (`bash -n`)
- ✅ Function export verification
- ✅ Execution test (generates valid report)
- ✅ Error handling (graceful degradation when jq/bc unavailable)

**Functions Exported**:
```bash
task_run_app_audit          # Main orchestrator
scan_apt_packages           # APT inventory
scan_snap_packages          # Snap inventory
scan_desktop_files          # Desktop app discovery
detect_duplicates           # Cross-manager duplicates
detect_disabled_snaps       # Disabled snap finder
detect_browsers             # Browser analysis
generate_audit_report       # Markdown report generator
```

**Next Steps for Phase 7**:
- T041: Duplicate categorization (already implemented in T040)
- T042: Safe cleanup commands (implement interactive removal)
- T043: CLI for app audit (create scripts/app-audit.sh)
- T044: Desktop icon verification (implement .desktop validation)

---

## 🚨 CRITICAL: Constitutional Requirements (MANDATORY)

### 1. Branch Management Strategy (NEVER VIOLATE)

**Branch Naming Convention** (MANDATORY):
```bash
YYYYMMDD-HHMMSS-type-short-description
```

Examples:
- `20251119-140000-feat-app-audit-system`
- `20251119-141500-fix-performance-issue`
- `20251119-143000-docs-testing-guide`

**Branch Preservation Rule** (ABSOLUTE):
- ❌ **NEVER** delete branches without explicit user permission
- ❌ **NEVER** use `git branch -d` or `git branch -D`
- ✅ **ALWAYS** preserve branches after merging to main
- ✅ Branches contain valuable configuration history

### 2. Constitutional Git Workflow (EVERY COMMIT)

**Step-by-Step Workflow**:
```bash
# 1. Create timestamped branch from main
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-your-feature-description"
git checkout main
git pull origin main
git checkout -b "$BRANCH_NAME"

# 2. Make your changes
# ... edit files ...

# 3. Stage and commit
git add .
git commit -m "$(cat <<'EOF'
feat: Your descriptive commit message

Detailed explanation of changes:
- Change 1
- Change 2
- Change 3

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

# 4. Push feature branch
git push -u origin "$BRANCH_NAME"

# 5. Merge to main (--no-ff REQUIRED)
git checkout main
git merge "$BRANCH_NAME" --no-ff -m "$(cat <<'EOF'
Merge feature branch: Your feature name

Detailed merge description:
- Feature highlights
- Constitutional compliance notes
- Verification status

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

# 6. Push to remote main
git push origin main

# 7. PRESERVE BRANCH (DO NOT DELETE)
# ❌ WRONG: git branch -d "$BRANCH_NAME"
# ✅ CORRECT: Leave branch intact for history
```

### 3. Configuration & Prerequisites

**Environment Files** (already configured):
- `.env` - Contains GITHUB_TOKEN and CONTEXT7_API_KEY
- `.mcp.json` - MCP server configuration (Context7, GitHub)
- Both files are gitignored for security

**Passwordless Sudo** (required for automated updates):
```bash
# Verify passwordless sudo is configured:
sudo -n apt update

# If fails, user needs to configure:
# sudo visudo
# Add: username ALL=(ALL) NOPASSWD: /usr/bin/apt
```

---

## 📋 Task Assignment Guide

### How to Pick Tasks

**Option 1: Sequential Implementation (Recommended)**
Start with Phase 7 (App Audit System) and work sequentially:

```bash
# Review outstanding tasks
cat specs/001-modern-tui-system/tasks.md

# Pick T040 (first uncompleted task in Phase 7)
# Create branch: 20251119-140000-feat-app-audit-duplicate-detection
```

**Option 2: Parallel Tracks (Advanced)**
Multiple LLMs can work simultaneously on different phases:
- LLM 1: Phase 7 (App Audit System)
- LLM 2: Phase 8 (Context7 Integration)
- LLM 3: Phase 9 (Testing Infrastructure)

**Task Dependencies** (Check Before Starting):
```bash
# Most Phase 7-10 tasks are independent
# Check spec for dependencies:
cat specs/001-modern-tui-system/spec.md | grep -A 5 "Dependencies"
```

---

## 🎯 Step-by-Step: Your First Task

### Example: Implement T040 (App Audit Duplicate Detection)

**Step 1: Review Task Details**
```bash
# Read task specification
cat specs/001-modern-tui-system/tasks.md | grep -A 20 "T040"

# Read spec for requirements
cat specs/001-modern-tui-system/spec.md | grep -A 30 "FR-026"
```

**Step 2: Create Feature Branch**
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-app-audit-duplicate-detection"
git checkout main
git pull origin main
git checkout -b "$BRANCH_NAME"
```

**Step 3: Implement Task**
```bash
# Create new module following existing patterns
# Reference: lib/tasks/gum.sh (recently created)
# Location: lib/tasks/app_audit.sh

# Key patterns to follow:
# 1. Shebang: #!/usr/bin/env bash
# 2. Header comments with constitutional compliance notes
# 3. set -euo pipefail
# 4. Source dependencies from lib/core/
# 5. Implement main function: task_install_app_audit()
# 6. Use duplicate_detection.sh for existing installations
# 7. Add logging with lib/core/logging.sh
# 8. Export functions at end
```

**Step 4: Update Documentation**
```bash
# Mark task as complete in tasks.md
# Update progress counter (30/64 → 31/64)
sed -i 's/30\/64 tasks complete/31\/64 tasks complete/' specs/001-modern-tui-system/tasks.md
sed -i 's/- \[ \] T040/- [X] T040/' specs/001-modern-tui-system/tasks.md
```

**Step 5: Commit with Constitutional Format**
```bash
git add lib/tasks/app_audit.sh specs/001-modern-tui-system/tasks.md
git commit -m "$(cat <<'EOF'
feat: Implement app audit duplicate detection (T040)

App Audit System - Duplicate Detection Module:
- NEW: lib/tasks/app_audit.sh - Duplicate app detection with disk usage
- Implements FR-026 (duplicate detection framework)
- Integration with lib/verification/duplicate_detection.sh
- Disk usage analysis via du command
- Categorization: apt, snap, flatpak, AppImage, manual

Progress: 31/64 tasks complete (48.4%)

Constitutional Compliance:
- Principle V: Modular Architecture
- FR-053: Idempotent operations
- Real verification tests

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

**Step 6: Push and Merge**
```bash
# Push feature branch
git push -u origin "$BRANCH_NAME"

# Merge to main
git checkout main
git merge "$BRANCH_NAME" --no-ff -m "$(cat <<'EOF'
Merge feature branch: App Audit duplicate detection implementation

Merged T040 implementation:
- lib/tasks/app_audit.sh module created
- Duplicate detection framework integration
- Disk usage analysis functionality

Progress: 31/64 tasks (48.4%)
Constitutional compliance maintained.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

# Push to remote
git push origin main

# PRESERVE BRANCH (constitutional requirement)
```

---

## 🛠️ Testing & Validation

### Before Committing (MANDATORY)

```bash
# 1. Validate Bash syntax
bash -n lib/tasks/your_new_module.sh

# 2. Test function export
source lib/tasks/your_new_module.sh
type task_install_your_feature  # Should show function definition

# 3. Dry-run installation (if applicable)
./start.sh --dry-run

# 4. Check logging
tail -f /tmp/ghostty-start-logs/start-*.log

# 5. Verify state tracking
cat /tmp/ghostty-start-logs/installation-state.json | jq '.'
```

### Local CI/CD (Future - Not Yet Implemented)
```bash
# TODO: T061 will implement complete test suite
# ./.runners-local/workflows/gh-workflow-local.sh all
```

---

## 📚 Key Documentation References

### MUST READ Before Starting:
1. **CLAUDE.md** - Constitutional requirements and LLM instructions
2. **ARCHITECTURE.md** - System architecture and design patterns
3. **specs/001-modern-tui-system/spec.md** - Feature requirements
4. **specs/001-modern-tui-system/tasks.md** - Task breakdown and progress

### Code Examples (Follow These Patterns):
1. **lib/tasks/gum.sh** - Recently created, perfect template
2. **lib/tasks/ghostty.sh** - Complex installation example
3. **lib/tasks/nodejs_fnm.sh** - Performance validation example
4. **lib/core/logging.sh** - Logging patterns
5. **lib/verification/duplicate_detection.sh** - Detection framework

---

## 🚨 Common Pitfalls (AVOID THESE)

### ❌ DO NOT:
1. Delete branches after merging (constitutional violation)
2. Use LTS versions instead of latest (violates version policy)
3. Skip Context7 validation for best practices
4. Commit without constitutional commit message format
5. Use `git merge` without `--no-ff` flag
6. Modify files in `docs/` directory (Astro build output only)
7. Remove `.nojekyll` file (breaks GitHub Pages)
8. Skip performance validation (performance measured and logged for fnm, performance measured and logged for gum target)
9. Hard-code success without real verification
10. Ignore existing user customizations

### ✅ DO:
1. Always create timestamped branches
2. Use latest versions for all dependencies
3. Query Context7 MCP for best practices when available
4. Follow constitutional commit message format
5. Use `--no-ff` for all merges to main
6. Edit source files in `website/src/` for documentation
7. Verify `.nojekyll` exists before deployment
8. Implement real verification tests (not mocked)
9. Use duplicate detection before installations
10. Preserve user customizations during updates

---

## 🎯 Quick Start Commands

### Clone and Setup
```bash
# Clone repository
git clone https://github.com/kairin/ghostty-config-files.git
cd ghostty-config-files

# Verify environment
cat .env  # Should have GITHUB_TOKEN and CONTEXT7_API_KEY
cat .mcp.json  # Should have Context7 and GitHub MCP config

# Check current status
git status
git log --oneline -5
cat specs/001-modern-tui-system/tasks.md | head -10
```

### Start Your First Task
```bash
# 1. Review available tasks
cat specs/001-modern-tui-system/tasks.md | grep "^\- \[ \]" | head -10

# 2. Pick a task (e.g., T040)
cat specs/001-modern-tui-system/tasks.md | grep -A 10 "T040"

# 3. Create branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
git checkout main
git pull origin main
git checkout -b "${DATETIME}-feat-your-feature"

# 4. Implement (follow patterns in lib/tasks/gum.sh)
# 5. Test (bash -n, source, dry-run)
# 6. Commit (constitutional format)
# 7. Push and merge (preserve branch!)
```

---

## 🆘 Troubleshooting

### Issue: Git Authentication Failed
```bash
# Solution: Use GitHub CLI for authentication
gh auth login
gh auth status
```

### Issue: Can't Push to Remote
```bash
# Solution: Verify remote configuration
git remote -v
# Should show: origin  https://github.com/kairin/ghostty-config-files.git

# Re-authenticate with GitHub CLI
gh auth refresh
```

### Issue: Merge Conflicts
```bash
# Solution: Pull latest main before creating branch
git checkout main
git pull origin main
git checkout -b "your-branch"
```

### Issue: Context7 MCP Not Working
```bash
# Solution: Verify MCP configuration
cat .env | grep CONTEXT7_API_KEY
cat .mcp.json | jq '.mcpServers.context7'

# Restart Claude Code to reload MCP
exit && claude
```

---

## 📊 Progress Tracking

### Update tasks.md After Each Task
```bash
# 1. Mark task complete
sed -i 's/- \[ \] T040/- [X] T040/' specs/001-modern-tui-system/tasks.md

# 2. Update progress counter
# Old: 30/64 tasks complete (46.9%)
# New: 31/64 tasks complete (48.4%)
sed -i 's/30\/64 tasks complete (46.9%)/31\/64 tasks complete (48.4%)/' specs/001-modern-tui-system/tasks.md

# 3. Add implementation notes
# Edit T040 section to add:
#   - **Status**: ✅ COMPLETE
#   - **Implementation**: lib/tasks/app_audit.sh created
#   - **Verification**: Duplicate detection integrated
```

---

## 🎯 Success Criteria

### Your Implementation is Ready When:
- ✅ Follows constitutional branch workflow
- ✅ Passes bash syntax validation (`bash -n`)
- ✅ Has real verification tests (not hard-coded success)
- ✅ Implements duplicate detection if applicable
- ✅ Uses latest versions (NOT LTS)
- ✅ Has comprehensive logging
- ✅ Updates tasks.md progress tracking
- ✅ Includes constitutional commit message
- ✅ Merges to main with `--no-ff`
- ✅ Preserves feature branch (never deleted)

---

## 📞 Contact & Support

**Repository Owner**: kairin
**GitHub**: https://github.com/kairin/ghostty-config-files
**Issues**: https://github.com/kairin/ghostty-config-files/issues

**Key Files for Questions**:
- CLAUDE.md - LLM instructions and requirements
- ARCHITECTURE.md - System design
- specs/001-modern-tui-system/spec.md - Feature specifications

---

## 🎬 Final Checklist Before You Start

- [ ] Read CLAUDE.md (constitutional requirements)
- [ ] Read ARCHITECTURE.md (system design)
- [ ] Review specs/001-modern-tui-system/tasks.md (task list)
- [ ] Verify `.env` has GITHUB_TOKEN and CONTEXT7_API_KEY
- [ ] Verify `.mcp.json` is configured
- [ ] Test git authentication: `gh auth status`
- [ ] Pull latest main: `git pull origin main`
- [ ] Understand constitutional branch workflow
- [ ] Know how to create timestamped branches
- [ ] Understand `--no-ff` merge requirement
- [ ] **CRITICAL**: Remember to NEVER delete branches

**Ready?** Pick your first task from Phase 7, 8, 9, or 10 and follow the "Step-by-Step: Your First Task" guide above!

---

**Version**: 1.0
**Last Updated**: 2025-11-19
**Repository State**: MVP Complete (30/64 tasks)
**Ready for**: Parallel development on Phases 7-10
