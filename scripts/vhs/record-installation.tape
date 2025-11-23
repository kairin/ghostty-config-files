# VHS Recording: Installation Demo
# Purpose: Record the installation process for documentation
# Usage: vhs scripts/vhs/record-installation.tape
# Output: documentation/demos/installation-demo.gif

# Video settings
Output documentation/demos/installation-demo.gif
Set Shell "bash"
Set FontSize 14
Set Width 1400
Set Height 900
Set TypingSpeed 50ms
Set Theme "Catppuccin Mocha"

# Title sequence
Type "# Ghostty Configuration Files - Installation Demo"
Enter
Sleep 1s
Type "# Automated terminal environment setup with 2025 optimizations"
Enter
Sleep 1s
Enter

# Show system check
Type "./start.sh"
Sleep 500ms
Enter
Sleep 3s

# Wait for pre-installation audit table
Sleep 5s

# Simulate user confirmation (auto-confirm for demo)
Type "y"
Enter

# Let installation run for demo (will be sped up in final edit)
Sleep 10s

# Show final status
Type "echo '✓ Installation Complete!'"
Enter
Sleep 2s

# Show Ghostty version
Type "ghostty --version"
Enter
Sleep 1s

# Show gum version
Type "gum --version"
Enter
Sleep 1s

# Credits
Enter
Type "# Demo recorded with VHS (Charm Bracelet)"
Enter
Sleep 2s
