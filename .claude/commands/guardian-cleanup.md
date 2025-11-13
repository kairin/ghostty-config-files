---
description: Identify and clean up redundant files, consolidate directory structures, with constitutional Git workflow
---

## User Input

```text
$ARGUMENTS
```

## Workflow

Execute the following agents **in sequence**:

1. **repository-cleanup-specialist**:
   - Scan for redundant files and scripts
   - Identify consolidation opportunities
   - Generate cleanup plan
   - Execute cleanup (with user approval)

2. **documentation-guardian** (if documentation changes detected):
   - Verify AGENTS.md symlinks integrity
   - Restore CLAUDE.md → AGENTS.md if needed
   - Restore GEMINI.md → AGENTS.md if needed

3. **git-operations-specialist**:
   - Execute constitutional commit workflow
   - Commit message: "refactor: Cleanup redundant files and consolidate structure"
   - Push changes to main branch

## Execution

1. Invoke `repository-cleanup-specialist` to identify and clean redundancies
2. If documentation was modified, invoke `documentation-guardian` to verify symlinks
3. Invoke `git-operations-specialist` to commit cleanup changes

Provide a summary of files removed, consolidated, and committed.
