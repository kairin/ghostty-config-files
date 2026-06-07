# scripts/dev.fish (symlinked to ~/.config/fish/functions/dev.fish at install time)
# Launches the dev workspace:
#   1:main      claude (left) / fish (right)
#   2:codex-agy codex  (left) / agy  (right)
#   3:nushell   nu     (full window)
# Requires tmux.

function dev --description 'Launch tmux dev workspace: main, codex-agy, nushell'
    if not command -q tmux
        echo "tmux not installed. Run: sudo apt install tmux"
        return 1
    end

    # Always kill and recreate — use 'tmux attach -t dev' to reattach manually.
    tmux kill-session -t dev 2>/dev/null

    tmux new-session -d -s dev -n main

    # Capture stable pane IDs via -P -F; tmux pane indexes change after splits.
    set -l claude (tmux display-message -p -t dev:main '#{pane_id}')
    set -l fish_pane (tmux split-window -h -t "$claude" -p 35 -P -F '#{pane_id}')
    tmux send-keys -t "$claude" 'claude' Enter
    tmux send-keys -t "$fish_pane" 'fish' Enter

    tmux new-window -t dev:2 -n codex-agy
    set -l codex (tmux display-message -p -t dev:codex-agy '#{pane_id}')
    set -l agy (tmux split-window -h -t "$codex" -p 50 -P -F '#{pane_id}')
    tmux send-keys -t "$codex" 'codex' Enter
    tmux send-keys -t "$agy" 'agy' Enter

    tmux new-window -t dev:3 -n nushell
    set -l nu (tmux display-message -p -t dev:nushell '#{pane_id}')
    tmux send-keys -t "$nu" 'nu' Enter

    tmux select-window -t dev:main
    tmux select-pane -t "$fish_pane"
    tmux attach -t dev
end
