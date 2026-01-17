#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# Available packages
ALL_PACKAGES=(tmux zsh ghostty atuin nvim)

# Parse arguments
DRY_RUN=false
PACKAGES=()

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [PACKAGES...]

Removes stow symlinks for the specified packages.

Options:
    -n, --dry-run    Show what would be done without making changes
    -h, --help       Show this help message

Packages: ${ALL_PACKAGES[*]}
    If no packages specified, all will be unstowed.

Examples:
    $(basename "$0")              # Unstow everything
    $(basename "$0") zsh tmux     # Unstow only zsh and tmux
    $(basename "$0") -n           # Dry run
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            err "unknown option: $1"
            usage
            ;;
        *)
            PACKAGES+=("$1")
            shift
            ;;
    esac
done

# Default to all packages if none specified
if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    PACKAGES=("${ALL_PACKAGES[@]}")
fi

# Validate packages
for pkg in "${PACKAGES[@]}"; do
    valid=false
    for valid_pkg in "${ALL_PACKAGES[@]}"; do
        [[ "$pkg" == "$valid_pkg" ]] && valid=true && break
    done
    if ! $valid; then
        err "unknown package: $pkg"
        err "valid packages: ${ALL_PACKAGES[*]}"
        exit 1
    fi
done

if $DRY_RUN; then
    msg "DRY RUN MODE - no changes will be made" "$YELLOW"
    echo ""
fi

if ! has_cmd stow; then
    err "stow is not installed. cannot unstow packages."
    exit 1
fi

cd "$REPO_ROOT"

# Build list of packages that exist
packages_to_unstow=()
for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$REPO_ROOT/$pkg" ]]; then
        packages_to_unstow+=("$pkg")
    else
        warn "package directory not found: $pkg"
    fi
done

if ((${#packages_to_unstow[@]})); then
    msg "unstowing packages: ${packages_to_unstow[*]}"
    
    if $DRY_RUN; then
        stow --delete --target="$HOME" --simulate "${packages_to_unstow[@]}" 2>&1 || true
    else
        stow --delete --target="$HOME" "${packages_to_unstow[@]}"
    fi
    
    msg "✅ unstow complete. symlinks removed."
else
    warn "no packages to unstow."
fi
