---
description: Execute comprehensive project health assessment - Context7 MCP, GitHub MCP, documentation, Git status
---

## User Input

```text
$ARGUMENTS
```

## Workflow

Execute the following agents **in parallel** (they are independent):

1. **project-health-auditor**:
   - Check Context7 MCP configuration and connectivity
   - Verify GitHub MCP authentication
   - Validate project configuration files
   - Query Context7 for latest best practices (if specific tech stack mentioned in $ARGUMENTS)

2. **documentation-guardian**:
   - Verify AGENTS.md symlinks (CLAUDE.md → AGENTS.md, GEMINI.md → AGENTS.md)
   - Check documentation consistency
   - Validate single source of truth compliance

3. **astro-build-specialist**:
   - Verify .nojekyll file integrity
   - Check Astro build status
   - Validate GitHub Pages deployment readiness

## Execution

Invoke all three agents **in parallel** using a single message with three Task tool calls:
- `project-health-auditor` for MCP and configuration health
- `documentation-guardian` for documentation integrity
- `astro-build-specialist` for build and deployment status

Consolidate all three reports into a single health summary.

## Output Format

```
🏥 PROJECT HEALTH REPORT
========================

✅/❌ Context7 MCP Status
✅/❌ GitHub MCP Status
✅/❌ Documentation Symlinks
✅/❌ Astro Build Status
✅/❌ GitHub Pages Deployment

[Detailed findings from each agent]

Overall Status: HEALTHY / NEEDS ATTENTION / CRITICAL
```
