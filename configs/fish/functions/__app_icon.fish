function __app_icon --description 'Emoji for a command, derived from its apt Section (cached per session)'
    # Resolve order: per-session cache -> apt Section -> non-apt override -> ⚡.
    # The apt Section map (__app_section_icon) does the heavy lifting, so newly
    # apt-installed tools get an icon automatically with no per-tool list to keep.
    # All emoji are single-codepoint (render in GTK/AppKit tab labels).

    # peel leading sudo/doas/wrappers and VAR=value assignments to reach the app
    set -l words (string split ' ' -- (string trim -- $argv))
    while set -q words[1]
        switch $words[1]
            case sudo doas command nice nohup time; set -e words[1]
            case '*=*';                             set -e words[1]
            case '*';                               break
        end
    end
    set -q words[1]; or return
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

    # --- apt Section (only for real on-disk binaries; skips builtins/functions) ---
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

    # --- non-apt overrides (AI/ML + tools installed outside apt) ---
    if test -z "$icon"
        switch $c
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
    end

    test -n "$icon"; or set icon ⚡

    # --- cache the result (bounded to the most recent 256 commands) ---
    set -g __appicon_cache $__appicon_cache "$c=$icon"
    if test (count $__appicon_cache) -gt 256
        set -g __appicon_cache $__appicon_cache[-256..-1]
    end
    echo $icon
end
