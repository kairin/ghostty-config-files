#!/bin/bash
# Test gum style newlines

# Method 1: Literal \n (Broken)
echo "Method 1: Literal \\n"
content="Line 1\nLine 2"
gum style --border rounded "$content"

# Method 2: $'\n' (Correct)
echo "Method 2: \$'\\n'"
content="Line 1"$'\n'"Line 2"
gum style --border rounded "$content"
