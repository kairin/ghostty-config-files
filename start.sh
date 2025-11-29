#!/bin/bash

# start.sh - System Installer for Ghostty, Feh, Local AI Tools
# Single entry point for installing feh and ghostty.

# set -e removed to prevent premature exit on confirmation warnings

# =============================================================================
# 0. Demo Mode Check
# =============================================================================
DEMO_MODE=0
if [[ "$1" == "--demo-child" ]]; then
    DEMO_MODE=1
fi

echo "$(date): Started with args: $@" >> /tmp/ghostty_start.log
echo "$(date): DEMO_MODE: $DEMO_MODE" >> /tmp/ghostty_start.log

# =============================================================================
# 1. Bootstrap Gum
# =============================================================================
if ! command -v gum &> /dev/null; then
    echo "Gum TUI not found. Installing..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y gum
    else
        # Fallback to binary install
        echo "apt not found. Attempting binary install..."
        mkdir -p "$HOME/.local/bin"
        curl -L -o /tmp/gum.tar.gz https://github.com/charmbracelet/gum/releases/latest/download/gum_Linux_x86_64.tar.gz
        tar -xzf /tmp/gum.tar.gz -C /tmp
        mv /tmp/gum "$HOME/.local/bin/"
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi

# =============================================================================
# 2. Sudo Pre-Authentication & Keep-Alive
# =============================================================================
# Authenticate once at the start (Skip in Demo Mode to avoid PTY issues)
if [[ "$DEMO_MODE" -eq 0 ]]; then
    gum style --foreground 212 "Authenticating sudo..."
    if ! sudo -v; then
        gum style --foreground 196 "Sudo authentication failed. Exiting."
        exit 1
    fi

    # Start background keep-alive
    (while true; do sudo -n true; sleep 60; done) &
    SUDO_PID=$!
    trap 'kill $SUDO_PID' EXIT
else
    echo "$(date): Skipping sudo auth in Demo Mode" >> /tmp/ghostty_start.log
fi

# =============================================================================
# 3. Helper Functions
# =============================================================================

# Show header
show_header() {
    clear
    gum style \
        --border double \
        --margin "1 2" \
        --padding "1 4" \
        --border-foreground 212 \
        "System Installer" \
        "Ghostty, Feh, Local AI Tools"
}

# Get App Status
get_app_status() {
    local app="$1"
    local check_script="scripts/000-check/check_${app}.sh"
    
    if [ -f "$check_script" ]; then
        # Run check script and capture output
        # Output format: INSTALLED|Version|Method|Location|LatestVersion
        local output
        output=$("$check_script" 2>/dev/null)
        
        if [[ "$output" == *"INSTALLED|"* ]]; then
            # Parse pipe-delimited output
            IFS='|' read -r status version method location latest <<< "$output"
            echo "$status|$version|$method|$location|$latest"
        else
            # Pass through "Not Installed" or other statuses, ensuring 5 fields
            # If output is just "Not Installed|-|-|-", append one more field
            if [[ "$output" == *"|"* ]]; then
                 echo "$output|-"
            else
                 echo "Not Installed|-|-|-|-"
            fi
        fi
    else
        echo "Unknown|-|-|-|-"
    fi
}

# Show Status Dashboard (Main)
show_dashboard() {
    # Helper to pad string to length
    pad() {
        local s="$1"
        local len="$2"
        printf "%-${len}s" "$s"
    }

    # Build Header
    # Columns: APP(15) STATUS(20) VERSION(20) METHOD(15) = 70 chars
    local header=$(printf "%-15s %-20s %-20s %-15s" "APP" "STATUS" "VERSION" "METHOD")
    local separator=$(printf "%0.s─" {1..70})
    
    # Accumulate body content
    local body=""
    
    # Function to append app row to body
    append_app_row() {
        local app_name="$1"
        local app_id="$2"
        
        IFS='|' read -r status version method location latest <<< "$(get_app_status $app_id)"
        
        local display_status="$status"
        
        # Logic for "Update Recommended"
        if [[ "$status" == "INSTALLED" ]]; then
            if [[ -n "$latest" ]] && [[ "$latest" != "-" ]] && [[ "$latest" != "$version" ]]; then
                 display_status="Update Available"
            else
                 display_status="Installed"
            fi
        fi
        
        # Colorize status
        local color_status="$display_status"
        if [[ "$display_status" == "Installed" ]]; then
            color_status="\033[32m$display_status\033[0m" # Green
        elif [[ "$display_status" == "Update Available" ]]; then
            color_status="\033[33m$display_status\033[0m" # Yellow
        elif [[ "$display_status" == "Not Installed" ]]; then
            color_status="\033[31m$display_status\033[0m" # Red
        fi
        
        # Calculate padding for status (since it has colors)
        local status_len=${#display_status}
        local status_pad=$((20 - status_len))
        if [ $status_pad -lt 0 ]; then status_pad=0; fi
        
        # Row 1: Columns
        local row1=$(printf "%-15s %b%*s %-20s %-15s" "$app_name" "$color_status" "$status_pad" "" "${version:0:19}" "$method")
        body+="${row1}"$'\n'
        
        # Row 2+: Location and Extra Details
        if [[ "$status" == "INSTALLED" ]]; then
             # Split location by ^ to handle extra details (e.g. npm version)
             IFS='^' read -ra details <<< "$location"
             
             # First part is always location
             local row2=$(printf "└─ Location: %s" "${details[0]}")
             body+="${row2}"$'\n'
             
             # Subsequent parts are extra details
             for ((i=1; i<${#details[@]}; i++)); do
                 local detail="${details[i]}"
                 local row_extra=$(printf "└─ %s" "$detail")
                 body+="${row_extra}"$'\n'
             done

             # Show latest version if available
             if [[ -n "$latest" ]] && [[ "$latest" != "-" ]]; then
                 local row_latest=$(printf "└─ Latest:   %s" "$latest")
                 body+="${row_latest}"$'\n'
             fi
        fi
    }
    
    append_app_row "Feh" "feh"
    append_app_row "Ghostty" "ghostty"
    append_app_row "Nerd Fonts" "nerdfonts"
    append_app_row "Node.js" "nodejs"
    
    # Local AI Tools (Placeholder)
    local ai_status="Not Installed"
    local ai_color="\033[31m$ai_status\033[0m"
    local ai_pad=$((20 - ${#ai_status}))
    local ai_row=$(printf "%-15s %b%*s %-20s %-15s" "Local AI Tools" "$ai_color" "$ai_pad" "" "-" "-")
    body+="${ai_row}"
    
    # Combine all content
    local content="${header}"$'\n'"${separator}"$'\n'"${body}"
    
    # Render with gum style
    gum style --border rounded --padding "0 1" --border-foreground 212 "$content"
    echo ""
}

# Show Extras Dashboard
show_extras_dashboard() {
    # Helper to pad string to length
    pad() {
        local s="$1"
        local len="$2"
        printf "%-${len}s" "$s"
    }

    # Build Header
    local header=$(printf "%-15s %-20s %-20s %-15s" "APP" "STATUS" "VERSION" "METHOD")
    local separator=$(printf "%0.s─" {1..70})
    
    local body=""
    
    # Function to append app row to body (Duplicated for now to avoid scope issues)
    append_app_row() {
        local app_name="$1"
        local app_id="$2"
        
        IFS='|' read -r status version method location latest <<< "$(get_app_status $app_id)"
        
        local display_status="$status"
        
        if [[ "$status" == "INSTALLED" ]]; then
            if [[ -n "$latest" ]] && [[ "$latest" != "-" ]] && [[ "$latest" != "$version" ]]; then
                 display_status="Update Available"
            else
                 display_status="Installed"
            fi
        fi
        
        local color_status="$display_status"
        if [[ "$display_status" == "Installed" ]]; then
            color_status="\033[32m$display_status\033[0m"
        elif [[ "$display_status" == "Update Available" ]]; then
            color_status="\033[33m$display_status\033[0m"
        elif [[ "$display_status" == "Not Installed" ]]; then
            color_status="\033[31m$display_status\033[0m"
        fi
        
        local status_len=${#display_status}
        local status_pad=$((20 - status_len))
        if [ $status_pad -lt 0 ]; then status_pad=0; fi
        
        local row1=$(printf "%-15s %b%*s %-20s %-15s" "$app_name" "$color_status" "$status_pad" "" "${version:0:19}" "$method")
        body+="${row1}"$'\n'
        
        if [[ "$status" == "INSTALLED" ]]; then
             IFS='^' read -ra details <<< "$location"
             local row2=$(printf "└─ Location: %s" "${details[0]}")
             body+="${row2}"$'\n'
             for ((i=1; i<${#details[@]}; i++)); do
                 local detail="${details[i]}"
                 local row_extra=$(printf "└─ %s" "$detail")
                 body+="${row_extra}"$'\n'
             done
             if [[ -n "$latest" ]] && [[ "$latest" != "-" ]]; then
                 local row_latest=$(printf "└─ Latest:   %s" "$latest")
                 body+="${row_latest}"$'\n'
             fi
        fi
    }
    
    append_app_row "Fastfetch" "fastfetch"
    append_app_row "Glow" "glow"
    append_app_row "Go" "go"
    append_app_row "Gum" "gum"
    append_app_row "Python (uv)" "python_uv"
    append_app_row "VHS" "vhs"
    append_app_row "Zsh" "zsh"
    
    local content="${header}"$'\n'"${separator}"$'\n'"${body}"
    gum style --border rounded --padding "0 1" --border-foreground 99 "$content" # Different color for extras? 99 is purple
    echo ""
}

# Run command with tailing output (The "Window" effect)
run_with_tail() {
    local cmd="$1"
    local log_file="$2"
    local description="$3"
    
    # Spinner characters and colors
    local spinners=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local colors=(31 32 33 34 35 36) # Red, Green, Yellow, Blue, Magenta, Cyan
    local spin_idx=0
    
    # Start command in background, redirecting to log
    eval "$cmd" > "$log_file" 2>&1 &
    local pid=$!
    
    # Loop while process is running
    while kill -0 $pid 2>/dev/null; do
        # Get current terminal width
        local cols=$(tput cols)
        # Adjust cols for indentation (4 spaces) + safety margin (2 spaces) = 6
        local max_len=$((cols - 6))
        if [ $max_len -lt 1 ]; then max_len=1; fi
        
        # 1. Print Description Line with Spinner
        local spin_char="${spinners[$spin_idx]}"
        local color="${colors[$((spin_idx % ${#colors[@]}))]}"
        printf "  \033[1;${color}m%s\033[0m %s\n" "$spin_char" "$description"
        
        # 2. Capture and Print Tail Output
        # Capture to variable to avoid race condition between printing and counting
        local tail_out
        tail_out=$(tail -n 5 "$log_file" | cut -c 1-"$max_len")
        
        local lines_printed=0
        if [ -n "$tail_out" ]; then
            while IFS= read -r line; do
                printf "    \033[90m%s\033[K\n" "$line" # Indent + Gray color + Clear line
                ((lines_printed++))
            done <<< "$tail_out"
        fi
        
        # 3. Wait and Update Spinner
        sleep 0.1
        spin_idx=$(( (spin_idx + 1) % ${#spinners[@]} ))
        
        # 4. Move Cursor Up
        # Move up lines_printed + 1 (description line)
        local move_up=$((lines_printed + 1))
        printf "\033[%dA" "$move_up"
    done
    
    # Wait for final exit code
    wait $pid
    local exit_code=$?
    
    # Clear the "window" area one last time
    # We don't know exactly how many lines were printed in the LAST iteration,
    # but we moved the cursor back to the start of the description line.
    # So we overwrite the description line and clear everything below it.
    
    if [ $exit_code -eq 0 ]; then
        printf "\033[K  \033[32m✓\033[0m %s\n" "$description"
        # Clear any potential leftover lines below
        printf "\033[J" 
        return 0
    else
        printf "\033[K  \033[31m✗\033[0m %s Failed (See %s)\n" "$description" "$log_file"
        printf "\033[J" # Clear below
        
        # Show the last few lines of the log for context (indented)
        echo "    Last 5 lines of log:"
        tail -n 5 "$log_file" | cut -c 1-"$max_len" | while IFS= read -r line; do
            printf "    \033[90m%s\033[0m\n" "$line"
        done
        return 1
    fi
}

# Run a specific workflow step for an app
run_step() {
    local step_dir="$1"
    local app="$2"
    local description="$3"
    
    local prefix=""
    case "$step_dir" in
        "scripts/000-check") prefix="check" ;;
        "scripts/001-uninstall") prefix="uninstall" ;;
        "scripts/002-install-first-time") prefix="install_deps" ;;
        "scripts/003-verify") prefix="verify_deps" ;;
        "scripts/004-reinstall") prefix="install" ;;
        "scripts/005-confirm") prefix="confirm" ;;
    esac
    
    local script_path="${step_dir}/${prefix}_${app}.sh"
    local log_file="scripts/006-logs/$(date +%Y%m%d-%H%M%S)-${prefix}_${app}.log"

    if [ -f "$script_path" ]; then
        run_with_tail "bash $script_path" "$log_file" "$description"
        return $?
    else
        return 0
    fi
}

# Install an application
install_app() {
    local app="$1"
    
    gum style --foreground 212 "Starting installation for: $app"
    
    # 1. Check
    run_step "scripts/000-check" "$app" "Checking existing installation..."

    # 2. Install Deps
    if ! run_step "scripts/002-install-first-time" "$app" "Installing dependencies..."; then
        if ! gum confirm "Dependency installation failed. Continue?"; then return 1; fi
    fi

    # 3. Verify Deps
    if ! run_step "scripts/003-verify" "$app" "Verifying dependencies..."; then
        if ! gum confirm "Dependency verification failed. Continue?"; then return 1; fi
    fi

    # 4. Install/Build
    if ! run_step "scripts/004-reinstall" "$app" "Building and Installing..."; then
        gum style --foreground 196 "Installation failed."
        return 1
    fi

    # 5. Confirm
    # Don't fail the whole installation if confirmation just warns (e.g. location mismatch)
    if ! run_step "scripts/005-confirm" "$app" "Confirming installation..."; then
        gum style --foreground 208 "Installation completed with warnings."
    else
        gum style --foreground 46 "✓ $app installation complete!"
    fi
    
    echo ""
}

# Uninstall an application
uninstall_app() {
    local app="$1"
    
    if ! gum confirm "Are you sure you want to uninstall $app?"; then
        return 0
    fi

    gum style --foreground 212 "Starting uninstallation for: $app"
    
    # Run uninstall script
    if ! run_step "scripts/001-uninstall" "$app" "Uninstalling..."; then
        gum style --foreground 196 "Uninstallation failed."
        return 1
    fi
    
    gum style --foreground 46 "✓ $app uninstallation complete!"
    echo ""
}

# Handle App Selection
handle_app_selection() {
    local app_name="$1"
    local app_id="$2"
    
    while true; do
        # Clear command hash to ensure we see newly installed binaries
        hash -r 2>/dev/null
        
        show_header
        # Determine which dashboard to show based on app_id? 
        # Or just show the relevant one?
        # For simplicity, if it's an extra app, show extras dashboard.
        case "$app_id" in
            fastfetch|glow|go|gum|python_uv|vhs|zsh)
                show_extras_dashboard
                ;;
            *)
                show_dashboard
                ;;
        esac
        
        IFS='|' read -r status version method location latest <<< "$(get_app_status $app_id)"
        
        local options=()
        
        if [[ "$status" == "INSTALLED" ]]; then
            if [[ -n "$latest" ]] && [[ "$latest" != "-" ]] && [[ "$latest" != "$version" ]]; then
                options+=("Update to $latest")
            fi
            options+=("Reinstall")
            # Node.js-specific: Install global packages option
            if [[ "$app_id" == "nodejs" ]]; then
                options+=("Install Global Packages (DaisyUI/Tailwind)")
            fi
            options+=("Uninstall")
        else
            options+=("Install")
            # Node.js-specific: Install with global packages option
            if [[ "$app_id" == "nodejs" ]]; then
                options+=("Install + Global Packages (DaisyUI/Tailwind)")
            fi
        fi
        
        if [[ "$DEMO_MODE" -eq 1 ]]; then
            options+=("Demo Mode Off")
        fi
        
        options+=("Back")
        
        local choice=$(gum choose "${options[@]}")
        
        case "$choice" in
            "Install")
                install_app "$app_id"
                ;;
            "Install + Global Packages (DaisyUI/Tailwind)")
                INSTALL_ASTRO_PACKAGES=1 install_app "$app_id"
                ;;
            "Install Global Packages (DaisyUI/Tailwind)")
                export INSTALL_ASTRO_PACKAGES=1
                run_step "scripts/004-reinstall" "nodejs" "Installing global npm packages..."
                run_step "scripts/005-confirm" "nodejs" "Verifying packages..."
                ;;
            "Update to "*)
                install_app "$app_id" # Re-run install to update
                ;;
            "Reinstall")
                install_app "$app_id"
                ;;
            "Uninstall")
                uninstall_app "$app_id"
                ;;
            "Demo Mode Off")
                exit 0
                ;;
            "Back")
                return
                ;;
        esac
        
        # Pause to let user see result before refreshing
        if [[ "$choice" != "Back" ]]; then
             echo "Press Enter to continue..."
             read -r
        fi
    done
}

# Handle Extras Menu
handle_extras_menu() {
    while true; do
        # Clear command hash here too
        hash -r 2>/dev/null
        
        show_header
        show_extras_dashboard
        
        local options=(
            "Fastfetch"
            "Glow"
            "Go"
            "Gum"
            "Python (uv)"
            "VHS"
            "Zsh"
            "Install All"
        )
        
        if [[ "$DEMO_MODE" -eq 1 ]]; then
            options+=("Demo Mode Off")
        fi
        
        options+=("Back")
        
        CHOICE=$(gum choose "${options[@]}")
            
        case "$CHOICE" in
            "Fastfetch") handle_app_selection "Fastfetch" "fastfetch" ;;
            "Glow") handle_app_selection "Glow" "glow" ;;
            "Go") handle_app_selection "Go" "go" ;;
            "Gum") handle_app_selection "Gum" "gum" ;;
            "Python (uv)") handle_app_selection "Python (uv)" "python_uv" ;;
            "VHS") handle_app_selection "VHS" "vhs" ;;
            "Zsh") handle_app_selection "Zsh" "zsh" ;;
            "Install All")
                install_app "fastfetch"
                install_app "glow"
                install_app "go"
                install_app "gum"
                install_app "python_uv"
                install_app "vhs"
                install_app "zsh"
                echo "Press Enter to continue..."
                read -r
                ;;
            "Demo Mode Off") exit 0 ;;
            "Back") return ;;
        esac
    done
}

# =============================================================================
# 4. Demo Mode Handler
# =============================================================================

handle_demo_mode() {
    # Check/install dependencies first
    ./scripts/vhs/record.sh check-deps

    while true; do
        show_header

        gum style --foreground 212 --bold "Demo Recording Menu"
        echo ""

        local OPTIONS=(
            "Start Recording"
            "Convert to Media"
            "View Recordings"
            "Back to Main Menu"
        )

        local CHOICE=$(gum choose "${OPTIONS[@]}" --header "Select an option")

        case "$CHOICE" in
            "Start Recording")
                ./scripts/vhs/record.sh start
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            "Convert to Media")
                ./scripts/vhs/record.sh convert
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            "View Recordings")
                ./scripts/vhs/record.sh list
                echo "Press Enter to continue..."
                read -r
                ;;
            "Back to Main Menu")
                return
                ;;
        esac
    done
}

# =============================================================================
# 5. Main Loop
# =============================================================================

while true; do
    # Clear command hash here as well
    hash -r 2>/dev/null
    
    if [[ "$DEMO_MODE" -eq 1 ]]; then echo "$(date): Main loop iteration" >> /tmp/ghostty_start.log; fi

    show_header
    if [[ "$DEMO_MODE" -eq 1 ]]; then echo "$(date): Header shown" >> /tmp/ghostty_start.log; fi

    show_dashboard
    if [[ "$DEMO_MODE" -eq 1 ]]; then echo "$(date): Dashboard shown" >> /tmp/ghostty_start.log; fi
    
    # Build Menu Options
    OPTIONS=(
        "Feh"
        "Ghostty"
        "Nerd Fonts"
        "Node.js"
        "Extras"
        "Install All (Feh + Ghostty + Node.js)"
    )
    
    if [[ "$DEMO_MODE" -eq 1 ]]; then
        OPTIONS+=("Demo Mode Off")
    else
        OPTIONS+=("Demo Mode")
    fi
    
    OPTIONS+=("Exit")
    
    if [[ "$DEMO_MODE" -eq 1 ]]; then echo "$(date): Waiting for gum choose" >> /tmp/ghostty_start.log; fi
    
    CHOICE=$(gum choose "${OPTIONS[@]}")
    
    if [[ "$DEMO_MODE" -eq 1 ]]; then echo "$(date): Choice made: $CHOICE" >> /tmp/ghostty_start.log; fi
        
    case "$CHOICE" in
        "Feh")
            handle_app_selection "Feh" "feh"
            ;;
        "Ghostty")
            handle_app_selection "Ghostty" "ghostty"
            ;;
        "Nerd Fonts")
            handle_app_selection "Nerd Fonts" "nerdfonts"
            ;;
        "Node.js")
            handle_app_selection "Node.js" "nodejs"
            ;;
        "Extras")
            handle_extras_menu
            ;;
        "Install All (Feh + Ghostty + Node.js)")
            install_app "feh"
            install_app "ghostty"
            install_app "nodejs"
            ;;
        "Demo Mode")
            handle_demo_mode
            ;;
        "Demo Mode Off")
            exit 0
            ;;
        "Exit")
            echo "Goodbye!"
            exit 0
            ;;
    esac
done
