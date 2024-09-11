#!/bin/bash

# Set strict mode
set -euo pipefail
IFS=$'\n\t'

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/setup_log.txt"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    log "Error on line $line_number: Command exited with status $exit_code"
    exit $exit_code
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Function to install a package using Homebrew
install_brew_package() {
    if ! brew list "$1" &>/dev/null; then
        log "Installing $1..."
        brew install "$1"
    else
        log "$1 is already installed."
    fi
}

# Function to install a cask using Homebrew
install_brew_cask() {
    if ! brew list --cask "$1" &>/dev/null; then
        log "Installing $1..."
        brew install --cask "$1"
    else
        log "$1 is already installed."
    fi
}

# Set up SSH for GitHub
setup_github_ssh() {
    local ssh_key_file=""

    # Check for existing SSH keys
    for key in id_rsa id_ed25519 id_ecdsa; do
        if [[ -f "$HOME/.ssh/${key}" ]]; then
            ssh_key_file="$HOME/.ssh/${key}"
            break
        fi
    done

    if [[ -z "$ssh_key_file" ]]; then
        log "No existing SSH key found. Generating a new ED25519 key..."
        ssh-keygen -t ed25519 -C "lotfi@ninetailed.com" -f "$HOME/.ssh/id_ed25519" -N ""
        ssh_key_file="$HOME/.ssh/id_ed25519"
    else
        log "Existing SSH key found: $ssh_key_file"
    fi

    # Ensure the SSH agent is running
    eval "$(ssh-agent -s)"
    ssh-add "$ssh_key_file"

    # Display the public key
    log "Your public key is:"
    cat "${ssh_key_file}.pub"
    log "Please ensure this key is added to your GitHub account."
    read -p "Press Enter once you've added the key to your GitHub account..."

    # Test the SSH connection
    log "Testing SSH connection to GitHub..."
    if ssh -T git@github.com 2>&1 | grep -q "Hi Lotfi-Arif! You've successfully authenticated"; then
        log "SSH connection to GitHub successful"
    else
        log "SSH connection test to GitHub failed. Please check your GitHub settings and try again."
        return 1
    fi
}

# Configure Git
configure_git() {
    log "Configuring Git..."
    git config --global user.email "lotfi@ninetailed.com"
    git config --global user.name "Lotfi Arif"
}

# Install and configure Zsh
install_zsh() {
    install_brew_package "zsh"
    if [[ $SHELL != */zsh ]]; then
        log "Setting Zsh as the default shell..."
        chsh -s "$(which zsh)"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log "Oh My Zsh is already installed."
    fi
}

# Install JetBrains Mono Nerd Font
install_jetbrains_mono() {
    log "Installing JetBrains Mono Nerd Font (non-Mono version)..."
    brew tap homebrew/cask-fonts
    install_brew_cask "font-jetbrains-mono-nerd-font"
    log "Please manually set your terminal font to 'JetBrainsMono Nerd Font' (not the Mono version) after installation."
}

# Install and configure Powerlevel10k theme
install_powerlevel10k() {
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ ! -d "$p10k_dir" ]; then
        log "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
        sed -i '' 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
    else
        log "Powerlevel10k theme is already installed."
    fi
}

# Install NVM and Node.js
install_nvm() {
    if [ ! -d "$HOME/.nvm" ]; then
        log "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        log "NVM is already installed."
    fi

    log "Installing Node.js 18.20.3..."
    nvm install 18.20.3
    nvm use 18.20.3
    nvm alias default 18.20.3

    npm install -g yarn
}

# Install Neovim 0.10 and dependencies
install_neovim() {
    log "Installing Neovim 0.10 and dependencies..."
    brew install neovim --HEAD # This installs the latest development version, which should be 0.10 or newer
    install_brew_package "ripgrep"
    install_brew_package "gcc"
    install_brew_package "make"
}

# Install NvChad
install_nvchad() {
    log "Preparing for NvChad installation..."

    # Delete old Neovim folders
    log "Removing old Neovim configurations..."
    rm -rf ~/.config/nvim
    rm -rf ~/.local/share/nvim
    rm -rf ~/.cache/nvim

    log "Installing NvChad..."
    git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
    log "NvChad installed. Please run 'nvim' to complete the setup."
    log "IMPORTANT: After running 'nvim', choose 'Yes' to install the example config if prompted."
}

# Install Doppler CLI
install_doppler() {
    # Prerequisite. gnupg is required for binary signature verification
    brew install gnupg

    # Next, install using brew (use `doppler update` for subsequent updates)
    brew install dopplerhq/cli/doppler

    # Verify the installation
    doppler --version
    if [ $? -ne 0 ]; then
        log "Doppler CLI installation failed. Please check the logs for errors."
        return 1
    fi
    log "Doppler CLI installed. Run 'doppler login' to authenticate."
}

# Install Cloudflare Wrangler CLI
install_wrangler() {
    log "Installing Cloudflare Wrangler CLI..."
    npm install -g @cloudflare/wrangler
}

# Install applications using Homebrew Cask
install_apps() {
    local apps=(
        "obsidian"
        "discord"
        "docker"
        "1password"
        "iterm2"
        "stremio"
        "expressvpn"
        "zen-browser"
        "visual-studio-code"
    )

    for app in "${apps[@]}"; do
        install_brew_cask "$app"
    done
}

# Main setup function
main_setup() {
    log "Starting setup process..."

    install_zsh
    install_oh_my_zsh
    setup_github_ssh
    configure_git
    install_jetbrains_mono
    install_powerlevel10k
    install_nvm
    install_neovim
    install_nvchad
    install_doppler
    install_wrangler
    install_apps

    log "Setup process completed successfully!"
    log "Please restart your terminal or run 'source ~/.zshrc' for all changes to take effect."
    log "Remember to run 'nvim' to complete the NvChad setup."
}

# Run the main setup function
main_setup
