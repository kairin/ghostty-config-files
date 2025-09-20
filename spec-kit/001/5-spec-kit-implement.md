# Spec-Kit `/implement` Command Guide

> 🚀 **Purpose**: Begin systematic implementation with monitoring, validation, and mandatory local CI/CD integration

## 📋 Complete `/implement` Prompt

Use this exact prompt with the `/implement` command:

```
Begin implementation with systematic execution, monitoring, and validation:

MANDATORY LOCAL CI/CD IMPLEMENTATION STRATEGY:
1. FIRST ACTION: Create and test local CI/CD infrastructure
2. EVERY component integration: Run local workflow validation
3. BEFORE any GitHub operation: Execute ./local-infra/runners/gh-workflow-local.sh all
4. COMMIT workflow: Always use timestamped branches with local validation
5. MONITORING: Continuous GitHub Actions usage monitoring
6. ERROR HANDLING: Local rollback procedures for failed validations

IMPLEMENTATION STRATEGY:
Execute tasks in dependency order with continuous validation and rollback capabilities. Implement comprehensive logging and error handling throughout.

IMMEDIATE ACTIONS TO TAKE:

1. ENVIRONMENT VALIDATION:
   - Verify system requirements: Python 3.12+, Node.js 18+, Git, GitHub CLI
   - Test network connectivity for package installations
   - Confirm disk space availability (minimum 2GB for all dependencies)
   - Validate write permissions in target directory

2. LOCAL CI/CD INFRASTRUCTURE SETUP (ABSOLUTE FIRST PRIORITY):
   - Create local-infra/ directory structure
   - Build local-infra/runners/astro-build-local.sh
   - Create local-infra/runners/gh-workflow-local.sh
   - Set up local-infra/runners/performance-monitor.sh
   - Configure git hooks (pre-commit, pre-push, post-merge)
   - Test complete local workflow end-to-end
   - Verify zero GitHub Actions consumption

3. SETUP EXECUTION (ONLY AFTER LOCAL CI/CD READY):
   - Create project directory with proper naming conventions
   - Install uv and verify installation: `uv --version`
   - Initialize uv project with proper configuration
   - Set up virtual environment and activate
   - Install base Python dependencies via uv pip install

4. ASTRO INITIALIZATION:
   - Install Node.js dependencies for Astro
   - Create Astro project with TypeScript template
   - Configure astro.config.mjs for static site generation
   - Set up basic project structure and routing
   - Test development server functionality

5. LOCAL CI/CD INTEGRATION CHECKPOINTS (MANDATORY):
   After each major component integration:
   - Execute MANDATORY local workflow: `./local-infra/runners/gh-workflow-local.sh all`
   - Run local Astro build simulation: `./local-infra/runners/astro-build-local.sh`
   - Validate with local pre-commit: `./local-infra/runners/pre-commit-local.sh`
   - Performance monitoring: `./local-infra/runners/performance-monitor.sh`
   - Run comprehensive tests: `npm run build && uv run python scripts/validate.py`
   - Verify no breaking changes to existing functionality
   - Check performance metrics against baselines
   - Validate TypeScript compilation: `npx tsc --noEmit`
   - Test cross-browser compatibility
   - CRITICAL: Only proceed to GitHub operations after ALL local validations pass

6. GITHUB INTEGRATION (ONLY AFTER LOCAL CI/CD SUCCESS):
   - Verify local CI/CD infrastructure is working: `./local-infra/runners/gh-workflow-local.sh status`
   - Create repository with appropriate settings
   - Configure branch protection and review requirements
   - Set up GitHub Actions workflow (triggered only after local validation)
   - Enable GitHub Pages with proper configuration
   - Test end-to-end deployment pipeline
   - Monitor GitHub Actions usage to ensure zero routine consumption

MONITORING AND VALIDATION:
- Continuous build testing throughout implementation
- Performance benchmarking at each integration point
- Dependency security scanning with regular updates
- Accessibility testing for all UI components
- Cross-platform compatibility verification
- MANDATORY: Local CI/CD execution logs review
- GitHub Actions usage monitoring for zero-cost compliance

ERROR HANDLING PROCEDURES:
- Automatic rollback for failed integrations
- Comprehensive error logging with stack traces
- Backup creation before major changes
- Alternative approach documentation for common failures
- Clear escalation paths for blocking issues
- Local CI/CD failure analysis and remediation
- Branch preservation during error scenarios

BRANCH STRATEGY IMPLEMENTATION:
For every commit during implementation:
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-implement-component-name"

# 1. MANDATORY: Execute complete local CI/CD validation
echo "🔄 Running mandatory local CI/CD validation..."
./local-infra/runners/gh-workflow-local.sh all

if [ $? -eq 0 ]; then
    echo "✅ Local validation passed. Proceeding with commit."
    git checkout -b "$BRANCH_NAME"
    git add .
    git commit -m "Implement [component]: [description]

    🤖 Generated with [Claude Code](https://claude.ai/code)
    Co-Authored-By: Claude <noreply@anthropic.com>"
    git push -u origin "$BRANCH_NAME"
    git checkout main
    git merge "$BRANCH_NAME" --no-ff
    git push origin main
    echo "✅ Implementation committed successfully"
    # PRESERVE BRANCH: Never delete without explicit permission
else
    echo "❌ Local CI/CD validation failed. Implementation blocked."
    echo "Review errors and fix issues before proceeding."
    exit 1
fi
```

SUCCESS METRICS:
- All components integrate successfully without conflicts
- Performance metrics meet or exceed specifications
- Development workflow is smooth and efficient
- Deployment pipeline functions reliably
- Documentation is complete and accurate
- Local CI/CD prevents any GitHub Actions consumption
- Zero breaking changes reach the main branch

IMPLEMENTATION TIMELINE:
- Hour 1-2: Local CI/CD infrastructure setup and validation
- Hours 3-4: Environment setup and basic Astro configuration
- Days 1-2: Tailwind CSS and shadcn/ui integration
- Days 3-4: Python tooling and automation scripts
- Days 5-6: GitHub Pages deployment and optimization
- Days 7-8: Testing, documentation, and final validation

POST-IMPLEMENTATION ACTIONS:
- Comprehensive testing across all supported environments
- Performance optimization based on real-world usage data
- Documentation updates with lessons learned
- Training materials for new team members
- Maintenance schedule establishment
- Local CI/CD monitoring and alerting setup

CRITICAL IMPLEMENTATION REQUIREMENTS:
1. LOCAL CI/CD INFRASTRUCTURE MUST BE CREATED FIRST
2. NO GitHub operations without local validation success
3. ALL commits must use timestamped branch strategy
4. MANDATORY performance monitoring at each step
5. Complete error logging and rollback procedures
6. Zero GitHub Actions consumption verification
7. Branch preservation strategy enforcement

Begin implementation immediately, starting with local CI/CD infrastructure setup. Report progress and any issues encountered during each phase.
```

## 🎯 Expected Outcomes

After running this `/implement` command, you should have:

### ✅ Systematic Implementation Process
- **Local CI/CD First**: Complete local infrastructure before any development
- **Validation Checkpoints**: Mandatory local testing at every integration step
- **Branch Strategy**: Timestamped branch creation with preservation policy
- **Error Prevention**: Comprehensive validation preventing GitHub Issues

### ✅ Monitoring and Logging Infrastructure
- **Performance Tracking**: Real-time monitoring throughout implementation
- **Error Management**: Complete logging and rollback procedures
- **Cost Compliance**: Zero GitHub Actions consumption verification
- **Quality Gates**: Automated validation preventing broken deployments

### ✅ Production-Ready Implementation
- **Component Integration**: Systematic addition of uv, Astro, Tailwind, shadcn/ui
- **Deployment Pipeline**: Zero-cost GitHub Pages with local validation
- **Development Workflow**: Optimized developer experience with hot reloading
- **Maintenance Automation**: Python scripts for ongoing site management

## 🔗 Implementation Complete

After successfully executing implementation, you'll have a fully functional:
- **uv-managed Python environment** with all dependencies
- **Astro.build website** with TypeScript and optimal performance
- **Tailwind CSS styling** with custom design system
- **shadcn/ui components** with full accessibility
- **GitHub Pages deployment** with zero ongoing costs
- **Local CI/CD infrastructure** ensuring quality and cost control

---

**Navigation**: [← Back: /tasks](4-spec-kit-tasks.md) | [Index](SPEC_KIT_INDEX.md)