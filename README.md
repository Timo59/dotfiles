# Dotfiles

Personal macOS dotfiles for automated setup and configuration of development environments. Based on [Dries Vints' dotfiles](https://github.com/driesvints/dotfiles).

## Quick Start

```zsh
# 1. Generate SSH key for GitHub (one-time, before cloning)
./ssh-setup.sh

# 2. Clone this repository
git clone --recursive git@github.com:Timo59/dotfiles.git ~/.dotfiles

# 3. Run the setup script (installs everything, including macOS preferences)
cd ~/.dotfiles && ./setup.sh
```

## Daily Apply Workflow

The setup script is designed to be re-run at any time to converge the machine to the desired state. After pulling new dotfiles commits, run:

```zsh
cd ~/.dotfiles && ./setup.sh
```

All steps are idempotent — existing symlinks, installed packages, and Nix are detected and skipped with `[EXISTS]` or `[DONE]` output. Only missing pieces are installed.

## What Gets Installed

The setup script installs and configures:

- **Oh-My-Zsh** - Shell framework with plugins and themes
- **Homebrew** - Package manager with all dependencies from Brewfile
- **Nix** - Reproducible build tool (Determinate Systems installer, flakes enabled)
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
| `install_mosek.sh` | MOSEK installer kept for reference. MOSEK is now provided via nixpkgs in per-project `flake.nix`. |
| `vpn-LUH` | Connects to University of Hannover VPN using OpenConnect. |

### Shell Configuration

| File | Description |
|------|-------------|
| `.zshrc` | Main Zsh configuration with Oh-My-Zsh setup, plugins, and shell options. |
| `aliases.zsh` | Custom shell aliases (copyssh, reloadshell, reloaddns, dotfiles). |

### Package Lists

| File | Description |
|------|-------------|
| `Brewfile` | Shared Homebrew packages and cask applications (git, pyenv, CLion, PyCharm, etc.). |
| `Brewfile.prometheus` | MacBook-specific Homebrew packages (hostname: prometheus). |
| `Brewfile.lucifer` | Desktop-specific Homebrew packages (hostname: lucifer). |
| `Texfile` | LaTeX packages to install via tlmgr (algorithm2e, tikz, biblatex, etc.). |

### Configuration Files

| File | Description |
|------|-------------|
| `macos.sh` | macOS system preferences script (Dock, Finder, keyboard, energy settings). Run by `setup.sh`. |
| `macos.prometheus.sh` | MacBook Pro specific macOS overrides (hostname, energy). Applied after `macos.sh` on prometheus. |
| `macos.lucifer.sh` | Desktop specific macOS overrides (hostname, energy). Applied after `macos.sh` on lucifer. |
| `.gitignore_global` | Global Git ignore patterns for compiled files, OS artifacts, and IDE folders. Registered via `core.excludesfile` by `setup.sh`. |
| `com.user.gitupdate.plist.template` | LaunchAgent template. `setup.sh` generates the final plist at install time (not symlinked). |

### Nix

| File | Description |
|------|-------------|
| `templates/flake.nix` | Example Nix flake for a C/CMake project with MOSEK. Use as a starting point for per-project dev shells. |

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
│   ├── nvim/           # Symlink to .dotfiles/nvim
│   └── nix/nix.conf    # Nix config (flakes enabled), written by setup.sh
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

## Symlink Map

| Source (in `.dotfiles/`) | Target |
|---|---|
| `.zshrc` | `~/.zshrc` |
| `nvim/` | `~/.config/nvim` |
| `tmux.conf` | `~/.tmux.conf` |
| `latexmkrc` | `~/.latexmkrc` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/agents` | `~/.claude/agents` |
| `vpn-LUH` | `/usr/local/bin/vpn-LUH` |

## Customization

### Adding Homebrew Packages

Edit `Brewfile` for packages needed on all machines, or the appropriate machine-specific file for packages needed only on one machine:

```ruby
# Brewfile          — all machines
# Brewfile.prometheus — MacBook only
# Brewfile.lucifer    — desktop only

brew 'package-name'      # CLI tools
cask 'app-name'          # GUI applications
mas 'App Name', id: 123  # Mac App Store apps
```

### Per-machine Brewfiles

`setup.sh` automatically picks up `Brewfile.<hostname>` after installing the shared `Brewfile`. To add a package to only one machine, add it to the matching file:

```zsh
echo "brew 'htop'" >> ~/.dotfiles/Brewfile.prometheus   # MacBook only
echo "brew 'ansible'" >> ~/.dotfiles/Brewfile.lucifer   # desktop only
```

### Adding LaTeX Packages

Edit `Texfile` and add package names (one per line).

### Adding Shell Aliases

Edit `aliases.zsh` to add custom aliases.

### Adding Git Repositories

Edit the `REPOS` array in `clone.sh`.

## macOS Preferences

`macos.sh` is called automatically by `setup.sh` and configures system preferences. To apply manually:

```zsh
./macos.sh
```

Machine-specific overrides (e.g. computer name) live in `macos.<hostname>.sh` and are also applied automatically by `setup.sh`.

Key settings include:
- Dock: Auto-hide, no animation, show only open apps
- Finder: Show path bar, list view, folders first
- Keyboard: Disable smart quotes/dashes, enable full keyboard access
- Energy: Custom sleep settings, disable hibernation
- Security: Require password immediately after sleep

## Nix

Nix is installed automatically by `setup.sh` via the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer) with flakes enabled. It is used for per-project development shells (C/CMake projects), not for system package management (that remains Homebrew).

### Dev Shell Template

`templates/flake.nix` provides a starting point for a C/CMake project with MOSEK pulled from nixpkgs (`allowUnfree = true`). No system-wide MOSEK installation is required — `nix develop` handles everything except the license file.

```zsh
cp ~/.dotfiles/templates/flake.nix ~/Code/my-project/flake.nix
cd ~/Code/my-project
nix develop   # enters a shell with cmake, gcc, pkg-config, and MOSEK from nixpkgs
```

Place the MOSEK license at `~/mosek/mosek.lic` (see Local-only Setup below).

## Local-only Setup (manual steps)

The following are not managed by `setup.sh` and must be set up manually on each machine:

| Item | Location | How to set up |
|------|----------|---------------|
| SSH keys | `~/.ssh/` | Copy from secure backup, or use 1Password SSH agent |
| GPG keys | `~/.gnupg/` | `gpg --export-secret-keys \| gpg --import` on new machine |
| MOSEK license | `~/mosek/mosek.lic` | Download from [MOSEK portal](https://www.mosek.com/products/academic-licenses/) |
| VPN credentials | macOS Keychain | `security add-generic-password -a "uni-id" -s "vpn-server.uni-hannover.de" -w "password" login.keychain` |
| API tokens | macOS Keychain or `.env` files | Store per-project in `.env` (never committed) |

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

## Credits

Based on [Dries Vints' dotfiles](https://github.com/driesvints/dotfiles). Zsh theme by [subnixr](https://github.com/subnixr/minimal).
