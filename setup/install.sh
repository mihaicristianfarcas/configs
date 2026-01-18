#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# Available components and stow packages
ALL_COMPONENTS=(nvim tmux zsh ghostty)
STOW_PACKAGES=(tmux zsh ghostty atuin)

# Parse arguments
DRY_RUN=false
COMPONENTS=()

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [COMPONENTS...]

Installs dotfiles and creates symlinks via stow.

Options:
    -n, --dry-run    Show what would be done without making changes
    -h, --help       Show this help message

Components: ${ALL_COMPONENTS[*]}
    If no components specified, all will be installed.

Examples:
    $(basename "$0")              # Install everything
    $(basename "$0") zsh tmux     # Install only zsh and tmux
    $(basename "$0") -n           # Dry run
    $(basename "$0") --dry-run zsh tmux  # Dry run for specific components
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
            COMPONENTS+=("$1")
            shift
            ;;
    esac
done

# Default to all components if none specified
if [[ ${#COMPONENTS[@]} -eq 0 ]]; then
    COMPONENTS=("${ALL_COMPONENTS[@]}")
fi

# Validate components
for comp in "${COMPONENTS[@]}"; do
    valid=false
    for valid_comp in "${ALL_COMPONENTS[@]}"; do
        [[ "$comp" == "$valid_comp" ]] && valid=true && break
    done
    if ! $valid; then
        err "unknown component: $comp"
        err "valid components: ${ALL_COMPONENTS[*]}"
        exit 1
    fi
done

if $DRY_RUN; then
    msg "DRY RUN MODE - no changes will be made" "$YELLOW"
    echo ""
fi

# Install system dependencies (skip in dry run)
if ! $DRY_RUN; then
    msg "installing system dependencies (sudo/Homebrew may prompt you)..."
    bash "$SCRIPT_DIR/dependencies.sh"
fi

# Check required commands
msg "checking required commands..."
for cmd in git stow; do
    if ! has_cmd "$cmd"; then
        err "please install $cmd and re-run setup."
        exit 1
    fi
done

# Run component installers
msg "running component installers..."
for section in "${COMPONENTS[@]}"; do
    script="$SCRIPT_DIR/$section.sh"
    if [[ -f "$script" ]]; then
        msg "→ $section"
        if ! $DRY_RUN; then
            bash "$script"
        else
            echo "  would run: $script"
        fi
    else
        warn "→ skipping $section (missing $script)"
    fi
done

# Apply stow links
msg "applying stow links..."
cd "$REPO_ROOT"

# Determine which packages to stow based on selected components
packages_to_stow=()
for pkg in "${STOW_PACKAGES[@]}"; do
    # Include package if it exists and matches a selected component or is atuin (always included)
    if [[ -d "$REPO_ROOT/$pkg" ]]; then
        if [[ "$pkg" == "atuin" ]]; then
            packages_to_stow+=("$pkg")
        else
            for comp in "${COMPONENTS[@]}"; do
                if [[ "$pkg" == "$comp" ]]; then
                    packages_to_stow+=("$pkg")
                    break
                fi
            done
        fi
    fi
done

if ((${#packages_to_stow[@]})); then
    msg "stowing packages: ${packages_to_stow[*]}"
    
    if $DRY_RUN; then
        stow --no-folding --restow --target="$HOME" --simulate "${packages_to_stow[@]}" 2>&1 || true
    else
        # Backup existing configs before adopting
        backup_configs ".zshrc" ".p10k.zsh" ".config/tmux" ".config/ghostty" ".config/atuin"
        
        # Use --adopt to handle existing files, then restore repo versions
        stow --no-folding --adopt --restow --target="$HOME" "${packages_to_stow[@]}"
        git -C "$REPO_ROOT" checkout -- .
    fi
else
    warn "no packages to stow. ensure your config directories exist."
fi

msg "✅ setup complete. restart your shell or reload configs."
