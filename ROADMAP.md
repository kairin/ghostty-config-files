# Development Roadmap

> **Version**: 3.3-2026-TUI-Update | **Last Updated**: 2026-01-17 | **Status**: Active

This document tracks planned features, outstanding tasks, and maintenance items for the Ghostty Configuration Files project.

---

## Current Focus

### v3.4 - TUI Completion (Target: February 2026)

| Task | Status | Priority | Location |
|------|--------|----------|----------|
| Per-family Nerd Font selection (Phase 3a) | Planned | High | `tui/internal/ui/model.go:516` |
| Glamour markdown viewer (`details.go`) | Planned | Medium | TUI Phase 2 |
| "Install All" batch installation | Planned | Low | TUI Phase 2 |
| TUI unit tests | Planned | Medium | TUI Phase 2 |
| Proper semver comparison | Planned | Low | TUI Phase 2 |

**Notes:**
- Phase 3a is the highest priority - currently all 8 Nerd Font families install together
- `details.go` will use Glamour for rendering tool documentation in-terminal

### v3.5 - Documentation Automation (Target: March 2026)

| Task | Status | Priority | Notes |
|------|--------|----------|-------|
| Automated link validation | Planned | Medium | Integrate `markdown-link-check` into CI/CD |
| AGENTS.md size tracking | Planned | Low | Monitor growth vs 40KB constitutional limit |
| CI/CD documentation pipeline | Planned | Medium | Add to local workflows |

### v4.0 - Advanced Features (Future)

| Task | Status | Priority | Notes |
|------|--------|----------|-------|
| Context7 health check integration | Planned | Medium | `health-check.sh --context7-validate all` |
| Parallel validation execution | Planned | Low | Wave 4 enhancement |
| HTML report generation | Planned | Low | Charts and graphs for performance reports |

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

| Task | Completed | Branch | Notes |
|------|-----------|--------|-------|
| TUI Installer v1.0 | 2026-01-17 | main | Core installation working |
| Nerd Fonts Management | 2026-01-17 | main | Bulk install/uninstall working |
| Dynamic Theme Switching | 2026-01-17 | main | Catppuccin Mocha/Latte auto-switch |
| Claude Workflow Generator | 2026-01-17 | 20260117-* | TUI command generator |

---

## How to Use This Roadmap

### Status Definitions
- **Planned**: Not yet started
- **In Progress**: Actively being worked on
- **Blocked**: Waiting on dependency or decision
- **Completed**: Done and merged to main

### Adding New Items
1. Add to appropriate version milestone
2. Include location (file:line if applicable)
3. Set initial priority (High/Medium/Low)
4. Move to Completed section when merged

### For AI Assistants
When working on tasks from this roadmap:
1. Follow [Git Strategy](/.claude/instructions-for-agents/requirements/git-strategy.md)
2. Run [Local CI/CD](/.claude/instructions-for-agents/requirements/local-cicd-operations.md) before pushing
3. Observe [Script Proliferation](/.claude/instructions-for-agents/principles/script-proliferation.md) principle

---

## References

- [README.md](README.md) - Project overview
- [CLAUDE.md](CLAUDE.md) - AI assistant instructions
- [System Architecture](/.claude/instructions-for-agents/architecture/system-architecture.md)
- [First-Time Setup](/.claude/instructions-for-agents/guides/first-time-setup.md)
