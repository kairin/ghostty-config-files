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

---

## Wave 1: Foundation (THIS WEEK)

> **Priority**: Enable efficient future work before adding features

| # | Task | Effort | Enables |
|---|------|--------|---------|
| 4 | Create /scripts/README.md | 1 hr | Script navigation for AI/humans |
| 5 | Consolidate MCP documentation | 2 hr | TUI MCP feature clarity |
| 6 | Create /scripts/007-update/README.md | 30 min | Update script discovery |
| 7 | Create /scripts/007-diagnostics/README.md | 30 min | Boot diagnostics docs |
| 8 | Update ai-cli-tools.md (fix "not created" text) | 15 min | Accurate documentation |

**Total**: ~4.5 hours | **Status**: ⏳ Pending Wave 0

**Details:**
- /scripts/README.md: 114 scripts with no master index
- MCP docs: 4+ overlapping guides need consolidation into single source
- ai-cli-tools.md: States "scripts not yet created" but they exist

---

## Wave 2: TUI Features (NEXT SPRINT)

> **Priority**: Build on solid documentation foundation

| # | Task | Effort | Dependencies |
|---|------|--------|--------------|
| 9 | Per-family Nerd Font selection | 2 hr | None |
| 10 | TUI MCP Server Management | 4 hr | #5 (MCP docs) |
| 11 | MCP prerequisites detection | 2 hr | #10 |
| 12 | MCP server registry | 1 hr | #10 |
| 13 | Secrets template setup wizard | 2 hr | #11, #12 |

**Total**: ~11 hours | **Status**: ⏳ Pending Wave 1

**Notes:**
- Nerd Fonts: Currently all 8 families install together, need per-family selection
- MCP feature: Add 7 MCP servers as category under Extras menu with prerequisites detection
- Location: `tui/internal/ui/extras.go` (under Extras menu)

---

## Wave 3: Enhancements (LATER)

> **Priority**: Nice-to-have improvements after core features complete

| # | Task | Priority | Notes |
|---|------|----------|-------|
| 14 | Glamour markdown viewer (`details.go`) | Medium | TUI polish - render docs in-terminal |
| 15 | TUI unit tests | Medium | Quality assurance |
| 16 | "Install All" batch installation | Low | Convenience feature |
| 17 | Automated link validation | Medium | CI/CD enhancement |
| 18 | AGENTS.md size tracking | Low | Monitor vs 40KB limit |
| 19 | Proper semver comparison | Low | TUI version handling |
| 20 | Rename LOGGING_GUIDE.md | Low | Caps inconsistent |
| 21 | Standardize script headers | Medium | 61% coverage, need 100% |
| 22 | Add bidirectional cross-references | Medium | Links go A→B but not B→A |
| 23 | Create stage-specific READMEs | Medium | 000-005 directories need docs |

**Status**: ⏳ Pending Wave 2

---

## Wave 4: Future Features (BACKLOG)

### Claude Code Enhancements

#### Skills/Slash Commands (Not Implemented)
| Task | Priority | Notes |
|------|----------|-------|
| Create `/health-check` skill | Medium | Quick system diagnostics invocation |
| Create `/deploy-site` skill | Medium | Astro build + deploy workflow |
| Create `/git-sync` skill | Low | Fetch, pull, push all branches |
| Create `/full-workflow` skill | Low | Complete commit workflow |

**What skills provide**: User-invocable `/commands` from `.claude/skills/` directory. Hot-reload enabled (v2.1.0+).

#### Hooks (Not Implemented)
| Task | Priority | Notes |
|------|----------|-------|
| Add PermissionRequest hook | High | Auto-approve safe ops, reduce prompts |
| Add PreToolUse validation hook | Medium | Validate before tool execution |
| Add PostToolUse audit hook | Medium | Log/validate after execution |
| Add Stop hook for CI/CD | Low | Auto-run validation on completion |
| Add Setup hook | Low | New contributor onboarding |

**What hooks provide**: Automated pre/post execution scripts. Configured in settings.json.

#### Memory Rules (Minimal Implementation)
| Task | Priority | Notes |
|------|----------|-------|
| Create `.claude/rules/git-conventions.md` | Medium | Branch naming, commit format rules |
| Create `.claude/rules/code-standards.md` | Low | Project coding standards |
| Migrate Tailwind rules to `.claude/rules/` | Low | Move from `rules-tailwindcss/` |

**What rules provide**: Persistent instructions loaded every session. Cleaner than AGENTS.md.

#### Reference Documentation
- **Skills docs**: https://code.claude.com/docs/en/slash-commands
- **Hooks docs**: https://code.claude.com/docs/en/hooks
- **Memory docs**: https://code.claude.com/docs/en/memory
- **Plugins docs**: https://code.claude.com/docs/en/plugins (for future consideration)

### Cross-System Synchronization

Goal: Enable seamless environment sync between multiple machines.

#### Machine Inventory & Tracking
| Task | Priority | Notes |
|------|----------|-------|
| Create `~/.ghostty-fleet/inventory.json` | High | Track all machines with this config |
| Per-machine version snapshots | Medium | Record tool versions on each system |
| Sync status reporting | Medium | Show drift between machines |

#### Update Management
| Task | Priority | Notes |
|------|----------|-------|
| Remote sync via SSH | Low | Push updates to other machines |
| Version pinning per-machine | Medium | Lock specific versions if needed |
| Rollback capability | Low | Revert to previous tool versions |

#### Claude Code Consistency
| Task | Priority | Notes |
|------|----------|-------|
| Agent version tracking | Medium | Track agent definitions across systems |
| Permission rule sync | Medium | Ensure identical approval rules |
| MCP server configuration sync | High | Same MCP servers on all machines (user scope) |
| MCP secrets portable sync | Medium | Gist export/import via TUI |

**Future consideration**: Could this become a Claude Code plugin for sharing with others?

### Advanced Features
| Task | Priority | Notes |
|------|----------|-------|
| Context7 health check integration | Medium | `health-check.sh --context7-validate all` |
| Parallel validation execution | Low | Wave 4 enhancement |
| HTML report generation | Low | Charts and graphs for performance reports |

**Status**: 📋 Backlog

---

## Maintenance Tasks

| Task | Status | Priority | Location |
|------|--------|----------|----------|
| Update ai-cli-tools.md documentation | Planned | Moderate | `.claude/instructions-for-agents/tools/ai-cli-tools.md` |

**Details:** Documentation states "scripts not yet created" but they actually exist:
- `/scripts/004-reinstall/install_ai_tools.sh`
- `/scripts/001-uninstall/uninstall_ai_tools.sh`
- `/scripts/005-confirm/confirm_ai_tools.sh`
- `/scripts/007-update/update_ai_tools.sh`

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

---

## How to Use This Roadmap

### Wave Execution Order

```
Wave 0 (IMMEDIATE)     →  Must complete first, blocks everything
    ↓
Wave 1 (THIS WEEK)     →  Foundation work, enables features
    ↓
Wave 2 (NEXT SPRINT)   →  TUI features, main development
    ↓
Wave 3 (LATER)         →  Enhancements, polish
    ↓
Wave 4 (BACKLOG)       →  Future features, ideas
```

### Status Indicators
- 🔴 **Not Started**: Blocking work, needs immediate attention
- ⏳ **Pending**: Waiting on previous wave completion
- 🟡 **In Progress**: Actively being worked on
- ✅ **Completed**: Done and merged to main
- 📋 **Backlog**: Future consideration, no timeline

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
