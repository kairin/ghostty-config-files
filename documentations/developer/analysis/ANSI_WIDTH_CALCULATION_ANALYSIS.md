# Box Drawing Width Calculation: ANSI Codes & Emoji - Technical Analysis

## Executive Summary

**Problem**: Box edges are misaligned on the right side when content contains ANSI color codes or emoji.

**Root Cause**: Bash's `printf "%-${width}s"` counts **bytes**, not **display width**. ANSI escape codes add invisible bytes that `printf` counts, causing misalignment.

**Solution**: Calculate display width separately (strip ANSI codes first), then manually add padding.

## Technical Deep Dive

### 1. The Core Problem

#### Example String
```bash
test_string="${GREEN}✅ This is a test${NC}"
# Actual value: \033[0;32m✅ This is a test\033[0m
```

#### What Happens
- **Byte length** (with ANSI codes): 33 bytes
  - `\033[0;32m` = 8 bytes
  - `✅ This is a test` = 16 bytes
  - `\033[0m` = 4 bytes

- **Display width** (what you see): 16 characters
  - Only `✅ This is a test` is visible

#### The Misalignment
```bash
# WRONG: printf counts ALL bytes
printf "║%-30s║\n" "$test_string"
# Result: ║\033[0;32m✅ This is a test\033[0m║
#         Right border appears immediately after invisible codes
```

### 2. Why printf Fails

Bash's `printf` format string `%-30s` means:
- `-` = left-align
- `30` = field width in **BYTES**
- `s` = string

**Critical Issue**: `printf` has NO AWARENESS of:
- ANSI escape sequences (color codes)
- Unicode display width
- Terminal rendering rules

It simply counts bytes and pads to that byte count.

### 3. ANSI Escape Code Anatomy

#### Common Types in This Codebase

| Type | Example | Purpose | Bytes |
|------|---------|---------|-------|
| **SGR (Color)** | `\033[0;32m` | Green text | 8 |
| **SGR Reset** | `\033[0m` | Reset formatting | 4 |
| **Bold + Color** | `\033[1;33m` | Bold yellow | 8 |

#### Complete ANSI Escape Patterns

```regex
\x1b\[[0-9;]*m              # Standard color codes (SGR)
\x1b\[[0-9;]*[A-Za-z]       # Cursor movement (CSI sequences)
\x1b\][^\x07]*\x07          # OSC sequences (window titles)
\x1b[()][AB012]             # Character set selection (G0/G1)
```

**Key Insight**: ALL of these are **zero display width** but consume bytes.

### 4. The Solution Architecture

#### Step-by-Step Algorithm

```bash
# 1. Strip ANSI codes to calculate display width
get_string_width() {
    local string="$1"
    local clean_string=$(echo -e "$string" | sed 's/\x1b\[[0-9;]*m//g')
    echo "${#clean_string}"
}

# 2. Calculate padding separately
display_width=$(get_string_width "$content")
padding=$((desired_width - display_width))

# 3. Print string AS-IS (preserves colors)
echo -ne "$content"

# 4. Add exact padding
printf '%*s' "$padding" ''
```

#### Why This Works

| Step | Action | Result |
|------|--------|--------|
| **Strip ANSI** | `sed 's/\x1b\[[0-9;]*m//g'` | Get true display width |
| **Calculate padding** | `desired - display` | Exact spaces needed |
| **Print with color** | `echo -ne "$content"` | Colors remain intact |
| **Add padding** | `printf '%*s'` | Exact space count |

### 5. Current Implementation Analysis

#### File: `/home/kkk/Apps/ghostty-config-files/start.sh`

**Lines 161-178**: `get_string_width()` function
```bash
get_string_width() {
    local string="$1"
    local clean_string=$(echo -e "$string" | sed -E '
        s/\x1b\[[0-9;]*m//g;
        s/\x1b\[[0-9;]*[A-Za-z]//g;
        s/\x1b\][^\x07]*\x07//g;
        s/\x1b[()][AB012]//g
    ')
    echo "${#clean_string}"
}
```

✅ **Correctly strips ALL ANSI escape sequences**

**Lines 216-219**: Content line rendering in `draw_box()`
```bash
for line in "${content[@]}"; do
    printf "${CYAN}║${NC}    %-${content_width}s    ${CYAN}║${NC}\n" "$line"
done
```

❌ **PROBLEM IDENTIFIED**: Using `printf "%-${content_width}s"` with the full string

### 6. The Bug Explained

#### What Happens Now
1. `get_string_width()` correctly calculates `display_width = 16`
2. `content_width = 16` (from max of all lines)
3. `printf "%-16s" "\033[0;32m✅ This is a test\033[0m"`
   - printf sees: 33 bytes total
   - printf wants: 16 byte field
   - printf does: **NO PADDING** (33 > 16, so no spaces added)
   - Result: Right border appears immediately after ANSI codes

#### Why Right Border Misaligns
```
Expected (16 char width + 4 padding = 20):
║    ✅ This is a test    ║

Actual (printf counts bytes):
║    \033[0;32m✅ This is a test\033[0m║
         ← No padding added because 33 bytes > 16 bytes
```

### 7. Emoji Width Complexity

#### Two Types of Width Issues

**Type 1: Character Count vs Display Width**
```bash
emoji="🎉"
echo ${#emoji}  # May output 1 (character count)
# But displays as 2-column width in terminal
```

**Type 2: Variation Selectors**
```bash
warning="⚠️"     # Warning sign + variation selector
echo ${#warning}  # Outputs 2
# But displays as 1-2 columns depending on font
```

#### Unicode Width Categories

| Category | Example | Display Width | Notes |
|----------|---------|---------------|-------|
| **Narrow** | `✅` | 1 column | ASCII-like |
| **Wide** | `🎉` | 2 columns | East Asian Width |
| **Variation** | `⚠️` | 1-2 columns | With U+FE0F selector |
| **ZWJ** | `👨‍👩‍👧‍👦` | Variable | Zero-width joiners |

#### Pragmatic Approach for This Codebase

**Current emoji in use**: ✅ ⚠️ ❌ 🎉 📊 🔧 ℹ️

**Observations**:
- Most are 1-column display width
- Bash `${#string}` gives reasonable approximation
- Minor misalignment is acceptable for emoji
- ANSI code issue is 100x more severe

**Decision**: Focus on ANSI codes, accept emoji limitations.

### 8. Recommended Solution

#### Option A: Manual Padding (Most Reliable)

```bash
draw_box() {
    local title="$1"
    shift
    local -a content=("$@")

    # Calculate maximum width
    local max_width=$(get_string_width "$title")
    for line in "${content[@]}"; do
        local line_width=$(get_string_width "$line")
        ((line_width > max_width)) && max_width=$line_width
    done

    local content_width=$max_width
    local inner_width=$((max_width + 8))

    # Top border
    printf "${CYAN}╔"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╗${NC}\n"

    # Title (manually pad)
    local title_display=$(get_string_width "$title")
    local title_padding=$((content_width - title_display))
    printf "${CYAN}║${NC}    "
    echo -ne "$title"
    printf '%*s' "$((title_padding + 4))" ''
    printf "${CYAN}║${NC}\n"

    # Separator
    printf "${CYAN}╠"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╣${NC}\n"

    # Content lines (manually pad each)
    for line in "${content[@]}"; do
        local line_display=$(get_string_width "$line")
        local line_padding=$((content_width - line_display))
        printf "${CYAN}║${NC}    "
        echo -ne "$line"
        printf '%*s' "$((line_padding + 4))" ''
        printf "${CYAN}║${NC}\n"
    done

    # Bottom border
    printf "${CYAN}╚"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╝${NC}\n"
}
```

**Advantages**:
- ✅ Correct width calculation
- ✅ Works with ANSI codes
- ✅ Preserves colors
- ✅ Pure bash (no external deps)

**Disadvantages**:
- ⚠️ More verbose code
- ⚠️ Slightly slower (more function calls)

#### Option B: Pre-strip and Re-colorize (Alternative)

```bash
# Strip colors, calculate width, then re-apply
draw_box_alt() {
    # Strip all color codes from content
    # Calculate widths on clean strings
    # Re-apply colors after padding
    # More complex, not recommended
}
```

**Not Recommended**: More complex, error-prone, loses color information context.

### 9. Performance Considerations

#### Current Implementation Cost

```bash
# For each line:
get_string_width() {
    echo -e "$string" | sed 's/\x1b\[[0-9;]*m//g'
}
# Cost: 1 subshell + 1 sed process = ~2ms
```

#### Box with 10 lines:
- Width calculations: 10 × 2ms = 20ms
- Rendering: 10 × printf calls = 5ms
- **Total**: ~25ms per box

**Verdict**: Negligible for terminal UI. Human perception threshold is 100ms.

### 10. Testing Strategy

#### Test Cases Required

```bash
# Test 1: Plain text (baseline)
draw_box "Plain" "No colors here"

# Test 2: Single color
draw_box "Single" "${GREEN}✅ Success${NC}"

# Test 3: Multiple colors per line
draw_box "Multi" "${GREEN}✅${NC} ${YELLOW}⚠️${NC} ${RED}❌${NC}"

# Test 4: Mixed line lengths
draw_box "Mixed" \
    "${GREEN}✅ Short${NC}" \
    "${GREEN}✅ This is a much longer line${NC}" \
    "${YELLOW}⚠️ Warning${NC}"

# Test 5: Emoji only
draw_box "Emoji" "🎉 🔧 📊 ✅"

# Test 6: Edge case - empty lines
draw_box "Empty" "" "${GREEN}✅ After empty${NC}" ""

# Test 7: Very long lines
draw_box "Long" \
    "${GREEN}✅ This is an extremely long line with multiple ${YELLOW}color${NC} ${CYAN}changes${NC} throughout"
```

#### Validation Criteria

✅ All right borders (`║`) perfectly aligned
✅ Colors display correctly
✅ Emoji don't break layout severely
✅ Empty lines render correctly
✅ Very long lines don't overflow

### 11. Implementation Checklist

- [ ] Update `draw_box()` in `start.sh` (lines 182-228)
- [ ] Update `draw_colored_box()` in `start.sh` (lines 232-279)
- [ ] Update `draw_header()` in `start.sh` (lines 281-301)
- [ ] Test with `test-box-color-rendering.sh`
- [ ] Run full installation: `./start.sh`
- [ ] Verify all boxes render correctly
- [ ] Check performance impact (should be none)
- [ ] Update documentation

### 12. References & Resources

#### Bash printf Documentation
- Format specifiers: `%-Ns` = left-align, N bytes
- No built-in ANSI awareness

#### ANSI Escape Code Standards
- **SGR (Select Graphic Rendition)**: `ESC[<params>m`
- **CSI (Control Sequence Introducer)**: `ESC[<params><command>`
- Full spec: ECMA-48 / ISO 6429

#### Unicode Width Algorithms
- **wcwidth()**: C library function for character width
- **East Asian Width**: Unicode property (Narrow/Wide/Fullwidth)
- **Grapheme clusters**: Multi-codepoint characters

#### Tools for Perfect Width Calculation
- `wc -L` (GNU coreutils) - works on display width
- Python `wcwidth` library
- Rust `unicode-width` crate

**Decision**: Pure bash is sufficient for this use case.

## Conclusion

**Primary Issue**: Printf byte counting vs display width
**Primary Solution**: Manual padding after width calculation
**Secondary Issue**: Emoji width (accepted limitation)
**Implementation**: Modify 3 functions in start.sh

**Impact**: Perfect box rendering with ANSI color codes, minor emoji imperfections accepted.

## Test Results Expected

### Before Fix
```
╔═══════════════════════════════════╗
║    Build Status    ║
╠═══════════════════════════════════╣
║    [0;32m✅ Success[0m║  ← Misaligned
╚═══════════════════════════════════╝
```

### After Fix
```
╔════════════════════════════╗
║    Build Status            ║
╠════════════════════════════╣
║    ✅ Success              ║  ← Perfectly aligned
╚════════════════════════════╝
```

---

**Document Version**: 1.0
**Analysis Date**: 2025-11-14
**Target Files**: `/home/kkk/Apps/ghostty-config-files/start.sh`
**Status**: Ready for implementation
