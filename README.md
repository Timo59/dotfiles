# Dotfiles

Personal macOS dotfiles for automated setup and configuration of development environments. Based on [Dries Vints' dotfiles](https://github.com/driesvints/dotfiles).

## Quick Start

```zsh
# 1. Generate SSH key for GitHub
./ssh-setup.sh

# 2. Clone this repository
git clone --recursive git@github.com:Timo59/dotfiles.git ~/.dotfiles

# 3. Run the setup script
cd ~/.dotfiles && ./setup.sh

# 4. (Optional) Apply macOS preferences
source ./.macos
```

## What Gets Installed

The setup script installs and configures:

- **Oh-My-Zsh** - Shell framework with plugins and themes
- **Homebrew** - Package manager with all dependencies from Brewfile
- **Neovim + tmux** - Terminal-based editor and multiplexer for LaTeX writing
- **LaTeX** - BasicTeX with custom packages for academic writing
- **Skim** - PDF viewer with SyncTeX support for neovim
- **Git Repositories** - Auto-cloned from GitHub and GitLab
- **MOSEK** - Optimization SDK for convex optimization
- **LaunchAgent** - Background service to keep repositories updated

## File Overview

### Installation Scripts

| File | Description |
|------|-------------|
| `setup.sh` | Main installation script that orchestrates the entire setup process. |
| `ssh-setup.sh` | Generates ed25519 SSH key for GitHub and configures ssh-agent with Keychain. |
| `clone.sh` | Clones and updates Git repositories from GitHub and GitLab Uni Hannover. |
| `dirs.sh` | Creates standard directory structure (Documents/*, Code). |
| `tex.sh` | Installs LaTeX packages and symlinks custom texmf directory and TeXShop engine. |
| `install_mosek.sh` | Downloads and installs the MOSEK optimization toolkit with checksum verification. |
| `vpn-LUH.sh` | Connects to University of Hannover VPN using OpenConnect. |

### Shell Configuration

| File | Description |
|------|-------------|
| `.zshrc` | Main Zsh configuration with Oh-My-Zsh setup, plugins, and shell options. |
| `aliases.zsh` | Custom shell aliases (copyssh, reloadshell, reloaddns, dotfiles). |
| `path.zsh` | PATH environment variable configuration. |
| `minimal.zsh-theme` | Minimal Zsh theme with git status, SSH indicator, and vim mode display. |

### Package Lists

| File | Description |
|------|-------------|
| `Brewfile` | Homebrew packages and cask applications (git, pyenv, CLion, PyCharm, etc.). |
| `Texfile` | LaTeX packages to install via tlmgr (algorithm2e, tikz, biblatex, etc.). |
| `Pyfile` | Python packages for pip installation (currently minimal). |

### Configuration Files

| File | Description |
|------|-------------|
| `.macos` | macOS system preferences script (Dock, Finder, keyboard, energy settings). |
| `.mackup.cfg` | Mackup configuration for backing up app preferences to iCloud. |
| `.gitignore_global` | Global Git ignore patterns for compiled files, OS artifacts, and IDE folders. |
| `com.user.gitupdate.plist` | LaunchAgent that runs clone.sh at system startup to sync repositories. |

### LaTeX Compilation

| File | Description |
|------|-------------|
| `pdfLaTeXWithBuild.engine` | Custom TeXShop engine that outputs build files to ./.build directory. |
| `latex-compile.sh` | Neovim/VimTeX compilation script (same behavior as TeXShop engine). |

### Neovim + tmux

| File | Description |
|------|-------------|
| `nvim/init.lua` | Neovim configuration with VimTeX, Telescope, Treesitter, and LaTeX workflow. |
| `tmux.conf` | tmux configuration with vim-like keybindings and LaTeX-focused layouts. |
| `TUTORIAL.md` | Step-by-step guide for using the neovim + tmux LaTeX workflow. |

### Custom LaTeX Packages (texmf/)

| File | Description |
|------|-------------|
| `texmf/tex/latex/base.sty` | Foundation package with math macros (sets, operators, Dirac notation, theorems). |
| `texmf/tex/latex/exercise.sty` | Exercise sheet package with numbered exercises and remarks. |
| `texmf/tex/latex/summary.sty` | Paper summary package with compact A4 layout. |
| `texmf/tex/latex/tn.sty` | Tensor network notation macros (MPS, MPO expansions). |

### Bibliography Files (texmf/bibtex/bib/)

| File | Description |
|------|-------------|
| `qsim.bib` | References for simulation methods. |
| `tn.bib` | Tensor network literature. |
| `qcp.bib` | Computing papers. |
| `qaoa.bib` | Optimization algorithm references. |
| `qaa.bib` | Algorithm references. |
| `classical.bib` | Classical computing and optimization. |
| `thesis.bib` | Thesis-specific references. |

## Directory Structure Created

```
~/
├── .dotfiles/          # This repository
├── .zshrc              # Symlink to .dotfiles/.zshrc
├── .tmux.conf          # Symlink to .dotfiles/tmux.conf
├── .config/
│   └── nvim/           # Symlink to .dotfiles/nvim
├── Code/               # Source code repositories
├── Documents/
│   ├── Conferences:Seminars/
│   ├── LUH/
│   ├── PhD/
│   └── Projects/
├── Library/
│   ├── TeXShop/Engines/    # Symlink to custom engine
│   └── texmf/              # Symlink to custom LaTeX packages
└── mosek/              # MOSEK installation
```

## Customization

### Adding Homebrew Packages

Edit `Brewfile` and add packages:
```ruby
brew 'package-name'      # CLI tools
cask 'app-name'          # GUI applications
mas 'App Name', id: 123  # Mac App Store apps
```

### Adding LaTeX Packages

Edit `Texfile` and add package names (one per line).

### Adding Shell Aliases

Edit `aliases.zsh` to add custom aliases.

### Adding Git Repositories

Edit the `REPOS` array in `clone.sh`.

## macOS Preferences

The `.macos` script configures system preferences. Run it manually after setup:

```zsh
source ~/.dotfiles/.macos
```

Key settings include:
- Dock: Auto-hide, no animation, show only open apps
- Finder: Show path bar, list view, folders first
- Keyboard: Disable smart quotes/dashes, enable full keyboard access
- Energy: Custom sleep settings, disable hibernation
- Security: Require password immediately after sleep

## LaTeX Workflow with Neovim

The dotfiles include a complete terminal-based LaTeX writing environment. See `TUTORIAL.md` for detailed instructions.

### Quick Start

```zsh
# Start tmux session
tmux new -s thesis

# Open a .tex file in neovim
nvim ~/path/to/thesis.tex

# Inside neovim:
# ,ll  - Compile LaTeX
# ,lv  - View PDF in Skim
# ,lt  - Toggle table of contents
```

### Key Features

- **VimTeX** plugin for LaTeX editing with syntax highlighting and completion
- **Skim** PDF viewer with forward/inverse search (SyncTeX)
- **Custom compile script** that mirrors TeXShop behavior (aux files in `.build/`)
- **tmux** for split terminal windows and persistent sessions

### Build Directory

Both TeXShop and neovim use `.build/` for auxiliary files, keeping source directories clean. The PDF is placed in the source directory.

## Backup with Mackup

Mackup backs up application preferences to iCloud:

```zsh
mackup backup   # Backup preferences
mackup restore  # Restore on new machine
```

## Credits

Based on [Dries Vints' dotfiles](https://github.com/driesvints/dotfiles). Zsh theme by [subnixr](https://github.com/subnixr/minimal).
