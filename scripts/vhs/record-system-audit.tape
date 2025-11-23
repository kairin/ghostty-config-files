# VHS Recording: System Audit Demo
# Purpose: Showcase the pre-installation system audit feature
# Usage: vhs scripts/vhs/record-system-audit.tape
# Output: documentation/demos/system-audit-demo.gif

# Video settings
Output documentation/demos/system-audit-demo.gif
Set Shell "bash"
Set FontSize 14
Set Width 1400
Set Height 900
Set TypingSpeed 50ms
Set Theme "Catppuccin Mocha"

# Title
Type "# System Audit Demo - Pre-Installation State"
Enter
Sleep 1s
Enter

# Show the audit command
Type "# First, let's see what's already installed"
Enter
Sleep 500ms
Type "./start.sh"
Enter
Sleep 2s

# Wait for system scan
Sleep 3s

# Wait for gum table display
Sleep 3s

# Show markdown report location
Type "# Markdown reports saved to logs/installation/"
Enter
Sleep 1s
Type "ls -lh logs/installation/system-state-*.md | tail -1"
Enter
Sleep 2s

# View markdown with glow
Type "# View detailed report with glow"
Enter
Sleep 500ms
Type "glow logs/installation/system-state-*.md"
Enter
Sleep 5s

# Credits
Enter
Type "# Powered by Charm Bracelet (gum + glow + vhs)"
Enter
Sleep 2s
