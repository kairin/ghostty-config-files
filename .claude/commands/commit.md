---
description: Fully automatic constitutional Git commit - analyzes changes, generates commit message, creates branch, commits, merges to main
---

## User Input

```text
$ARGUMENTS
```

**Note**: User input is OPTIONAL. If provided, use it as additional context for commit message generation.

## Automatic Workflow

You **MUST** perform these steps BEFORE invoking the git-operations-specialist:

### 1. Analyze Changes (REQUIRED)

Run these git commands in parallel to understand what changed:
```bash
git status --short
git diff --staged
git diff
```

### 2. Auto-Generate Commit Details (REQUIRED)

Based on the git analysis, automatically determine:

**Commit Type** (use the most appropriate):
- `feat` - New feature or functionality
- `fix` - Bug fix
- `docs` - Documentation changes only
- `refactor` - Code restructuring without behavior change
- `perf` - Performance improvement
- `test` - Adding or updating tests
- `build` - Build system or dependencies
- `ci` - CI/CD configuration changes
- `chore` - Maintenance tasks

**Short Description** (for branch name):
- Extract from file names and changes
- 2-4 words, kebab-case
- Examples: "slash-commands", "agent-restructuring", "mcp-integration"

**Commit Message**:
- First line: `type(scope): Brief summary` (max 72 chars)
- Blank line
- Detailed bullet points of what changed
- Focus on WHY not WHAT (code shows what)
- Blank line
- Claude attribution (automatic by agent)

**Example Analysis**:
```
Files changed: .claude/commands/commit.md, .claude/commands/deploy.md
Type: feat (new slash commands)
Scope: commands
Description: automatic-commit-workflow
Message: feat(commands): Add fully automatic commit workflow

- Auto-analyze git changes to determine commit type
- Auto-generate commit message from file analysis
- Auto-create branch name from change description
- No user input required for commit execution
```

### 3. Invoke git-operations-specialist (REQUIRED)

Pass the auto-generated details to the agent:
- Commit type (auto-detected)
- Commit message (auto-generated)
- Short description (auto-generated from changes)
- Optional: User context from $ARGUMENTS if provided

## Constitutional Workflow (Executed by Agent)

The git-operations-specialist will automatically:

1. ✅ Create timestamped constitutional branch (YYYYMMDD-HHMMSS-type-description)
2. ✅ Stage all changes (git add .)
3. ✅ Commit with constitutional format (including Claude attribution)
4. ✅ Push to remote with upstream tracking
5. ✅ Merge to main with --no-ff (preserving branch history)
6. ✅ Push main to remote
7. ✅ Return to feature branch (NEVER delete - constitutional requirement)

## Output

Provide a concise summary:
```
🤖 AUTOMATIC COMMIT COMPLETE

Detected Changes:
  - 2 files modified (.claude/commands/)

Auto-Generated:
  Type: feat
  Branch: 20251113-134500-feat-automatic-commit
  Message: "feat(commands): Add fully automatic commit workflow"

Status: ✅ Committed, merged to main, branch preserved
```

**IMPORTANT**:
- NO user input required (fully automatic)
- User can provide optional context via $ARGUMENTS
- All naming and documentation generated automatically
- Constitutional compliance enforced by agent
