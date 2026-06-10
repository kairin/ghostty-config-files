# scripts/dev.fish (symlinked to ~/.config/fish/functions/dev.fish at install time)
# Toggles the og-tools tmux dev session, rooted at ~/Apps/OG-tools:
#   claude  claude (left) / fish (right)
#   codex   codex
#   agy     agy
# `dev` inside tmux detaches (hides); outside it reattaches, creating the session if needed.
# `dev reset` kills the session and rebuilds it. Requires tmux.

function dev --description 'Toggle the og-tools tmux dev session (dev reset rebuilds)'
    set -l session og-tools
    set -l project /home/kkk/Apps/OG-tools

    if not command -q tmux
        echo "tmux not installed. Run: sudo apt install tmux"
        return 1
    end

    # 'dev reset' tears the session down so the block below rebuilds it.
    if test "$argv[1]" = reset
        tmux kill-session -t "$session" 2>/dev/null
    else
        # Toggle: inside tmux -> hide (detach); session already running -> reattach.
        if set -q TMUX
            tmux detach-client
            return
        end
        if tmux has-session -t "$session" 2>/dev/null
            tmux attach-session -t "$session"
            return
        end
    end

    tmux new-session -d -s "$session" -c "$project" -n claude "claude"
    tmux set-option -t "$session" status on
    tmux set-option -t "$session" status-position bottom
    tmux set-option -t "$session" mouse on

    tmux split-window -h -p 50 -t "$session:claude" -c "$project" "fish"
    tmux select-pane -t "$session:claude.{left}"

    tmux new-window -t "$session:" -c "$project" -n codex "codex"
    tmux new-window -t "$session:" -c "$project" -n agy "agy"
    tmux select-window -t "$session:claude"

    # 'dev reset' from inside a *different* tmux session -> switch; else attach.
    if set -q TMUX
        tmux switch-client -t "$session"
    else
        tmux attach-session -t "$session"
    end
end
