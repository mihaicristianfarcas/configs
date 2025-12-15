#!/usr/bin/env bash
set -euo pipefail

msg() { echo -e "\033[1;35m[deps] $*\033[0m"; }

install_deps() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            echo "Homebrew is required to install dependencies. Install it from https://brew.sh first." >&2
            exit 1
        fi
        msg "installing/upgrading packages via Homebrew..."
        brew install curl git stow tmux neovim zsh fzf ripgrep fd zoxide font-meslo-lg-nerd-font lazygit lazydocker atuin
	brew install --cask nikitabobko/tap/aerospace

    elif [[ -f /etc/arch-release ]]; then
        msg "installing/upgrading packages via pacman..."
        sudo pacman -Syu --needed curl git stow tmux neovim zsh fzf ripgrep fd zoxide ttf-meslo-nerd lazygit lazydocker atuin

    elif [[ -f /etc/debian_version ]]; then
        msg "installing/upgrading packages via apt..."
        sudo apt update
        sudo apt install -y curl git stow tmux neovim zsh fzf ripgrep fd-find zoxide wget unzip lazygit
	curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

        # Symlink fd to fd-find (Debian uses a different binary name)
        if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
            sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
        fi

    else
        msg "unsupported OS. please install git and dependencies manually."
    fi
}

install_deps

