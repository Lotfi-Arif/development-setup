#!/bin/bash

# Set strict mode
set -euo pipefail
IFS=$'\n\t'

# Function to handle errors
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo "Error on line $line_number: Command exited with status $exit_code"
    exit $exit_code
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package if it's not already installed
install_if_not_exists() {
    if ! command_exists "$1"; then
        echo "Installing $1..."
        sudo apt install -y "$1" || {
            echo "Failed to install $1. Please check your internet connection and try again."
            return 1
        }
    else
        echo "$1 is already installed."
    fi
}

# Function to run commands with error checking
run_command() {
    if ! "$@"; then
        echo "Command failed: $*"
        return 1
    fi
}

# Update package lists
echo "Updating package lists..."
if ! sudo apt update; then
    echo "Failed to update package lists. Please check your internet connection and try again."
    exit 1
fi
echo "Package lists updated!"

# Install essential packages
essential_packages=(
    "zsh"
    "curl"
    "git"
    "unzip"
    "wget"
    "apt-transport-https"
    "ca-certificates"
    "gnupg"
    "software-properties-common"
    "python3"
    "python3-pip"
    "flatpak"
)

for package in "${essential_packages[@]}"; do
    install_if_not_exists "$package" || exit 1
done

# Install Oh My ZSH
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My ZSH..."
    if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        echo "Failed to install Oh My ZSH. Please check your internet connection and try again."
        exit 1
    fi
    echo "Oh My ZSH installed!"
else
    echo "Oh My ZSH is already installed."
fi

# Install ZSH plugins
zsh_plugins=(
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "fast-syntax-highlighting"
    "zsh-autocomplete"
)

for plugin in "${zsh_plugins[@]}"; do
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin" ]; then
        echo "Installing $plugin..."
        if ! git clone "https://github.com/zsh-users/$plugin.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"; then
            echo "Failed to install $plugin. Please check your internet connection and try again."
            exit 1
        fi
    else
        echo "$plugin is already installed."
    fi
done

# Install JetBrains Mono Nerd Font
if [ ! -f "$HOME/.local/share/fonts/JetBrains Mono Regular Nerd Font Complete.ttf" ]; then
    echo "Installing JetBrains Mono Nerd Font..."
    mkdir -p "$HOME/.local/share/fonts"
    if ! wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip; then
        echo "Failed to download JetBrains Mono Nerd Font. Please check your internet connection and try again."
        exit 1
    fi
    unzip JetBrainsMono.zip -d "$HOME/.local/share/fonts" || {
        echo "Failed to extract JetBrains Mono Nerd Font."
        exit 1
    }
    fc-cache -fv
    rm JetBrainsMono.zip
    echo "JetBrains Mono Nerd Font installed!"
else
    echo "JetBrains Mono Nerd Font is already installed."
fi

# Install Powerlevel10k theme
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k theme..."
    if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"; then
        echo "Failed to install Powerlevel10k theme. Please check your internet connection and try again."
        exit 1
    fi
    echo "Powerlevel10k theme installed!"
else
    echo "Powerlevel10k theme is already installed."
fi

# Update .zshrc
echo "Updating .zshrc..."
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc" || {
    echo "Failed to update ZSH theme in .zshrc"
    exit 1
}
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)/' "$HOME/.zshrc" || {
    echo "Failed to update plugins in .zshrc"
    exit 1
}
echo "Updated .zshrc!"

# Install NVM (Node Version Manager)
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    NVM_VERSION="0.40.0"
    if ! curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash; then
        echo "Failed to install NVM. Please check your internet connection and try again."
        exit 1
    fi
    echo "NVM installed!"
else
    echo "NVM is already installed."
fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js and Yarn
if ! command_exists node; then
    echo "Installing Node.js..."
    if ! nvm install --lts; then
        echo "Failed to install Node.js. Please check your internet connection and try again."
        exit 1
    fi
    echo "Node.js installed!"

    echo "Installing Yarn..."
    if ! npm install -g yarn; then
        echo "Failed to install Yarn. Please check your internet connection and try again."
        exit 1
    fi
    echo "Yarn installed!"
else
    echo "Node.js is already installed."
fi

# Install pipenv
if ! command_exists pipenv; then
    echo "Installing pipenv..."
    if ! pip3 install pipenv; then
        echo "Failed to install pipenv. Please check your internet connection and try again."
        exit 1
    fi
    echo "Pipenv installed!"
else
    echo "Pipenv is already installed."
fi

# Install Go (Golang)
if ! command_exists go; then
    echo "Installing Go (Golang)..."
    GO_VERSION="1.23.0"
    if ! wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"; then
        echo "Failed to download Go. Please check your internet connection and try again."
        exit 1
    fi
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.zshrc"
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
    echo "Go (Golang) installed!"
else
    echo "Go (Golang) is already installed."
fi

# Install Doppler CLI
if ! command_exists doppler; then
    echo "Installing Doppler CLI..."
    if ! curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -; then
        echo "Failed to add Doppler's GPG key. Please check your internet connection and try again."
        exit 1
    fi
    echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
    if ! sudo apt-get update && sudo apt-get install -y doppler; then
        echo "Failed to install Doppler CLI. Please check your internet connection and try again."
        exit 1
    fi
    echo "Doppler CLI installed!"
else
    echo "Doppler CLI is already installed."
fi

# Install Docker and Docker Compose
if ! command_exists docker; then
    echo "Installing Docker..."
    if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -; then
        echo "Failed to add Docker's GPG key. Please check your internet connection and try again."
        exit 1
    fi
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    if ! sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io; then
        echo "Failed to install Docker. Please check your internet connection and try again."
        exit 1
    fi
    sudo usermod -aG docker "$USER"
    echo "Docker installed!"
else
    echo "Docker is already installed."
fi

if ! command_exists docker-compose; then
    echo "Installing Docker Compose..."
    if ! sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
        echo "Failed to download Docker Compose. Please check your internet connection and try again."
        exit 1
    fi
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed!"
else
    echo "Docker Compose is already installed."
fi

# GIT configuration
echo "Configuring GIT..."
git config --global user.email "lotfi@ninetailed.com"
git config --global user.name "Lotfi Arif"

# Add flathub repo
echo "Adding flathub repo..."
if ! flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
    echo "Failed to add Flathub repository. Please check your internet connection and try again."
    exit 1
fi

# Install flatpak applications
flatpak_apps=(
    "com.stremio.Stremio"
    "com.visualstudio.code"
    "md.obsidian.Obsidian"
    "com.slack.Slack"
    "com.getpostman.Postman"
    "com.github.alpaca"
    "com.github.lainsce.notesnook"
)

for app in "${flatpak_apps[@]}"; do
    echo "Installing $app..."
    if ! flatpak install -y flathub "$app"; then
        echo "Failed to install $app. Continuing with other installations."
    fi
done

# Install AnyDesk
if ! command_exists anydesk; then
    echo "Installing AnyDesk..."
    if ! wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo apt-key add -; then
        echo "Failed to add AnyDesk's GPG key. Please check your internet connection and try again."
        exit 1
    fi
    echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
    if ! sudo apt update && sudo apt install -y anydesk; then
        echo "Failed to install AnyDesk. Please check your internet connection and try again."
        exit 1
    fi
    echo "AnyDesk installed!"
else
    echo "AnyDesk is already installed."
fi

# Install Steam
if ! command_exists steam; then
    echo "Installing Steam..."
    if ! sudo apt install -y steam; then
        echo "Failed to install Steam. Please check your internet connection and try again."
        exit 1
    fi
    echo "Steam installed!"
else
    echo "Steam is already installed."
fi

# Install WebStorm
if [ ! -d "/opt/webstorm" ]; then
    echo "Installing WebStorm..."
    WEBSTORM_VERSION="2024.2"
    if ! wget -O webstorm.tar.gz "https://download.jetbrains.com/webstorm/WebStorm-${WEBSTORM_VERSION}.tar.gz"; then
        echo "Failed to download WebStorm. Please check your internet connection and try again."
        exit 1
    fi
    sudo tar -xzf webstorm.tar.gz -C /opt || {
        echo "Failed to extract WebStorm."
        exit 1
    }
    rm webstorm.tar.gz
    sudo mv "/opt/WebStorm-${WEBSTORM_VERSION}" /opt/webstorm
    echo "WebStorm installed!"
else
    echo "WebStorm is already installed."
fi

# Install Flutter
if ! command_exists flutter; then
    echo "Installing Flutter..."
    if ! sudo apt-get install -y libglu1-mesa; then
        echo "Failed to install libglu1-mesa. Please check your internet connection and try again."
        exit 1
    fi
    if ! sudo snap install android-studio --classic; then
        echo "Failed to install Android Studio. Please check your internet connection and try again."
        exit 1
    fi
    if ! git clone https://github.com/flutter/flutter.git "$HOME/flutter"; then
        echo "Failed to clone Flutter repository. Please check your internet connection and try again."
        exit 1
    fi
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> "$HOME/.zshrc"
    source "$HOME/.zshrc"
    if ! flutter doctor; then
        echo "Flutter doctor reported issues. Please review and resolve them manually."
    fi
    echo "Flutter installed!"
else
    echo "Flutter is already installed."
fi

# Install Neovim
if ! command_exists nvim; then
    echo "Installing Neovim..."
    if ! sudo add-apt-repository ppa:neovim-ppa/unstable; then
        echo "Failed to add Neovim PPA. Please check your internet connection and try again."
        exit 1
    fi
    if ! sudo apt-get update && sudo apt-get install -y neovim; then
        echo "Failed to install Neovim. Please check your internet connection and try again."
        exit 1
    fi
    echo "Neovim installed!"
else
    echo "Neovim is already installed."
fi

# Install ripgrep (required for Telescope)
if ! command_exists rg; then
    echo "Installing ripgrep..."
    if ! sudo apt-get install -y ripgrep; then
        echo "Failed to install ripgrep. Please check your internet connection and try again."
        exit 1
    fi
    echo "ripgrep installed!"
else
    echo "ripgrep is already installed."
fiu

# Install NvChad
if [ ! -d "$HOME/.config/nvim" ]; then
    echo "Installing NvChad..."