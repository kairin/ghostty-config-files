---
name: 031-tool
description: Check if a single tool is installed and get its version. Single atomic task.
model: haiku
---

## Single Task
Check installation status and version of a specified tool.

## Input
- tool_name: Name of tool to check (e.g., gh, node, npm, git, jq, curl)

## Execution
```bash
check_tool() {
  local tool="$1"

  if [ -z "$tool" ]; then
    echo "status=error"
    echo "error=tool_name_required"
    return 1
  fi

  # Check if command exists
  if ! command -v "$tool" &>/dev/null; then
    echo "status=not_installed"
    echo "tool=$tool"
    echo "installed=false"
    return 0
  fi

  # Get version based on tool
  local version=""
  case "$tool" in
    git)
      version=$(git --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
      ;;
    node)
      version=$(node -v 2>/dev/null | sed 's/v//')
      ;;
    npm)
      version=$(npm -v 2>/dev/null)
      ;;
    gh)
      version=$(gh --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
      ;;
    jq)
      version=$(jq --version 2>/dev/null | sed 's/jq-//')
      ;;
    curl)
      version=$(curl --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
      ;;
    bash)
      version=$(bash --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
      ;;
    *)
      # Generic version check
      version=$($tool --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' || echo "unknown")
      ;;
  esac

  # Get path
  local path=$(which "$tool" 2>/dev/null)

  echo "status=installed"
  echo "tool=$tool"
  echo "installed=true"
  echo "version=$version"
  echo "path=$path"
}

# Check tool
check_tool "$TOOL_NAME"
```

## Output
Return ONLY:
```
status: installed | not_installed | error
tool: <tool name>
installed: true | false
version: <version string>
path: <executable path>
```

## Examples
```
Input: tool_name=gh
Output: status=installed, tool=gh, installed=true, version=2.40.0, path=/usr/bin/gh

Input: tool_name=missing-tool
Output: status=not_installed, tool=missing-tool, installed=false
```

## Constraints
- Single tool check per invocation
- Does not install tools
- Read-only operation
