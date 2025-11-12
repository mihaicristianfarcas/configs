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
        brew install curl git stow tmux neovim zsh fzf ripgrep fd zoxide font-meslo-lg-nerd-font
    elif [[ -f /etc/arch-release ]]; then
        msg "installing/upgrading packages via pacman..."
        sudo pacman -Syu --needed curl git stow tmux neovim zsh fzf ripgrep fd zoxide ttf-meslo-nerd
    else
        msg "unsupported OS. please install git/stow/tmux/neovim/zsh manually."
    fi
}

install_deps
