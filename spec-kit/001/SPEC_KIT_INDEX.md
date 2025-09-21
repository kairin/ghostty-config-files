# Spec-Kit Command Guide Index

> 🎯 **Complete Implementation Guide**: uv + Astro + GitHub Pages + Local CI/CD Stack

## 📚 Command Execution Order

Execute these spec-kit commands in the exact order listed below. Each command builds upon the previous one to create a comprehensive, production-ready development stack with mandatory local CI/CD integration.

### 1. 🏛️ **[`/constitution`](1-spec-kit-constitution.md)** - Establish Project Principles
**Purpose**: Define non-negotiable principles and constraints
**Duration**: 15-30 minutes
**Output**: Constitutional framework for all technical decisions

**Key Requirements**:
- Technology stack mandates (uv, Astro, Tailwind, shadcn/ui)
- Local CI/CD constitutional requirements
- Performance and security principles
- Branch preservation strategy

---

### 2. 🔧 **[`/specify`](2-spec-kit-specify.md)** - Create Technical Specifications
**Purpose**: Define detailed technical specifications for each component
**Duration**: 30-45 minutes
**Output**: Complete technical blueprints and configuration requirements

**Key Requirements**:
- Python environment specifications (uv, pyproject.toml)
- Astro framework and TypeScript configuration
- Local CI/CD infrastructure specifications
- Project structure with local-infra/ directory

---

### 3. 📋 **[`/plan`](3-spec-kit-plan.md)** - Create Implementation Plans
**Purpose**: Break down implementation into manageable phases
**Duration**: 45-60 minutes
**Output**: 7-phase implementation plan with dependencies and timelines

**Key Requirements**:
- Phase 0: Local CI/CD infrastructure setup (MANDATORY FIRST)
- Phased rollout with validation checkpoints
- Risk mitigation and rollback procedures
- Timeline and resource planning

---

### 4. ✅ **[`/tasks`](4-spec-kit-tasks.md)** - Generate Actionable Tasks
**Purpose**: Convert plans into specific, executable tasks
**Duration**: 30-45 minutes
**Output**: Prioritized task list with validation criteria

**Key Requirements**:
- Task 0: Local CI/CD infrastructure (HIGHEST PRIORITY)
- Detailed execution instructions with commands
- Mandatory local validation for every task
- Branch strategy integration

---

### 5. 🚀 **[`/implement`](5-spec-kit-implement.md)** - Execute Implementation
**Purpose**: Begin systematic implementation with monitoring
**Duration**: Ongoing (1-4 weeks)
**Output**: Fully functional development stack

**Key Requirements**:
- Local CI/CD infrastructure setup FIRST
- Continuous validation checkpoints
- Real-time monitoring and error handling
- Zero GitHub Actions consumption verification

---

## 🎯 Stack Architecture Overview

This guide creates a modern development stack featuring:

### **Core Technologies**
- **Python Management**: `uv` for all dependencies, virtual environments, and package management
- **Frontend Framework**: Astro.build for static site generation with optimal performance
- **Styling System**: Tailwind CSS with utility-first approach
- **Component Library**: shadcn/ui for premium, accessible UI components
- **Deployment**: GitHub Pages with GitHub CLI automation

### **Local CI/CD Integration**
- **MANDATORY Local Workflows**: All GitHub Actions simulated locally first
- **Zero-Cost Strategy**: No GitHub Actions minutes consumed for routine operations
- **Comprehensive Validation**: Build, test, performance, security checks
- **Git Hook Integration**: Automatic enforcement of local CI/CD compliance
- **Complete Logging**: Full audit trail of all operations

### **Development Experience**
- **Zero-Configuration Setup**: New developers productive within 30 minutes
- **Hot Reloading**: Instant feedback for all file changes
- **TypeScript-First**: Strict mode enforcement throughout
- **Performance Focus**: Lighthouse scores 95+ across all metrics

## 🚨 Critical Success Requirements

### **MANDATORY Local CI/CD Infrastructure**
Before proceeding with ANY development work:

1. **Create `local-infra/` directory structure**
2. **Build all local runner scripts**
3. **Configure git hooks for automatic execution**
4. **Validate zero GitHub Actions consumption**
5. **Test complete local workflow end-to-end**

### **Branch Strategy Compliance**
Every commit must use timestamped branches:
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feature-description"

# MANDATORY: Local CI/CD validation FIRST
./local-infra/runners/gh-workflow-local.sh all || exit 1

# Only proceed if validation passes
git checkout -b "$BRANCH_NAME"
# ... commit workflow
# PRESERVE BRANCH: Never delete without explicit permission
```

### **Zero-Cost Compliance**
- Monitor GitHub Actions usage: `gh api user/settings/billing/actions`
- All workflows execute locally before GitHub operations
- Comprehensive local logging and error handling
- Performance monitoring integrated into local workflow

## 📊 Expected Timeline

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| Constitution | 15-30 min | Project principles established |
| Specifications | 30-45 min | Technical blueprints complete |
| Planning | 45-60 min | Implementation roadmap ready |
| Tasks | 30-45 min | Actionable task list generated |
| Implementation | 1-4 weeks | Fully functional development stack |

## 🔗 Quick Navigation

- **Start Here**: [1. Constitution](1-spec-kit-constitution.md)
- **Current Step**: [Check your progress against the timeline above]
- **Need Help**: Refer to the individual command guides for detailed instructions

## 📚 Additional Resources

### **Related Documentation**
- [Original Comprehensive Guide](SPEC_KIT_GUIDE.md) - Complete reference document
- [Project README](../../README.md) - User documentation and quick start
- [CLAUDE Integration](../../CLAUDE.md) - Claude Code integration details
- [AGENTS Instructions](../../AGENTS.md) - Complete AI assistant guidelines

### **Tools and Dependencies**
- [uv Documentation](https://docs.astral.sh/uv/)
- [Astro Documentation](https://docs.astro.build/)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [shadcn/ui Documentation](https://ui.shadcn.com/)
- [GitHub Pages Documentation](https://docs.github.com/pages)

---

**🚀 Ready to Start?** Begin with [**1. Constitution**](1-spec-kit-constitution.md) to establish your project principles.