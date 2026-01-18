# SpecKit Workflow Quick Reference

## Command Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  /speckit.specify  →  Define what to build (creates spec.md)   │
│         ↓                                                       │
│  /speckit.clarify  →  Answer ambiguities (refines spec.md)     │
│         ↓                                                       │
│  /speckit.plan     →  Design how to build (creates plan.md)    │
│         ↓                                                       │
│  /speckit.tasks    →  Break into steps (creates tasks.md)      │
│         ↓                                                       │
│  /speckit.taskstoissues → Track in GitHub (optional)           │
│         ↓                                                       │
│  /speckit.implement → Execute tasks (builds the feature)       │
└─────────────────────────────────────────────────────────────────┘
```

## Commands Reference

| # | Command | Purpose | Creates/Updates |
|---|---------|---------|-----------------|
| 1 | `/speckit.specify "description"` | Define WHAT to build | `specs/NNN-name/spec.md` |
| 2 | `/speckit.clarify` | Resolve ambiguities | Updates `spec.md` |
| 3 | `/speckit.plan` | Design HOW to build | `plan.md`, `research.md`, `data-model.md` |
| 4 | `/speckit.tasks` | Break into actionable steps | `tasks.md` |
| 4b | `/speckit.taskstoissues` | Create GitHub issues (optional) | GitHub Issues |
| 5 | `/speckit.implement` | Execute the tasks | Source code |

## When to Use Each

### `/speckit.specify`
**Start here.** Provide a natural language description of your feature.
```
/speckit.specify Add dark mode toggle to settings page
```
- Creates feature branch (`NNN-feature-name`)
- Generates `spec.md` with user stories, requirements, success criteria

### `/speckit.clarify`
**Optional.** Run if spec has `[NEEDS CLARIFICATION]` markers.
- Asks targeted questions about ambiguities
- Updates spec with your answers

### `/speckit.plan`
**Design phase.** Creates implementation blueprint.
- Generates `plan.md` with phases, files to modify
- Creates supporting docs (`research.md`, `data-model.md`, `contracts/`)

### `/speckit.tasks`
**Task breakdown.** Converts plan into executable steps.
- Creates `tasks.md` with T001, T002, etc.
- Organizes by user story and phase
- Marks parallel opportunities with `[P]`

### `/speckit.taskstoissues`
**Optional.** Converts tasks to GitHub Issues for tracking.
- Requires GitHub MCP server
- Creates one issue per task
- Links via milestone

### `/speckit.implement`
**Execution.** Works through tasks systematically.
- Executes tasks in dependency order
- Commits after each logical group

## Quick Examples

**New feature:**
```
/speckit.specify Add user authentication with OAuth2
/speckit.clarify
/speckit.plan
/speckit.tasks
/speckit.implement
```

**Bug fix:**
```
/speckit.specify Fix login timeout issue on slow connections
/speckit.plan
/speckit.tasks
/speckit.implement
```

**Simple enhancement (skip clarify):**
```
/speckit.specify Add loading spinner to dashboard
/speckit.plan
/speckit.tasks
/speckit.implement
```

## Tips

- You can skip `/speckit.clarify` if spec has no `[NEEDS CLARIFICATION]` markers
- Run `/speckit.taskstoissues` only if you want GitHub issue tracking
- Each command builds on the previous - don't skip `/speckit.plan` before `/speckit.tasks`
- Use `/speckit.analyze` after `/speckit.tasks` to verify consistency across all artifacts
