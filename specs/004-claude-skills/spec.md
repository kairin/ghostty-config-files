# Feature Specification: Claude Code Workflow Skills

**Feature Branch**: `004-claude-skills`
**Created**: 2026-01-18
**Status**: Draft
**Input**: Wave 3 - Claude Code Skills: Create 4 user-invocable slash commands that wrap existing local CI/CD infrastructure for streamlined developer experience.

## Clarifications

### Session 2026-01-18

- Q: Should skills be project-level, user-level, or both for portability? → A: Both - templates in project (`.claude/commands/`), install script copies to user-level (`~/.claude/commands/`)
- Q: How to handle existing `full-git-workflow` skill that overlaps with `/git-sync`? → A: Replace - new `/git-sync` supersedes `full-git-workflow`; delete the old one
- Q: How should path resolution work for cross-project portability? → A: Project-aware - skills detect current project; Astro/health features only in ghostty-config-files, git features work everywhere

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Health Check Diagnostics (Priority: P1)

As a developer, I want to run `/health-check` to quickly verify my development environment is properly configured before starting work.

**Why this priority**: Health diagnostics are foundational - all other workflows depend on a healthy environment. Running this first prevents downstream failures and saves debugging time.

**Independent Test**: Can be fully tested by running `/health-check` in Claude Code and verifying all system components report status. Delivers immediate value by showing environment readiness.

**Acceptance Scenarios**:

1. **Given** a properly configured environment, **When** I run `/health-check`, **Then** I see a structured summary with all items showing PASS status
2. **Given** a missing MCP server connection, **When** I run `/health-check`, **Then** I see a FAIL status for MCP connectivity with remediation suggestions
3. **Given** an outdated Node.js version, **When** I run `/health-check`, **Then** I see a WARNING status with the current and recommended versions
4. **Given** the health check completes successfully, **When** I view the output, **Then** I see a handoff button suggesting `/deploy-site` as the next step

---

### User Story 2 - Site Deployment (Priority: P2)

As a developer, I want to run `/deploy-site` to build and deploy the Astro website to GitHub Pages with a single command.

**Why this priority**: Deployment is the primary delivery mechanism for the project website. Streamlining this workflow reduces manual steps and ensures consistent, validated deployments.

**Independent Test**: Can be fully tested by running `/deploy-site` and verifying the site is accessible at the GitHub Pages URL. Delivers value by automating a multi-step process.

**Acceptance Scenarios**:

1. **Given** a clean working directory, **When** I run `/deploy-site`, **Then** dependencies are installed, the site is built, validated, and deployment completes
2. **Given** the build succeeds, **When** I view the output, **Then** I see build metrics (file count, bundle size, build duration) and the deployment URL
3. **Given** the `.nojekyll` file is missing, **When** the build runs, **Then** it is automatically created to ensure CSS/JS assets are served correctly
4. **Given** the bundle size exceeds 100KB, **When** the build completes, **Then** I see a constitutional compliance WARNING
5. **Given** successful deployment, **When** I view the output, **Then** I see a handoff button suggesting `/git-sync` as the next step

---

### User Story 3 - Git Synchronization (Priority: P3)

As a developer, I want to run `/git-sync` to synchronize my local repository with the remote, handling fetch, pull, and push operations safely.

**Why this priority**: Git synchronization is essential for team collaboration but less critical than health checks or deployment. It ensures code is properly shared without manual git commands.

**Independent Test**: Can be fully tested by running `/git-sync` with pending local commits and verifying they are pushed to remote. Delivers value by automating routine git operations.

**Acceptance Scenarios**:

1. **Given** a branch with unpushed commits, **When** I run `/git-sync`, **Then** changes are fetched, pulled with rebase, and pushed to remote
2. **Given** a branch with a non-constitutional name, **When** I run `/git-sync`, **Then** I see a WARNING about branch naming format (YYYYMMDD-HHMMSS-type-description)
3. **Given** a diverged branch (local and remote have different commits), **When** I run `/git-sync`, **Then** I see the divergence status and am prompted for resolution approach
4. **Given** successful synchronization, **When** I view the output, **Then** I see sync status (up-to-date/behind/ahead/diverged) with commit counts
5. **Given** an attempt to delete a branch, **When** the operation is detected, **Then** it is BLOCKED with a constitutional violation warning (branch preservation)

---

### User Story 4 - Full Development Workflow (Priority: P4)

As a developer, I want to run `/full-workflow` to execute a complete development cycle including health check, deployment, and git sync with comprehensive validation.

**Why this priority**: This is an orchestration skill that combines other skills. While convenient, each component skill must work independently first, hence lower priority.

**Independent Test**: Can be fully tested by running `/full-workflow` and verifying all stages complete successfully. Delivers value by automating the entire development cycle.

**Acceptance Scenarios**:

1. **Given** a healthy environment, **When** I run `/full-workflow`, **Then** health check, deploy, and git sync execute in sequence with a comprehensive report
2. **Given** uncommitted changes exist, **When** I run `/full-workflow`, **Then** I am prompted to commit or stash before proceeding
3. **Given** the local CI/CD validation fails, **When** I run `/full-workflow`, **Then** the workflow STOPS before any GitHub operations (constitutional requirement)
4. **Given** any stage fails, **When** I view the output, **Then** I see which stage failed, the error details, and suggested remediation
5. **Given** all stages complete, **When** I view the report, **Then** I see a structured summary with pass/fail status, metrics, and timing for each stage

---

### Edge Cases

- What happens when `.runners-local/workflows/health-check.sh` script doesn't exist? → Skill reports FAIL with installation instructions
- What happens when git credentials are expired? → `/git-sync` detects auth failure and prompts for credential refresh
- What happens when Astro build has TypeScript errors? → `/deploy-site` shows build errors with file locations
- What happens when network is unavailable? → Skills that require network report connection failure with offline fallback where possible
- What happens when running on a non-main branch? → Skills work normally; `/git-sync` syncs current branch with its remote tracking branch

## Requirements *(mandatory)*

### Functional Requirements

**Skill Definition Requirements:**

- **FR-001**: Each skill MUST be defined as a markdown file in `.claude/commands/` (project-level template) with YAML frontmatter
- **FR-002**: Each skill MUST include a `description` field in the frontmatter for display in skill listings
- **FR-003**: Each skill MUST include `handoffs` in frontmatter to suggest next workflow steps
- **FR-004**: Skills MUST be hot-reload compatible (Claude Code v2.1.0+)

**Portability Requirements:**

- **FR-005**: An install script MUST copy skills from `.claude/commands/` to `~/.claude/commands/` for global availability
- **FR-006**: Skills MUST use relative paths or environment detection to work in any project location
- **FR-007**: The install script MUST be idempotent (safe to run multiple times)
- **FR-008**: Skills installed to user-level MUST sync when the project is pulled on other computers (via git + install script)
- **FR-009**: Install script MUST remove deprecated `full-git-workflow.md` from `~/.claude/commands/` when installing `/git-sync`

**Project Detection Requirements:**

- **FR-060**: Skills MUST detect if running in ghostty-config-files project (check for `.runners-local/` or `AGENTS.md`)
- **FR-061**: When in ghostty-config-files: enable full feature set (health-check, deploy-site, git-sync, full-workflow)
- **FR-062**: When in other projects: `/git-sync` works with standard git; `/health-check` shows basic tool versions; `/deploy-site` reports "not available in this project"
- **FR-063**: `/full-workflow` in other projects runs only generic stages (git sync) and skips project-specific stages

**Health Check Skill (/health-check):**

- **FR-010**: In ghostty-config-files: skill MUST execute `.runners-local/workflows/health-check.sh` for full diagnostics
- **FR-010a**: In other projects: skill MUST check basic tools (git, gh, node) and report versions
- **FR-011**: Skill MUST check: core tools (git, gh, node, npm, jq), MCP connectivity, Astro environment
- **FR-012**: Skill MUST output structured summary with PASS/FAIL/WARNING status per component
- **FR-013**: Skill MUST complete within 30 seconds under normal conditions
- **FR-014**: Skill MUST provide handoff to `/deploy-site` when Astro environment is healthy

**Deploy Site Skill (/deploy-site):**

- **FR-020**: Skill MUST execute the Astro build workflow (deps → build → validate → deploy)
- **FR-021**: Skill MUST verify `.nojekyll` file exists in output directory (auto-create if missing)
- **FR-022**: Skill MUST report bundle size and warn if exceeding 100KB constitutional limit
- **FR-023**: Skill MUST output build metrics: file count, bundle size, build duration
- **FR-024**: Skill MUST output deployment URL upon success
- **FR-025**: Skill MUST provide handoff to `/git-sync` after successful deploy

**Git Sync Skill (/git-sync):**

- **FR-030**: Skill MUST fetch remote state for current branch
- **FR-031**: Skill MUST pull with rebase (`--rebase` flag)
- **FR-032**: Skill MUST push local commits with upstream tracking
- **FR-033**: Skill MUST validate branch naming format (YYYYMMDD-HHMMSS-type-description)
- **FR-034**: Skill MUST report sync status: up-to-date, behind, ahead, or diverged
- **FR-035**: Skill MUST NEVER delete branches (constitutional requirement)
- **FR-036**: Skill MUST provide handoff to `/full-workflow` for complete cycle

**Full Workflow Skill (/full-workflow):**

- **FR-040**: Skill MUST orchestrate: health-check → deploy-site → git-sync in sequence
- **FR-041**: Skill MUST run local CI/CD validation before any GitHub operations
- **FR-042**: Skill MUST STOP workflow if local CI/CD fails (constitutional requirement)
- **FR-043**: Skill MUST generate comprehensive report with timing and status per stage
- **FR-044**: Skill MUST prompt for uncommitted changes before proceeding
- **FR-045**: Skill MUST support creating timestamped branch if requested

**Output Requirements:**

- **FR-050**: All skills MUST output structured summaries (not verbose logs by default)
- **FR-051**: All skills MUST show key metrics in summary (duration, counts, status)
- **FR-052**: All skills MUST provide clear error messages with remediation suggestions on failure

### Key Entities

- **Skill**: A Claude Code slash command defined in `.claude/commands/` with YAML frontmatter and markdown instructions
- **Handoff**: A workflow transition defined in skill frontmatter that suggests the next skill to run
- **Health Report**: Structured output showing component status (PASS/FAIL/WARNING) with details
- **Build Metrics**: Measurements from Astro build (file count, bundle size, duration)
- **Sync Status**: Git synchronization state (up-to-date/behind/ahead/diverged)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can run each skill (`/health-check`, `/deploy-site`, `/git-sync`, `/full-workflow`) successfully from Claude Code
- **SC-002**: Health check completes in under 30 seconds and reports accurate environment status
- **SC-003**: Deploy workflow completes successfully with valid GitHub Pages deployment
- **SC-004**: Git sync correctly identifies and reports repository synchronization status
- **SC-005**: Full workflow completes all stages when environment is healthy
- **SC-006**: All skills provide structured summary output with pass/fail status and key metrics
- **SC-007**: Handoff buttons appear after each skill execution, enabling smooth workflow progression
- **SC-008**: Constitutional requirements are enforced (no branch deletion, local CI/CD before GitHub, .nojekyll preservation)
- **SC-009**: Zero GitHub Actions minutes consumed (all validation runs locally)
- **SC-010**: Skills are hot-reload compatible - changes take effect without Claude Code restart

## Assumptions

- Claude Code v2.1.0+ is installed (required for skill hot-reload)
- Existing shell scripts (`.runners-local/workflows/`) are functional and tested
- GitHub CLI (`gh`) is authenticated with appropriate repository permissions
- Node.js and npm are installed for Astro builds
- Git is configured with valid credentials for push operations

## Constraints

- Skills must wrap existing scripts - no new shell scripts may be created (script proliferation prevention)
- All git operations must preserve branches (constitutional requirement)
- Local CI/CD must pass before any GitHub push operations (constitutional requirement)
- `.nojekyll` file must always exist in `docs/` for GitHub Pages (constitutional requirement)

## Dependencies

- `.runners-local/workflows/health-check.sh` - Health diagnostics script
- `.runners-local/workflows/astro-build-local.sh` - Astro build script
- `.runners-local/workflows/astro-complete-workflow.sh` - Complete Astro workflow
- `.runners-local/workflows/gh-cli-integration.sh` - GitHub CLI integration
- `.runners-local/workflows/gh-workflow-local.sh` - Local CI/CD orchestrator
