#!/bin/bash

# Self-Hosted GitHub Actions Runner Setup for Astro Builds
# Based on: https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/use-in-a-workflow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
RUNNER_DIR="$HOME/actions-runner"
LOG_DIR="$SCRIPT_DIR/../logs"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "ERROR") echo -e "${RED}[$timestamp] [ERROR] $message${NC}" ;;
        "SUCCESS") echo -e "${GREEN}[$timestamp] [SUCCESS] $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}[$timestamp] [WARNING] $message${NC}" ;;
        "INFO") echo -e "${BLUE}[$timestamp] [INFO] $message${NC}" ;;
    esac

    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/runner-setup-$(date +%s).log"
}

# Check prerequisites
check_prerequisites() {
    log "INFO" "🔍 Checking prerequisites for self-hosted runner..."

    # Check if running on supported OS
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        log "ERROR" "❌ Self-hosted runners require Linux. Current OS: $OSTYPE"
        return 1
    fi

    # Check required tools
    local missing_tools=()
    for tool in curl tar gh node npm; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log "ERROR" "❌ Missing required tools: ${missing_tools[*]}"
        return 1
    fi

    # Check GitHub CLI authentication
    if ! gh auth status >/dev/null 2>&1; then
        log "ERROR" "❌ GitHub CLI not authenticated. Run: gh auth login"
        return 1
    fi

    log "SUCCESS" "✅ All prerequisites met"
}

# Download and configure GitHub Actions runner
setup_runner() {
    log "INFO" "📦 Setting up GitHub Actions runner..."

    # Create runner directory
    mkdir -p "$RUNNER_DIR"
    cd "$RUNNER_DIR"

    # Get latest runner release
    local runner_version
    runner_version=$(gh api repos/actions/runner/releases/latest --jq '.tag_name' | sed 's/v//')

    if [ -z "$runner_version" ]; then
        log "ERROR" "❌ Failed to get runner version"
        return 1
    fi

    log "INFO" "📥 Downloading runner version $runner_version..."

    # Download runner if not already present
    local runner_file="actions-runner-linux-x64-${runner_version}.tar.gz"
    if [ ! -f "$runner_file" ]; then
        curl -o "$runner_file" -L "https://github.com/actions/runner/releases/download/v${runner_version}/${runner_file}"

        # Verify checksum
        local expected_hash
        expected_hash=$(gh api repos/actions/runner/releases/latest --jq '.assets[] | select(.name | endswith("linux-x64-'$runner_version'.tar.gz")) | .browser_download_url' | xargs -I {} curl -sL {} | sha256sum | cut -d' ' -f1)

        tar xzf "$runner_file"
    fi

    log "SUCCESS" "✅ Runner downloaded and extracted"
}

# Configure runner for the repository
configure_runner() {
    log "INFO" "⚙️ Configuring runner for repository..."

    cd "$RUNNER_DIR"

    # Get repository information
    local repo_info
    repo_info=$(gh repo view --json owner,name)
    local owner=$(echo "$repo_info" | jq -r '.owner.login')
    local repo_name=$(echo "$repo_info" | jq -r '.name')

    # Get registration token
    local token
    token=$(gh api repos/"$owner"/"$repo_name"/actions/runners/registration-token --jq '.token')

    if [ -z "$token" ]; then
        log "ERROR" "❌ Failed to get registration token"
        return 1
    fi

    # Configure runner with custom labels for Astro builds
    local runner_name="astro-builder-$(hostname)-$(date +%s)"
    local labels="self-hosted,linux,x64,astro,nodejs,ghostty-config"

    log "INFO" "🏷️ Configuring runner with labels: $labels"

    # Run configuration (non-interactive)
    ./config.sh \
        --url "https://github.com/$owner/$repo_name" \
        --token "$token" \
        --name "$runner_name" \
        --labels "$labels" \
        --work "_work" \
        --unattended \
        --replace

    log "SUCCESS" "✅ Runner configured: $runner_name"
    echo "$runner_name" > "$LOG_DIR/runner-name.txt"
}

# Create systemd service for runner
create_service() {
    log "INFO" "🔧 Creating systemd service for runner..."

    local service_name="github-actions-runner-$(whoami)"
    local service_file="/etc/systemd/system/$service_name.service"

    # Create service file
    sudo tee "$service_file" > /dev/null << EOF
[Unit]
Description=GitHub Actions Runner for Astro Builds
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$RUNNER_DIR
ExecStart=$RUNNER_DIR/run.sh
Restart=always
RestartSec=15
StandardOutput=journal
StandardError=journal
SyslogIdentifier=github-actions-runner

# Environment variables for Astro builds
Environment=NODE_ENV=production
Environment=ASTRO_TELEMETRY_DISABLED=1
Environment=PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$HOME/.local/bin

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start service
    sudo systemctl daemon-reload
    sudo systemctl enable "$service_name"

    log "SUCCESS" "✅ Systemd service created: $service_name"
    echo "$service_name" > "$LOG_DIR/service-name.txt"
}

# Create Astro-specific workflow
create_astro_workflow() {
    log "INFO" "📄 Creating Astro build workflow for self-hosted runner..."

    local workflow_dir="$REPO_DIR/.github/workflows"
    mkdir -p "$workflow_dir"

    cat > "$workflow_dir/astro-self-hosted.yml" << 'EOF'
name: Astro Build (Self-Hosted)

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    name: Build Astro Site
    runs-on: [self-hosted, linux, x64, astro, nodejs]
    timeout-minutes: 10

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 'lts/*'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run Astro check
        run: npm run check

      - name: Build Astro site
        run: npm run build
        env:
          NODE_ENV: production
          ASTRO_TELEMETRY_DISABLED: 1

      - name: Verify build output
        run: |
          if [ ! -f "docs/index.html" ]; then
            echo "❌ Build failed - no index.html found"
            exit 1
          fi
          echo "✅ Build successful - $(du -sh docs/)"

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: astro-build
          path: docs/
          retention-days: 7

      - name: Deploy to GitHub Pages
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs
          cname: ${{ vars.CUSTOM_DOMAIN }}
EOF

    log "SUCCESS" "✅ Astro workflow created at .github/workflows/astro-self-hosted.yml"
}

# Start runner service
start_runner() {
    log "INFO" "🚀 Starting GitHub Actions runner..."

    if [ -f "$LOG_DIR/service-name.txt" ]; then
        local service_name
        service_name=$(cat "$LOG_DIR/service-name.txt")

        sudo systemctl start "$service_name"

        # Check if service started successfully
        if sudo systemctl is-active --quiet "$service_name"; then
            log "SUCCESS" "✅ Runner service started successfully"

            # Show runner status
            local runner_name
            if [ -f "$LOG_DIR/runner-name.txt" ]; then
                runner_name=$(cat "$LOG_DIR/runner-name.txt")
                log "INFO" "🏃 Runner '$runner_name' is now active"
            fi
        else
            log "ERROR" "❌ Failed to start runner service"
            return 1
        fi
    else
        log "ERROR" "❌ Service name not found - run setup first"
        return 1
    fi
}

# Stop runner service
stop_runner() {
    log "INFO" "🛑 Stopping GitHub Actions runner..."

    if [ -f "$LOG_DIR/service-name.txt" ]; then
        local service_name
        service_name=$(cat "$LOG_DIR/service-name.txt")

        sudo systemctl stop "$service_name"
        log "SUCCESS" "✅ Runner service stopped"
    else
        log "WARNING" "⚠️ Service name not found"
    fi
}

# Remove runner
remove_runner() {
    log "INFO" "🗑️ Removing GitHub Actions runner..."

    # Stop service first
    stop_runner

    # Remove from GitHub
    cd "$RUNNER_DIR"
    if [ -f "./config.sh" ]; then
        local repo_info
        repo_info=$(gh repo view --json owner,name)
        local owner=$(echo "$repo_info" | jq -r '.owner.login')
        local repo_name=$(echo "$repo_info" | jq -r '.name')

        local token
        token=$(gh api repos/"$owner"/"$repo_name"/actions/runners/remove-token --jq '.token')

        ./config.sh remove --token "$token"
    fi

    # Remove systemd service
    if [ -f "$LOG_DIR/service-name.txt" ]; then
        local service_name
        service_name=$(cat "$LOG_DIR/service-name.txt")

        sudo systemctl disable "$service_name"
        sudo rm -f "/etc/systemd/system/$service_name.service"
        sudo systemctl daemon-reload
    fi

    # Clean up files
    rm -rf "$RUNNER_DIR"
    rm -f "$LOG_DIR/runner-name.txt" "$LOG_DIR/service-name.txt"

    log "SUCCESS" "✅ Runner removed successfully"
}

# Show runner status
status_runner() {
    log "INFO" "📊 Checking runner status..."

    if [ -f "$LOG_DIR/service-name.txt" ]; then
        local service_name
        service_name=$(cat "$LOG_DIR/service-name.txt")

        echo "Service Status:"
        sudo systemctl status "$service_name" --no-pager -l

        if [ -f "$LOG_DIR/runner-name.txt" ]; then
            local runner_name
            runner_name=$(cat "$LOG_DIR/runner-name.txt")
            echo -e "\n${BLUE}Runner Name:${NC} $runner_name"
        fi

        # Show recent logs
        echo -e "\n${BLUE}Recent Logs:${NC}"
        sudo journalctl -u "$service_name" --no-pager -n 10

    else
        log "WARNING" "⚠️ No runner service found"
    fi
}

# Show help
show_help() {
    cat << EOF
GitHub Actions Self-Hosted Runner for Astro Builds

Usage: $0 [COMMAND]

Commands:
  setup       Complete runner setup (download, configure, create service)
  start       Start the runner service
  stop        Stop the runner service
  restart     Restart the runner service
  remove      Remove runner and cleanup
  status      Show runner status and logs
  workflow    Create/update Astro workflow for self-hosted runner
  help        Show this help message

Examples:
  $0 setup      # Initial setup of self-hosted runner
  $0 start      # Start the runner
  $0 status     # Check runner status
  $0 workflow   # Create Astro workflow

Note: This script configures a self-hosted runner specifically for Astro builds
with labels: [self-hosted, linux, x64, astro, nodejs, ghostty-config]
EOF
}

# Main execution
main() {
    mkdir -p "$LOG_DIR"

    case "${1:-help}" in
        "setup")
            check_prerequisites
            setup_runner
            configure_runner
            create_service
            create_astro_workflow
            log "SUCCESS" "🎉 Self-hosted runner setup complete!"
            log "INFO" "💡 Run '$0 start' to start the runner"
            ;;
        "start")
            start_runner
            ;;
        "stop")
            stop_runner
            ;;
        "restart")
            stop_runner
            sleep 2
            start_runner
            ;;
        "remove")
            remove_runner
            ;;
        "status")
            status_runner
            ;;
        "workflow")
            create_astro_workflow
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi