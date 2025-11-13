---
description: Execute the complete constitutional Git commit workflow with branch creation, commit, push, and merge to main
---

## User Input

```text
$ARGUMENTS
```

Use the commit message from user input if provided. Otherwise, analyze staged/unstaged changes to generate an appropriate commit message.

## Workflow

You **MUST** invoke the `git-operations-specialist` agent to execute the complete constitutional Git workflow:

1. **Create timestamped constitutional branch** (YYYYMMDD-HHMMSS-type-description)
2. **Stage all changes** (or use already staged changes)
3. **Commit with constitutional format** (including Claude attribution)
4. **Push to remote** with upstream tracking
5. **Merge to main** with --no-ff (preserving branch history)
6. **Push main to remote**
7. **Return to feature branch** (NEVER delete - constitutional requirement)

**IMPORTANT**:
- The git-operations-specialist handles the ENTIRE workflow
- You do NOT need to run individual git commands
- The agent ensures constitutional compliance automatically
- Branch preservation is MANDATORY (never delete feature branches)

## Execution

Invoke the git-operations-specialist with the Task tool and provide:
- Commit message (from $ARGUMENTS or auto-generated)
- Commit type (feat, fix, docs, refactor, etc.)
- Short description for branch name

The agent will handle everything else and provide a detailed operation report.
