---
name: 024-extract
description: Extract a section from markdown file to new file. Single atomic task.
model: haiku
---

## Single Task
Extract a specific section from a markdown file and save to a new file.

## Input
- source_file: Source markdown file (default: AGENTS.md)
- section_name: Name of section to extract (## header text)
- target_file: Destination file path
- replace_with_link: Replace section with link to new file (default: true)

## Execution
```bash
extract_section() {
  local source="${1:-AGENTS.md}"
  local section="$2"
  local target="$3"
  local replace="${4:-true}"

  if [ ! -f "$source" ]; then
    echo "status=error"
    echo "error=source_not_found"
    return 1
  fi

  if [ -z "$section" ] || [ -z "$target" ]; then
    echo "status=error"
    echo "error=missing_parameters"
    return 1
  fi

  # Find section boundaries
  local start_line=$(grep -n "^## $section" "$source" | head -1 | cut -d: -f1)

  if [ -z "$start_line" ]; then
    echo "status=error"
    echo "error=section_not_found"
    echo "section=$section"
    return 1
  fi

  # Find next section or end of file
  local end_line=$(tail -n +$((start_line + 1)) "$source" | grep -n "^## " | head -1 | cut -d: -f1)
  if [ -z "$end_line" ]; then
    end_line=$(wc -l < "$source")
  else
    end_line=$((start_line + end_line - 1))
  fi

  local section_lines=$((end_line - start_line))

  # Extract section to target file
  mkdir -p "$(dirname \"$target\")"
  sed -n "${start_line},${end_line}p" "$source" > "$target"

  if [ ! -s "$target" ]; then
    echo "status=error"
    echo "error=extraction_failed"
    return 1
  fi

  # Optionally replace section with link
  if [ "$replace" = "true" ]; then
    local link_text="## $section

> This section has been modularized. See: [$section]($target)
"
    # Create temp file with replacement
    head -n $((start_line - 1)) "$source" > "${source}.tmp"
    echo "$link_text" >> "${source}.tmp"
    tail -n +$((end_line + 1)) "$source" >> "${source}.tmp"
    mv "${source}.tmp" "$source"
  fi

  # Output
  echo "status=success"
  echo "source=$source"
  echo "section=$section"
  echo "target=$target"
  echo "lines_extracted=$section_lines"
  echo "replaced_with_link=$replace"
}

# Extract section
extract_section "$SOURCE_FILE" "$SECTION_NAME" "$TARGET_FILE" "$REPLACE_WITH_LINK"
```

## Output
Return ONLY:
```
status: success | error
source: <source file>
section: <section name>
target: <target file created>
lines_extracted: <number of lines>
replaced_with_link: true | false
error: <error message if failed>
```

## Examples
```
Input: source=AGENTS.md, section="Git Operations", target=.claude/instructions/git-ops.md
Output:
  status=success
  lines_extracted=280
  target=.claude/instructions/git-ops.md
  replaced_with_link=true

Input: source=AGENTS.md, section="Missing Section"
Output:
  status=error
  error=section_not_found
```

## Modularization Pattern
Extracts section content to separate file and replaces with:
```markdown
## Section Name

> This section has been modularized. See: [Section Name](path/to/file.md)
```

## Constraints
- Creates target directory if needed
- Replaces section with link by default
- Parent should verify extraction before committing
