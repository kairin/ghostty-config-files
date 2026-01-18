---
name: 031-report
description: Generate setup instructions markdown file from health check results. Single atomic task.
model: haiku
---

## Single Task
Generate a markdown file with setup instructions for missing/failed components.

## Input
- failed_checks: Semicolon-separated list of failed checks with details
- output_path: Where to write report (default: .runners-local/logs/setup-needed.md)

## Execution
```bash
generate_setup_report() {
  local failed="$1"
  local output="${2:-.runners-local/logs/setup-needed-$(date +%Y%m%d-%H%M%S).md}"

  if [ -z "$failed" ]; then
    echo "status=no_failures"
    echo "message=nothing_to_report"
    return 0
  fi

  # Ensure output directory exists
  mkdir -p "$(dirname \"$output\")"

  # Start report
  cat > "$output" << 'HEADER'
# Setup Required

The following components need configuration or installation.

Generated: $(date)

---

HEADER

  # Parse failed checks and generate instructions
  for check in $(echo "$failed" | tr ';' '\n'); do
    [ -z "$check" ] && continue

    local type=$(echo "$check" | cut -d: -f1)
    local detail=$(echo "$check" | cut -d: -f2-)

    case "$type" in
      missing_tool)
        cat >> "$output" << EOF
## Missing Tool: $detail

Install with:
\`\`\`bash
# Ubuntu/Debian
sudo apt install $detail

# macOS
brew install $detail
\`\`\`

EOF
        ;;

      env_not_set)
        cat >> "$output" << EOF
## Environment Variable: $detail

Add to your .env file:
\`\`\`
$detail=your_value_here
\`\`\`

Then source it:
\`\`\`bash
source .env
# or
export $detail=your_value
\`\`\`

EOF
        ;;

      missing_file)
        cat >> "$output" << EOF
## Missing File: $detail

This file is required. Create it or restore from backup:
\`\`\`bash
# Check git history
git log --all -- "$detail"

# Restore if found
git checkout HEAD~1 -- "$detail"
\`\`\`

EOF
        ;;

      gh_not_authenticated)
        cat >> "$output" << EOF
## GitHub CLI Authentication

Authenticate with GitHub:
\`\`\`bash
gh auth login
\`\`\`

Follow the prompts to complete authentication.

EOF
        ;;

      *)
        cat >> "$output" << EOF
## Issue: $type

Details: $detail

Please investigate and resolve manually.

EOF
        ;;
    esac
  done

  # Footer
  cat >> "$output" << 'FOOTER'
---

After completing setup, run the health check again:
\`\`\`bash
./.runners-local/workflows/gh-workflow-local.sh health
\`\`\`
FOOTER

  local line_count=$(wc -l < "$output")

  echo "status=generated"
  echo "output=$output"
  echo "line_count=$line_count"
  echo "issues_documented=$(echo \"$failed\" | tr ';' '\n' | grep -c . || echo 0)"
}

# Generate report
generate_setup_report "$FAILED_CHECKS" "$OUTPUT_PATH"
```

## Output
Return ONLY:
```
status: generated | no_failures | error
output: <path to generated file>
line_count: <lines in report>
issues_documented: <number of issues>
```

## Examples
```
Input: failed_checks="missing_tool:jq;env_not_set:CONTEXT7_API_KEY"
Output: status=generated, output=.runners-local/logs/setup-needed-20251128.md, issues_documented=2

Input: failed_checks=""
Output: status=no_failures, message=nothing_to_report
```

## Report Format
Generates actionable markdown with:
- Issue description
- Specific installation/setup commands
- Verification steps

## Constraints
- Creates timestamped files
- Does not execute setup commands
- Provides guidance only
