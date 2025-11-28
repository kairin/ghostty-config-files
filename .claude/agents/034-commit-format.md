---
name: 034-commit-format
description: Format a constitutional commit message from components. Takes type, scope, summary, body, changes and returns formatted message with Claude attribution. Single atomic task - no decision making.
model: haiku
---

## Single Task
Format a constitutional commit message from provided components.

## Input
- type: One of feat|fix|docs|refactor|test|chore
- scope: Component name (e.g., "agents", "website", "git")
- summary: One-line summary (imperative mood)
- body: Optional detailed description
- changes: Optional bullet list of changes

## Constitutional Format
```
<type>(<scope>): <summary>

<body>

<changes>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Execution
```bash
format_commit_message() {
  local type="$1"
  local scope="$2"
  local summary="$3"
  local body="$4"
  local changes="$5"

  # Build message
  local message="${type}(${scope}): ${summary}"

  # Add body if provided
  if [ -n "$body" ]; then
    message="${message}

${body}"
  fi

  # Add changes if provided
  if [ -n "$changes" ]; then
    message="${message}

${changes}"
  fi

  # Add Claude attribution (MANDATORY)
  message="${message}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

  echo "$message"
}
```

## Output
Return ONLY:
```
message: <the formatted commit message>
status: success
```

## Example
```
Input:
  type: feat
  scope: agents
  summary: add Haiku tier sub-agents for atomic task execution
  body: Created 50 new Haiku agents to handle atomic execution tasks.
  changes: |
    - Added 034-* shared utility agents
    - Added 021-* git operation agents
    - Added 022-* astro build agents

Output:
  message: |
    feat(agents): add Haiku tier sub-agents for atomic task execution

    Created 50 new Haiku agents to handle atomic execution tasks.

    - Added 034-* shared utility agents
    - Added 021-* git operation agents
    - Added 022-* astro build agents

    🤖 Generated with [Claude Code](https://claude.com/claude-code)

    Co-Authored-By: Claude <noreply@anthropic.com>
  status: success
```

## Constraints
- Claude attribution is MANDATORY - never omit
- Type must be from allowed list
- Scope should be short (1-2 words)
- Summary should be imperative mood, <72 chars
