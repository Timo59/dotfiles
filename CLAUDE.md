# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal macOS dotfiles for automated setup. See README.md for file descriptions and setup instructions.

## Architecture

**Setup flow**: `setup.sh` orchestrates everything by calling subsidiary scripts in sequence: Oh-My-Zsh → Homebrew → symlinks (zshrc, nvim, tmux, latexmkrc, claude) → Brewfile packages → MacTeX path → tex.sh → source .zshrc → dirs.sh → clone.sh → LaunchAgent → VPN symlink → MOSEK.

**Shell configuration**: Oh-My-Zsh loads `.zshrc`, which sets `ZSH_CUSTOM=$DOTFILES`. This causes Oh-My-Zsh to automatically source all `*.zsh` files in this directory (aliases.zsh, path.zsh).

**LaTeX setup**: tex.sh installs packages from `Texfile`, symlinks `texmf/` to `~/Library/texmf` (making custom .sty files available system-wide), and symlinks the TeXShop engine. setup.sh calls `/usr/libexec/path_helper` before tex.sh to ensure MacTeX CLI tools are on `$PATH`.

**Neovim + tmux**: setup.sh symlinks `nvim/` to `~/.config/nvim` and `tmux.conf` to `~/.tmux.conf`. The neovim config uses VimTeX for LaTeX editing with Skim as PDF viewer. Both TeXShop and neovim use `latex-compile.sh` (or equivalent logic) which puts auxiliary files in `.build/` subdirectory.

**Repository auto-sync**: `com.user.gitupdate.plist` is a LaunchAgent that runs `clone.sh` at startup, keeping all repositories in the `REPOS` array synchronized.

**Known bug**: Line 206 of `setup.sh` calls `.install_mosek.sh` (dot-prefixed, not `./install_mosek.sh`), so MOSEK installation is silently skipped even when the file is present.

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
├── vpn-LUH                    # VPN script for LUH network
├── tmux.conf                     # tmux configuration (symlinked to ~/.tmux.conf)
├── latexmkrc                     # LaTeX build config (symlinked to ~/.latexmkrc)
├── com.user.gitupdate.plist      # macOS LaunchAgent: runs clone.sh at startup
├── nvim/                         # Neovim config dir (symlinked to ~/.config/nvim)
└── claude/
    ├── settings.json             # Claude Code settings (symlinked to ~/.claude/settings.json)
    └── agents/                   # Custom Claude agents (symlinked to ~/.claude/agents)
```

## Setup Sequence (`setup.sh`)

1. Guard: exit if not run from inside `.dotfiles/`
2. Install Oh-My-Zsh (idempotent — skips if `~/.oh-my-zsh` exists)
3. Install Homebrew (idempotent — skips if `brew` is on `$PATH`); appends shellenv to `~/.zprofile`
4. Symlink `.zshrc` → `~/.zshrc` (**destructive**: removes existing file unconditionally)
5. Symlink `nvim/` → `~/.config/nvim` (idempotent)
6. Symlink `tmux.conf` → `~/.tmux.conf` (idempotent)
7. Symlink `latexmkrc` → `~/.latexmkrc` (idempotent)
8. Symlink `claude/settings.json` → `~/.claude/settings.json` and `claude/agents` → `~/.claude/agents` (idempotent)
9. `brew update` + `brew bundle` from `Brewfile`
10. `/usr/libexec/path_helper` — injects MacTeX CLI tools into `$PATH`
11. Run `tex.sh`
12. Source `~/.zshrc` — activates new shell config for remaining steps
13. Run `dirs.sh`
14. Run `clone.sh`
15. Symlink + `launchctl load` `com.user.gitupdate.plist` → `~/Library/LaunchAgents/` (idempotent)
16. `chmod +x` + `sudo` symlink `vpn-LUH` → `/usr/local/bin/vpn-LUH` (idempotent)
17. Run `install_mosek.sh` (**currently broken**: called as `.install_mosek.sh` — missing `./`)

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
| `vpn-LUH` | `/usr/local/bin/vpn-LUH` |

## Conventions

- Scripts output `[DONE]`, `[EXISTS]`, `[WARNING]`, or `[ERROR]` status prefixes
- Scripts check for file/directory existence before creating symlinks
- LaTeX packages use `\RequirePackage{base}` to inherit common math macros
- Shell scripts use `#!/bin/zsh` except tex.sh, latex-compile.sh, and install_mosek.sh which use `#!/bin/bash`
- LaTeX auxiliary files go in `.build/` subdirectory, PDF stays in source directory
