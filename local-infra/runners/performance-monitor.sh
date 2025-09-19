#!/bin/bash
# Performance monitoring for Ghostty
echo "📊 Monitoring Ghostty performance..."

monitor_performance() {
    local test_mode="$1"
    local log_dir="$(dirname "$0")/../logs"

    # Startup time measurement
    if command -v ghostty >/dev/null 2>&1; then
        local startup_time
        startup_time=$(time (ghostty --version >/dev/null 2>&1) 2>&1 | grep real | awk '{print $2}' || echo "0m0.000s")

        # Configuration load time
        local config_time
        config_time=$(time (ghostty +show-config >/dev/null 2>&1) 2>&1 | grep real | awk '{print $2}' || echo "0m0.000s")

        # Store results
        cat > "$log_dir/performance-$(date +%s).json" << EOL
{
    "timestamp": "$(date -Iseconds)",
    "startup_time": "$startup_time",
    "config_load_time": "$config_time",
    "test_mode": "$test_mode",
    "optimizations": {
        "cgroup_single_instance": $(grep -q "linux-cgroup.*single-instance" ~/.config/ghostty/config 2>/dev/null && echo "true" || echo "false"),
        "shell_integration_detect": $(grep -q "shell-integration.*detect" ~/.config/ghostty/config 2>/dev/null && echo "true" || echo "false")
    }
}
EOL
        echo "✅ Performance data collected"
    else
        echo "⚠️ Ghostty not found for performance testing"
    fi
}

case "$1" in
    --test) monitor_performance "test" ;;
    --baseline) monitor_performance "baseline" ;;
    --compare) monitor_performance "compare" ;;
    *) monitor_performance "default" ;;
esac
