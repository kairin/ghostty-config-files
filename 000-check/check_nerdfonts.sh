#!/bin/bash
# Check if Nerd Fonts are installed

# Target font to check (we install multiple, but checking one is sufficient for status)
FONT_NAME="JetBrainsMonoNL Nerd Font"

if fc-list : family | grep -q "$FONT_NAME"; then
    # Get version (best effort) or just say "Latest" since fc-list doesn't always show version easily
    # We can try to find the file and check it, but for dashboard "Installed" is often enough.
    # Let's try to find the file path.
    FONT_PATH=$(fc-list : family file | grep "$FONT_NAME" | head -n 1 | cut -d: -f1)
    
    if [ -n "$FONT_PATH" ]; then
        # Check if it's in our local directory
        if [[ "$FONT_PATH" == *"$HOME/.local/share/fonts"* ]]; then
            METHOD="Script"
        else
            METHOD="System"
        fi
        
        echo "INSTALLED|Latest|$METHOD|$FONT_PATH"
    else
        echo "INSTALLED|Unknown|Unknown|Unknown"
    fi
else
    echo "Not Installed|-|-|-"
fi
