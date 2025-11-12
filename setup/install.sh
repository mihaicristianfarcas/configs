#!/usr/bin/env bash
set -euo pipefail

msg() { echo -e "\033[1;32m[+] $*\033[0m"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

msg "installing system dependencies (sudo/Homebrew may prompt you)..."
bash "$SCRIPT_DIR/dependencies.sh"

msg "checking required commands..."
for cmd in git stow; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "please install $cmd and re-run setup." >&2
        exit 1
    fi
done

msg "running component installers..."
for section in nvim tmux zsh ghostty; do
    script="$SCRIPT_DIR/$section.sh"
    if [[ -x "$script" ]]; then
        msg "→ $section"
        bash "$script"
    else
        msg "→ skipping $section (missing $script)"
    fi
done

msg "applying stow links..."
cd "$REPO_ROOT"
packages=()
for dir in tmux zsh ghostty; do
    [[ -d "$dir" ]] && packages+=("$dir")
done

if ((${#packages[@]})); then
    stow --no-folding --restow --target="$HOME" "${packages[@]}"
else
    echo "no packages to stow. ensure your config directories exist." >&2
fi

msg "✅ setup complete. restart your shell or reload configs."
