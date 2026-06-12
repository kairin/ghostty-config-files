# scripts/dev.fish (symlinked to ~/.config/fish/functions/dev.fish at install time)
# Toggles a per-directory tmux dev session, rooted at the directory you launch from:
#   claude  claude (left) / fish (right)
#   codex   codex
#   agy     agy
# Each directory gets its own session named dev-<basename>-<8-char sha1 of full path>,
# so two dirs with the same basename (~/work/web vs ~/play/web) never collide.
# Before reattaching, the session's recorded root dir is verified against the
# current dir; on any mismatch the stale session is rebuilt here. `dev` inside
# tmux detaches (hides); outside it reattaches, creating the session if needed.
# `dev reset` kills the current directory's session and rebuilds it.
# `dev last` jumps to the most-recently-used dev session (no need to recall its dir).
# `dev ls`   lists all dev sessions with their root directories. Requires tmux.

function dev --description 'Toggle a per-directory tmux dev session (last/ls/reset)'
    if not command -q tmux
        echo "tmux not installed. Run: sudo apt install tmux"
        return 1
    end

    # 'dev ls' — show every dev session and the directory it is rooted at.
    if test "$argv[1]" = ls
        set -l rows (tmux list-sessions -F '#{session_name}	#{session_path}' 2>/dev/null \
            | string match --entire 'dev-*')
        if test -z "$rows"
            echo "No dev sessions running."
            return 1
        end
        printf '%s\n' $rows
        return 0
    end

    # 'dev last' — attach the most recently used dev session, wherever it roots.
    if test "$argv[1]" = last
        set -l target (tmux list-sessions -F '#{session_last_attached} #{session_name}' 2>/dev/null \
            | string match --entire '* dev-*' \
            | sort -rn \
            | head -1 \
            | string replace -r '^[0-9]* ' '')
        if test -z "$target"
            echo "No dev sessions running."
            return 1
        end
        if set -q TMUX
            tmux switch-client -t "$target"
        else
            tmux attach-session -t "$target"
        end
        return 0
    end

    # Resolve symlinks so the same physical dir always maps to the same session,
    # regardless of which path you cd'd through.
    set -l project (realpath $PWD)

    # tmux session names can't contain '.' or ':'. Keep the basename for
    # readability; append a hash of the FULL path so identity is per-path,
    # not per-basename.
    set -l hash (echo -n $project | sha1sum | string sub -l 8)
    set -l session dev-(string replace -ra '[^A-Za-z0-9_-]' '-' (basename $project))-$hash

    # 'dev reset' tears the session down so the block below rebuilds it.
    if test "$argv[1]" = reset
        tmux kill-session -t "$session" 2>/dev/null
    else
        # Toggle: inside tmux -> hide (detach).
        if set -q TMUX
            tmux detach-client
            return
        end
        if tmux has-session -t "$session" 2>/dev/null
            # Belt and braces: only reattach if the session really roots here.
            # Guards against any residual name collision or a stale session
            # whose directory has since been moved/renamed.
            set -l session_root (tmux display-message -p -t "$session" '#{session_path}')
            if test "$session_root" = "$project"
                tmux attach-session -t "$session"
                return
            end
            # Wrong root: it is not this directory's session. Rebuild here.
            tmux kill-session -t "$session" 2>/dev/null
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
