#!/usr/bin/env bash
set -euo pipefail
msg() { echo -e "\033[1;33m[tmux] $*\033[0m"; }

TMUX_DIR="$HOME/.config/tmux"
PLUGINS_DIR="$TMUX_DIR/plugins"

mkdir -p "$PLUGINS_DIR"

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

ensure_repo https://github.com/tmux-plugins/tpm "$PLUGINS_DIR/tpm"
ensure_repo https://github.com/janoamaral/tokyo-night-tmux "$PLUGINS_DIR/tokyo-night-tmux"
ensure_repo https://github.com/christoomey/vim-tmux-navigator "$PLUGINS_DIR/vim-tmux-navigator"

if tmux info >/dev/null 2>&1; then
    msg "reloading tmux configuration..."
    tmux source-file "$TMUX_DIR/tmux.conf"
else
    msg "tmux isn't running. start a session and press <prefix> + r to reload."
fi
