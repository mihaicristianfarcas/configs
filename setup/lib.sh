#!/usr/bin/env bash
# Shared utilities for setup scripts

# Colors
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

msg() {
    local color="${2:-$GREEN}"
    echo -e "${color}[+] $1${NC}"
}

msg_section() {
    echo -e "${BLUE}[$1]${NC} $2"
}

warn() {
    echo -e "${YELLOW}[!] $1${NC}"
}

err() {
    echo -e "${RED}[✗] $1${NC}" >&2
}

# Clone or update a git repository
# Usage: ensure_repo <repo_url> <target_dir>
ensure_repo() {
    local repo="$1" target="$2"
    local name="${target##*/}"
    
    if [[ -d "$target/.git" ]]; then
        msg_section "$name" "updating..."
        if ! git -C "$target" diff --quiet 2>/dev/null; then
            warn "$name has local changes, stashing..."
            git -C "$target" stash push -m "auto-stash by setup script"
        fi
        git -C "$target" pull --ff-only || warn "failed to update $name (may have diverged)"
    else
        msg_section "$name" "installing..."
        git clone --depth=1 "$repo" "$target"
    fi
}

# Check if a command exists
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Get the repository root directory
get_repo_root() {
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

# Backup current configs before stow --adopt
backup_configs() {
    local backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    local needs_backup=false
    
    # Check if any target files exist and are not symlinks
    for file in "$@"; do
        if [[ -e "$HOME/$file" && ! -L "$HOME/$file" ]]; then
            needs_backup=true
            break
        fi
    done
    
    if $needs_backup; then
        msg "backing up existing configs to $backup_dir"
        mkdir -p "$backup_dir"
        for file in "$@"; do
            if [[ -e "$HOME/$file" && ! -L "$HOME/$file" ]]; then
                local dir
                dir=$(dirname "$backup_dir/$file")
                mkdir -p "$dir"
                cp -R "$HOME/$file" "$backup_dir/$file" 2>/dev/null || true
            fi
        done
        echo "$backup_dir"
    fi
}
