#!/bin/bash

# Setup automatic sync every day at 6 PM
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up daily auto-sync..."

# Add to crontab
(crontab -l 2>/dev/null; echo "0 18 * * * cd '$REPO_DIR' && ./auto-update-repo.sh >> '$REPO_DIR/auto-sync.log' 2>&1") | crontab -

echo "✅ Scheduled daily sync at 6 PM"
echo "📝 Logs will be written to auto-sync.log"
echo ""
echo "To remove:"
echo "crontab -e"
echo "# Delete the line containing auto-update-repo.sh"
