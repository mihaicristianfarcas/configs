#!/usr/bin/env bash
set -euo pipefail
msg() { echo -e "\033[1;36m[zsh] $*\033[0m"; }

ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

mkdir -p "$ZDOTDIR"

if [[ ! -d "$ZSH_DIR" ]]; then
    msg "installing Oh My Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    msg "updating Oh My Zsh..."
    git -C "$ZSH_DIR" pull --ff-only
fi

ensure_repo() {
    local repo="$1" target="$2"
    if [[ -d "$target/.git" ]]; then
        msg "updating ${target##*/}..."
        git -C "$target" pull --ff-only
    else
        msg "installing ${target##*/}..."
        git clone --depth=1 "$repo" "$target"
    fi
}

mkdir -p "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"

ensure_repo https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
ensure_repo https://github.com/zdharma-continuum/zsh-alias-finder.git \
    "$ZSH_CUSTOM/plugins/zsh-alias-finder"
ensure_repo https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git \
    "$ZSH_CUSTOM/plugins/autoupdate"
ensure_repo https://github.com/zsh-users/zsh-autosuggestions.git \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
ensure_repo https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"

msg "zsh bootstrap complete. configs will be linked via stow."
