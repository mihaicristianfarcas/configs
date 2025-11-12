#!/usr/bin/env bash
set -euo pipefail
msg() { echo -e "\033[1;34m[nvim] $*\033[0m"; }

NVIM_DIR="$HOME/.config/nvim"
REPO_URL="https://github.com/mihaicristianfarcas/kickstart.nvim.git"

if [[ -d "$NVIM_DIR/.git" ]]; then
    msg "updating existing Neovim config..."
    git -C "$NVIM_DIR" pull --ff-only
elif [[ -d "$NVIM_DIR" && -n "$(ls -A "$NVIM_DIR" 2>/dev/null)" ]]; then
    msg "warning: $NVIM_DIR exists but is not a git repo. skipping clone."
else
    msg "cloning Kickstart config..."
    rm -rf "$NVIM_DIR"
    git clone "$REPO_URL" "$NVIM_DIR"
fi

msg "open nvim to let Lazy install plugins."
