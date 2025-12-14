#!/bin/bash
# install_zsh.sh

echo "Installing zsh..."

# Smart apt update - skip if cache is fresh (< 5 min)
APT_LISTS="/var/lib/apt/lists"
CACHE_AGE=$(($(date +%s) - $(stat -c%Y "$APT_LISTS" 2>/dev/null || echo 0)))
if [[ $CACHE_AGE -gt 300 ]]; then
    sudo stdbuf -oL apt-get update
else
    echo "APT cache fresh (${CACHE_AGE}s ago), skipping update"
fi
sudo stdbuf -oL apt-get install -y zsh

# Install/Update Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh is already installed. Updating..."
    # Use git to update if it's a git repo
    if [ -d "$HOME/.oh-my-zsh/.git" ]; then
        git -C "$HOME/.oh-my-zsh" pull
    else
        echo "OMZ directory exists but not a git repo. Skipping update."
    fi
else
    echo "Installing Oh My Zsh..."
    # Unattended install
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Ensure zsh is default shell?
# if [ "$SHELL" != "$(which zsh)" ]; then
#     echo "Changing default shell to zsh..."
#     chsh -s "$(which zsh)"
# fi
