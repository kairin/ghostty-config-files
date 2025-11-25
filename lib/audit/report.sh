#!/usr/bin/env bash
#
# lib/audit/report.sh - System audit reporting logic
#
# Contains functions for generating markdown reports and displaying
# the installation strategy table.
#

generate_recommendation() {
    local app_name="$1"
    local min_required="$2"
    local apt_avail="$3"
    local installed="$4"
    local source_latest="$5"
    local install_method="$6"

    if [ "$installed" = "not installed" ] || [ "$installed" = "unknown" ] || [ "$installed" = "built-from-source" ]; then
        if [ "$install_method" = "npm" ]; then echo "INSTALL via npm"; return 0;
        elif [ "$apt_avail" != "N/A" ] && [ "$apt_avail" != "unknown" ]; then echo "INSTALL (APT available)"; return 0;
        else echo "INSTALL (build from source)"; return 0; fi
    fi

    min_required="${min_required#v}"
    apt_avail="${apt_avail#v}"
    installed="${installed#v}"
    source_latest="${source_latest#v}"

    local meets_minimum=false
    if [ "$min_required" != "unknown" ] && [ "$min_required" != "latest" ]; then
        if version_compare "$installed" "$min_required"; then meets_minimum=true; fi
    else meets_minimum=true; fi

    if [ "$meets_minimum" = false ]; then echo "⚠ CRITICAL (below minimum $min_required)"; return 0; fi

    local apt_viable=false
    local source_advantage=false
    local at_latest=false

    if [ "$apt_avail" != "N/A" ] && [ "$apt_avail" != "unknown" ]; then
        if [ "$min_required" = "unknown" ] || [ "$min_required" = "latest" ] || version_compare "$apt_avail" "$min_required"; then apt_viable=true; fi
    fi

    if [ "$source_latest" != "N/A" ] && [ "$apt_avail" != "N/A" ]; then
        if version_compare "$source_latest" "$apt_avail"; then source_advantage=true; fi
    fi

    if [ "$source_latest" != "N/A" ]; then
        if [ "$installed" = "$source_latest" ]; then at_latest=true; fi
    elif [ "$apt_avail" != "N/A" ]; then
        if [ "$installed" = "$apt_avail" ]; then at_latest=true; fi
    fi

    if [ "$at_latest" = true ]; then
        if [ "$install_method" = "source" ] || [ "$install_method" = "other" ]; then echo "✓ OK (built from source)"; else echo "✓ OK (APT latest)"; fi
    elif [ "$source_advantage" = true ]; then
        local delta="$source_latest"
        echo "↑ UPGRADE (source → $delta)"
    elif [ "$apt_viable" = true ] && [ "$install_method" != "apt" ]; then
        echo "✓ OK (can use APT $apt_avail)"
    else
        echo "✓ OK (meets minimum)"
    fi
}

generate_markdown_report() {
    local -a audit_data=("$@")
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local markdown_file="${REPO_ROOT}/logs/installation/system-state-${timestamp}.md"

    mkdir -p "${REPO_ROOT}/logs/installation"

    cat > "$markdown_file" <<EOF
# System State Audit
**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## Installation Status

| App/Tool | Current Version | Path | Method | Min Required | Action |
|----------|----------------|------|--------|--------------|--------|
EOF

    for data in "${audit_data[@]}"; do
        IFS='|' read -r name current path method min_req apt_ver src_ver status <<< "$data"
        echo "| $name | $current | $path | $method | $min_req | $status |" >> "$markdown_file"
    done

    cat >> "$markdown_file" <<EOF

## Version Analysis & Recommendations

| App/Tool | Min Required | APT Available | Installed | Source Latest | Recommendation |
|----------|--------------|---------------|-----------|---------------|----------------|
EOF

    for data in "${audit_data[@]}"; do
        IFS='|' read -r app_name current_ver path method min_required apt_avail source_latest status <<< "$data"
        local recommendation
        recommendation=$(generate_recommendation "$app_name" "$min_required" "$apt_avail" "$current_ver" "$source_latest" "$method")
        local installed_mark="✗"
        if [ "$current_ver" != "not installed" ] && [ "$current_ver" != "unknown" ]; then
            if [ "$min_required" = "unknown" ] || [ "$min_required" = "latest" ] || version_compare "$current_ver" "$min_required"; then installed_mark="✓"; else installed_mark="⚠"; fi
        fi
        echo "| $app_name | $min_required | $apt_avail | $current_ver $installed_mark | $source_latest | $recommendation |" >> "$markdown_file"
    done

    cat >> "$markdown_file" <<EOF

**Legend:**
- ✓ = Meets minimum requirement
- ⚠ = Below minimum (CRITICAL)
- ✗ = Not installed
- ? = Built from source (version unknown)
- ↑ = Newer version available

EOF

    local total_apps="${#audit_data[@]}"
    local installed_count=0
    local upgrade_count=0
    local install_count=0

    for data in "${audit_data[@]}"; do
        IFS='|' read -r _ _ _ _ _ _ _ action <<< "$data"
        case "$action" in
            "OK") ((installed_count++)) ;;
            "UPGRADE") ((upgrade_count++)) ;;
            "INSTALL") ((install_count++)) ;;
        esac
    done

    cat >> "$markdown_file" <<EOF

## Summary Statistics

- **Total apps/tools:** $total_apps
- **Already installed (OK):** $installed_count
- **Will upgrade:** $upgrade_count
- **Will install:** $install_count

## Installation Methods

EOF

    local method_apt=0 method_source=0 method_binary=0 method_npm=0 method_missing=0
    for data in "${audit_data[@]}"; do
        IFS='|' read -r _ _ _ method _ _ <<< "$data"
        case "$method" in
            "apt") ((method_apt++)) ;;
            "source") ((method_source++)) ;;
            "binary"|"user-binary") ((method_binary++)) ;;
            "npm") ((method_npm++)) ;;
            "missing") ((method_missing++)) ;;
        esac
    done

    [ "$method_apt" -gt 0 ] && echo "- **APT packages:** $method_apt" >> "$markdown_file"
    [ "$method_source" -gt 0 ] && echo "- **Built from source:** $method_source" >> "$markdown_file"
    [ "$method_binary" -gt 0 ] && echo "- **Binary installations:** $method_binary" >> "$markdown_file"
    [ "$method_npm" -gt 0 ] && echo "- **NPM global packages:** $method_npm" >> "$markdown_file"
    [ "$method_missing" -gt 0 ] && echo "- **Not installed:** $method_missing" >> "$markdown_file"

    log "INFO" "Markdown report saved: $markdown_file"
    log "INFO" "View detailed report: glow $markdown_file"
}

display_installation_strategy_groups() {
    local -a audit_data=("$@")

    log "INFO" "════════════════════════════════════════"
    log "INFO" "Installation Strategy by Tool Category"
    log "INFO" "════════════════════════════════════════"
    echo ""

    local -a npm_tools=()
    local -a curl_installer_tools=()
    local -a apt_tools=()
    local -a source_tools=()
    local -a other_tools=()

    for data in "${audit_data[@]}"; do
        IFS='|' read -r app_name current_ver path method min_required apt_avail source_latest status <<< "$data"
        local row="${app_name}|${current_ver}|${path}|${method}|${min_required}|${status}|${source_latest}"

        if [ "$method" = "snap" ]; then other_tools+=("$row");
        elif [ "$app_name" = "fnm" ] || [ "$app_name" = "Python UV" ] || [ "$app_name" = "Oh My ZSH" ] || [ "$app_name" = "Go Language" ]; then curl_installer_tools+=("$row");
        elif [ "$method" = "npm" ] || [ "$app_name" = "Node.js" ] || [ "$app_name" = "npm" ]; then npm_tools+=("$row");
        elif [ "$apt_avail" != "N/A" ] && [ "$apt_avail" != "unknown" ]; then
            if [ "$source_latest" != "N/A" ] && [ "$source_latest" != "unknown" ]; then
                local apt_major src_major
                apt_major=$(echo "$apt_avail" | cut -d. -f1 2>/dev/null || echo "0")
                src_major=$(echo "$source_latest" | cut -d. -f1 2>/dev/null || echo "0")
                if [ "$src_major" != "$apt_major" ] && [ "$src_major" -gt "$apt_major" ] 2>/dev/null; then source_tools+=("$row"); else apt_tools+=("$row"); fi
            else apt_tools+=("$row"); fi
        elif [ "$source_latest" != "N/A" ] && [ "$source_latest" != "unknown" ]; then source_tools+=("$row");
        else other_tools+=("$row"); fi
    done

    local -a consolidated_table=()

    sort_array_alphabetically() {
        local -n arr=$1
        if [ ${#arr[@]} -gt 0 ]; then mapfile -t arr < <(printf '%s\n' "${arr[@]}" | sort -t'|' -k1,1 -f); fi
    }

    truncate_path() {
        local path="$1"
        local max_len="${2:-45}"
        if [ ${#path} -le "$max_len" ]; then echo "$path"; return; fi
        local prefix_len=15
        local suffix_len=$((max_len - prefix_len - 3))
        echo "${path:0:$prefix_len}...${path: -$suffix_len}"
    }

    sort_array_alphabetically curl_installer_tools
    sort_array_alphabetically npm_tools
    sort_array_alphabetically apt_tools
    sort_array_alphabetically source_tools
    sort_array_alphabetically other_tools

    add_section() {
        local title="$1"
        local -n items=$2
        local color_name="$3"

        if [ ${#items[@]} -gt 0 ]; then
            local f2="────────────────────────────────────────────────"
            local f3="───────────────"
            local f4="────────────"
            local f5="──────────"
            local marker=""
            case "$color_name" in
                "blue")    marker="🌐" ;;
                "green")   marker="📦" ;;
                "magenta") marker="🐧" ;;
                "yellow")  marker="🔨" ;;
                "cyan")    marker="🔧" ;;
                *)         marker="▪" ;;
            esac

            local header_row="${marker} [ ${title} ]|${f2}|${f3}|${f4}|${f5}"
            consolidated_table+=("$header_row")

            for item in "${items[@]}"; do
                IFS='|' read -r app_name current_ver path method min_required status source_latest <<< "$item"
                local version_display="version ${current_ver}"
                local green=$'\033[32m'
                local red=$'\033[31m'
                local reset=$'\033[0m'

                if [ "$current_ver" = "not installed" ] || [ "$current_ver" = "N/A" ]; then
                    version_display="(not installed)"
                elif [ "$current_ver" = "built-from-source" ]; then
                     version_display="version ${current_ver}"
                else
                     local is_compliant=true
                     if [[ "$method" == "npm" || "$app_name" == "Node.js" || "$app_name" == "npm" ]]; then
                         if [ "$source_latest" != "N/A" ] && [ "$source_latest" != "unknown" ]; then
                             if ! version_compare "$current_ver" "$source_latest"; then is_compliant=false; fi
                         fi
                     elif [[ "$app_name" == "fnm" || "$app_name" == "Python UV" || "$app_name" == "Go Language" ]]; then
                         if [ "$source_latest" != "N/A" ] && [ "$source_latest" != "unknown" ]; then
                             if ! version_compare "$current_ver" "$source_latest"; then is_compliant=false; fi
                         fi
                     elif [ "$min_required" != "unknown" ] && [ "$min_required" != "latest" ]; then
                         if ! version_compare "$current_ver" "$min_required"; then is_compliant=false; fi
                     fi
                     
                     if [ "$is_compliant" = true ]; then version_display="${green}version ${current_ver}${reset}"; else version_display="${red}⚠ version ${current_ver}${reset}"; fi
                fi
                
                local row1="${app_name}|${version_display}|${method}|${source_latest}|${status}"
                consolidated_table+=("$row1")

                local truncated_path
                truncated_path=$(truncate_path "$path" 45)
                local row2="...|${truncated_path}| | | "
                consolidated_table+=("$row2")
            done
        fi
    }

    add_section "CURL / WEB" curl_installer_tools "blue"
    add_section "NODE / NPM" npm_tools "green"
    add_section "APT / DEB" apt_tools "magenta"
    add_section "SOURCE" source_tools "yellow"
    add_section "CUSTOM" other_tools "cyan"

    log "INFO" "Consolidated Installation Strategy:"
    echo ""

    local table_widths="20,48,15,12,10"
    if command_exists "gum"; then
        {
            echo "App/Tool|Version / Path|Install Source|Latest Release|Status"
            printf '%s\n' "${consolidated_table[@]}"
        } | gum table --separator "|" --widths "$table_widths" --border rounded --border.foreground "6" --height 0 --print
    else
        printf "%-20s | %-48s | %-15s | %-12s | %-10s\n" "App/Tool" "Version / Path" "Install Source" "Latest Release" "Status"
        echo "─────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
        for row in "${consolidated_table[@]}"; do
            IFS='|' read -r name ver_path method min stat <<< "$row"
            printf "%-20s | %-48s | %-15s | %-12s | %-10s\n" "$name" "$ver_path" "$method" "$min" "$stat"
        done
    fi
    echo ""
}

display_version_analysis() {
    local -a audit_data=("$@")
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Version Analysis & Recommendations"
    log "INFO" "════════════════════════════════════════"
    echo ""
    log "INFO" "Analyzing version deltas and upgrade opportunities..."
    echo ""

    local -a analysis_rows=()
    for data in "${audit_data[@]}"; do
        IFS='|' read -r app_name current_ver path method min_required apt_avail source_latest status <<< "$data"
        local recommendation
        recommendation=$(generate_recommendation "$app_name" "$min_required" "$apt_avail" "$current_ver" "$source_latest" "$method")
        local installed_mark="✗"
        if [ "$current_ver" != "not installed" ] && [ "$current_ver" != "unknown" ] && [ "$current_ver" != "built-from-source" ]; then
            if [ "$min_required" = "unknown" ] || [ "$min_required" = "latest" ] || version_compare "$current_ver" "$min_required"; then installed_mark="✓"; else installed_mark="⚠"; fi
        elif [ "$current_ver" = "built-from-source" ]; then installed_mark="?"; fi
        local row="${app_name}|${min_required}|${apt_avail}|${current_ver} ${installed_mark}|${source_latest}|${recommendation}"
        analysis_rows+=("$row")
    done

    if command_exists "gum"; then
        local table_header="App/Tool|Min Required|APT Available|Installed|Source Latest|Recommendation"
        { echo "$table_header"; printf '%s\n' "${analysis_rows[@]}"; } | gum table --separator "|" --border rounded --border.foreground "6" --height 0 --print
    else
        printf "%-20s %-15s %-15s %-20s %-15s %-40s\n" "App/Tool" "Min Required" "APT Available" "Installed" "Source Latest" "Recommendation"
        printf "%-20s %-15s %-15s %-20s %-15s %-40s\n" "--------------------" "---------------" "---------------" "--------------------" "---------------" "----------------------------------------"
        for row in "${analysis_rows[@]}"; do
            IFS='|' read -r app min_req apt_ver inst_ver src_ver recommend <<< "$row"
            printf "%-20s %-15s %-15s %-20s %-15s %-40s\n" "$app" "$min_req" "$apt_ver" "$inst_ver" "$src_ver" "$recommend"
        done
    fi
    echo ""
    log "INFO" "Legend:"
    log "INFO" "  ✓ = Meets minimum requirement"
    log "INFO" "  ⚠ = Below minimum (CRITICAL)"
    log "INFO" "  ✗ = Not installed"
    log "INFO" "  ? = Built from source (version unknown)"
    log "INFO" "  ↑ = Newer version available"
    echo ""

    local upgrade_opportunities=0
    local critical_count=0
    local optimal_count=0
    for row in "${analysis_rows[@]}"; do
        IFS='|' read -r _ _ _ _ _ recommend <<< "$row"
        case "$recommend" in
            *"CRITICAL"*) ((critical_count++)) ;;
            *"UPGRADE"*) ((upgrade_opportunities++)) ;;
            *"OK"*) ((optimal_count++)) ;;
        esac
    done

    log "INFO" "════════════════════════════════════════"
    log "INFO" "Version Analysis Summary"
    log "INFO" "════════════════════════════════════════"
    [ "$critical_count" -gt 0 ] && log "ERROR" "⚠ CRITICAL upgrades needed: $critical_count"
    [ "$upgrade_opportunities" -gt 0 ] && log "WARNING" "↑ Upgrade opportunities: $upgrade_opportunities"
    [ "$optimal_count" -gt 0 ] && log "SUCCESS" "✓ Optimal installations: $optimal_count"
    echo ""
}
