---
name: 022-metrics
description: Calculate build metrics - file counts, sizes, asset breakdown. Single atomic task for reporting.
model: haiku
---

## Single Task
Collect and calculate metrics from Astro build output.

## Input
- output_dir: Build output directory (default: docs)

## Metrics Collected
- Total file count
- HTML page count
- CSS/JS asset count and size
- Total output size
- Average page size

## Execution
```bash
calculate_build_metrics() {
  local output_dir="${1:-docs}"

  # Verify directory exists
  if [ ! -d "$output_dir" ]; then
    echo "status=error"
    echo "error=output_dir_missing"
    return 1
  fi

  # Count files by type
  local html_count=$(find "$output_dir" -name "*.html" -type f | wc -l)
  local css_count=$(find "$output_dir" -name "*.css" -type f | wc -l)
  local js_count=$(find "$output_dir" -name "*.js" -type f | wc -l)
  local image_count=$(find "$output_dir" \( -name "*.png" -o -name "*.jpg" -o -name "*.svg" -o -name "*.webp" \) -type f | wc -l)
  local total_count=$(find "$output_dir" -type f | wc -l)

  # Calculate sizes
  local total_size_kb=$(du -sk "$output_dir" 2>/dev/null | cut -f1)
  local html_size_kb=$(find "$output_dir" -name "*.html" -type f -exec du -k {} + 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
  local assets_size_kb=$(du -sk "$output_dir/_astro" 2>/dev/null | cut -f1 || echo 0)

  # Calculate averages
  local avg_html_size=0
  if [ "$html_count" -gt 0 ]; then
    avg_html_size=$((html_size_kb / html_count))
  fi

  # Output metrics
  echo "status=success"
  echo "output_dir=$output_dir"
  echo ""
  echo "# File Counts"
  echo "html_pages=$html_count"
  echo "css_files=$css_count"
  echo "js_files=$js_count"
  echo "images=$image_count"
  echo "total_files=$total_count"
  echo ""
  echo "# Sizes (KB)"
  echo "total_size_kb=$total_size_kb"
  echo "html_size_kb=$html_size_kb"
  echo "assets_size_kb=$assets_size_kb"
  echo "avg_html_size_kb=$avg_html_size"
  echo ""
  echo "# Size (Human Readable)"
  echo "total_size=$(du -sh \"$output_dir\" 2>/dev/null | cut -f1)"
}

# Calculate metrics
calculate_build_metrics "$OUTPUT_DIR"
```

## Output
Return ONLY:
```
status: success | error
output_dir: <path>

# File Counts
html_pages: <count>
css_files: <count>
js_files: <count>
images: <count>
total_files: <count>

# Sizes (KB)
total_size_kb: <size in KB>
html_size_kb: <HTML total in KB>
assets_size_kb: <_astro/ size in KB>
avg_html_size_kb: <average HTML page size>

# Size (Human Readable)
total_size: <e.g., "2.5M">
```

## Examples
```
Input: output_dir=docs
Output:
  status=success
  html_pages=80
  css_files=12
  js_files=8
  total_files=150
  total_size_kb=2560
  total_size=2.5M
```

## Constraints
- Read-only calculation
- Does not modify any files
- Used for reporting and performance tracking
