#!/bin/bash
# Validate all internal documentation links

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

echo "Validating documentation links..."
echo ""

BROKEN_LINKS=0
VALID_LINKS=0

validate_markdown_links() {
    local FILE=$1

    if [ ! -f "$FILE" ]; then
        echo "Warning: $FILE not found, skipping"
        return
    fi

    echo "Checking: $FILE"

    # Extract markdown links: [text](file.md)
    grep -o '\[.*\](.*\.md[^)]*)' "$FILE" | while IFS= read -r link; do
        # Extract the file path from the link
        LINKED_FILE=$(echo "$link" | sed -n 's/.*(\([^)]*\))/\1/p' | sed 's/#.*//')

        # Skip external links
        if [[ "$LINKED_FILE" =~ ^https?:// ]]; then
            continue
        fi

        # Check if file exists
        if [ -f "$LINKED_FILE" ]; then
            echo "  ✓ $LINKED_FILE"
            VALID_LINKS=$((VALID_LINKS + 1))
        else
            echo "  ✗ BROKEN: $LINKED_FILE"
            BROKEN_LINKS=$((BROKEN_LINKS + 1))
        fi
    done

    echo ""
}

# Validate key documentation files
validate_markdown_links "AGENTS.md"
validate_markdown_links "README.md"
validate_markdown_links "docs-setup/context7-mcp.md"
validate_markdown_links "docs-setup/github-mcp.md"
validate_markdown_links "docs-setup/constitutional-compliance-criteria.md"

# Check specs directory
if [ -d "specs" ]; then
    find specs -name "*.md" -type f | while read -r spec_file; do
        validate_markdown_links "$spec_file"
    done
fi

echo "=== Summary ==="
echo "Valid links: $VALID_LINKS"
echo "Broken links: $BROKEN_LINKS"
echo ""

if [ $BROKEN_LINKS -gt 0 ]; then
    echo "🚨 Found $BROKEN_LINKS broken links"
    echo "Fix broken links before committing"
    exit 1
else
    echo "✅ All documentation links are valid"
    exit 0
fi
