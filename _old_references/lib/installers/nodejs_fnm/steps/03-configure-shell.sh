#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Source P10k-compliant zshrc manager
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
source "${REPO_ROOT}/lib/utils/zshrc_manager.sh"

main() {
    log "INFO" "Configuring shell integration..."

    # fnm configuration block
    local fnm_block
    read -r -d '' fnm_block <<'EOF' || true
# fnm (Fast Node Manager) - 2025 Performance Optimized
# MUST be loaded before Powerlevel10k instant prompt to avoid console output
# Significantly faster than NVM, performance measured and logged
export FNM_DIR="$HOME/.local/share/fnm"
if [ -d "$FNM_DIR" ]; then
  export PATH="$FNM_DIR:$PATH"
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
fi
EOF

    # Configure .zshrc (P10k-compliant injection)
    if [ -f "$HOME/.zshrc" ]; then
        log "INFO" "  Configuring .zshrc..."

        # Inject before P10k to prevent console output warnings
        if inject_into_zshrc "fnm initialization" "$fnm_block" "before_p10k" "fnm env"; then
            log "SUCCESS" "  ✓ Added fnm to .zshrc (before P10k instant prompt)"
        else
            local exit_code=$?
            if [ $exit_code -eq 2 ]; then
                log "INFO" "  ↷ fnm already configured in .zshrc"
            else
                log "ERROR" "  ✗ Failed to configure .zshrc"
                exit 1
            fi
        fi
    fi

    # Configure .bashrc (simple append, no P10k concerns)
    if [ -f "$HOME/.bashrc" ]; then
        log "INFO" "  Configuring .bashrc..."

        if grep -q "fnm env" "$HOME/.bashrc" 2>/dev/null; then
            log "INFO" "  ↷ fnm already configured in .bashrc"
        else
            echo "" >> "$HOME/.bashrc"
            echo "# fnm (Fast Node Manager) - Performance measured and logged" >> "$HOME/.bashrc"
            echo 'export FNM_DIR="$HOME/.local/share/fnm"' >> "$HOME/.bashrc"
            echo 'if [ -d "$FNM_DIR" ]; then' >> "$HOME/.bashrc"
            echo '  export PATH="$FNM_DIR:$PATH"' >> "$HOME/.bashrc"
            echo '  eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"' >> "$HOME/.bashrc"
            echo 'fi' >> "$HOME/.bashrc"
            log "INFO" "  ✓ Added fnm to .bashrc"
        fi
    fi

    log "SUCCESS" "✓ Shell integration configured (P10k-compliant)"
    exit 0
}

main "$@"
