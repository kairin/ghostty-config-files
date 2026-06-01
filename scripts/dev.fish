# scripts/dev.fish (symlinked to ~/.config/fish/functions/dev.fish at install time)
# Launches the dev layout: claude on the left, nushell on the right (50/50 split).
# Requires tmux. If a 'dev' session already exists, reattaches to it.

function dev --description 'Launch tmux dev layout: claude left, nushell right'
    if not command -q tmux
        echo "tmux not installed. Run: sudo apt install tmux"
        return 1
    end

    # Reattach if session already exists
    if tmux has-session -t dev 2>/dev/null
        tmux attach -t dev
        return
    end

    # New session: left pane = claude, right pane = nushell (50/50)
    tmux new-session -d -s dev
    tmux send-keys -t dev "claude" Enter
    tmux split-window -t dev -h -p 50
    tmux send-keys -t dev "nu" Enter
    tmux select-pane -t dev:1.1
    tmux attach -t dev
end
