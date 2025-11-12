#!/usr/bin/env bash
set -euo pipefail
msg() { echo -e "\033[1;32m[ghostty] $*\033[0m"; }

CONFIG_DIR="$HOME/.config/ghostty"
mkdir -p "$CONFIG_DIR"
msg "ghostty uses plain stow'ed configs. nothing else to install."
