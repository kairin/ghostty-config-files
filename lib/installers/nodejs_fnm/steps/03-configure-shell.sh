#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Configuring shell integration..."
    
    for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
        [ ! -f "$rc_file" ] && continue
        
        if grep -q "fnm env" "$rc_file" 2>/dev/null; then
            log "INFO" "  ↷ fnm already configured in $rc_file"
        else
            echo "" >> "$rc_file"
            echo "# fnm (Fast Node Manager) - CONSTITUTIONAL: <50ms startup required" >> "$rc_file"
            echo 'eval "$(fnm env --use-on-cd)"' >> "$rc_file"
            log "INFO" "  ✓ Added fnm to $rc_file"
        fi
    done
    
    log "SUCCESS" "✓ Shell integration configured"
    exit 0
}

main "$@"
