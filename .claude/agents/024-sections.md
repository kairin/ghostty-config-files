---
name: 024-sections
description: Extract and analyze sections from markdown file. Counts lines per section, identifies large sections. Single atomic task.
model: haiku
---

## Single Task
Parse markdown file and report section-level metrics.

## Input
- file_path: Path to markdown file (default: AGENTS.md)
- threshold: Line threshold for "large" sections (default: 200)

## Execution
```bash
analyze_sections() {
  local file="${1:-AGENTS.md}"
  local threshold="${2:-200}"

  if [ ! -f "$file" ]; then
    echo "status=error"
    echo "error=file_not_found"
    return 1
  fi

  # Extract H2 sections (## Header)
  local sections=""
  local large_sections=""
  local current_section=""
  local current_lines=0
  local total_sections=0
  local max_lines=0
  local max_section=""

  while IFS= read -r line; do
    if echo "$line" | grep -qE '^## '; then
      # Save previous section
      if [ -n "$current_section" ]; then
        sections="${sections}${current_section}:${current_lines};"
        if [ $current_lines -gt $threshold ]; then
          large_sections="${large_sections}${current_section}:${current_lines};"
        fi
        if [ $current_lines -gt $max_lines ]; then
          max_lines=$current_lines
          max_section="$current_section"
        fi
        total_sections=$((total_sections + 1))
      fi
      # Start new section
      current_section=$(echo "$line" | sed 's/^## //')
      current_lines=0
    else
      current_lines=$((current_lines + 1))
    fi
  done < "$file"

  # Handle last section
  if [ -n "$current_section" ]; then
    sections="${sections}${current_section}:${current_lines};"
    if [ $current_lines -gt $threshold ]; then
      large_sections="${large_sections}${current_section}:${current_lines};"
    fi
    if [ $current_lines -gt $max_lines ]; then
      max_lines=$current_lines
      max_section="$current_section"
    fi
    total_sections=$((total_sections + 1))
  fi

  local large_count=$(echo "$large_sections" | tr ';' '\n' | grep -c ':' || echo 0)

  # Output
  echo "status=success"
  echo "file=$file"
  echo "total_sections=$total_sections"
  echo "threshold=$threshold"
  echo "large_section_count=$large_count"
  echo "largest_section=$max_section"
  echo "largest_lines=$max_lines"
  echo ""
  echo "sections=$sections"
  echo "large_sections=$large_sections"
}

# Analyze sections
analyze_sections "$FILE_PATH" "$THRESHOLD"
```

## Output
Return ONLY:
```
status: success | error
file: <file path>
total_sections: <count of ## sections>
threshold: <line threshold used>
large_section_count: <sections over threshold>
largest_section: <name of largest section>
largest_lines: <lines in largest section>

sections: <semicolon-separated name:lines pairs>
large_sections: <only sections over threshold>
```

## Examples
```
Input: file_path=AGENTS.md, threshold=200
Output:
  total_sections=12
  large_section_count=2
  largest_section=Git Operations
  largest_lines=280
  large_sections=Git Operations:280;Build System:210;
```

## Modularization Candidates
Sections over threshold are candidates for extraction to separate files.
Use 024-extract to actually extract them.

## Constraints
- Read-only analysis
- Only parses ## (H2) sections
- Does not modify file
