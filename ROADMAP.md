# Development Roadmap

> **Version**: 3.4-Wave-Structure | **Last Updated**: 2026-01-18 | **Status**: Active

This document tracks planned features, outstanding tasks, and maintenance items for the Ghostty Configuration Files project.

---

## Vision: Consistent Developer Environment Everywhere

**Goal**: Every Ubuntu Linux system you set up - whether a fresh install or an update to an existing machine - will have all your familiar tools configured identically, so you can work the same way on any computer.

### Why This Matters

| Scenario | Without This Project | With This Project |
|----------|---------------------|-------------------|
| New machine setup | Hours of manual configuration | `git clone && ./start.sh` |
| Updating existing system | Remember what's installed where | `./start.sh` detects and updates |
| AI assistant behavior | Different on each machine | Same 65 agents, same rules, same behavior |
| Tool versions | Drift over time | Centralized version management |

### Core Philosophy: Developer Environment as Code

This project treats your **personal developer environment** the same way infrastructure-as-code treats servers:

1. **Reproducible** - Clone the repo, run one command, get the same environment
2. **Version-controlled** - All configuration is tracked in Git
3. **Declarative** - AGENTS.md defines how AI assistants behave
4. **Idempotent** - Run `./start.sh` multiple times safely; it detects what's already installed
5. **Self-documenting** - 34 guide files explain every component

### What Gets Synchronized

| Category | Components | Status |
|----------|-----------|--------|
| **Terminal** | Ghostty config, Catppuccin themes, Nerd Fonts | ✅ Complete |
| **Shell** | ZSH, Oh My ZSH, PowerLevel10k | ✅ Complete |
| **AI Tools** | Claude Code agents/permissions, Gemini CLI | ✅ Complete |
| **Development** | Go, Node.js (fnm), Python (uv) | ✅ Complete |
| **TUI Tools** | gum, glow, vhs, fastfetch, feh | ✅ Complete |
| **MCP Servers** | Context7, GitHub, MarkItDown, Playwright | ✅ Template ready |

### Design Principles

1. **One Command**: Fresh install should work with `./start.sh`
2. **Detect, Don't Duplicate**: Check if tools exist before installing
3. **Local First**: CI/CD runs locally, not burning GitHub Actions minutes
4. **Script Proliferation Prevention**: Enhance existing scripts, don't create new ones
5. **Single Source of Truth**: AGENTS.md is the master; CLAUDE.md/GEMINI.md are symlinks

### Claude Code: Same Behavior Everywhere

The AI assistant configuration is **fully portable**:

| Component | What It Provides | Location |
|-----------|-----------------|----------|
| **65 Custom Agents** | Specialized subagents for every task type | `.claude/agents/` |
| **195+ Permission Rules** | Pre-approved tools, no repeated prompts | `.claude/settings.local.json` |
| **7 MCP Servers** | Context7, GitHub, MarkItDown, Playwright, HF, shadcn (x2) | `~/.claude.json` (user scope) |
| **34 Guide Files** | Consistent instructions for AI behavior | `.claude/instructions-for-agents/` |
| **Symlink Architecture** | CLAUDE.md → AGENTS.md (single source of truth) | Project root |

**Result**: Clone this repo on any Ubuntu system, and Claude Code will behave identically - same agents available, same permissions configured, same documentation context.

### Update Workflow: Existing Systems

The project supports both **fresh installs** and **updates to existing systems**:

| Scenario | Command | What Happens |
|----------|---------|--------------|
| **Fresh install** | `git clone && ./start.sh` | Installs everything from scratch |
| **Update existing** | `cd ghostty-config-files && git pull && ./start.sh` | Detects installed tools, updates only what's needed |
| **Daily auto-update** | `./scripts/daily-updates.sh` (cron) | Runs at 9 AM, updates all tools |
| **Check before update** | `./start.sh` → "Check Updates" | Shows what would change |

**Idempotent by design**: Running `./start.sh` multiple times is safe - it checks what's already installed and skips those tools.

### Machine Management (Future)

Track your fleet of Ubuntu systems:

```
~/.ghostty-fleet/
├── inventory.json         # List of machines with this config
├── machine-001.json       # Per-machine version snapshots
├── machine-002.json
└── sync-report.md         # Last sync status
```

---

## Wave 0: Immediate Fixes (COMPLETE)

> **Priority**: ✅ COMPLETED - 2026-01-18

| # | Task | Effort | Blocker For | Status |
|---|------|--------|-------------|--------|
| 1 | Create LICENSE file | 5 min | README badges, project credibility | ✅ Done |
| 2 | Fix broken link in local-cicd-operations.md | 5 min | AI assistant navigation | ✅ Done |
| 3 | Unify agent tier definitions (4→5 tier) | 30 min | Documentation consistency | ✅ Done |

**Total**: ~40 minutes | **Status**: ✅ COMPLETE

**Completed:**
- LICENSE: MIT license created with copyright "Mr K" (2026)
- Broken link: Created `local-cicd-guide.md` in guides/
- Tier conflict: Unified to 5-tier (0-4) across all 4 architecture files

**SpecKit Artifacts:** [specs/001-foundation-fixes/](specs/001-foundation-fixes/)

---

## Wave 1: Foundation (COMPLETE)

> **Priority**: ✅ COMPLETED - 2026-01-18

| # | Task | Effort | Enables | Status |
|---|------|--------|---------|--------|
| 4 | Create /scripts/README.md | 1 hr | Script navigation for AI/humans | ✅ Done |
| 5 | Consolidate MCP documentation | 2 hr | TUI MCP feature clarity | ✅ Done |
| 6 | Create /scripts/007-update/README.md | 30 min | Update script discovery | ✅ Done |
| 7 | Create /scripts/007-diagnostics/README.md | 30 min | Boot diagnostics docs | ✅ Done |
| 8 | Update ai-cli-tools.md (fix "not created" text) | 15 min | Accurate documentation | ✅ Done |

**Total**: ~4.5 hours | **Status**: ✅ COMPLETE

**Completed:**
- scripts/README.md: Master index for 114 scripts across 11 directories
- MCP docs: Consolidated 5 guides into single mcp-setup.md with redirect stubs
- 007-update/README.md: Documents 12 update scripts with usage and troubleshooting
- 007-diagnostics/README.md: Documents boot diagnostics workflow
- ai-cli-tools.md: Updated from "PLANNED" to "IMPLEMENTED" with correct paths
- AGENTS.md: Updated references to point to new mcp-setup.md

**SpecKit Artifacts:** [specs/002-scripts-documentation/](specs/002-scripts-documentation/)

---

## Wave 2: TUI Features (COMPLETE)

> **Priority**: ✅ COMPLETED - 2026-01-18

| # | Task | Effort | Dependencies | Status |
|---|------|--------|--------------|--------|
| 9 | Per-family Nerd Font selection | 2 hr | None | ✅ Done |
| 10 | TUI MCP Server Management | 4 hr | #5 (MCP docs) | ✅ Done |
| 11 | MCP prerequisites detection | 2 hr | #10 | ✅ Done |
| 12 | MCP server registry | 1 hr | #10 | ✅ Done |
| 13 | Secrets template setup wizard | 2 hr | #11, #12 | ✅ Done |

**Total**: ~11 hours | **Status**: ✅ COMPLETE

**Completed:**
- Per-family Nerd Font: Individual font selection with Install/Reinstall/Uninstall actions
- MCP Server Management: New view under Extras → MCP Servers (7 servers with status)
- MCP Prerequisites: Auto-check Node.js, uvx, gh auth before install with fix instructions
- MCP Registry: Data-driven registry in `tui/internal/registry/mcp.go`
- Secrets Wizard: Interactive setup for ~/.mcp-secrets file

**New TUI Files Created:**
- `tui/internal/registry/mcp.go` - MCP server registry (7 servers)
- `tui/internal/ui/mcpservers.go` - MCP Servers management view
- `tui/internal/ui/mcpprereq.go` - Prerequisites failure view
- `tui/internal/ui/secretswizard.go` - Secrets setup wizard

**SpecKit Artifacts:** [specs/003-tui-features/](specs/003-tui-features/)

---

## Wave 3: Claude Code Skills (COMPLETE)

> **Priority**: ✅ COMPLETED - 2026-01-18
> **Theme**: Custom slash commands and portable configuration

| # | Task | Effort | Priority | Status |
|---|------|--------|----------|--------|
| 14 | Create `/001-health-check` skill | 1 hr | Medium | ✅ Done |
| 15 | Create `/001-deploy-site` skill | 1 hr | Medium | ✅ Done |
| 16 | Create `/001-git-sync` skill | 1 hr | Low | ✅ Done |
| 17 | Create `/001-full-workflow` skill | 1 hr | Low | ✅ Done |
| 18 | Skills user-level consolidation | 1 hr | **High** | ✅ Done |
| 19 | Agents user-level consolidation | 2 hr | **High** | ✅ Done |
| 20 | Combined install script | 1 hr | **High** | ✅ Done |

**Completed (Skills)**:
- 4 workflow skills created: `/001-health-check`, `/001-deploy-site`, `/001-git-sync`, `/001-full-workflow`
- Skills moved from `.claude/commands/` → `.claude/skill-sources/` (source files)
- Install script copies to `~/.claude/commands/` (user-level)

**Completed (Agents)**:
- 65 agents moved from `.claude/agents/` → `.claude/agent-sources/` (source files)
- Combined install script created: `scripts/install-claude-config.sh`
- Installs to `~/.claude/agents/` at user level

**What this provides**: Portable Claude Code configuration across all computers. Clone repo, run `./scripts/install-claude-config.sh`, identical setup everywhere.

**Total**: ~7 hours | **Status**: ✅ Complete

**SpecKit Artifacts:** [specs/004-claude-skills/](specs/004-claude-skills/) (skills) | [specs/005-claude-agents/](specs/005-claude-agents/) (agents)

**Reference**: [Skills docs](https://code.claude.com/docs/en/slash-commands)

---

## Wave 4: Claude Code Hooks (READY)

> **Priority**: Automation hooks (HIGH VALUE subset) - reduces permission prompts
> **Theme**: Pre/post execution automation

| # | Task | Effort | Priority | Notes |
|---|------|--------|----------|-------|
| 18 | Add PermissionRequest hook | 2 hr | **High** | Auto-approve safe ops, reduce prompts |
| 19 | Add PreToolUse validation hook | 1 hr | Medium | Validate before tool execution |
| 20 | Add PostToolUse audit hook | 1 hr | Medium | Log/validate after execution |

**Deferred to backlog**: Stop hook (Low), Setup hook (Low)

**What hooks provide**: Automated pre/post execution scripts. Configured in settings.json.

**Total**: ~4 hours | **Status**: ⏳ Ready to start

**Reference**: [Hooks docs](https://code.claude.com/docs/en/hooks)

---

## Wave 5: Claude Code Memory (READY)

> **Priority**: Persistent rules for consistent behavior - cleaner than AGENTS.md
> **Theme**: Memory rules and standards

| # | Task | Effort | Priority | Notes |
|---|------|--------|----------|-------|
| 21 | Create `.claude/rules/git-conventions.md` | 45 min | Medium | Branch naming, commit format rules |
| 22 | Create `.claude/rules/code-standards.md` | 45 min | Low | Project coding standards |
| 23 | Migrate Tailwind rules to `.claude/rules/` | 30 min | Low | Move from `rules-tailwindcss/` |

**What rules provide**: Persistent instructions loaded every session. Cleaner than AGENTS.md.

**Total**: ~2 hours | **Status**: ⏳ Ready to start

**Reference**: [Memory docs](https://code.claude.com/docs/en/memory)

---

## Wave 6a: TUI Detail Views (COMPLETE)

> **Priority**: ✅ COMPLETED - 2026-01-18
> **Theme**: Navigation restructure for better usability

| # | Task | Effort | Priority | Status |
|---|------|--------|----------|--------|
| 24 | Create ViewToolDetail component | 2 hr | **High** | ✅ Done |
| 25 | Simplify main dashboard (3 tools in table) | 1 hr | **High** | ✅ Done |
| 26 | Add Ghostty/Feh as menu items | 1 hr | **High** | ✅ Done |
| 27 | Convert Extras to navigation menu | 1.5 hr | **High** | ✅ Done |

**Total**: ~5.5 hours | **Status**: ✅ COMPLETE

**What this fixed**:
- Extras header was cut off (not visible)
- Main dashboard too crowded with 5 tools
- Extras showed 7 tools in cramped table

**Solution implemented**:
- Created `tui/internal/ui/tooldetail.go` - reusable ViewToolDetail component (~378 lines)
- Main table: Node.js, AI Tools, Antigravity only (3 tools)
- Ghostty and Feh accessible via menu → detail view
- Extras: navigation menu → individual detail views

**New/Modified TUI Files:**
- `tui/internal/ui/tooldetail.go` - New ViewToolDetail component
- `tui/internal/ui/model.go` - Added ViewToolDetail routing and dashboard simplification
- `tui/internal/ui/extras.go` - Converted from table to menu navigation

**SpecKit Artifacts:** [specs/006-tui-detail-views/](specs/006-tui-detail-views/)

---

## Wave 6b: TUI Polish (READY)

> **Priority**: Complete TUI functionality after detail views
> **Theme**: TUI enhancements and quality

| # | Task | Effort | Priority | Notes |
|---|------|--------|----------|-------|
| 28 | Glamour markdown viewer (`details.go`) | 2 hr | Medium | Render docs in-terminal |
| 29 | TUI unit tests | 2 hr | Medium | Quality assurance |
| 30 | "Install All" batch installation | 1 hr | Low | Convenience feature |
| 31 | Proper semver comparison | 1 hr | Low | TUI version handling |

**Total**: ~6 hours | **Status**: ⏳ Ready to start

---

## Wave 7: Documentation Cleanup (READY)

> **Priority**: Finalize documentation consistency
> **Theme**: Documentation standardization

| # | Task | Effort | Priority | Notes |
|---|------|--------|----------|-------|
| 32 | Standardize script headers | 2 hr | Medium | 61% coverage → 100% |
| 33 | Add bidirectional cross-references | 1 hr | Medium | Links go A→B but not B→A |
| 34 | Create stage-specific READMEs | 1 hr | Medium | 000-005 directories need docs |
| 35 | Rename LOGGING_GUIDE.md | 15 min | Low | Caps inconsistent |

**Total**: ~4 hours | **Status**: ⏳ Ready to start

---

## Wave 8: CI/CD & Monitoring (READY)

> **Priority**: Automated quality gates
> **Theme**: Continuous quality monitoring

| # | Task | Effort | Priority | Notes |
|---|------|--------|----------|-------|
| 36 | Automated link validation | 1.5 hr | Medium | CI/CD enhancement |
| 37 | AGENTS.md size tracking | 30 min | Low | Monitor vs 40KB limit |

**Total**: ~2 hours | **Status**: ⏳ Ready to start

---

## Wave 9: Multi-Machine Foundation (READY)

> **Priority**: Core sync infrastructure
> **Theme**: Cross-system synchronization basics

| # | Task | Effort | Priority | Notes |
|---|------|--------|----------|-------|
| 38 | Create `~/.ghostty-fleet/inventory.json` | 2 hr | **High** | Track all machines with this config |
| 39 | Per-machine version snapshots | 2 hr | Medium | Record tool versions on each system |
| 40 | Sync status reporting | 2 hr | Medium | Show drift between machines |
| 41 | MCP server configuration sync | 2 hr | **High** | Same MCP servers on all machines |

**Total**: ~8 hours | **Status**: ⏳ Ready to start

---

## Wave 10: Multi-Machine Advanced (BACKLOG)

> **Priority**: Extended sync capabilities - future consideration
> **Theme**: Advanced cross-system features

| Task | Priority | Notes |
|------|----------|-------|
| Remote sync via SSH | Low | Push updates to other machines |
| Version pinning per-machine | Medium | Lock specific versions if needed |
| Rollback capability | Low | Revert to previous tool versions |
| Agent version tracking | Medium | Track agent definitions across systems |
| Permission rule sync | Medium | Ensure identical approval rules |
| MCP secrets portable sync | Medium | Gist export/import via TUI |

**Status**: 📋 Backlog

---

## Wave 11: Advanced Features (BACKLOG)

> **Priority**: Nice-to-have enhancements
> **Theme**: Future polish and advanced capabilities

| Task | Priority | Notes |
|------|----------|-------|
| Add Stop hook for CI/CD | Low | Auto-run validation on completion |
| Add Setup hook | Low | New contributor onboarding |
| Context7 health check integration | Medium | `health-check.sh --context7-validate all` |
| Parallel validation execution | Low | Performance enhancement |
| HTML report generation | Low | Charts and graphs for reports |

**Future consideration**: Could this become a Claude Code plugin for sharing with others?

**Reference**: [Plugins docs](https://code.claude.com/docs/en/plugins)

**Status**: 📋 Backlog

---

## Maintenance Tasks

*No pending maintenance tasks.*

---

## Completed

| Task | Completed | Notes |
|------|-----------|-------|
| TUI Installer v1.0 | 2026-01-17 | Core installation working |
| Nerd Fonts Management | 2026-01-17 | Bulk install/uninstall working |
| Dynamic Theme Switching | 2026-01-17 | Catppuccin Mocha/Latte auto-switch |
| Claude Workflow Generator | 2026-01-17 | TUI command generator |
| Context7 header auth fix | 2026-01-18 | Setup script updated with --header flag |
| MCP scope verification | 2026-01-18 | User scope confirmed correct via Context7 |
| ROADMAP wave restructure | 2026-01-18 | Replaced v3.x with Wave 0-4 structure |
| Wave 0 Foundation Fixes | 2026-01-18 | LICENSE, broken link fix, tier unification - [specs/001-foundation-fixes/](specs/001-foundation-fixes/) |
| Wave 1 Scripts Documentation | 2026-01-18 | 5 READMEs, MCP consolidation, ai-cli-tools fix - [specs/002-scripts-documentation/](specs/002-scripts-documentation/) |
| Wave 2 TUI Features | 2026-01-18 | Per-font selection, MCP management, prerequisites, secrets wizard - [specs/003-tui-features/](specs/003-tui-features/) |
| Wave 3 Skills + Agents | 2026-01-18 | 4 skills + 65 agents consolidated to user-level - [specs/004-claude-skills/](specs/004-claude-skills/) + [specs/005-claude-agents/](specs/005-claude-agents/) |
| Wave 6a TUI Detail Views | 2026-01-18 | ViewToolDetail component, dashboard simplification, extras menu - [specs/006-tui-detail-views/](specs/006-tui-detail-views/) |

---

## SpecKit Verification Summary

All completed waves have been verified against their SpecKit specifications:

| Wave | SpecKit Spec | Checklist | Tasks | Status |
|------|--------------|-----------|-------|--------|
| Wave 0 | [001-foundation-fixes](specs/001-foundation-fixes/) | 16/16 ✓ | 17/17 ✓ | ✅ Verified |
| Wave 1 | [002-scripts-documentation](specs/002-scripts-documentation/) | 16/16 ✓ | 54/54 ✓ | ✅ Verified |
| Wave 2 | [003-tui-features](specs/003-tui-features/) | 16/16 ✓ | 78/78 ✓ | ✅ Verified |
| Wave 3 | [004-claude-skills](specs/004-claude-skills/) + [005-claude-agents](specs/005-claude-agents/) | 16/16 ✓ | 7/7 ✓ | ✅ Verified |
| Wave 4 | *Claude Hooks* | - | 3 defined | ⏳ Ready |
| Wave 5 | *Claude Memory* | - | 3 defined | ⏳ Ready |
| Wave 6a | [006-tui-detail-views](specs/006-tui-detail-views/) | 16/16 ✓ | 44/44 ✓ | ✅ Verified |
| Wave 6b | *TUI Polish* | - | 4 defined | ⏳ Ready |
| Wave 7 | *Documentation* | - | 4 defined | ⏳ Ready |
| Wave 8 | *CI/CD & Monitoring* | - | 2 defined | ⏳ Ready |
| Wave 9 | *Multi-Machine* | - | 4 defined | ⏳ Ready |
| Wave 10-11 | *Backlog* | - | ~11 defined | 📋 Future |

**Total verified tasks:** 193 across 5 completed waves
**Pending tasks:** 35 across 7 ready waves + 11 in backlog

**Last verified:** 2026-01-18

---

## How to Use This Roadmap

### Wave Execution Order

```
COMPLETED:
  Wave 0 (Immediate Fixes)      ✅ Done
  Wave 1 (Foundation Docs)      ✅ Done
  Wave 2 (TUI Features)         ✅ Done
  Wave 3 (Claude Skills+Agents) ✅ Done
  Wave 6a (TUI Detail Views)    ✅ Done

NEXT UP:
  Wave 4 (Claude Hooks)         ⏳ 3 tasks, ~4 hr  ← START HERE
      ↓
  Wave 5 (Claude Memory)        ⏳ 3 tasks, ~2 hr
      ↓
  Wave 5 (Claude Memory)        ⏳ 3 tasks, ~2 hr

THEN ENHANCEMENTS:
  Wave 6b (TUI Polish)          ⏳ 4 tasks, ~6 hr
      ↓
  Wave 7 (Documentation)        ⏳ 4 tasks, ~4 hr
      ↓
  Wave 8 (CI/CD & Monitoring)   ⏳ 2 tasks, ~2 hr
      ↓
  Wave 9 (Multi-Machine)        ⏳ 4 tasks, ~8 hr

BACKLOG:
  Wave 10-11 (Advanced)         📋 ~11 tasks
```

### Status Indicators
- 🔴 **Not Started**: Blocking work, needs immediate attention
- ⏳ **Pending**: Waiting on previous wave completion
- 🟡 **In Progress**: Actively being worked on
- ✅ **Completed**: Done and merged to main
- 📋 **Backlog**: Future consideration, no timeline

### SpecKit Workflow for New Waves

When starting a new wave, use SpecKit to manage the development lifecycle:

```
1. /speckit.specify   →  Create spec.md from ROADMAP tasks
2. /speckit.checklist →  Generate requirements checklist
3. /speckit.plan      →  Create implementation plan
4. /speckit.tasks     →  Generate detailed tasks.md
5. /speckit.implement →  Execute tasks with tracking
6. /speckit.analyze   →  Verify completion
```

**Spec directory structure:**
```
specs/
├── 001-foundation-fixes/      # Wave 0 ✅
├── 002-scripts-documentation/ # Wave 1 ✅
├── 003-tui-features/          # Wave 2 ✅
├── 004-claude-skills/         # Wave 3 (when started)
├── 005-claude-hooks/          # Wave 4 (when started)
├── 006-claude-memory/         # Wave 5 (when started)
├── 007-tui-polish/            # Wave 6 (when started)
├── 008-documentation/         # Wave 7 (when started)
├── 009-cicd-monitoring/       # Wave 8 (when started)
└── 010-multi-machine/         # Wave 9 (when started)
```

### Adding New Items
1. Determine which wave the task belongs to
2. Add with effort estimate and dependencies
3. Include location (file:line if applicable)
4. Move to Completed section when merged

### For AI Assistants
When working on tasks from this roadmap:
1. **Check Wave 0 first** - Complete blocking items before other work
2. Follow [Git Strategy](/.claude/instructions-for-agents/requirements/git-strategy.md)
3. Run [Local CI/CD](/.claude/instructions-for-agents/requirements/local-cicd-operations.md) before pushing
4. Observe [Script Proliferation](/.claude/instructions-for-agents/principles/script-proliferation.md) principle

---

## References

- [README.md](README.md) - Project overview
- [CLAUDE.md](CLAUDE.md) - AI assistant instructions
- [System Architecture](/.claude/instructions-for-agents/architecture/system-architecture.md)
- [First-Time Setup](/.claude/instructions-for-agents/guides/first-time-setup.md)
