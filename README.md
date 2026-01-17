# Dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
# Clone the repository
git clone https://github.com/mihaicristianfarcas/configs.git ~/Projects/configs
cd ~/Projects/configs

# Run the installer
./setup/install.sh
```

## What's Included

| Component | Description |
|-----------|-------------|
| **zsh** | Zsh config with Oh My Zsh, Powerlevel10k theme, and plugins |
| **tmux** | Tmux config with TPM, Tokyo Night theme, and vim-tmux-navigator |
| **nvim** | Neovim config (forked kickstart.nvim with Lazy plugin manager) |
| **ghostty** | Ghostty terminal emulator config |
| **atuin** | Atuin shell history config |

## Usage

### Full Installation

```bash
./setup/install.sh
```

This will:
1. Install system dependencies (via Homebrew, pacman, or apt)
2. Set up each component (clone plugins, themes, etc.)
3. Create symlinks via stow (with automatic backup of existing configs)

### Selective Installation

Install only specific components:

```bash
./setup/install.sh zsh tmux      # Only zsh and tmux
./setup/install.sh nvim          # Only neovim
```

### Dry Run

Preview what would happen without making changes:

```bash
./setup/install.sh --dry-run
./setup/install.sh -n zsh tmux
```

### Uninstall

Remove symlinks (keeps the repo intact):

```bash
./setup/uninstall.sh             # Remove all symlinks
./setup/uninstall.sh zsh tmux    # Remove specific symlinks
./setup/uninstall.sh --dry-run   # Preview what would be removed
```

## Directory Structure

```
configs/
├── setup/
│   ├── install.sh       # Main installer
│   ├── uninstall.sh     # Remove symlinks
│   ├── dependencies.sh  # System package installer
│   ├── lib.sh           # Shared utilities
│   ├── nvim.sh          # Neovim setup
│   ├── tmux.sh          # Tmux setup
│   ├── zsh.sh           # Zsh/Oh My Zsh setup
│   └── ghostty.sh       # Ghostty setup
├── Brewfile             # macOS Homebrew dependencies
├── zsh/                 # Zsh configs (stowed to ~/)
│   ├── .zshrc
│   └── .p10k.zsh
├── tmux/                # Tmux configs (stowed to ~/.config/tmux)
│   └── .config/tmux/
├── ghostty/             # Ghostty configs (stowed to ~/.config/ghostty)
│   └── .config/ghostty/
├── atuin/               # Atuin configs (stowed to ~/.config/atuin)
│   └── .config/atuin/
└── nvim/                # Neovim configs (stowed to ~/.config/nvim)
    └── .config/nvim/    # (cloned from kickstart.nvim fork)
```

## Platform Support

| Platform | Package Manager | Status |
|----------|-----------------|--------|
| macOS | Homebrew | ✅ Full support |
| Arch Linux | pacman | ✅ Full support |
| Debian/Ubuntu | apt | ✅ Full support (with manual installs for some tools) |

## Dependencies

Core tools installed automatically:
- `git`, `stow`, `curl`
- `zsh`, `tmux`, `neovim`
- `fzf`, `ripgrep`, `fd`, `zoxide`
- `lazygit`, `lazydocker`, `atuin`
- Meslo Nerd Font

## Customization

### Adding a New Component

1. Create a directory with the stow structure:
   ```bash
   mkdir -p newcomponent/.config/newcomponent
   # Add your config files
   ```

2. Add a setup script (optional):
   ```bash
   # setup/newcomponent.sh
   ```

3. Add to `ALL_COMPONENTS` and `STOW_PACKAGES` in `install.sh`

### Overriding Configs

The installer uses `stow --adopt` which will:
1. Backup your existing configs to `~/.config-backup-<timestamp>/`
2. Move existing files into the repo (adopt)
3. Restore the repo versions via `git checkout`

This ensures your repo configs always win while preserving a backup.

## Troubleshooting

### Stow conflicts

If stow reports conflicts, the installer handles this automatically with `--adopt`. If you still have issues:

```bash
# Check what would happen
./setup/install.sh --dry-run

# Manually unstow and restow
./setup/uninstall.sh
./setup/install.sh
```

### Reset to repo state

```bash
cd ~/Projects/configs
git checkout -- .
./setup/install.sh
```

## License

MIT
