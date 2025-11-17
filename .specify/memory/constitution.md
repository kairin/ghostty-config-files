# Ghostty Configuration Files Constitution

<!--
SYNC IMPACT REPORT:
Version Change: Template → 1.0.0
Constitution Type: Initial ratification (TUI redesign + existing principles consolidation)
Date: 2025-11-18

Modified Principles:
- NEW: All 10 core principles established (TUI Framework through Performance Standards)
- NEW: Technology Stack Mandates section
- NEW: Development Workflow section
- CONSOLIDATED: Existing AGENTS.md non-negotiable requirements integrated

Templates Status:
- ⚠ .specify/templates/plan-template.md: Pending review for TUI principle alignment
- ⚠ .specify/templates/spec-template.md: Pending review for verification requirements
- ⚠ .specify/templates/tasks-template.md: Pending review for lib/ architecture categorization

Follow-up TODOs:
- Validate template alignment after constitution ratification
- Update AGENTS.md to reference this constitution
- Propagate TUI principles to all spec-kit templates
-->

## Core Principles

### I. TUI Framework Standard (NON-NEGOTIABLE)

**gum (Charm Bracelet)** is the exclusive TUI framework for all installation and interactive scripts.

**Requirements**:
- All installation UI MUST use gum for spinners, progress bars, prompts, and styling
- No alternative TUI frameworks (whiptail, dialog, rich-cli, etc.) permitted
- gum MUST be installed via system package manager (apt/snap)
- Fallback to plain text output if gum unavailable (graceful degradation)

**Rationale**: gum provides fast (<10ms startup), reliable, cross-platform TUI with zero dependencies. Standardization prevents broken UI across different terminals and SSH sessions.

### II. Adaptive Box Drawing (NON-NEGOTIABLE)

All box drawing MUST use adaptive UTF-8/ASCII detection with automatic fallback.

**Requirements**:
- UTF-8 double-line boxes (╔═╗ ║ ╚═╝) for modern terminals (Ghostty, xterm, etc.)
- ASCII boxes (+=-|) for SSH connections and legacy terminals
- Automatic terminal capability detection via TERM environment variable
- Manual override via `BOX_DRAWING=ascii` or `BOX_DRAWING=utf8` environment variable
- NO hard-coded box characters without fallback logic

**Rationale**: Solves broken box character problem permanently across all terminal types while maintaining professional appearance where supported.

### III. Real Verification Tests (NON-NEGOTIABLE)

All installation verification MUST use real system state checks. Hard-coded success messages are PROHIBITED.

**Requirements**:
- Every installation task MUST have corresponding `verify_<component>()` function
- Verification functions MUST check actual system state (command existence, version numbers, file contents)
- Verification MUST return proper exit codes (0=success, 1=failure)
- NO echo "✓ Success" without actual verification
- Multi-layer verification: unit tests (per-component), integration tests (cross-component), health checks (pre/post)

**Rationale**: Prevents false positives where installation appears successful but components are missing or misconfigured. Enables idempotency and resume capability.

### IV. Docker-Like Collapsible Output (NON-NEGOTIABLE)

Installation output MUST use progressive summarization (Docker-like UX).

**Requirements**:
- Completed tasks collapse to single-line summaries: `✓ Task name (duration)`
- Active task shows full output with animated spinner
- Queued tasks show pending status with ⏸ indicator
- Errors auto-expand with recovery suggestions
- Verbose mode toggle (press 'v' or --verbose flag) for full output
- Overall progress percentage and time estimates displayed

**Rationale**: Reduces overwhelming output while maintaining full transparency. Professional UX familiar to developers from Docker CLI.

### V. Modular lib/ Architecture (NON-NEGOTIABLE)

All installation code MUST follow modular library structure, NOT monolithic scripts.

**Required Directory Structure**:
```
lib/
├── core/
│   ├── logging.sh          # Structured logging (JSON + human-readable)
│   ├── state.sh            # State management (resume capability)
│   ├── errors.sh           # Error handling + recovery suggestions
│   └── utils.sh            # Shared utilities
├── ui/
│   ├── tui.sh              # gum integration
│   ├── boxes.sh            # Adaptive box drawing
│   ├── collapsible.sh      # Progressive summarization
│   └── progress.sh         # Progress bars + spinners
├── tasks/
│   ├── ghostty.sh          # Ghostty installation
│   ├── zsh.sh              # ZSH configuration
│   ├── python_uv.sh        # Python + uv setup
│   ├── nodejs_fnm.sh       # Node.js + fnm setup
│   └── ai_tools.sh         # Claude, Gemini, Copilot CLI
└── verification/
    ├── unit_tests.sh       # Per-component verification
    ├── integration_tests.sh # Cross-component validation
    └── health_checks.sh    # Pre/post installation checks
```

**Rationale**: Modularity enables independent testing, maintainability, and reusability. Each component has single responsibility and clear interface.

### VI. Package Manager Exclusivity (NON-NEGOTIABLE)

**Python**: `uv` exclusively (10-100x faster than pip)
**Node.js**: `fnm` exclusively (<50ms startup, constitutional requirement)

**Requirements**:
- ALL Python package operations MUST use `uv pip install`, `uv run`, `uv venv`
- NO usage of `pip`, `pip3`, `python -m pip`, `poetry`, `pipenv`
- ALL Node.js version management MUST use `fnm install`, `fnm use`, `fnm default`
- NO usage of `nvm`, `n`, `asdf`, manual Node.js installation
- Package managers MUST be verified after installation with real version checks

**Rationale**: uv and fnm provide massive performance improvements (10-100x and 40x respectively). Standardization prevents conflicts and ensures constitutional compliance.

### VII. Structured Logging (NON-NEGOTIABLE)

All installation processes MUST implement dual-format logging.

**Requirements**:
- Human-readable console output (color-coded, formatted)
- Structured JSON logs for parsing/automation (`/tmp/installation-logs/*.json`)
- Log rotation and retention (keep last 10 installations)
- Performance metrics captured (task timing, system resources)
- System state snapshots (before/after installation)

**Rationale**: Dual logging enables both user-friendly output and machine-parseable analytics for debugging and automation.

### VIII. Error Handling & Recovery (NON-NEGOTIABLE)

All errors MUST provide clear recovery suggestions, not just failure messages.

**Requirements**:
- Error messages MUST include: what failed, why it likely failed, how to fix it
- Errors MUST auto-expand in collapsible output
- Continue-or-abort option for non-critical errors
- Rollback capability for failed tasks where applicable
- Error aggregation at end of installation (summary of all failures)

**Rationale**: Users should never be stuck with cryptic errors. Clear recovery paths reduce support burden and improve success rates.

### IX. Idempotency (NON-NEGOTIABLE)

All installation tasks MUST be safe to re-run without side effects.

**Requirements**:
- Check existing state before installation (skip if already installed)
- Preserve user customizations during updates
- Backup critical files before modification
- Restore capability for failed modifications
- Resume capability for interrupted installations (state persistence)

**Rationale**: Users should confidently re-run installations for updates or recovery without fear of corruption or data loss.

### X. Performance Standards (NON-NEGOTIABLE)

Installation MUST meet performance targets.

**Requirements**:
- Total installation time: <10 minutes on fresh Ubuntu system
- fnm startup time: <50ms (constitutional requirement)
- gum startup time: <10ms (verified during installation)
- Parallel task execution where dependencies allow
- Progress feedback MUST update at least every 5 seconds

**Rationale**: Fast installation improves user experience. Performance targets ensure system remains responsive and efficient.

## Technology Stack Mandates

### Terminal Environment (NON-NEGOTIABLE)

**Ghostty Terminal**:
- MUST install latest from source (Zig 0.14.0+)
- MUST enable Linux CGroup single-instance (`linux-cgroup = single-instance`)
- MUST configure enhanced shell integration (auto-detection)
- MUST set unlimited scrollback (999999999 lines) with CGroup protection
- MUST configure auto theme switching (light/dark mode support)
- MUST enable clipboard paste protection

**ZSH Configuration**:
- MUST install Oh My ZSH framework
- MUST configure productivity plugins
- MUST preserve user customizations during updates

**Context Menu Integration**:
- MUST configure Nautilus "Open in Ghostty" context menu
- MUST work immediately after installation

### AI Tools Integration (NON-NEGOTIABLE)

**Claude Code**: Latest via npm (@anthropic-ai/claude-code)
**Gemini CLI**: Latest via npm (@google/gemini-cli)
**GitHub Copilot CLI**: Latest via npm (@github/copilot)

All AI tools MUST be installed via npm using fnm-managed Node.js.

### MCP Server Integration (NON-NEGOTIABLE)

**Context7 MCP**: MUST be operational for up-to-date documentation queries
**GitHub MCP**: MUST be operational for repository operations

MCP servers MUST be verified with health check scripts before constitutional compliance declared.

### Critical File Preservation (NON-NEGOTIABLE)

**docs/.nojekyll**: MUST NEVER be deleted (CRITICAL for GitHub Pages asset loading)
**.runners-local/**: MUST remain as current CI/CD infrastructure directory
**website/package.json**: MUST contain DaisyUI (NOT shadcn/ui), Node.js >=25.0.0

### Directory Standards (NON-NEGOTIABLE)

**XDG Compliance**: ALL user configuration MUST follow XDG Base Directory Specification
- dircolors: `~/.config/dircolors` (NOT `~/.dircolors`)
- Application configs: `~/.config/<app>/` (NOT `~/.<app>/`)

**Current Infrastructure Naming**:
- `.runners-local/` is the CURRENT local CI/CD directory (NOT `local-infra/`)
- All references to `local-infra/` are OBSOLETE and MUST be corrected

## Development Workflow

### Branch Management (NON-NEGOTIABLE)

**Branch Preservation**: NEVER delete branches without explicit user permission. ALL branches contain valuable configuration history.

**Branch Naming Schema** (MANDATORY):
```
YYYYMMDD-HHMMSS-type-short-description

Examples:
- 20251118-143000-feat-tui-redesign
- 20251118-143515-fix-box-drawing
- 20251118-144030-docs-constitution
```

**Constitutional Branch Workflow**:
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-type-description"

git checkout -b "$BRANCH_NAME"
git add .
git commit -m "Descriptive message

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin "$BRANCH_NAME"
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main

# DO NOT: git branch -d "$BRANCH_NAME"
# Branches are preserved for historical reference
```

### Local CI/CD Requirements (NON-NEGOTIABLE)

**Pre-Deployment Verification**: EVERY configuration change MUST complete local CI/CD pipeline FIRST before GitHub deployment.

**Required Pipeline Execution**:
```bash
# Run complete local workflow (MANDATORY)
./.runners-local/workflows/gh-workflow-local.sh all

# Individual validation stages available:
./.runners-local/workflows/gh-workflow-local.sh validate  # Config validation
./.runners-local/workflows/gh-workflow-local.sh test      # Performance testing
./.runners-local/workflows/gh-workflow-local.sh build     # Build simulation
./.runners-local/workflows/gh-workflow-local.sh deploy    # Deployment simulation
```

**Zero-Cost Requirement**: NO GitHub Actions minutes may be consumed for routine operations. All CI/CD MUST run locally first.

### GitHub Pages Infrastructure (NON-NEGOTIABLE)

**`.nojekyll` Protection**: The `docs/.nojekyll` file is ABSOLUTELY CRITICAL.

**Requirements**:
- MUST exist in docs/ directory (empty file)
- MUST be verified before and after every deployment
- MUST be restored immediately if missing: `touch docs/.nojekyll`
- WITHOUT this file, ALL CSS/JS assets return 404 errors on GitHub Pages

**Purpose**: Disables Jekyll processing to allow `_astro/` directory assets to load correctly.

### Logging & Debugging (NON-NEGOTIABLE)

**Installation Logs**: `/tmp/ghostty-start-logs/`
- `start-TIMESTAMP.log` - Human-readable main log
- `start-TIMESTAMP.log.json` - Structured JSON for parsing
- `errors.log` - Critical issues only
- `performance.json` - Performance metrics
- `system_state_TIMESTAMP.json` - Complete system state snapshots

**CI/CD Logs**: `./.runners-local/logs/`
- `workflow-TIMESTAMP.log` - Local workflow execution
- `gh-pages-TIMESTAMP.log` - GitHub Pages simulation
- `performance-TIMESTAMP.json` - CI performance metrics
- `test-results-TIMESTAMP.json` - Test execution results

### Conversation Logging (MANDATORY)

ALL AI assistant conversations working on this repository MUST save complete conversation logs.

**Requirements**:
- Complete logs from start to finish (exclude API keys/sensitive data)
- Storage: `documentations/development/conversation_logs/`
- Naming: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- Include system state captures for debugging
- Include CI/CD execution logs when applicable

## Governance

### Amendment Procedure

This constitution supersedes all other development practices and documentation except where explicitly deferred.

**Amendment Requirements**:
1. Amendments MUST be documented with rationale
2. Version MUST be bumped according to semantic versioning:
   - MAJOR: Backward incompatible principle removals/redefinitions
   - MINOR: New principles added or material expansions
   - PATCH: Clarifications, wording improvements, non-semantic changes
3. Sync Impact Report MUST be generated (prepended as HTML comment)
4. Template propagation MUST be completed before merge
5. Migration plan MUST be provided for breaking changes

### Compliance Verification

**All code reviews, PRs, and spec-kit workflows MUST verify constitutional compliance**:
- TUI framework = gum (not alternatives)
- Package managers = uv (Python), fnm (Node.js) only
- Directory naming = .runners-local/ (not local-infra/)
- Component library = DaisyUI (not shadcn/ui)
- Node.js version = latest (v25.2.0+, not LTS/18+)
- Critical files preserved (docs/.nojekyll, etc.)
- Verification tests are real (not hard-coded)
- Box drawing is adaptive (UTF-8 with ASCII fallback)

**Violations MUST be rejected** with clear explanation and constitutional reference.

### Complexity Justification

Any deviation from constitutional simplicity MUST be justified with:
- Performance data showing benefit
- Security analysis if applicable
- Maintenance impact assessment
- Alternative approaches considered and rejected

### Runtime Guidance

For development workflow guidance beyond constitutional principles, refer to:
- `AGENTS.md` - LLM assistant instructions (v2.0-2025-LocalCI)
- `.claude/commands/` - Spec-kit slash commands
- `docs-setup/` - MCP integration guides
- `SPEC-KIT-TUI-INTEGRATION.md` - TUI redesign workflow integration

---

**Version**: 1.0.0 | **Ratified**: 2025-11-18 | **Last Amended**: 2025-11-18
