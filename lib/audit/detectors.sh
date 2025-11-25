#!/usr/bin/env bash
# lib/audit/detectors.sh - Application status detection logic

#
# GitHub Repository Mapping for Source Version Detection
#
declare -gA SOURCE_REPOS=(
    ["fastfetch"]="fastfetch-cli/fastfetch"
    ["go"]="golang/go"
    ["gum"]="charmbracelet/gum"
    ["glow"]="charmbracelet/glow"
    ["vhs"]="charmbracelet/vhs"
    ["feh"]="derf/feh"
    ["zig"]="ziglang/zig"
    ["node"]="nodejs/node"
    ["fnm"]="Schniz/fnm"
    ["uv"]="astral-sh/uv"
    ["ttyd"]="tsl0922/ttyd"
)

# Cache directory for version checks (5 minute TTL)
readonly VERSION_CACHE_DIR="${HOME}/.cache/ghostty-system-audit"
readonly VERSION_CACHE_TTL=300

init_version_cache() {
    mkdir -p "$VERSION_CACHE_DIR"
}

get_cached_version() {
    local cache_key="$1"
    local cache_file="${VERSION_CACHE_DIR}/${cache_key}"

    if [ -f "$cache_file" ]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [ "$cache_age" -lt "$VERSION_CACHE_TTL" ]; then
            cat "$cache_file"
            return 0
        fi
    fi
    return 1
}

set_cached_version() {
    local cache_key="$1"
    local version="$2"
    local cache_file="${VERSION_CACHE_DIR}/${cache_key}"
    echo "$version" > "$cache_file"
}

version_compare() {
    local current="$1"
    local expected="$2"

    # Remove 'v' prefix
    current="${current#v}"
    expected="${expected#v}"

    # Extract major.minor.patch
    local current_major current_minor current_patch
    current_major=$(echo "$current" | cut -d. -f1 | grep -oP '\d+' || echo "0")
    current_minor=$(echo "$current" | cut -d. -f2 | grep -oP '\d+' || echo "0")
    current_patch=$(echo "$current" | cut -d. -f3 | grep -oP '\d+' || echo "0")

    local expected_major expected_minor expected_patch
    expected_major=$(echo "$expected" | cut -d. -f1 | grep -oP '\d+' || echo "0")
    expected_minor=$(echo "$expected" | cut -d. -f2 | grep -oP '\d+' || echo "0")
    expected_patch=$(echo "$expected" | cut -d. -f3 | grep -oP '\d+' || echo "0")

    if [ "$current_major" -gt "$expected_major" ]; then return 0; fi
    if [ "$current_major" -eq "$expected_major" ]; then
        if [ "$current_minor" -gt "$expected_minor" ]; then return 0; fi
        if [ "$current_minor" -eq "$expected_minor" ]; then
            if [ "$current_patch" -ge "$expected_patch" ]; then return 0; fi
        fi
    fi
    return 1
}

detect_apt_version() {
    local package_name="$1"
    local cache_key="apt-${package_name}"

    local cached_version
    if cached_version=$(get_cached_version "$cache_key"); then
        echo "$cached_version"
        return 0
    fi

    local apt_version="N/A"
    if timeout 5s apt-cache policy "$package_name" >/dev/null 2>&1; then
        apt_version=$(apt-cache policy "$package_name" 2>/dev/null | grep "Candidate:" | awk '{print $2}' | grep -oP '^[\d.]+' || echo "N/A")
    fi

    set_cached_version "$cache_key" "$apt_version"
    echo "$apt_version"
}

detect_source_version() {
    local app_name="$1"

    # Special handling for Go
    if [ "$app_name" = "go" ]; then
        local cache_key="go-dev-latest"
        local cached_version
        if cached_version=$(get_cached_version "$cache_key"); then
            echo "$cached_version"
            return 0
        fi
        
        local source_version="N/A"
        if command -v curl >/dev/null 2>&1; then
            local go_json
            if go_json=$(timeout 5s curl -s "https://go.dev/dl/?mode=json"); then
                source_version=$(echo "$go_json" | grep -oP '"version": "\K[^"]+' | head -1 | sed 's/^go//')
            fi
        fi
        set_cached_version "$cache_key" "$source_version"
        echo "$source_version"
        return 0
    fi

    local repo="${SOURCE_REPOS[$app_name]:-}"
    if [ -z "$repo" ]; then echo "N/A"; return 1; fi

    local cache_key="github-${repo//\//-}"
    local cached_version
    if cached_version=$(get_cached_version "$cache_key"); then
        echo "$cached_version"
        return 0
    fi

    local source_version="N/A"
    if command_exists "gh"; then
        local api_response
        if api_response=$(timeout 5s gh api "repos/${repo}/releases/latest" 2>&1); then
            if echo "$api_response" | grep -q '"tag_name"'; then
                source_version=$(echo "$api_response" | grep -oP '"tag_name":\s*"\K[^"]+' || echo "N/A")
                source_version="${source_version#v}"
                source_version=$(echo "$source_version" | grep -oP '^\d+\.\d+(\.\d+)?' || echo "N/A")
            fi
        fi
    elif command_exists "curl"; then
        # Fallback to curl if gh not available
        local api_response
        if api_response=$(timeout 5s curl -s "https://api.github.com/repos/${repo}/releases/latest"); then
             source_version=$(echo "$api_response" | grep -oP '"tag_name":\s*"\K[^"]+' | head -1 || echo "N/A")
             source_version="${source_version#v}"
             source_version=$(echo "$source_version" | grep -oP '^\d+\.\d+(\.\d+)?' || echo "N/A")
        fi
    fi

    set_cached_version "$cache_key" "$source_version"
    echo "$source_version"
}

detect_npm_version() {
    local package_name="$1"
    local command_name="$2"
    local cache_key="npm-${package_name//\//-}"

    local installed_version="not installed"
    local latest_version="N/A"

    if command -v "$command_name" >/dev/null 2>&1; then
        installed_version=$("$command_name" --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        if [ "$installed_version" = "unknown" ]; then
            installed_version=$(npm list -g "$package_name" --depth=0 2>/dev/null | grep "$package_name" | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        fi
    fi

    local cached_latest
    if cached_latest=$(get_cached_version "$cache_key"); then
        latest_version="$cached_latest"
    else
        if command -v npm >/dev/null 2>&1; then
            local npm_response
            if npm_response=$(timeout 5s npm view "$package_name" version 2>&1); then
                latest_version=$(echo "$npm_response" | grep -oP '^\d+\.\d+\.\d+' || echo "N/A")
                set_cached_version "$cache_key" "$latest_version"
            fi
        fi
    fi

    echo "${installed_version}|${latest_version}"
}

detect_app_status() {
    local app_name="$1"
    local command_name="$2"
    local version_cmd="$3"
    local expected_version="${4:-unknown}"

    local current_version="not installed"
    local install_path="N/A"
    local install_method="missing"
    local status="INSTALL"

    if command_exists "$command_name"; then
        install_path=$(command -v "$command_name")
        if [ -n "$version_cmd" ]; then
            current_version=$(eval "$version_cmd" 2>/dev/null || echo "unknown")
        fi

        case "$install_path" in
            /usr/bin/*)
                if dpkg -l "$command_name" 2>/dev/null | grep -q "^ii"; then install_method="apt"; else install_method="binary"; fi ;;
            /usr/local/bin/*) install_method="source" ;;
            "$HOME/.local/bin/"*) install_method="user-binary" ;;
            */node_modules/.bin/*) install_method="npm" ;;
            "$HOME/.cargo/bin/"*) install_method="cargo" ;;
            *) install_method="other" ;;
        esac

        if [ "$expected_version" != "unknown" ] && [ "$current_version" != "unknown" ]; then
            if version_compare "$current_version" "$expected_version"; then status="OK"; else status="UPGRADE"; fi
        else
            status="OK"
        fi
    fi
    echo "${app_name}|${current_version}|${install_path}|${install_method}|${expected_version}|${status}"
}

detect_app_status_enhanced() {
    local app_name="$1"
    local command_name="$2"
    local version_cmd="$3"
    local expected_version="${4:-unknown}"
    local apt_package="${5:-$command_name}"
    local source_key="${6:-${app_name,,}}"

    local basic_status
    basic_status=$(detect_app_status "$app_name" "$command_name" "$version_cmd" "$expected_version")
    IFS='|' read -r name current_ver path method expected status <<< "$basic_status"

    local apt_avail="N/A"
    if [ "$apt_package" != "none" ]; then apt_avail=$(detect_apt_version "$apt_package"); fi

    local source_latest="N/A"
    if [ "$source_key" != "none" ] && [ -n "${SOURCE_REPOS[$source_key]:-}" ]; then
        source_latest=$(detect_source_version "$source_key")
    fi

    # Recalculate status based on source_latest if available (Enforce Latest)
    if [ "$source_latest" != "N/A" ] && [ "$source_latest" != "unknown" ] && [ "$current_ver" != "not installed" ] && [ "$current_ver" != "unknown" ] && [ "$current_ver" != "built-from-source" ]; then
        if ! version_compare "$current_ver" "$source_latest"; then
            status="UPGRADE"
        fi
    fi

    echo "${name}|${current_ver}|${path}|${method}|${expected}|${apt_avail}|${source_latest}|${status}"
}

detect_npm_package_status() {
    local display_name="$1"
    local npm_package="$2"
    local command_name="$3"
    local min_required="${4:-latest}"

    local npm_info
    npm_info=$(detect_npm_version "$npm_package" "$command_name")
    local installed_version="${npm_info%%|*}"
    local latest_version="${npm_info##*|}"

    local install_path="N/A"
    if command -v "$command_name" >/dev/null 2>&1; then install_path=$(command -v "$command_name"); fi

    local install_method="missing"
    if [ "$installed_version" != "not installed" ]; then install_method="npm"; fi

    local status="INSTALL"
    if [ "$installed_version" != "not installed" ] && [ "$installed_version" != "unknown" ]; then
        if [ "$min_required" = "latest" ]; then
            if [ "$latest_version" != "N/A" ] && [ "$latest_version" != "unknown" ]; then
                if ! version_compare "$installed_version" "$latest_version"; then status="UPGRADE"; else status="OK"; fi
            else
                status="OK"
            fi
        elif version_compare "$installed_version" "$min_required"; then
            status="OK"
        else
            status="UPGRADE"
        fi
    fi

    echo "${display_name}|${installed_version}|${install_path}|${install_method}|${min_required}|N/A|${latest_version}|${status}"
}

detect_omz_status() {
    local omz_dir="$HOME/.oh-my-zsh"
    local current_version="not installed"
    local latest_version="N/A"
    local status="INSTALL"
    local install_path="N/A"
    local install_method="missing"

    if [ -d "$omz_dir" ]; then
        install_path="$omz_dir"
        install_method="source"
        if command_exists "git"; then
            current_version=$(git -C "$omz_dir" rev-parse --short HEAD 2>/dev/null || echo "unknown")
            local cache_key="github-ohmyzsh-ohmyzsh-master"
            if ! latest_version=$(get_cached_version "$cache_key"); then
                if command_exists "gh"; then
                    latest_version=$(timeout 5s gh api repos/ohmyzsh/ohmyzsh/commits/master -q .sha 2>/dev/null | cut -c1-7 || echo "N/A")
                elif command_exists "curl"; then
                    latest_version=$(timeout 5s curl -s "https://api.github.com/repos/ohmyzsh/ohmyzsh/commits/master" | grep -oP '"sha": "\K[^"]+' | head -1 | cut -c1-7 || echo "N/A")
                fi
                set_cached_version "$cache_key" "$latest_version"
            fi
            if [ "$current_version" != "unknown" ] && [ "$latest_version" != "N/A" ]; then
                if [ "$current_version" = "$latest_version" ]; then status="OK"; else status="UPGRADE"; fi
            elif [ "$current_version" != "unknown" ]; then status="OK"; fi
        else
            current_version="installed"
            status="OK"
        fi
    fi
    echo "Oh My ZSH|${current_version}|${install_path}|${install_method}|latest|N/A|${latest_version}|${status}"
}
