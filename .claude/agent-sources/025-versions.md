---
name: 025-versions
description: Check system tool versions (git, Node.js, npm, gh CLI). Single atomic task.
model: haiku
---

## Single Task
Check and report versions of required development tools.

## Input
- tools: Comma-separated tools to check (default: git,node,npm,gh,bash)

## Required Versions
- Node.js: 18+
- git: 2.0+
- npm: 8+
- gh (GitHub CLI): any
- bash: 4+

## Execution
```bash
check_tool_versions() {
  local tools="${1:-git,node,npm,gh,bash}"
  local results=""
  local missing=""
  local outdated=""

  for tool in $(echo "$tools" | tr ',' ' '); do
    case "$tool" in
      git)
        if command -v git &>/dev/null; then
          local ver=$(git --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
          results="${results}git:$ver;"
          local major=$(echo $ver | cut -d. -f1)
          [ "$major" -lt 2 ] && outdated="${outdated}git:need 2.0+,have $ver;"
        else
          missing="${missing}git;"
        fi
        ;;
      node)
        if command -v node &>/dev/null; then
          local ver=$(node -v | sed 's/v//')
          results="${results}node:$ver;"
          local major=$(echo $ver | cut -d. -f1)
          [ "$major" -lt 18 ] && outdated="${outdated}node:need 18+,have $ver;"
        else
          missing="${missing}node;"
        fi
        ;;
      npm)
        if command -v npm &>/dev/null; then
          local ver=$(npm -v)
          results="${results}npm:$ver;"
          local major=$(echo $ver | cut -d. -f1)
          [ "$major" -lt 8 ] && outdated="${outdated}npm:need 8+,have $ver;"
        else
          missing="${missing}npm;"
        fi
        ;;
      gh)
        if command -v gh &>/dev/null; then
          local ver=$(gh --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
          results="${results}gh:$ver;"
          # Check authentication
          if gh auth status &>/dev/null; then
            results="${results}gh_auth:true;"
          else
            results="${results}gh_auth:false;"
          fi
        else
          missing="${missing}gh;"
        fi
        ;;
      bash)
        local ver=$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        results="${results}bash:$ver;"
        local major=$(echo $ver | cut -d. -f1)
        [ "$major" -lt 4 ] && outdated="${outdated}bash:need 4+,have $ver;"
        ;;
    esac
  done

  local missing_count=$(echo "$missing" | tr ';' '\n' | grep -c . || echo 0)
  local outdated_count=$(echo "$outdated" | tr ';' '\n' | grep -c . || echo 0)

  # Output
  if [ $missing_count -gt 0 ]; then
    echo "status=missing_tools"
  elif [ $outdated_count -gt 0 ]; then
    echo "status=outdated_tools"
  else
    echo "status=all_ok"
  fi

  echo "missing_count=$missing_count"
  echo "outdated_count=$outdated_count"
  echo ""
  echo "versions=$results"
  echo "missing=$missing"
  echo "outdated=$outdated"
}

# Check versions
check_tool_versions "$TOOLS"
```

## Output
Return ONLY:
```
status: all_ok | outdated_tools | missing_tools
missing_count: <count>
outdated_count: <count>

versions: <semicolon-separated tool:version pairs>
missing: <semicolon-separated missing tools>
outdated: <semicolon-separated outdated tools with details>
```

## Examples
```
Input: tools=git,node,npm
Output:
  status=all_ok
  versions=git:2.43;node:22.0.0;npm:10.0.0;

Input: tools=git,node (Node 16)
Output:
  status=outdated_tools
  outdated=node:need 18+,have 16.0.0;
```

## Constraints
- Read-only checks
- Does not install or upgrade tools
- Reports for parent/user to act on
