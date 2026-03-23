#!/usr/bin/env bash
set -euo pipefail

msg() { echo -e "\033[1;35m[deps] $*\033[0m"; }

# Install lazygit from GitHub releases (not in Ubuntu/Debian repos)
install_lazygit() {
    if command -v lazygit >/dev/null 2>&1; then
        msg "lazygit already installed"
        return
    fi
    msg "installing lazygit from GitHub releases..."
    local version
    version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm -f /tmp/lazygit.tar.gz /tmp/lazygit
}

# Install lazydocker from GitHub releases
install_lazydocker() {
    if command -v lazydocker >/dev/null 2>&1; then
        msg "lazydocker already installed"
        return
    fi
    msg "installing lazydocker from GitHub releases..."
    local version
    version=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${version}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazydocker.tar.gz -C /tmp lazydocker
    sudo install /tmp/lazydocker /usr/local/bin
    rm -f /tmp/lazydocker.tar.gz /tmp/lazydocker
}

# Install atuin shell history
install_atuin() {
    if command -v atuin >/dev/null 2>&1; then
        msg "atuin already installed"
        return
    fi
    msg "installing atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
}

# Install neovim from GitHub releases (Ubuntu repos often have outdated versions)
install_neovim_latest() {
    msg "installing neovim from GitHub releases..."
    curl -Lo /tmp/nvim-linux64.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf /tmp/nvim-linux64.tar.gz
    sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
    rm -f /tmp/nvim-linux64.tar.gz
}

install_deps() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            echo "Homebrew is required to install dependencies. Install it from https://brew.sh first." >&2
            exit 1
        fi
        msg "installing/upgrading packages via Homebrew..."
        brew upgrade
        brew install curl git stow tmux neovim zsh fzf ripgrep fd zoxide font-meslo-lg-nerd-font lazygit lazydocker atuin

    elif [[ -f /etc/arch-release ]]; then
        msg "installing/upgrading packages via pacman..."
        sudo pacman -Syu --needed curl git stow tmux neovim zsh fzf ripgrep fd zoxide ttf-meslo-nerd lazygit lazydocker atuin

    elif [[ -f /etc/debian_version ]]; then
        # Detect if running on Ubuntu Server or Debian
        local is_ubuntu=false
        if [[ -f /etc/os-release ]] && grep -qi ubuntu /etc/os-release; then
            is_ubuntu=true
            msg "detected Ubuntu - installing/upgrading packages..."
        else
            msg "detected Debian - installing/upgrading packages..."
        fi

        sudo apt update && sudo apt full-upgrade -y
        sudo apt install -y curl git stow tmux zsh fzf ripgrep fd-find zoxide wget unzip

        # Symlink fd to fd-find (Debian/Ubuntu uses a different binary name)
        if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
            sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
        fi

        # Install neovim (latest from GitHub for better plugin compatibility)
        install_neovim_latest

        # Install tools not in apt repos
        install_lazygit
        install_lazydocker
        install_atuin

    else
        msg "unsupported OS. please install git and dependencies manually."
    fi
}

install_deps

