# Tasks: Modern Web Development Stack

**Input**: Design documents from `/home/kkk/Apps/ghostty-config-files/specs/001-modern-web-development/`
**Prerequisites**: plan.md (✅), research.md (✅), data-model.md (✅), contracts/ (✅), quickstart.md (✅)
**Feature Branch**: `001-modern-web-development`

## Execution Flow Summary
```
1. Load plan.md from feature directory
   → ✅ COMPLETE: Tech stack (uv, Astro, Tailwind, shadcn/ui), web application structure
2. Load optional design documents:
   → ✅ data-model.md: 5 entities extracted → model/configuration tasks
   → ✅ contracts/: local-cicd-runner.yaml → contract test tasks
   → ✅ research.md: Technology decisions → setup tasks
   → ✅ quickstart.md: Implementation scenarios → validation tasks
3. Generate tasks by category:
   → ✅ Local CI/CD: local-infra setup, runner scripts, git hooks
   → ✅ Setup: uv project init, dependencies, linting
   → ✅ Tests: contract tests, integration tests, local validation
   → ✅ Core: Astro components, shadcn/ui integration, Python scripts
   → ✅ Integration: GitHub Pages, performance monitoring, deployment
   → ✅ Polish: unit tests, performance optimization, documentation
4. Apply task rules:
   → ✅ Different files = mark [P] for parallel
   → ✅ Same file = sequential (no [P])
   → ✅ Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- All file paths are absolute and follow constitutional structure
- Tasks follow constitutional compliance order: uv → Astro → Tailwind+shadcn/ui → Local CI/CD → GitHub Pages

## Path Conventions
**Web Application Structure** (constitutional compliance):
- **Root Configuration**: `pyproject.toml`, `astro.config.mjs`, `tailwind.config.mjs`, `components.json`, `tsconfig.json`
- **Source Code**: `src/` (Astro), `components/` (shadcn/ui), `scripts/` (Python), `public/` (static assets)
- **Local CI/CD**: `local-infra/runners/`, `local-infra/logs/`, `local-infra/config/`
- **Build Output**: `dist/` (GitHub Pages deployment)
- **Python Environment**: `.venv/` (uv managed)

## Phase 3.1: Constitutional Setup (uv-First Python Management)
- [x] T001 Create constitutional project structure per plan.md specifications
- [x] T002 Initialize uv Python environment with pyproject.toml at repository root
- [x] T003 [P] Configure Python linting tools (ruff, black, mypy) in pyproject.toml
- [x] T004 [P] Setup .gitignore for modern web stack (.venv/, dist/, node_modules/, .astro/)

## Phase 3.2: Node.js and Package Management Setup
- [x] T005 Initialize Node.js environment with package.json at repository root
- [x] T006 Install core Astro.build dependencies (>=4.0) with TypeScript strict mode
- [x] T007 [P] Install Tailwind CSS (>=3.4) and required plugins
- [x] T008 [P] Install shadcn/ui dependencies and create components.json

## Phase 3.3: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.4
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [x] T009 [P] Contract test /local-cicd/astro-build in local-infra/tests/contract/test_astro_build.py ✅ FAILING
- [x] T010 [P] Contract test /local-cicd/gh-workflow in local-infra/tests/contract/test_gh_workflow.py ✅ FAILING
- [x] T011 [P] Contract test /local-cicd/performance-monitor in local-infra/tests/contract/test_performance_monitor.py ✅ FAILING
- [x] T012 [P] Contract test /local-cicd/pre-commit in local-infra/tests/contract/test_pre_commit.py ✅ FAILING
- [x] T013 [P] Integration test uv environment setup in tests/integration/test_uv_setup.py ✅ CREATED
- [x] T014 [P] Integration test Astro build workflow in tests/integration/test_astro_workflow.py ✅ FAILING
- [x] T015 [P] Integration test GitHub Pages deployment in tests/integration/test_github_pages.py ✅ FAILING
- [x] T016 [P] Performance validation test (Lighthouse 95+) in tests/performance/test_lighthouse.py ✅ FAILING

## Phase 3.4: Core Configuration Implementation (ONLY after tests are failing)
- [x] T017 [P] Project Configuration entity - Create pyproject.toml with uv settings
- [x] T018 [P] Project Configuration entity - Create astro.config.mjs with TypeScript strict mode
- [x] T019 [P] Project Configuration entity - Create tailwind.config.mjs with design system
- [x] T020 [P] Project Configuration entity - Create components.json for shadcn/ui
- [x] T021 [P] Project Configuration entity - Create tsconfig.json with strict compliance
- [x] T022 [P] Local CI/CD Infrastructure entity - Create local-infra/runners/ directory structure
- [x] T023 [P] Development Workflow entity - Create .github/workflows/ (documentation only, zero consumption)

## Phase 3.5: Local CI/CD Runner Implementation
- [x] T024 Local CI/CD Infrastructure - Implement astro-build-local.sh runner script
- [ ] T025 Local CI/CD Infrastructure - Implement gh-workflow-local.sh runner script
- [ ] T026 Local CI/CD Infrastructure - Implement performance-monitor.sh runner script
- [ ] T027 Local CI/CD Infrastructure - Implement pre-commit-local.sh validation script
- [ ] T028 [P] Local CI/CD Infrastructure - Create logging system in local-infra/logs/
- [ ] T029 [P] Local CI/CD Infrastructure - Create config management in local-infra/config/

## Phase 3.6: Astro.build Implementation
- [ ] T030 [P] Create Astro project structure in src/ directory
- [ ] T031 [P] Create base Layout component in src/layouts/Layout.astro
- [ ] T032 [P] Create sample page with shadcn/ui integration in src/pages/index.astro
- [ ] T033 [P] Configure Tailwind CSS integration in src/styles/globals.css
- [ ] T034 [P] Setup TypeScript configuration for Astro components

## Phase 3.7: shadcn/ui Component Integration
- [ ] T035 [P] Initialize shadcn/ui with base components (Button, Card) in components/ui/
- [ ] T036 [P] Create utility functions for component styling in src/lib/utils.ts
- [ ] T037 [P] Configure dark mode support with CSS variables
- [ ] T038 [P] Setup accessibility compliance validation

## Phase 3.8: Python Automation Scripts
- [ ] T039 [P] Performance Metrics entity - Create performance monitoring script in scripts/monitor_performance.py
- [ ] T040 [P] Development Workflow entity - Create git hook management script in scripts/setup_hooks.py
- [ ] T041 [P] Deployment Pipeline entity - Create asset optimization script in scripts/optimize_assets.py
- [ ] T042 [P] Create dependency update automation in scripts/update_dependencies.py

## Phase 3.9: GitHub Pages Integration
- [ ] T043 Deployment Pipeline entity - Configure GitHub Pages settings via gh CLI
- [ ] T044 Deployment Pipeline entity - Setup custom domain and HTTPS enforcement
- [ ] T045 Deployment Pipeline entity - Implement asset optimization pipeline
- [ ] T046 Deployment Pipeline entity - Create deployment monitoring and rollback capabilities

## Phase 3.10: Local Validation Integration
- [ ] T047 Development Workflow - Integrate all runners into unified workflow
- [ ] T048 Development Workflow - Setup git hooks for local validation
- [ ] T049 Performance Metrics - Configure continuous monitoring pipeline
- [ ] T050 Verify zero GitHub Actions consumption compliance

## Phase 3.11: Polish and Optimization
- [ ] T051 [P] Unit tests for Python scripts in tests/unit/test_scripts.py
- [ ] T052 [P] Unit tests for Astro components in tests/unit/test_components.py
- [ ] T053 Performance optimization - Bundle size validation (<100KB JS)
- [ ] T054 Performance optimization - Lighthouse score validation (95+)
- [ ] T055 [P] Update documentation with quickstart validation
- [ ] T056 [P] Create troubleshooting guide
- [ ] T057 Code quality review and refactoring
- [ ] T058 Run complete integration test suite from quickstart.md

## Dependencies
**Critical Ordering (Constitutional Compliance)**:
- Setup (T001-T008) before everything
- Tests (T009-T016) before implementation (T017-T058)
- uv setup (T002) blocks Python scripts (T039-T042)
- Astro config (T018) blocks Astro implementation (T030-T034)
- Tailwind config (T019) blocks CSS integration (T033, T037)
- shadcn/ui config (T020) blocks component implementation (T035-T038)
- Local CI/CD setup (T022-T029) blocks workflow integration (T047-T050)
- Implementation before polish (T051-T058)

**Parallel Execution Blocks**:
- T003, T004, T007, T008 (different config files)
- T009-T016 (different test files)
- T017-T021 (different config files)
- T022, T023, T028, T029 (different CI/CD components)
- T030-T034 (different Astro files)
- T035-T038 (different component files)
- T039-T042 (different Python scripts)
- T051, T052, T055, T056 (different documentation/test files)

## Parallel Execution Examples

### Setup Phase Parallel Block
```bash
# Launch T003, T004, T007, T008 together:
Task: "Configure Python linting tools (ruff, black, mypy) in pyproject.toml"
Task: "Setup .gitignore for modern web stack (.venv/, dist/, node_modules/, .astro/)"
Task: "Install Tailwind CSS (>=3.4) and required plugins"
Task: "Install shadcn/ui dependencies and create components.json"
```

### Contract Tests Parallel Block (TDD Critical)
```bash
# Launch T009-T012 together (contract tests):
Task: "Contract test /local-cicd/astro-build in local-infra/tests/contract/test_astro_build.py"
Task: "Contract test /local-cicd/gh-workflow in local-infra/tests/contract/test_gh_workflow.py"
Task: "Contract test /local-cicd/performance-monitor in local-infra/tests/contract/test_performance_monitor.py"
Task: "Contract test /local-cicd/pre-commit in local-infra/tests/contract/test_pre_commit.py"
```

### Configuration Implementation Parallel Block
```bash
# Launch T017-T021 together (configuration files):
Task: "Project Configuration entity - Create pyproject.toml with uv settings"
Task: "Project Configuration entity - Create astro.config.mjs with TypeScript strict mode"
Task: "Project Configuration entity - Create tailwind.config.mjs with design system"
Task: "Project Configuration entity - Create components.json for shadcn/ui"
Task: "Project Configuration entity - Create tsconfig.json with strict compliance"
```

### Component Development Parallel Block
```bash
# Launch T035-T038 together (shadcn/ui components):
Task: "Initialize shadcn/ui with base components (Button, Card) in components/ui/"
Task: "Create utility functions for component styling in src/lib/utils.ts"
Task: "Configure dark mode support with CSS variables"
Task: "Setup accessibility compliance validation"
```

## Validation Checklist
*GATE: Checked before task execution*

- [x] All contracts have corresponding tests (T009-T012)
- [x] All entities have configuration/implementation tasks (T017-T050)
- [x] All tests come before implementation (T009-T016 before T017+)
- [x] Parallel tasks truly independent (different files, no shared dependencies)
- [x] Each task specifies exact file path or component
- [x] No task modifies same file as another [P] task
- [x] Constitutional compliance order maintained (uv → Astro → Tailwind → CI/CD → GitHub Pages)
- [x] Zero GitHub Actions consumption enforced throughout
- [x] Performance targets integrated (Lighthouse 95+, JS <100KB)
- [x] Local CI/CD mandatory validation implemented
- [x] Branch preservation strategy maintained

## Notes
- **[P] tasks**: Different files, no dependencies, can run simultaneously
- **Constitutional Compliance**: uv-first Python management enforced throughout
- **Zero GitHub Actions**: All CI/CD runs locally before GitHub deployment
- **Performance Targets**: Lighthouse 95+, FCP <1.5s, JS bundles <100KB
- **TDD Requirement**: Tests T009-T016 MUST fail before implementation begins
- **Local Validation**: Every change must pass local CI/CD before GitHub operations
- **Branch Preservation**: Follow YYYYMMDD-HHMMSS-type-description naming convention

## Success Criteria
1. **Environment**: uv ≥0.4.0, Astro ≥4.0, Tailwind ≥3.4, TypeScript strict mode
2. **Performance**: All Lighthouse scores ≥95, JavaScript bundles <100KB, build time <30s
3. **Local CI/CD**: Complete workflow simulation with zero GitHub Actions consumption
4. **Deployment**: Functional GitHub Pages deployment with asset optimization
5. **Compliance**: All constitutional principles satisfied throughout implementation

Total Tasks: **58** (22 parallel-eligible, 36 sequential)
Estimated Duration: **3-4 days** with parallel execution
Critical Path: **Setup → TDD Tests → Core Implementation → Local CI/CD → Deployment → Polish**