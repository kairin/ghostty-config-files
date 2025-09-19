# Spec-Kit `/constitution` Command Guide

> 🏛️ **Purpose**: Establish project principles and non-negotiable constraints for uv + Astro + GitHub Pages stack

## 📋 Complete `/constitution` Prompt

Use this exact prompt with the `/constitution` command:

```
Create a project constitution for a modern web development stack with the following core principles:

TECHNOLOGY STACK MANDATES:
- Python dependency management: uv ONLY (no pip, pipenv, poetry, conda)
- Virtual environment management: uv venv ONLY
- Package installation: uv pip install ONLY
- Frontend framework: Astro.build (latest stable version)
- Styling: Tailwind CSS with full utility-first approach
- UI Components: shadcn/ui for all interactive components
- Deployment: GitHub Pages via GitHub CLI automation
- Version Control: Git with conventional commits

PERFORMANCE PRINCIPLES:
- Static site generation (SSG) preferred over client-side rendering
- Minimal JavaScript bundle sizes
- Optimal Core Web Vitals scores
- Fast build times with caching strategies
- Efficient dependency management

DEVELOPMENT EXPERIENCE PRINCIPLES:
- Zero-configuration setup for new developers
- Hot reloading for all file types
- TypeScript-first development
- Automated code formatting and linting
- Comprehensive error handling and logging

DEPLOYMENT PRINCIPLES:
- Zero-cost hosting via GitHub Pages
- LOCAL CI/CD MANDATORY: All workflows MUST run locally before GitHub push
- Branch protection and review requirements
- Semantic versioning for releases
- Environment-specific configurations

LOCAL CI/CD PRINCIPLES (NON-NEGOTIABLE):
- ALL GitHub Actions workflows MUST be simulated locally before push/sync
- MANDATORY local build validation for every commit
- Local testing infrastructure using GitHub CLI simulation
- Zero GitHub Actions minutes consumption for routine operations
- Comprehensive local logging and error handling
- Automated local workflow execution integrated with git hooks

LOCAL CI/CD CONSTITUTIONAL REQUIREMENTS:
- EVERY commit MUST execute complete local workflow validation
- ZERO GitHub Actions minutes consumption for routine operations
- Git hooks MUST enforce local CI/CD compliance
- Branch preservation strategy with timestamped naming
- Comprehensive local logging and error handling
- Performance benchmarking integrated into local workflow

MAINTAINABILITY PRINCIPLES:
- Clear separation of concerns
- Comprehensive documentation
- Automated testing (unit, integration, e2e)
- Security-first dependency management
- Regular dependency updates

Please establish these as non-negotiable principles that will constrain all subsequent technical decisions.
```

## 🎯 Expected Outcomes

After running this `/constitution` command, you should have:

### ✅ Constitutional Framework
- **Technology Stack Constraints**: Clear mandates for uv, Astro, Tailwind, shadcn/ui
- **Performance Requirements**: Specific targets for Core Web Vitals and bundle sizes
- **Development Standards**: TypeScript-first, zero-config setup requirements
- **Local CI/CD Mandates**: Non-negotiable local workflow requirements

### ✅ Decision-Making Guidelines
- **Technology Choices**: Framework for evaluating tools and libraries
- **Performance Benchmarks**: Criteria for accepting/rejecting implementations
- **Quality Gates**: Standards that must be met before deployment
- **Cost Constraints**: Zero GitHub Actions consumption requirements

### ✅ Compliance Framework
- **Git Workflow**: Timestamped branch strategy with preservation
- **Pre-Commit Requirements**: Mandatory local validation before any GitHub operations
- **Performance Monitoring**: Integrated benchmarking and tracking
- **Error Handling**: Comprehensive logging and rollback procedures

## 🔗 Next Command

After successfully establishing your constitution, proceed to:
**[`/specify`](2-spec-kit-specify.md)** - Create detailed technical specifications

---

**Navigation**: [← Back to Index](SPEC_KIT_INDEX.md) | [Next: /specify →](2-spec-kit-specify.md)