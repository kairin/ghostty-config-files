# Claude Code Agent & Command System

**Single Source of Truth**: [`/home/kkk/Apps/ghostty-config-files/AGENTS.md`](../AGENTS.md)

**Status**: ACTIVE - MANDATORY COMPLIANCE
**Last Updated**: 2025-11-21

---

## 🚨 CRITICAL: Read This First

**Before performing ANY task in this repository:**

1. **Read AGENTS.md** - Contains ALL non-negotiable requirements
2. **Check constitutional principles** in `.claude/principles/`
3. **Verify compliance** before creating any new files

**Key Constitutional Principles** (MANDATORY):
- ✅ **Script Proliferation Prevention** - Enhance existing scripts, don't create new ones
- ✅ **Branch Preservation** - Never delete branches without permission
- ✅ **Git Workflow** - Timestamped branches, --no-ff merges
- ✅ **Documentation Sync** - CLAUDE.md/GEMINI.md symlink to AGENTS.md

---

## 📋 Quick Reference

### Constitutional Principles (MANDATORY)

**Location**: `.claude/principles/`

| Principle | File | Status |
|-----------|------|--------|
| **Script Proliferation Prevention** | `script-proliferation.md` | 🔴 CRITICAL |
| Branch Preservation | *(in AGENTS.md)* | 🔴 CRITICAL |
| Git Workflow | *(in AGENTS.md)* | 🔴 CRITICAL |
| Documentation Sync | *(in AGENTS.md)* | 🔴 CRITICAL |

**Before Creating ANY New File**:
1. Read `.claude/principles/script-proliferation.md`
2. Complete the validation checklist
3. Verify you're not violating proliferation rules

---

## 🤖 Agent Selection Matrix

**Use this table to select the appropriate agent for your task:**

| Need | Agent | Source File |
|------|-------|-------------|
| **Multiple parallel tasks** | 001-orchestrator | `agent-sources/001-orchestrator.md` |
| **Git operations** | 002-git | `agent-sources/002-git.md` |
| **Constitutional validation** | 002-compliance | `agent-sources/002-compliance.md` |
| **Health check** | 002-health | `agent-sources/002-health.md` |
| **Cleanup operations** | 002-cleanup | `agent-sources/002-cleanup.md` |
| **Build/deploy** | 002-astro | `agent-sources/002-astro.md` |
| **Local CI/CD** | 003-cicd | `agent-sources/003-cicd.md` |
| **Symlink integrity** | 003-symlink | `agent-sources/003-symlink.md` |
| **Documentation sync** | 003-docs | `agent-sources/003-docs.md` |
| **Workflow orchestration** | 003-workflow | `agent-sources/003-workflow.md` |

> **Note**: Source files are in `.claude/agent-sources/`. Run `./scripts/install-claude-config.sh` to install to `~/.claude/agents/` for use.

---

## ⚡ Workflow Agents (Quick Reference)

### Tier 0 Workflow Agents (Fully Automatic)

**Invoke via natural language or Task tool:**

| Agent | Natural Language Trigger | Purpose |
|-------|--------------------------|---------|
| `000-health` | "Check project health" | System health assessment |
| `000-docs` | "Fix documentation" | Fix documentation and symlinks |
| `000-commit` | "Commit my changes" | Constitutional Git commit |
| `000-deploy` | "Deploy the website" | Deploy with validation |
| `000-cleanup` | "Clean up the repo" | Safe cleanup with preservation |

---

## 🏗️ Architecture Overview

```
Repository Structure:

AGENTS.md (master)            ← Single source of truth
    ↓ symlinked by
CLAUDE.md, GEMINI.md         ← AI assistant entry points
    ↓ references
.claude/                      ← Agent & skill source definitions
├── README.md                 ← This file (quick reference)
├── principles/               ← Constitutional requirements
│   └── script-proliferation.md  🔴 CRITICAL
├── skill-sources/            ← 4 workflow skills (installed to ~/.claude/commands/)
│   ├── 001-health-check.md
│   ├── 001-deploy-site.md
│   ├── 001-git-sync.md
│   └── 001-full-workflow.md
└── agent-sources/            ← 65 agents (installed to ~/.claude/agents/)
    ├── 000-health.md            (Tier 0: Workflow)
    ├── 000-cleanup.md           (Tier 0: Workflow)
    ├── 000-commit.md            (Tier 0: Workflow)
    ├── 000-deploy.md            (Tier 0: Workflow)
    ├── 000-docs.md              (Tier 0: Workflow)
    ├── 001-orchestrator.md      (Tier 1: Opus)
    ├── 002-*.md                 (Tier 2: Sonnet Core - 5 agents)
    ├── 003-*.md                 (Tier 3: Sonnet Utility - 4 agents)
    └── 0XX-*.md                 (Tier 4: Haiku Atomic - 50 agents)

Installation: ./scripts/install-claude-config.sh
```

---

## 🚨 Script Proliferation Prevention

### CRITICAL REQUIREMENT

**Before creating ANY new `.sh` file:**

1. ✅ Read `.claude/principles/script-proliferation.md`
2. ✅ Complete validation checklist
3. ✅ Verify you're not creating:
   - Wrapper scripts (to fix other scripts)
   - Helper scripts (single-use utilities)
   - Management scripts (that only call others)

### Quick Checklist

- [ ] **Can this be added to an existing script?** → Add it there, STOP
- [ ] **Is this a test file?** (`tests/`, `*_test.sh`) → Allowed
- [ ] **Is this wrapping another script?** → Fix original, STOP
- [ ] **Is this a single-use helper?** → Add to core library, STOP
- [ ] **Absolutely necessary?** → Document justification

### ❌ Violations (NEVER DO THIS)

```bash
# Wrong: Creating helper for version comparison
lib/utils/version-compare.sh       # VIOLATION

# Wrong: Creating wrapper to fix script
scripts/fix-installer.sh            # VIOLATION

# Wrong: Creating icon installer
scripts/install-ghostty-icon.sh     # VIOLATION
```

### ✅ Correct Approach

```bash
# Correct: Add to existing core library
lib/core/logging.sh                 # Add version_compare()

# Correct: Fix original script
scripts/installer.sh                # Fix directly

# Correct: Enhance existing step
lib/installers/ghostty/steps/07-create-desktop-entry.sh
                                    # Add install_ghostty_icon()
```

**Enforcement**: 002-compliance validates all new files.

---

## 📖 Detailed Documentation

### Primary Resources

1. **AGENTS.md** (40KB, 892 lines)
   - ALL non-negotiable requirements
   - Branch management & Git strategy
   - Local CI/CD requirements
   - Documentation structure
   - Development commands

2. **`.claude/principles/script-proliferation.md`** (15KB)
   - Detailed script proliferation rules
   - Examples and violations
   - Validation checklist
   - Enforcement procedures

3. **Agent Definitions** (`.claude/agent-sources/`)
   - 65 agent source files (5 Tier 0 + 1 Tier 1 + 5 Tier 2 + 4 Tier 3 + 50 Tier 4)
   - Installed to `~/.claude/agents/` via `./scripts/install-claude-config.sh`
   - Detailed capabilities and usage
   - Constitutional compliance enforcement

### Supporting Documentation

- **`.claude/instructions-for-agents/requirements/`** - Constitutional compliance and validation rules
- **`.claude/instructions-for-agents/architecture/system-architecture.md`** - System architecture
- **`AGENTS.md`** - Quick onboarding (gateway file)
- **`astro-website/src/ai-guidelines/`** - Modular extracts (reference only)

---

## 🔄 Workflow Examples

### Example 1: Simple Enhancement Task

```
Task: Add version detection to Ghostty installer

1. Check AGENTS.md for requirements ✅
2. Check script proliferation principle ✅
3. Identify existing script to enhance:
   → lib/installers/ghostty/steps/08-verify-installation.sh
4. Enhance existing script (don't create new file) ✅
5. Add version_compare() to lib/core/logging.sh ✅
6. Follow constitutional Git workflow ✅
```

### Example 2: Complex Multi-Component Task

```
Task: Implement update detection for all components

1. Check AGENTS.md for requirements ✅
2. Check script proliferation principle ✅
3. Select agent: 001-orchestrator ✅
4. Instruct to enhance existing scripts only ✅
5. Agents modify existing verification scripts ✅
6. No new scripts created ✅
7. Constitutional Git workflow ✅
```

---

## 🎯 Common Scenarios

### Scenario: User Asks to Create New Script

**WRONG Response**:
```
I'll create scripts/new-helper.sh to handle this...
```

**CORRECT Response**:
```
I'll enhance the existing lib/installers/*/steps/XX-*.sh script
to add this functionality directly, following the script
proliferation prevention principle.
```

### Scenario: Bug in Existing Script

**WRONG Response**:
```
I'll create scripts/fix-broken-script.sh to work around this...
```

**CORRECT Response**:
```
I'll fix the bug in the original script directly at the source,
following the script proliferation prevention principle.
```

### Scenario: Need Utility Function

**WRONG Response**:
```
I'll create lib/utils/helper-function.sh for this...
```

**CORRECT Response**:
```
I'll add this function to lib/core/logging.sh (existing core
library), following the script proliferation prevention principle.
```

---

## ⚖️ Constitutional Enforcement

### Automated Validation

**002-compliance** checks:
- ✅ New `.sh` file creation
- ✅ Script proliferation violations
- ✅ Branch naming compliance
- ✅ Git workflow adherence
- ✅ Documentation sync

### Manual Override Process

**If you believe a new script is absolutely necessary:**

1. Complete full validation checklist
2. Document detailed justification
3. Explain why alternatives won't work
4. Include in commit message
5. Request user review
6. Await explicit user approval

**Commit Message Template**:
```
feat: Add new script for [purpose]

SCRIPT PROLIFERATION JUSTIFICATION:
- Cannot enhance existing script because: [reason]
- Not a wrapper script because: [reason]
- Not a helper function because: [reason]
- Absolute necessity: [detailed explanation]

Constitutional compliance checklist:
- [x] Test file exception - NO
- [x] Enhancement opportunity - NO (reason: ...)
- [x] Wrapper detection - NO
- [x] Helper function - NO (reason: ...)
- [x] Absolute necessity - YES (reason: ...)
- [x] Documentation - YES (see above)
```

---

## 📞 Support & Help

### When You're Unsure

1. **Read AGENTS.md** - Answers most questions
2. **Check `.claude/principles/`** - Detailed constitutional rules
3. **Review this README** - Quick reference and examples
4. **Ask user** - If still unclear, ask for clarification

### Common Questions

**Q: When can I create a new script?**
**A**: Only when ALL alternatives exhausted AND user approves.

**Q: What about test files?**
**A**: Test files are EXEMPT from proliferation rules.

**Q: Can I create a wrapper script to fix a bug?**
**A**: NO. Fix the original script directly.

**Q: Need a utility function used by 10+ scripts?**
**A**: Add to `lib/core/*.sh` (core library), NOT new file.

---

## 📊 Metrics & Monitoring

**Track these metrics**:
- Total script count (target: stable or decreasing)
- New scripts per month (alert: +5/month)
- Maximum call depth (target: ≤ 2 levels)
- Wrapper/helper count (target: 0)

**Monthly review**: Check script proliferation metrics and consolidation opportunities.

---

## 🔗 Quick Links

- **AGENTS.md** - [`../AGENTS.md`](../AGENTS.md)
- **Script Proliferation Principle** - [`principles/script-proliferation.md`](principles/script-proliferation.md)
- **Constitutional Compliance** - [`instructions-for-agents/requirements/`](instructions-for-agents/requirements/)
- **System Architecture** - [`instructions-for-agents/architecture/system-architecture.md`](instructions-for-agents/architecture/system-architecture.md)

---

## 📜 Version History

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2025-11-21 | Initial README with script proliferation emphasis |

---

**Status**: ACTIVE - MANDATORY COMPLIANCE FOR ALL AI ASSISTANTS
**Next Review**: 2025-12-21

---

**Remember**: AGENTS.md is the single source of truth. This README is a quick reference guide pointing to the authoritative documentation.

**End of Claude Code Agent & Command System README**
