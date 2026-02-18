# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal macOS dotfiles for automated setup. See README.md for file descriptions and setup instructions.

## Architecture

**Setup flow**: `setup.sh` orchestrates everything by calling subsidiary scripts in sequence: Oh-My-Zsh → Homebrew → .zshrc symlink → Brewfile packages → tex.sh → dirs.sh → clone.sh → LaunchAgent → VPN symlink → MOSEK.

**Shell configuration**: Oh-My-Zsh loads `.zshrc`, which sets `ZSH_CUSTOM=$DOTFILES`. This causes Oh-My-Zsh to automatically source all `*.zsh` files in this directory (aliases.zsh, path.zsh).

**LaTeX setup**: tex.sh installs packages from `Texfile`, symlinks `texmf/` to `~/Library/texmf` (making custom .sty files available system-wide), and symlinks the TeXShop engine.

**Neovim + tmux**: setup.sh symlinks `nvim/` to `~/.config/nvim` and `tmux.conf` to `~/.tmux.conf`. The neovim config uses VimTeX for LaTeX editing with Skim as PDF viewer. Both TeXShop and neovim use `latex-compile.sh` (or equivalent logic) which puts auxiliary files in `.build/` subdirectory.

**Repository auto-sync**: `com.user.gitupdate.plist` is a LaunchAgent that runs `clone.sh` at startup, keeping all repositories in the `REPOS` array synchronized.

## Repository Structure

```
.dotfiles/
├── setup.sh                      # Main orchestrator — run once on a fresh macOS install
├── .zshrc                        # Zsh shell config (symlinked to ~/.zshrc)
├── Brewfile                      # Homebrew bundle: lists all formulae/casks to install
├── tex.sh                        # LaTeX environment setup script
├── dirs.sh                       # Creates standard directory structure
├── clone.sh                      # Clones Git repositories (also called by LaunchAgent)
├── install_mosek.sh              # Downloads and installs the MOSEK SDK to ~/mosek
├── vpn-LUH.sh                    # VPN script for LUH network
├── tmux.conf                     # tmux configuration (symlinked to ~/.tmux.conf)
├── latexmkrc                     # LaTeX build config (symlinked to ~/.latexmkrc)
├── com.user.gitupdate.plist      # macOS LaunchAgent: runs clone.sh at startup
├── nvim/                         # Neovim config dir (symlinked to ~/.config/nvim)
└── claude/
    ├── settings.json             # Claude Code settings (symlinked to ~/.claude/settings.json)
    └── agents/                   # Custom Claude agents (symlinked to ~/.claude/agents)
```

## Setup Sequence (`setup.sh`)

1. Install Oh-My-Zsh
2. Install Homebrew
3. Symlink `.zshrc` → `~/.zshrc`
4. Symlink `nvim/` → `~/.config/nvim`
5. Symlink `tmux.conf` → `~/.tmux.conf`
6. Symlink `latexmkrc` → `~/.latexmkrc`
7. Symlink `claude/settings.json` → `~/.claude/settings.json` and `claude/agents` → `~/.claude/agents`
8. `brew bundle` from `Brewfile`
9. Run `tex.sh`
10. Source `~/.zshrc`
11. Run `dirs.sh`
12. Run `clone.sh`
13. Symlink + load `com.user.gitupdate.plist` → `~/Library/LaunchAgents/`
14. Symlink `vpn-LUH.sh` → `/usr/local/bin/vpn-LUH.sh`
15. Run `install_mosek.sh`

## Symlink Map

| Source (in `.dotfiles/`) | Target |
|---|---|
| `.zshrc` | `~/.zshrc` |
| `nvim/` | `~/.config/nvim` |
| `tmux.conf` | `~/.tmux.conf` |
| `latexmkrc` | `~/.latexmkrc` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/agents` | `~/.claude/agents` |
| `com.user.gitupdate.plist` | `~/Library/LaunchAgents/com.user.gitupdate.plist` |
| `vpn-LUH.sh` | `/usr/local/bin/vpn-LUH.sh` |

## Conventions

- Scripts output `[DONE]`, `[EXISTS]`, `[WARNING]`, or `[ERROR]` status prefixes
- Scripts check for file/directory existence before creating symlinks
- LaTeX packages use `\RequirePackage{base}` to inherit common math macros
- Shell scripts use `#!/bin/zsh` except tex.sh, latex-compile.sh, and install_mosek.sh which use `#!/bin/bash`
- LaTeX auxiliary files go in `.build/` subdirectory, PDF stays in source directory
