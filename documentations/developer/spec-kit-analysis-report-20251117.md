# SPEC-KIT ANALYSIS REPORT: Requirement Evolution Issues & Breaking Changes

**Analysis Date**: 2025-11-17
**Repository**: /home/kkk/Apps/ghostty-config-files
**Scope**: Complete spec-kit directory analysis (guides + templates)
**Status**: CRITICAL ISSUES FOUND

---

## EXECUTIVE SUMMARY

The spec-kit guides contain **multiple critical contradictions** between:
1. **OLD SPEC-KIT REQUIREMENTS** (uv + Astro + shadcn/ui + .runners-local/)
2. **CURRENT PROJECT STATE** (Ghostty terminal + .runners-local/ + DaisyUI + manage.sh)
3. **CLAUDE.md PROJECT MANDATES** (Node.js latest, branch preservation, .runners-local infrastructure)

These contradictions create **broken workflows** when users follow spec-kit commands, as they will:
- Create wrong directory structure (`.runners-local/` instead of `.runners-local/`)
- Recommend outdated component libraries (shadcn/ui instead of DaisyUI)
- Miss node version requirements (specifies Node.js 18+ instead of latest)
- Reference non-existent scripts and workflows
- Introduce obsolete implementation patterns

**Risk Level**: HIGH - Users following spec-kit will implement outdated architecture

---

## 1. REQUIREMENT EVOLUTION ISSUES

### ISSUE 1.1: Directory Structure Mismatch (CRITICAL)

**Location**: ALL spec-kit guides reference `.runners-local/`

- `spec-kit/guides/SPEC_KIT_INDEX.md:31, 103, 116`
- `spec-kit/guides/2-spec-kit-specify.md:65-71, 87-99`
- `spec-kit/guides/3-spec-kit-plan.md:14, 99, 177-179`
- `spec-kit/guides/4-spec-kit-tasks.md:14, 54, 93-97, 164-186`
- `spec-kit/guides/5-spec-kit-implement.md:15, 32-36, 56-59, 68, 102`

**Current Requirement** (CLAUDE.md):
```
./.runners-local/                      # CONSOLIDATED LOCAL CI/CD (actual structure)
├── workflows/                         # Workflow execution scripts (committed)
├── self-hosted/                       # Self-hosted runner management
├── tests/                             # Complete test infrastructure
├── logs/                              # Execution logs
├── docs/                              # Infrastructure documentation
└── README.md
```

**What spec-kit Teaches**:
```
./.runners-local/                         # WRONG DIRECTORY NAME
├── .runners-local/workflows/
├── logs/
├── config/
└── tests/
```

**Impact**:
- Users create `.runners-local/` directory when `.runners-local/` already exists
- Duplicate infrastructure scattered across codebase
- Scripts in wrong location won't be found
- CI/CD pipelines fail silently

**Example Contradiction** (4-spec-kit-tasks.md:186):
```bash
./.runners-local/.runners-local/workflows/gh-workflow-local.sh all || exit 1  # WRONG PATH
# Should be:
./.runners-local/workflows/gh-workflow-local.sh all || exit 1  # CORRECT PATH
```

---

### ISSUE 1.2: Component Library Evolution (SIGNIFICANT)

**Location**: 
- `spec-kit/guides/SPEC_KIT_INDEX.md:15, 82, 158`
- `spec-kit/guides/1-spec-kit-constitution.md:18`
- `spec-kit/guides/2-spec-kit-specify.md:40-46`
- `spec-kit/guides/4-spec-kit-tasks.md:69-77`

**Current Requirement** (Spec 005 - Complete Terminal Infrastructure):
```
- **Component Library**: DaisyUI (latest stable) with Tailwind CSS (>=4.0)
- shadcn/ui reserved for future consideration if deeper customization needed
```

**What spec-kit Still Teaches**:
```
- UI Components: shadcn/ui for all interactive components
- Styling: Tailwind CSS with full utility-first approach
- Initialize shadcn/ui: `npx shadcn-ui@latest init`
```

**Spec 005 Evidence** (spec.md:142):
> "System MUST provide UI components through **DaisyUI (latest stable)** with Tailwind CSS (>=4.0, latest stable) and **full accessibility (shadcn/ui reserved for future consideration if deeper customization needed)**"

**Impact**:
- Users install wrong component library
- DaisyUI + shadcn/ui mixture creates conflicts
- Component examples won't work
- Team onboarding follows wrong stack

**Contradiction Example** (4-spec-kit-tasks.md:72):
```bash
npx shadcn-ui@latest add button card input  # OUTDATED - DaisyUI is now standard
```

---

### ISSUE 1.3: Node.js Version Policy Mismatch (MODERATE)

**Location**:
- `spec-kit/guides/3-spec-kit-plan.md:169` - "Node.js 18+: Required for Astro"
- `spec-kit/guides/5-spec-kit-implement.md:26` - "Python 3.12+, Node.js 18+"

**Current Policy** (CLAUDE.md):
```
- **Global Policy**: Always use the latest Node.js version (not LTS)
- **Health Audit Note**: Latest Node.js version is intentional and should NOT be flagged as a warning
```

**What spec-kit Says**:
```
Node.js 18+: Required for Astro and npm packages
(Implies minimum 18, doesn't mention "latest" requirement)
```

**Impact**:
- Users may stick with Node.js 18 LTS instead of upgrading to latest (25.2.0+)
- Misses cutting-edge JavaScript features
- Contradicts global fnm policy stated in CLAUDE.md
- Performance and feature gap from outdated Node.js

---

### ISSUE 1.4: Project Purpose Confusion (CRITICAL)

**Location**: `spec-kit/guides/SPEC_KIT_INDEX.md` and all spec-kit prompts

**Current Project Context** (CLAUDE.md):
```
Ghostty Configuration Files is a comprehensive TERMINAL ENVIRONMENT SETUP
featuring Ghostty terminal emulator with 2025 performance optimizations,
right-click context menu integration, plus integrated AI tools (Claude Code, Gemini CLI)
```

**What spec-kit Presents**:
```
Complete Implementation Guide: uv + Astro + GitHub Pages + Local CI/CD Stack
```

**The Problem**:
Spec-kit guides focus ENTIRELY on building a documentation website with Astro.build. 
They completely omit the Ghostty terminal configuration aspects:

- No Ghostty performance optimization (linux-cgroup, shell integration)
- No Ghostty theming (Catppuccin, light/dark mode)
- No context menu integration
- No Ghostty configuration validation (`ghostty +show-config`)
- No terminal-focused CI/CD pipelines
- No dircolors XDG-compliant setup
- No shell integration features

**Where Spec 005 Defines This**: Complete Terminal Infrastructure
```
User Story 1: Unified Development Environment
- Ghostty terminal emulator with 2025 optimizations
- ZSH + Oh My Zsh with productivity plugins
- Node.js latest via fnm
- Modern Unix tools (bat, exa, ripgrep, fd, zoxide)
- Claude Code integration
- Gemini CLI integration
```

**Impact**:
- Users following spec-kit miss 70% of project value
- Terminal configuration requirements completely undocumented in spec-kit
- Users won't install/configure Ghostty properly
- AI assistant integration missing from guidance

---

## 2. BREAKING CHANGES

### ISSUE 2.1: Script Path Incompatibility (CRITICAL)

**All spec-kit commands reference scripts that won't exist if users follow other guidance**:

```bash
# SPEC-KIT SAYS (wrong paths):
./.runners-local/.runners-local/workflows/gh-workflow-local.sh
./.runners-local/.runners-local/workflows/astro-build-local.sh
./.runners-local/.runners-local/workflows/performance-monitor.sh

# ACTUAL PROJECT HAS (correct paths):
./.runners-local/workflows/gh-workflow-local.sh
./.runners-local/workflows/astro-build-local.sh
./.runners-local/workflows/performance-monitor.sh
```

**Evidence**:
- All 5 spec-kit guide files (1-5) contain >100 references to wrong paths
- `.runners-local/` directory ALREADY EXISTS with correct scripts
- No `.runners-local/` directory in project

**User Experience**:
```bash
User: ./.runners-local/.runners-local/workflows/gh-workflow-local.sh all
Error: No such file or directory
(User is confused - thinks they did something wrong, but actually spec-kit was wrong)
```

---

### ISSUE 2.2: Divergent Implementation Strategy (HIGH)

**Spec-kit teaches PHASE 0 approach**:
```
Phase 0 (BEFORE ALL OTHERS): Local CI/CD Infrastructure Setup
- Create complete .runners-local/ directory structure
- Build and test all runner scripts
- Configure git hooks for automatic execution
```

**Actual Implementation** (per CLAUDE.md):
```
LOCAL CI/CD REQUIREMENTS:
- Use existing ./.runners-local/ infrastructure (already built and tested)
- Integrate with `.runners-local/workflows/gh-workflow-local.sh all`
- No Phase 0 needed - infrastructure ready to use
```

**Impact**:
- Users waste 4-6 hours building duplicate CI/CD infrastructure
- Creates competing systems (`.runners-local/` vs `.runners-local/`)
- Branch workflow examples won't work
- Performance monitoring integrations fail

---

### ISSUE 2.3: Missing Context7 Integration (HIGH)

**Location**: NONE of spec-kit mentions Context7 MCP

**Current Requirement** (CLAUDE.md):
```
### 🚨 CRITICAL: Context7 MCP Integration & Documentation Synchronization
**MANDATORY**: Query Context7 before major configuration changes
**RECOMMENDED**: Add Context7 validation to local CI/CD workflows
**BEST PRACTICE**: Document Context7 queries in conversation logs
```

**What Spec-kit Says**: NOTHING about Context7

**Impact**:
- Users won't integrate documentation synchronization
- Miss up-to-date library documentation
- Spec-kit examples become outdated faster
- No knowledge base synchronization

---

### ISSUE 2.4: Missing GitHub MCP Integration (HIGH)

**Location**: NONE of spec-kit mentions GitHub MCP

**Current Requirement** (CLAUDE.md):
```
### 🚨 CRITICAL: GitHub MCP Integration & Repository Operations
**MANDATORY**: Use GitHub MCP for all repository operations
Branch preservation strategy with timestamped naming
```

**What Spec-kit Says**: Uses manual git commands and basic gh CLI

**Impact**:
- Users won't use proper GitHub MCP functions
- Manual repository operations instead of safe API integration
- No branch preservation enforcement
- Higher risk of accidental branch deletion

---

## 3. SPECIFICATION CONSISTENCY ISSUES

### ISSUE 3.1: Branch Strategy Contradiction (MODERATE)

**Spec-kit Version** (4-spec-kit-tasks.md:183-200):
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-task-X-description"

# 1. MANDATORY: Local CI/CD validation
./.runners-local/.runners-local/workflows/gh-workflow-local.sh all || exit 1
```

**CLAUDE.md Version** (requires .runners-local, not local-infra):
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-type-short-description"

# Correct workflow uses .runners-local
./.runners-local/workflows/gh-workflow-local.sh all || exit 1
```

**Additional Contradiction**:
- Spec-kit shows: `task-X-description` (task-focused naming)
- CLAUDE.md shows: `type-short-description` (type-focused: feat, fix, docs)

---

### ISSUE 3.2: Size/Context Issues (MODERATE)

**Large Monolithic Prompts**:
- `SPEC_KIT_GUIDE.md`: 892 lines (too large for single LLM context window)
- Each constitution/specify/plan prompt exceeds 100+ lines in code blocks

**Problem for LLM Usage**:
- Easy to miss key requirements buried in long prompts
- Copy-paste errors likely with such long blocks
- Context window wasted on verbose formatting
- Templates could be split into smaller, focused modules

**Missing Prompts**:
- No Context7 integration prompt
- No GitHub MCP integration prompt
- No Ghostty-focused configuration prompt
- No terminal-first development workflow prompt

---

### ISSUE 3.3: Test Coverage Gap (HIGH)

**Spec-kit References**:
- Mentions tests should exist in `.runners-local/tests/`
- No guidance on HOW to write tests
- No test templates provided
- Test structure conflicts with `.runners-local/tests/` reality

**Current Reality**:
- `.runners-local/tests/` directory exists with contract/unit/integration structure
- Spec-kit doesn't document this structure
- Users won't know about existing test infrastructure

---

### ISSUE 3.4: Missing .nojekyll Documentation (HIGH)

**CLAUDE.md Critical Requirement**:
```
- **`.nojekyll` File**: ABSOLUTELY CRITICAL for GitHub Pages deployment
- **Location**: `docs/.nojekyll` (empty file, no content needed)
- **Purpose**: Disables Jekyll processing to allow `_astro/` directory assets
- **WARNING**: This file is ESSENTIAL - never remove during cleanup operations
```

**What Spec-kit Says**: NOTHING about .nojekyll file

**Impact**:
- Users deploy to GitHub Pages without .nojekyll
- CSS/JS assets return 404 errors
- Site appears broken despite code being correct
- Critical failure with no debugging guidance

---

## 4. CONTEXT AND SIZE ISSUES

### ISSUE 4.1: Disconnected Guide Sequence (MODERATE)

**Current Index** (SPEC_KIT_INDEX.md):
- Constitution → Specify → Plan → Tasks → Implement

**Problem**:
- No transition guidance between steps
- No "what you should have at this point" verification
- Users don't know if previous step succeeded
- Missing integration checkpoints

**Missing Content**:
- Checklist of expected outputs after each command
- Troubleshooting for common failures
- How to recover if a step partially completes
- What to do if spec-kit requirements conflict with project policy

---

### ISSUE 4.2: Orphaned Documentation (MODERATE)

**Large files with overlapping content**:
- `SPEC_KIT_GUIDE.md` (892 lines) - comprehensive but unwieldy
- `SPEC_KIT_INDEX.md` (162 lines) - navigation guide
- Individual guides 1-5 (177-231 lines each)

**Result**: Multiple sources of truth, easy to get lost

**What's Missing**:
- Quick reference card (1-page)
- FAQ addressing common contradictions
- Troubleshooting guide
- When NOT to use spec-kit guidance

---

### ISSUE 4.3: File Structure Documentation Gaps (HIGH)

**Spec-kit teaches** (2-spec-kit-specify.md:73-113):
```
project-root/
├── .runners-local/        # WRONG: Should be .runners-local
├── scripts/            # Only Python scripts mentioned
├── src/                # Astro source (missing Ghostty config details)
```

**Actual Structure** (from CLAUDE.md):
```
/home/kkk/Apps/ghostty-config-files/
├── configs/            # Ghostty config, themes, dircolors, workspace
├── scripts/            # Installation AND management scripts  
├── documentations/     # User, developer, specifications, archive
├── .runners-local/     # Local CI/CD (not local-infra)
├── website/src/        # Astro documentation source
├── docs/               # GitHub Pages build output
├── specs/              # Feature specifications
```

**Gap**: Spec-kit completely ignores `configs/`, `documentations/`, `specs/` directories

---

## 5. CRITICAL RECOMMENDATIONS

### FIX 1: Create "Spec-Kit Reconciliation Guide" (URGENT)

**File**: `spec-kit/guides/0-spec-kit-reconciliation.md`

**Content**:
```markdown
# Spec-Kit Reconciliation with Current Project State

## KNOWN DIVERGENCES (Updated 2025-11-17)

### Directory Structure
- SPEC-KIT SAYS: .runners-local/
- ACTUAL PROJECT: .runners-local/
- ACTION: Replace all .runners-local/ with .runners-local/

### Component Library
- SPEC-KIT SAYS: shadcn/ui
- ACTUAL PROJECT: DaisyUI (shadcn/ui reserved for future)
- ACTION: Use DaisyUI installation commands

### Node.js Version
- SPEC-KIT SAYS: Node.js 18+
- ACTUAL PROJECT: Node.js latest (v25.2.0+) via fnm
- ACTION: Use `fnm default node` to get latest version

### Project Scope
- SPEC-KIT SAYS: uv + Astro + GitHub Pages stack only
- ACTUAL PROJECT: Includes Ghostty terminal, AI tools, modern Unix tools
- ACTION: See CLAUDE.md for complete project requirements

## When to Use This Guide

Use spec-kit for: Building modern web development stacks with Astro
USE CLAUDE.md for: Terminal configuration and complete project requirements
```

---

### FIX 2: Update All Path References (URGENT)

**Script**: Create automated path replacement

```bash
# Update all local-infra references to .runners-local
find spec-kit/guides -name "*.md" -exec sed -i \
  's|./.runners-local/.runners-local/workflows/|./.runners-local/workflows/|g' {} \;

find spec-kit/guides -name "*.md" -exec sed -i \
  's|./.runners-local/|./.runners-local/|g' {} \;
```

**Files affected**:
- `1-spec-kit-constitution.md` - 0 mentions (constitution phase doesn't reference paths)
- `2-spec-kit-specify.md` - 5 critical path mentions
- `3-spec-kit-plan.md` - 3 critical path mentions  
- `4-spec-kit-tasks.md` - 8 critical path mentions
- `5-spec-kit-implement.md` - 7 critical path mentions
- `SPEC_KIT_INDEX.md` - 3 critical path mentions
- `SPEC_KIT_GUIDE.md` - 40+ path mentions

---

### FIX 3: Add Context7 & GitHub MCP Integration (HIGH)

**Create**: `spec-kit/guides/0-spec-kit-prerequisites.md`

**Content**:
```markdown
# Spec-Kit Prerequisites: Context7 & GitHub MCP

Before running spec-kit commands, configure:

## Context7 MCP Integration
cp .env.example .env  # Add CONTEXT7_API_KEY
./scripts/check_context7_health.sh

## GitHub MCP Integration  
gh auth status  # Verify authentication
./scripts/check_github_mcp_health.sh

## Why These Matter
- Context7 keeps library docs up-to-date during implementation
- GitHub MCP ensures safe branch management and operations
- Both are NON-NEGOTIABLE for constitutional compliance
```

---

### FIX 4: Add Ghostty-Aware Guidance (HIGH)

**Create**: `spec-kit/guides/6-spec-kit-terminal-integration.md`

**Content**:
```markdown
# Spec-Kit Step 6: Terminal Environment Integration

After completing Astro/web stack, integrate with Ghostty terminal environment:

## Validate Ghostty Configuration
ghostty +show-config | grep linux-cgroup

## Add Terminal Performance Baseline
./.runners-local/workflows/performance-monitor.sh --baseline

## Integrate Documentation with Terminal
./manage.sh docs build  # Uses local CI/CD
```

---

### FIX 5: Create Reconciliation Matrix (IMMEDIATE)

**File**: `spec-kit/guides/RECONCILIATION_MATRIX.md`

| Aspect | Spec-Kit Says | Actual Project | Status | Fix |
|--------|---------------|----------------|--------|-----|
| Local CI/CD dir | `.runners-local/` | `.runners-local/` | CRITICAL | Replace all paths |
| Components | shadcn/ui | DaisyUI | CRITICAL | Update tasks |
| Node.js | 18+ | latest | MODERATE | Add fnm guidance |
| Project scope | Web stack only | Terminal + Web | HIGH | Add Ghostty section |
| Scripts location | .runners-local/runners | .runners-local/workflows | CRITICAL | Update 40+ refs |
| Test location | .runners-local/tests | .runners-local/tests | MODERATE | Update structure |
| .nojekyll | Not mentioned | CRITICAL file | HIGH | Add to deploy docs |

---

### FIX 6: Add Validation Checkpoints (MODERATE)

**Create**: `spec-kit/guides/validation-checkpoints.md`

**Content**:
```markdown
# Spec-Kit Validation Checkpoints

After each spec-kit phase, verify actual project state:

## After /constitution
✓ Core values documented
✓ Tech stack constraints clear
  → MUST include: Local CI/CD, Ghostty focus, Latest Node.js

## After /specify
✓ Tech specifications created
  → VERIFY: Uses .runners-local, not local-infra
  → VERIFY: DaisyUI in components, not shadcn/ui
  → VERIFY: Node.js latest in requirements

## After /plan
✓ 7-phase implementation plan created
  → VERIFY: Phase 0 uses existing .runners-local infrastructure
  → CHECK: No "create local-infra from scratch" steps

## After /tasks
✓ Actionable task list generated
  → VERIFY: All script paths reference .runners-local
  → VERIFY: Component setup uses DaisyUI
  → VERIFY: Includes Ghostty integration tasks

## After /implement
✓ Implementation underway
  → VERIFY: Zero GitHub Actions consumed (local CI/CD worked)
  → VERIFY: docs/.nojekyll exists and wasn't removed
  → VERIFY: Branch preservation policy followed
```

---

## 6. PRIORITY FIXES ROADMAP

### IMMEDIATE (This Week)
1. Update all `.runners-local/` to `.runners-local/` paths in spec-kit guides
2. Add reconciliation matrix to spec-kit
3. Add prerequisites guide (Context7, GitHub MCP)
4. Document .nojekyll critical file requirement

### SHORT TERM (This Month)
1. Create full Ghostty-aware spec-kit section
2. Update component library references (shadcn/ui → DaisyUI)
3. Add comprehensive troubleshooting guide
4. Create validation checkpoints document

### MEDIUM TERM (Next Phase)
1. Refactor SPEC_KIT_GUIDE.md into smaller focused modules
2. Create quick reference cards for each phase
3. Add FAQ addressing common contradictions
4. Integrate Context7 library documentation examples

### LONG TERM (Architecture)
1. Separate "web development stack" spec-kit from "terminal configuration"
2. Create terminal-focused spec-kit guidelines
3. Merge all reconciliation into single source of truth
4. Make spec-kit generation-aware (don't conflict with generated docs)

---

## 7. EVIDENCE COMPILATION

### Contradiction #1: Directory Names
- **Spec-kit**: `.runners-local/.runners-local/workflows/gh-workflow-local.sh` (100+ occurrences)
- **Actual**: `.runners-local/workflows/gh-workflow-local.sh` (confirmed existing)
- **File**: `/home/kkk/Apps/ghostty-config-files/.runners-local/workflows/gh-workflow-local.sh`

### Contradiction #2: Components
- **Spec-kit**: "shadcn/ui for all interactive components" (4-spec-kit-tasks.md:70)
- **Spec 005**: "DaisyUI (latest stable)...shadcn/ui reserved for future" (spec.md:142)
- **Evidence**: specs/005-complete-terminal-infrastructure/spec.md:14, 142

### Contradiction #3: Node.js
- **Spec-kit**: "Node.js 18+: Required" (3-spec-kit-plan.md:169)
- **CLAUDE.md**: "Always use the latest Node.js version (not LTS)" (CLAUDE.md:24)
- **Evidence**: Current v25.2.0+ in use, fnm configured for latest

### Contradiction #4: Project Purpose
- **Spec-kit**: "uv + Astro + GitHub Pages + Local CI/CD Stack"
- **CLAUDE.md**: "Ghostty terminal emulator with 2025 optimizations, right-click context menu, AI tools"
- **Evidence**: CLAUDE.md project overview vs SPEC_KIT_INDEX.md overview

### Contradiction #5: Script Paths  
- **Spec-kit**: "./.runners-local/.runners-local/workflows/gh-workflow-local.sh all" (4-spec-kit-tasks.md:186)
- **CLAUDE.md**: "./.runners-local/workflows/gh-workflow-local.sh all" (CLAUDE.md:148)
- **Evidence**: Both files explicitly state these paths

---

## CONCLUSION

**Severity**: HIGH - Multiple breaking changes that could introduce weeks of wasted effort

**Primary Issue**: Spec-kit documents an OLD implementation plan for a web development stack, while the actual project has evolved to include Ghostty terminal configuration with `.runners-local/` CI/CD infrastructure.

**Recommended Action**: Apply FIX recommendations in priority order, starting with path reconciliation and adding prerequisite documentation.

**Timeline**: Fixes should be applied before any users attempt to follow spec-kit guidance for this repository.

---

**Report Generated**: 2025-11-17
**Analysis Scope**: /home/kkk/Apps/ghostty-config-files/spec-kit (complete directory)
**Files Analyzed**: 8 markdown files, 1974 total lines
**Issues Found**: 14 major + multiple supporting issues
