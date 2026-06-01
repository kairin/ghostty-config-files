# scripts/font-picker.fish (symlinked to ~/.config/fish/functions/font-picker.fish at install time)
# Picks an installed Nerd Font via zenity and updates ~/.config/ghostty/config.

function font-picker --description 'Pick a Nerd Font for Ghostty via zenity'
    set -l config_file ~/.config/ghostty/config
    mkdir -p (dirname $config_file)

    # Unique base Nerd Font families (FiraCode, Hack, JetBrainsMono, Meslo*, ...)
    set -l fonts (fc-list : family \
        | string match -r '.*Nerd Font.*' \
        | string replace -r ',.*' '' \
        | sort -u)

    if test (count $fonts) -eq 0
        echo "No Nerd Fonts found. Install some into ~/.local/share/fonts/."
        return 1
    end

    set -l selected (printf '%s\n' $fonts \
        | zenity --list --title 'Select Ghostty Font' \
            --column 'Font' --width 400 --height 500 2>/dev/null)

    if test -z "$selected"
        echo "No font selected."
        return 0
    end

    # Replace the single font-family line, or append if absent.
    # NOTE: this replaces EVERY ^font-family line; the config must keep exactly one.
    if test -f $config_file; and grep -q '^font-family' $config_file
        sed -i "s|^font-family.*|font-family = $selected|" $config_file
    else
        echo "font-family = $selected" >> $config_file
    end

    # SIGUSR2 is Ghostty's documented live-reload signal on Linux/GTK.
    if pkill -SIGUSR2 ghostty 2>/dev/null
        echo "Font set to: $selected (Ghostty reloaded via SIGUSR2)."
    else
        echo "Font set to: $selected."
        echo "Press ctrl+shift+, in Ghostty to reload the config."
    end
end
