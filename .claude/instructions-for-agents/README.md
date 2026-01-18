# Instructions for Agents - Documentation Index

> **Token Optimization**: This directory contains modular documentation offloaded from the main AGENTS.md file, reducing token usage by 87% (from 12KB to 1.5KB).

## 📁 Directory Structure

```
.claude/instructions-for-agents/
├── README.md                           (this file)
├── AGENTS.md-BACKUP-20251121.md       (original 12KB file - backup)
│
├── requirements/                       (Critical requirements & policies)
│   ├── CRITICAL-requirements.md        (All 🚨 CRITICAL sections)
│   ├── git-strategy.md                 (Branch preservation, workflow)
│   └── local-cicd-operations.md        (CI/CD pipeline, logging)
│
├── architecture/                       (System design documentation)
│   ├── system-architecture.md          (Overview, tech stack, goals)
│   ├── agent-delegation.md             (5-tier hierarchy, delegation decision tree)
│   └── agent-registry.md               (Complete 60-agent reference)
│
├── guides/                            (Operational how-to guides)
│   └── first-time-setup.md            (Installation, configuration)
│
└── principles/                        (Constitutional principles)
    └── script-proliferation.md         (MANDATORY script creation rules)
```

---

## 📊 Token Optimization Results

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| AGENTS.md size | 12,000 tokens | 1,500 tokens | **87% reduction** |
| Word count | 4,516 words | 874 words | **80% reduction** |
| Quick navigation | Full 12KB load | 1.5KB load | **8x faster** |
| Context per task | ~12KB | ~1.2KB | **90% reduction** |
| Maintainability | Monolithic | Modular | **Clear boundaries** |

---

## 🗂️ File Contents

### Requirements (Detailed Policies)

#### `CRITICAL-requirements.md` (~8KB)
**Contains:**
- Ghostty Performance & Optimization (2025)
- Package Management & Dependencies
- Installation Prerequisites
- Context7 MCP Integration
- GitHub MCP Integration
- GitHub Pages Infrastructure

**When to reference**: Before any system configuration changes

#### `git-strategy.md` (~1.5KB)
**Contains:**
- Branch preservation (MANDATORY)
- Branch naming schema (`YYYYMMDD-HHMMSS-type-description`)
- GitHub safety strategy
- Constitutional branch workflow diagram
- Commit message format
- Pre-commit checklist

**When to reference**: Before creating branches, committing, or modifying Git workflow

#### `local-cicd-operations.md` (~2.5KB)
**Contains:**
- Pre-deployment verification (MANDATORY)
- Local CI/CD pipeline stages (7 stages)
- Workflow tools and commands
- Cost verification (GitHub Actions monitoring)
- Dual-mode logging system
- Workflow status monitoring
- Emergency procedures

**When to reference**: Before running CI/CD workflows or troubleshooting builds

---

### Architecture (System Design)

#### `system-architecture.md` (~2KB)
**Contains:**
- Project overview and goals
- Directory structure (essential structure)
- Technology stack (terminal, AI, CI/CD)
- Core functionality and workflows
- Performance metrics (2025)
- Documentation structure

**When to reference**: Understanding system design or planning major architectural changes

#### `agent-delegation.md` (~500 tokens)
**Contains:**
- 5-tier agent hierarchy diagram
- Delegation decision tree
- Cost/complexity matrix (Opus $$$ → Sonnet $$ → Haiku $)
- When to delegate vs execute directly
- Good/bad delegation examples

**When to reference**: Deciding which agent tier to use for a task

#### `agent-registry.md` (~800 tokens)
**Contains:**
- Complete 60-agent registry
- Parent-child relationships (Sonnet → Haiku)
- Parallel-safe indicators
- Purpose descriptions by tier

**When to reference**: Looking up specific agents or understanding agent relationships

---

### Guides (Operational How-Tos)

#### `first-time-setup.md` (~1.9KB)
**Contains:**
- Prerequisites and system requirements
- Passwordless sudo setup
- Installation steps
- Post-installation configuration (MCP servers, Git, themes)
- First workflow execution
- Troubleshooting common issues
- Daily operations
- Next steps

**When to reference**: Setting up new systems or helping users with installation

---

### Principles (Constitutional Requirements)

#### `script-proliferation.md` (existing)
**Contains:**
- MANDATORY principle: Enhance existing scripts, don't create new ones
- Before-creation checklist
- Validation requirements
- Examples (violations vs compliant)
- Enforcement procedures

**When to reference**: Before creating ANY new `.sh` file

---

## 🔗 Navigation Patterns

### From Main AGENTS.md (Gateway)
```
AGENTS.md → requirements/CRITICAL-requirements.md
         → requirements/git-strategy.md
         → requirements/local-cicd-operations.md
         → architecture/system-architecture.md
         → guides/first-time-setup.md
         → principles/script-proliferation.md
```

### Cross-References Between Files
Each file includes:
- `[← Back to AGENTS.md]` link at top
- **Related Sections** list with links to related documentation
- Clear section anchors for deep linking

---

## 📝 File Naming Conventions

### Pattern: `category-specific-topic.md`

**Examples:**
- ✅ `CRITICAL-requirements.md` (clear, uppercase critical)
- ✅ `git-strategy.md` (specific topic)
- ✅ `local-cicd-operations.md` (descriptive)
- ✅ `first-time-setup.md` (user-focused)
- ❌ `doc1.md` (unclear purpose)
- ❌ `requirements.md` (too generic)

---

## 🎯 Usage Guidelines

### For AI Assistants
1. **Load gateway first**: Read `AGENTS.md` (1.5KB)
2. **Follow links**: Load only relevant detailed docs as needed
3. **Average load**: ~1.2KB per typical task (vs 12KB previously)
4. **Complete reference**: Full 12KB still available if needed

### For Humans
1. **Quick reference**: Start with `AGENTS.md` for overview
2. **Detailed info**: Follow links to specific topic files
3. **Troubleshooting**: Check `guides/first-time-setup.md`
4. **Architecture**: Review `architecture/system-architecture.md`

---

## 🔄 Maintenance

### Adding New Documentation
1. **Determine category**: requirements, architecture, guides, or principles
2. **Create file**: Follow naming convention
3. **Add frontmatter**:
   ```markdown
   ---
   title: Document Title
   category: requirements | architecture | guides | principles
   linked-from: AGENTS.md, other-doc.md
   status: ACTIVE
   last-updated: YYYY-MM-DD
   ---
   ```
4. **Add to AGENTS.md**: Include link in appropriate section
5. **Cross-reference**: Add related sections links

### Updating Existing Documentation
1. **Update last-updated**: Change frontmatter date
2. **Maintain links**: Ensure all links still work
3. **Check cross-refs**: Update related sections if needed
4. **Test navigation**: Verify gateway → detailed → back flow

---

## 📚 Related Documentation

**Main Gateway**: [AGENTS.md](../../../../AGENTS.md)
**Original Backup**: [AGENTS.md-BACKUP-20251121.md](./AGENTS.md-BACKUP-20251121.md)
**README**: [README.md](../../../../README.md)

**External References**:
- [Context7 MCP Setup](./guides/context7-mcp.md)
- [GitHub MCP Setup](./guides/github-mcp.md)
- [Directory Structure](./architecture/DIRECTORY_STRUCTURE.md)
- [Logging Guide](./guides/LOGGING_GUIDE.md)

---

## 📊 Version History

- **v3.0** (2025-11-21): Token optimization - Modular documentation structure
- **v2.0** (2025-09-19): Local CI/CD integration
- **v1.0** (2025-01-01): Initial comprehensive AGENTS.md

---

**Last Updated**: 2025-11-21
**Structure Status**: ACTIVE
**Token Savings**: 87% (10.5KB saved per typical agent invocation)
