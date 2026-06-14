function __app_icon --description 'Emoji for a command, derived from its apt Section (cached per session)'
    # Resolve order: per-session cache -> curated override -> apt Section -> ⚡.
    # The override wins (curated icons beat generic Section icons and skip the
    # dpkg cost); the apt Section map (__app_section_icon) auto-covers everything
    # else with no per-tool list to maintain. Single-codepoint emoji only.

    set -l words (string split ' ' -- (string trim -- $argv))
    set -q words[1]; or return
    set -l first $words[1]   # remember the leading token for the bare-wrapper case

    # peel leading sudo/doas/wrappers and real NAME=value assignments
    while set -q words[1]
        switch $words[1]
            case sudo doas command nice nohup time env
                set -e words[1]
            case '*=*'
                # only a true `NAME=value` assignment (not e.g. /opt/a=b/tool)
                if string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- $words[1]
                    set -e words[1]
                else
                    break
                end
            case '*'
                break
        end
    end
    set -q words[1]; or set words $first   # bare wrapper -> icon the wrapper itself
    set -l c (string replace -r '.*/' '' -- $words[1])
    test -n "$c"; or return

    # --- per-session cache (linear scan; the command set per session is small) ---
    for e in $__appicon_cache
        set -l kv (string split -m1 '=' -- $e)
        if test "$kv[1]" = "$c"
            echo $kv[2]
            return
        end
    end

    set -l icon ''

    # --- curated override (authoritative; also avoids the dpkg lookup) ---
    switch $c
        case nvim vim vi hx helix nano;         set icon 📝
        case claude claude-code;                set icon 🤖
        case codex;                             set icon 🧠
        case agy;                               set icon 👾
        case gemini;                            set icon ✨
        case ollama vllm llamacpp;              set icon 🦙
        case hf huggingface-cli;                set icon 🤗
        case comfyui comfy;                     set icon 🎨
        case uv uvx;                            set icon 🐍
        case bun;                               set icon 🥟
        case deno;                              set icon 🦕
        case node nodejs npm npx pnpm yarn fnm; set icon 📦
        case cargo rustc rustup;                set icon 🦀
        case go;                                set icon 🐹
        case gh;                                set icon 🐙
        case starship;                          set icon 🚀
        case zoxide z;                          set icon 📂
        case codacy codacy-cli codacy-cli-v2;   set icon ✅
        case ghostty;                           set icon 👻
        case nvidia-smi nvtop gpustat nvitop;   set icon 🎮
        case aws gcloud az;                     set icon ⛅
        case kubectl k9s helm;                  set icon 🚢
    end

    # --- apt Section (only if no override matched; real on-disk binaries only) ---
    if test -z "$icon"
        set -l bin (command -v $c 2>/dev/null)
        if test -n "$bin"; and test -e "$bin"
            set bin (realpath -- "$bin" 2>/dev/null; or echo $bin)
            set -l owner (dpkg -S "$bin" 2>/dev/null | head -1)
            if test -n "$owner"
                # "pkg: path" or "pkg1, pkg2: path" (-m1 also drops any :arch on pkg)
                set -l pkg (string trim -- (string split ',' -- (string split -m1 ':' -- $owner)[1])[1])
                if test -n "$pkg"
                    set -l section (dpkg-query -W -f='${Section}' "$pkg" 2>/dev/null)
                    test -n "$section"; and set icon (__app_section_icon $section)
                end
            end
        end
    end

    test -n "$icon"; or set icon ⚡

    # --- cache the result (bounded to the most recent 256 commands) ---
    set -g __appicon_cache $__appicon_cache "$c=$icon"
    if test (count $__appicon_cache) -gt 256
        set -g __appicon_cache $__appicon_cache[-256..-1]
    end
    echo $icon
end
