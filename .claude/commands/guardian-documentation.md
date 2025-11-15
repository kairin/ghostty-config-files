---
description: Verify documentation structure, consolidation, cross-references, and agent system integrity
---

## User Input

```text
$ARGUMENTS
```

## Workflow

Execute the following verification steps using specialized agents **in parallel**:

### 1. Agent System Verification

Invoke **master-orchestrator** to verify:
- All 9 agents are properly documented in AGENT_REGISTRY.md
- Agent capabilities match their actual implementations
- Delegation network is accurate and up-to-date
- No undocumented agents exist in `.claude/agents/`

**Current Agent System (9 agents)**:
1. master-orchestrator (35KB) - Multi-agent coordination
2. symlink-guardian (16KB) - CLAUDE.md/GEMINI.md symlink integrity
3. constitutional-compliance-agent (22KB) - AGENTS.md size management
4. documentation-guardian (18KB) - Single source of truth
5. git-operations-specialist (19KB) - Git/GitHub operations
6. astro-build-specialist (18KB) - Astro.build operations
7. project-health-auditor (19KB) - Health checks & Context7 MCP
8. repository-cleanup-specialist (21KB) - Cleanup operations
9. constitutional-workflow-orchestrator (18KB) - Shared templates

### 2. Documentation Structure Verification

Invoke **constitutional-compliance-agent** to verify:

#### Primary Documentation Files
- **AGENTS.md** - Single source of truth (<40KB limit)
  - ✅ All symlinks (CLAUDE.md, GEMINI.md) point correctly
  - ✅ Quick links section up-to-date
  - ✅ All referenced files exist

- **README.md** (root) - User-facing project overview
  - ✅ Links to AGENTS.md, documentation/, website
  - ✅ Installation instructions current
  - ✅ No duplicate content from AGENTS.md

#### Centralized Documentation Hub: `documentations/`

**Constitutional Structure** (as of 2025-11-09):
```
documentations/
├── user/              # End-user documentation
│   ├── setup/        # Setup guides (Context7, GitHub MCP)
│   ├── configuration/
│   └── troubleshooting/
├── developer/         # Developer documentation
│   ├── architecture/ # DIRECTORY_STRUCTURE.md, system design
│   ├── analysis/     # Analysis reports, README.md
│   └── workflows/    # Development workflows
├── specifications/    # Active feature specifications
│   ├── 001-*/        # Spec-Kit feature planning
│   ├── 002-*/
│   └── 004-modern-web-development/OVERVIEW.md
├── archive/          # Historical/obsolete documentation
│   └── [deprecated docs preserved for reference]
├── development/      # Conversation logs, system states
│   ├── conversation_logs/
│   ├── system_states/
│   └── ci_cd_logs/
└── performance/      # Performance documentation
    └── README.md
```

**Verification Checks**:
- ✅ All README.md files link to parent documentation
- ✅ No orphaned documentation (files not referenced anywhere)
- ✅ OVERVIEW.md in specifications/ properly linked from AGENTS.md
- ✅ Archive contains only historical documentation
- ✅ No duplicate content across folders

#### Website Documentation: `website/src/`

**Astro Source Structure**:
```
website/src/
├── content/
│   ├── docs/          # Markdown documentation
│   └── config.ts      # Content collections
├── pages/             # Page routes
└── components/        # UI components
```

**Verification Checks**:
- ✅ No duplicate content between `website/src/` and `documentations/`
- ✅ `website/src/` references `documentations/` for technical details
- ✅ Built output in `docs/` directory (GitHub Pages deployment)

#### Local CI/CD Documentation: `.runners-local/`

**Verification Checks**:
- ✅ `.runners-local/README.md` exists and up-to-date
- ✅ Workflow scripts documented
- ✅ Links from AGENTS.md to .runners-local/ workflows work

### 3. Cross-Reference Validation

Invoke **documentation-guardian** to verify:

#### Symlink Integrity
- ✅ `CLAUDE.md → AGENTS.md` (symlink, not regular file)
- ✅ `GEMINI.md → AGENTS.md` (symlink, not regular file)
- ✅ No broken symlinks in repository

#### Link Integrity
Scan all documentation files for broken links:
```bash
# Find all markdown files
find documentations/ -name "*.md"
find .claude/ -name "*.md"

# Check links to:
- documentations/user/setup/*.md
- documentations/developer/architecture/*.md
- documentations/specifications/*/OVERVIEW.md
- .claude/agents/*.md
- .claude/commands/*.md
- spec-kit/guides/*.md
```

**Common Broken Link Patterns**:
- ❌ `docs-source/` → Should be `website/src/`
- ❌ `runners/` → Should be `.runners-local/workflows/`
- ❌ Absolute paths when relative paths required
- ❌ Links to deleted/moved files

### 4. Documentation Consolidation Validation

Verify NO scattered documentation:

**❌ Anti-Patterns to Detect**:
- Multiple README.md files with conflicting information
- Documentation in random subdirectories not under `documentations/`
- Orphaned markdown files in root directory
- Duplicate setup guides in multiple locations

**✅ Proper Patterns**:
- Single source of truth in `documentations/[category]/`
- README.md files are index/navigation only
- All detailed docs in appropriate subdirectory
- Clear linking hierarchy

### 5. Agent Documentation Consistency

Verify each agent in `.claude/agents/` has:
- ✅ Proper frontmatter (name, description, model)
- ✅ Invocation examples
- ✅ Clear delegation patterns
- ✅ Tools usage section
- ✅ Entry in AGENT_REGISTRY.md

### 6. Slash Command Documentation

Verify `.claude/commands/` completeness:
- ✅ All guardian-* commands follow same format
- ✅ Each command documents parallel vs sequential execution
- ✅ Output format templates provided
- ✅ Links to relevant agents

## Execution

Run all verification steps **in parallel** where possible:
1. Agent system verification (master-orchestrator)
2. Documentation structure (constitutional-compliance-agent)
3. Symlink integrity (documentation-guardian)
4. Link validation (automated scan)
5. Consolidation check (automated scan)

## Output Format

```
📚 DOCUMENTATION INTEGRITY REPORT
===================================

🤖 AGENT SYSTEM STATUS
✅/❌ All 9 agents documented in AGENT_REGISTRY.md
✅/❌ Agent capabilities accurate
✅/❌ Delegation network up-to-date
✅/❌ No undocumented agents

📁 DOCUMENTATION STRUCTURE
✅/❌ AGENTS.md < 40KB (current: XXkB)
✅/❌ Symlinks intact (CLAUDE.md, GEMINI.md)
✅/❌ documentations/ properly organized
  ✅/❌ user/ setup guides exist
  ✅/❌ developer/ architecture docs exist
  ✅/❌ specifications/ active specs exist
  ✅/❌ archive/ contains only historical docs
✅/❌ website/src/ vs documentations/ separation
✅/❌ .runners-local/README.md exists

🔗 CROSS-REFERENCE INTEGRITY
✅/❌ Symlink verification passed
✅/❌ All internal links valid (XX checked)
✅/❌ No broken references to moved files
✅/❌ Quick Links section current

🗂️ CONSOLIDATION COMPLIANCE
✅/❌ No scattered documentation
✅/❌ Single source of truth maintained
✅/❌ No duplicate README.md conflicts
✅/❌ All docs in proper subdirectories

📋 AGENT DOCUMENTATION
✅/❌ All agents have proper frontmatter
✅/❌ Invocation examples complete
✅/❌ Delegation patterns documented
✅/❌ AGENT_REGISTRY.md synchronized

⚙️ SLASH COMMANDS
✅/❌ All guardian-* commands consistent
✅/❌ Command descriptions accurate
✅/❌ Output formats documented

---

ISSUES FOUND: X
- [List of specific issues with file paths]

RECOMMENDATIONS:
- [Specific actions to fix issues]

Overall Status: EXCELLENT / GOOD / NEEDS ATTENTION / CRITICAL
```

## Constitutional Requirements

This command verifies compliance with:
- **Single Source of Truth**: AGENTS.md as master reference
- **Documentation Organization**: Proper use of `documentations/` structure
- **Agent System**: All 9 agents properly documented and registered
- **Link Integrity**: No broken cross-references
- **Consolidation**: No scattered or duplicate documentation
- **Symlink Integrity**: CLAUDE.md/GEMINI.md always point to AGENTS.md

## When to Invoke

Run `/guardian-documentation` proactively:
- After adding new agents to `.claude/agents/`
- After major documentation reorganization
- Before large commits affecting documentation
- When links may be broken (file moves, renames)
- Weekly health check for documentation integrity
- After merging branches with documentation changes
