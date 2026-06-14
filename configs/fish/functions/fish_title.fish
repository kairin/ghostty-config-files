function fish_title
    # SSH-aware tab title:  🌐 <label>  📁 <path>  [<app-icon> <cmd>]
    #   🌐 <label> : only over SSH; label from ~/.host-label (e.g. "DGX"), else short hostname
    #   📁 <path>  : current directory, compact (~/A/g form)
    #   <app-icon> : per-running-command emoji from __app_icon (apt-Section derived)
    # `host` is an empty STRING (not an empty list) so local concatenation works.
    set -l host ""
    if set -q SSH_TTY
        set -l label
        # flatten any newlines and cap length, same as the hostname fallback
        test -r ~/.host-label; and set label (string trim < ~/.host-label | string join ' ' | string sub -l 12)
        test -z "$label"; and set label (prompt_hostname | string sub -l 12)
        set host "🌐 $label "
    end

    set -l cmd
    if set -q argv[1]
        # collapse newlines so a multi-line command can't fan out into a list
        set cmd (string trim -- $argv[1] | string collect | string replace -a -- \n ' ')
    else
        set cmd (status current-command)
        test "$cmd" = fish; and set cmd ""
    end

    if test -n "$cmd"
        set -l icon (__app_icon $cmd)
        echo -- $host"📁 "(prompt_pwd -d 1 -D 0)" $icon "(string sub -l 24 -- $cmd)
    else
        echo -- $host"📁 "(prompt_pwd -d 1 -D 0)
    end
end
