# Implementation Plan: Repository Structure Refactoring

**Branch**: `001-repo-structure-refactor` | **Date**: 2025-10-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-repo-structure-refactor/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature refactors the Ghostty Configuration Files repository structure to improve maintainability through three key improvements: (1) consolidating all management operations into a single `manage.sh` entry point that orchestrates modular scripts, (2) separating documentation source files (docs-source/) from generated build artifacts (docs-dist/), and (3) breaking down the monolithic start.sh script into 10+ fine-grained, independently testable modules. The migration follows an incremental per-component approach to ensure safety and allow partial completion states without breaking existing functionality.

## Technical Context

**Language/Version**: Bash 5.x+ (Ubuntu 25.04 default shell), Node.js LTS (for Astro.build documentation site)
**Primary Dependencies**:
- Ghostty terminal emulator (built from source with Zig 0.14.0)
- Astro.build >=4.0 (static site generation for documentation)
- ZSH with Oh My ZSH (shell environment)
- GitHub CLI (gh) for repository operations
- Standard Unix utilities (git, find, grep, sed, awk)

**Storage**: File-based configuration and documentation (no database)
**Testing**: NEEDS CLARIFICATION - Current testing approach for bash scripts and validation strategy
**Target Platform**: Ubuntu 25.04+ (Linux x86_64) with bash-compatible shells
**Project Type**: Configuration management / Infrastructure as Code (script-based automation)
**Performance Goals**:
- manage.sh command execution <2 seconds for help display
- Individual module testing <10 seconds per module
- Documentation build time maintained or improved vs current baseline
- Script startup overhead <500ms

**Constraints**:
- Must preserve backward compatibility with existing start.sh during migration
- Must maintain zero GitHub Actions consumption (local CI/CD only)
- Must preserve all existing directory structures (spec-kit/, local-infra/, .specify/)
- Module isolation required - no circular dependencies allowed
- Maximum 4-5 top-level directories, maximum 2 levels of nesting

**Scale/Scope**:
- ~10-15 modular script files to replace monolithic start.sh
- 4-5 top-level directories in new structure
- Documentation reorganization affecting 5-10 major doc sections
- Incremental migration over multiple development sessions

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Critical Requirements from CLAUDE.md

| Requirement | Compliance Status | Notes |
|------------|------------------|-------|
| **Branch Preservation** | ✅ PASS | Current branch `001-repo-structure-refactor` follows naming convention. No branch deletion planned. |
| **Local CI/CD First** | ✅ PASS | All changes will be validated with `./local-infra/runners/gh-workflow-local.sh` before GitHub operations. |
| **Zero GitHub Actions Consumption** | ✅ PASS | No GitHub Actions triggers planned. All CI/CD runs locally. |
| **Documentation Structure** | ⚠️ REQUIRES ATTENTION | Plan changes `docs/` → `docs-dist/` + new `docs-source/`. Must preserve `.nojekyll` file. See Complexity Tracking. |
| **Preserve Existing Structures** | ✅ PASS | spec-kit/, local-infra/, .specify/ remain unchanged per FR-015. |
| **Configuration Backup** | ✅ PASS | Incremental migration with automatic backups before each change. |
| **Logging Requirements** | ✅ PASS | Conversation log will be saved per LLM Conversation Logging requirements. |

### Gates Evaluation

**GATE 1 - Branch Strategy**: ✅ PASS
- Branch name follows `###-type-description` format
- No branch deletion in scope
- Merge to main without deletion planned

**GATE 2 - GitHub Pages Infrastructure**: ⚠️ REQUIRES DESIGN ATTENTION
- **CRITICAL**: Must preserve `docs/.nojekyll` during restructure
- Must handle docs/ → docs-dist/ migration carefully
- See Complexity Tracking for justification

**GATE 3 - Local CI/CD**: ✅ PASS
- All script changes will be validated locally first
- No GitHub Actions consumption
- Performance monitoring in place

**GATE 4 - Backward Compatibility**: ✅ PASS
- start.sh becomes wrapper to manage.sh (FR-004)
- Incremental migration allows partial completion (FR-013, FR-014)
- User customizations preserved

**OVERALL GATE STATUS**: ⚠️ CONDITIONAL PASS (Initial Assessment)
- Proceed to Phase 0 Research
- **Must resolve** `.nojekyll` preservation strategy before Phase 1
- **Must define** testing approach for bash scripts (marked NEEDS CLARIFICATION)

---

## Constitution Check - Post-Design Re-Evaluation

*Updated after Phase 1 design completion*

### Resolution of Initial Concerns

| Initial Concern | Resolution | Status |
|----------------|------------|--------|
| **.nojekyll preservation** | Multi-layered defense approach designed: Astro public/ directory (primary) + Vite plugin (secondary) + post-build validation (tertiary) + git hook (quaternary). See research.md for complete strategy. | ✅ RESOLVED |
| **Bash testing approach** | Hybrid strategy defined: ShellCheck + Custom Bash Test Functions + Pytest integration. Per-module testing <10s validated. See research.md and contracts/bash-module-interface.md. | ✅ RESOLVED |

### Updated Gates Evaluation

**GATE 1 - Branch Strategy**: ✅ PASS (Unchanged)
- Branch name follows `###-type-description` format
- No branch deletion in scope
- Merge to main without deletion planned

**GATE 2 - GitHub Pages Infrastructure**: ✅ PASS (RESOLVED)
- **RESOLVED**: Multi-layered .nojekyll preservation strategy designed
- Primary: Astro `public/` directory (automatic copy to build output)
- Secondary: Vite plugin automation (already implemented in astro.config.mjs)
- Tertiary: Post-build validation (astro-deploy-enhanced.sh)
- Quaternary: Pre-commit git hook (to be implemented)
- Migration path includes zero-downtime parallel deployment
- Rollback capability verified

**GATE 3 - Local CI/CD**: ✅ PASS (Unchanged)
- All script changes will be validated locally first
- No GitHub Actions consumption
- Performance monitoring in place
- Testing strategy integrates with existing test-runner-local.sh

**GATE 4 - Backward Compatibility**: ✅ PASS (Unchanged)
- start.sh becomes wrapper to manage.sh (FR-004)
- Incremental migration allows partial completion (FR-013, FR-014)
- User customizations preserved

**GATE 5 - Data Model Compliance**: ✅ PASS (New - Post-Design)
- All entities defined with validation rules
- Directory nesting limit (2 levels) enforced in Directory Structure entity
- Module contract specifies single-responsibility principle
- Testing requirements (<10s per module) encoded in Test Suite entity
- No circular dependencies (validated by Bash Module entity relationships)

**GATE 6 - Contract Compliance**: ✅ PASS (New - Post-Design)
- manage.sh CLI contract defines all commands, options, exit codes
- Bash module interface contract specifies function signatures, documentation requirements
- Error handling patterns standardized across all modules
- Output format (stdout/stderr) clearly defined
- Versioning strategy (semantic versioning) specified

**OVERALL GATE STATUS POST-DESIGN**: ✅ PASS
- All initial concerns resolved through research and design
- Multi-layered protections for critical requirements (.nojekyll)
- Comprehensive contracts ensure implementation consistency
- Testing strategy validated for performance targets
- Constitutional compliance maintained throughout design

### Design Quality Assessment

**Strengths**:
1. **Defense in Depth**: Critical .nojekyll requirement has 4 independent protection layers
2. **Testability**: Module contract enforces sourceable design for unit testing
3. **Performance**: Testing strategy validated to meet <10s per-module requirement
4. **Incremental Safety**: Design supports partial migration without breaking changes
5. **Contract-Driven**: Clear contracts for CLI and module interfaces prevent drift

**Risks Mitigated**:
1. **Complexity Creep**: Flat directory structure and single-responsibility modules prevent
2. **Circular Dependencies**: Automated validation tool specified in contracts
3. **GitHub Pages Breakage**: Four-layer .nojekyll protection makes accidental removal nearly impossible
4. **Performance Regression**: Explicit timing requirements in contracts and entity definitions
5. **Integration Failures**: Contract tests (pytest) ensure manage.sh compliance

**Remaining Risks** (Low Severity):
1. **Learning Curve**: Developers must learn bash module contract (mitigated by template and examples)
2. **Test Maintenance**: 10-15 unit test files to maintain (mitigated by test template)
3. **Documentation Debt**: AI guidelines split across multiple files may fragment context (mitigated by Astro site navigation)

**Risk Assessment**: **LOW** - Design is sound, well-researched, and protected by multiple validation layers.

### Recommendations for Implementation

1. **Start with Template**: Create module template and validation script first (reduces repetition)
2. **Test Framework First**: Implement test helper functions before first module (enables TDD)
3. **Simple Module First**: Begin with `validate_config.sh` (no dependencies, easy to test)
4. **Parallel Development**: After first 3 modules, remaining modules can be developed in parallel
5. **Documentation Migration**: Handle last (after all modules working) to avoid interrupting development flow

**FINAL GATE STATUS**: ✅ APPROVED FOR TASK GENERATION
- Ready to proceed with `/speckit.tasks` command
- All technical unknowns resolved
- Design meets constitutional requirements
- Contracts provide clear implementation guidance

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Current Structure (to be refactored)
/home/kkk/Apps/ghostty-config-files/
├── start.sh                    # REFACTOR: Becomes wrapper to manage.sh
├── CLAUDE.md                   # PRESERVE: Project constitution
├── README.md                   # UPDATE: Reference new manage.sh
├── configs/                    # PRESERVE: No changes
├── scripts/                    # REFACTOR: Add modular scripts
│   ├── check_updates.sh       # PRESERVE: Keep as-is
│   ├── install_*.sh           # PRESERVE: Keep existing
│   └── [NEW MODULES]          # ADD: 10+ new modular scripts
├── docs/                       # MIGRATE: → docs-dist/ (build output)
├── local-infra/                # PRESERVE: No changes
├── spec-kit/                   # PRESERVE: No changes
└── .specify/                   # PRESERVE: No changes

# Target Structure (after migration)
/home/kkk/Apps/ghostty-config-files/
├── manage.sh                   # NEW: Unified management interface
├── start.sh                    # MODIFIED: Wrapper calling manage.sh install
├── CLAUDE.md                   # UNCHANGED
├── README.md                   # UPDATED: Document manage.sh commands
├── configs/                    # UNCHANGED
│   └── ghostty/               # UNCHANGED
├── scripts/                    # EXPANDED: Modular scripts
│   ├── install_node.sh        # NEW: Node.js installation module
│   ├── install_zig.sh         # NEW: Zig installation module
│   ├── build_ghostty.sh       # NEW: Ghostty build module
│   ├── setup_zsh.sh           # NEW: ZSH configuration module
│   ├── configure_theme.sh     # NEW: Theme configuration module
│   ├── install_context_menu.sh # NEW: Context menu integration
│   ├── validate_config.sh     # NEW: Configuration validation
│   ├── performance_check.sh   # NEW: Performance monitoring
│   ├── dependency_check.sh    # NEW: Dependency validation
│   ├── backup_config.sh       # NEW: Configuration backup
│   └── [existing scripts]     # PRESERVED
├── docs-source/                # NEW: Documentation source files
│   ├── user-guide/            # NEW: User documentation
│   │   ├── installation.md
│   │   ├── configuration.md
│   │   └── usage.md
│   ├── ai-guidelines/         # NEW: Modularized from AGENTS.md
│   │   ├── core-principles.md
│   │   ├── git-strategy.md
│   │   ├── ci-cd-requirements.md
│   │   └── development-commands.md
│   └── developer/             # NEW: Developer documentation
│       ├── architecture.md
│       ├── contributing.md
│       └── testing.md
├── docs-dist/                  # NEW: Astro build output (gitignored)
│   └── .nojekyll              # CRITICAL: Must exist for GitHub Pages
├── local-infra/                # UNCHANGED
├── spec-kit/                   # UNCHANGED
└── .specify/                   # UNCHANGED
```

**Structure Decision**:
This is a **configuration management project** that uses scripts for automation and Astro for documentation. The structure follows a hybrid approach:
1. Top-level remains flat with key entry points (manage.sh, start.sh)
2. scripts/ directory expands with fine-grained modules (flat structure, no scripts/modules/ subdirectory)
3. Documentation separates source (docs-source/) from generated content (docs-dist/)
4. Existing spec-kit/, local-infra/, .specify/ structures preserved unchanged per constitutional requirements

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Documentation Structure Change (docs/ → docs-dist/) | Current docs/ mixes Astro source with build output, causing confusion about which files to edit. GitHub Pages requires build output in specific location. | Keeping current docs/ structure would perpetuate confusion between source and generated files. Using separate docs-source/ makes intent explicit and prevents accidental editing of generated content. |
| `.nojekyll` Preservation Required | GitHub Pages requires `.nojekyll` in build output directory to serve Astro's `_astro/` assets correctly. Without it, all CSS/JS returns 404. | This is non-negotiable per constitutional requirement. No simpler alternative exists - it's a GitHub Pages technical requirement. Must be preserved during migration. |
| 10+ Script Modules vs Fewer Large Modules | Fine-grained modules (install_node.sh, install_zig.sh, etc.) enable <10s isolated testing and precise debugging. Larger modules would take longer to test and harder to maintain. | Creating 3-5 larger modules would improve module count but violate FR-007 requirement for "highly specific sub-tasks" and SC-007 requirement for "<10 second" independent testing. Fine granularity is the feature requirement. |

**Justification Summary**:
All complexity additions are driven by explicit functional requirements (FR-005 through FR-009) and are necessary to achieve the feature's core goals of maintainability and clarity. The documentation restructure addresses user confusion (User Story 2), and fine-grained modules enable rapid testing (User Story 3). Constitutional compliance is maintained through incremental migration and preservation of existing structures.
