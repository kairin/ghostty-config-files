# Box Drawing ANSI Width - Quick Reference Card

## The Problem in 30 Seconds

```bash
# ❌ BROKEN
printf "║%-30s║\n" "${GREEN}✅ Success${NC}"
# Result: ║\033[0;32m✅ Success\033[0m║  ← Right border misaligned

# ✅ FIXED
display=$(get_string_width "${GREEN}✅ Success${NC}")
padding=$((30 - display))
printf "║"
echo -ne "${GREEN}✅ Success${NC}"
printf '%*s' "$padding" ''
printf "║\n"
# Result: ║✅ Success                    ║  ← Perfect alignment
```

## Why It Breaks

| What | printf Sees | Terminal Displays | Problem |
|------|-------------|-------------------|---------|
| `${GREEN}✅${NC}` | 18 bytes | 1 character | printf counts 18, pads for 18 |
| `"%-10s"` | 18 > 10 | - | NO PADDING ADDED |
| Result | Immediate `║` | Misaligned border | Right side cut off |

## The Fix (3 Steps)

### Step 1: Get Display Width
```bash
clean=$(echo -e "$string" | sed 's/\x1b\[[0-9;]*m//g')
display_width=${#clean}
```

### Step 2: Calculate Padding
```bash
padding=$((desired_width - display_width))
```

### Step 3: Manual Print + Pad
```bash
echo -ne "$string"              # Print with colors
printf '%*s' "$padding" ''     # Add exact spaces
```

## Code Template

```bash
# Box line with ANSI color support
render_box_line() {
    local content="$1"
    local max_width="$2"

    local display=$(get_string_width "$content")
    local padding=$((max_width - display))

    printf "║    "
    echo -ne "$content"
    printf '%*s' "$((padding + 4))" ''
    printf "║\n"
}
```

## Testing Checklist

```bash
# ✅ Test 1: Plain text (baseline)
draw_box "Test" "Plain text"

# ✅ Test 2: Single color
draw_box "Test" "${GREEN}✅ Success${NC}"

# ✅ Test 3: Multiple colors
draw_box "Test" "${GREEN}✅${NC} ${YELLOW}⚠️${NC} ${RED}❌${NC}"

# ✅ Test 4: Emoji
draw_box "Test" "🎉 Party 🔧 Tools"

# ✅ Test 5: Mixed lengths
draw_box "Test" "${GREEN}✅ Short${NC}" "Medium line" "Very long line here"
```

## Key Functions

| Function | Purpose | Returns |
|----------|---------|---------|
| `get_string_width "$str"` | Calculate display width | Integer (character count) |
| `echo -ne "$str"` | Print with colors | (displays to terminal) |
| `printf '%*s' $n ''` | Print N spaces | (adds padding) |

## Common Errors

### Error 1: Using printf with ANSI codes
```bash
# ❌ WRONG
printf "%-${width}s" "$colored_string"
```

### Error 2: Forgetting to strip codes
```bash
# ❌ WRONG
width=${#colored_string}  # Counts bytes, not display width
```

### Error 3: Using echo -e without -n
```bash
# ❌ WRONG
echo -e "$string"  # Adds newline
printf '%*s' "$padding" ''  # Padding on next line!

# ✅ CORRECT
echo -ne "$string"  # No newline
printf '%*s' "$padding" ''  # Padding on same line
```

## Performance

- **Cost per line**: ~2ms (subshell + sed)
- **10-line box**: ~25ms total
- **User perception**: 100ms threshold
- **Verdict**: ✅ Negligible impact

## Files to Modify

1. `/home/kkk/Apps/ghostty-config-files/start.sh`
   - `draw_box()` - Lines 182-228
   - `draw_colored_box()` - Lines 232-279
   - `draw_header()` - Lines 281-301

## Rollback Command

```bash
git checkout start.sh
```

## Verification

```bash
# Syntax check
bash -n start.sh

# Run test suite
./test-box-color-rendering.sh

# Visual check
./start.sh | less -R
```

---

**Keep this card handy during implementation!**
