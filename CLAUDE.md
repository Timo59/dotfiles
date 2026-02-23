# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal macOS dotfiles for automated setup. See README.md for file descriptions and setup instructions.

## Architecture

**Setup flow**: `setup.sh` orchestrates everything by calling subsidiary scripts in sequence: Oh-My-Zsh → Homebrew → Nix → symlinks (zshrc, nvim, tmux, latexmkrc, claude) → Brewfile packages → machine-specific Brewfile → MacTeX path → tex.sh → source .zshrc → dirs.sh → clone.sh → LaunchAgent (generated from template) → VPN symlink → MOSEK → macos.sh → machine-specific macos overrides.

**Shell configuration**: Oh-My-Zsh loads `.zshrc`, which sets `ZSH_CUSTOM=$DOTFILES`. This causes Oh-My-Zsh to automatically source all `*.zsh` files in this directory (aliases.zsh, path.zsh).

**LaTeX setup**: tex.sh installs packages from `Texfile`, symlinks `texmf/` to `~/Library/texmf` (making custom .sty files available system-wide), and symlinks the TeXShop engine. setup.sh calls `/usr/libexec/path_helper` before tex.sh to ensure MacTeX CLI tools are on `$PATH`.

**Neovim + tmux**: setup.sh symlinks `nvim/` to `~/.config/nvim` and `tmux.conf` to `~/.tmux.conf`. The neovim config uses VimTeX for LaTeX editing with Skim as PDF viewer. Both TeXShop and neovim use `latex-compile.sh` (or equivalent logic) which puts auxiliary files in `.build/` subdirectory.

**Repository auto-sync**: `com.user.gitupdate.plist.template` is a LaunchAgent template. `setup.sh` generates the final plist at install time using `sed` (substituting the real dotfiles path), so the hardcoded path in the installed plist is always correct regardless of username or dotfiles location.

**Machine-specific configuration**: `Brewfile.<hostname>` and `macos.<hostname>.sh` allow per-machine package and settings overrides. Current machines: `prometheus` (MacBook Pro), `lucifer` (desktop). Both are applied after their shared counterparts.

**Nix**: Installed via Determinate Systems (not Homebrew). Used for C/CMake project dev shells. Flakes enabled via `~/.config/nix/nix.conf`. See `templates/flake.nix` for a C/CMake+MOSEK template.

## Repository Structure

```
.dotfiles/
├── setup.sh                             # Main orchestrator — run once on a fresh macOS install
├── .zshrc                               # Zsh shell config (symlinked to ~/.zshrc)
├── aliases.zsh                          # Shell aliases (auto-sourced by Oh-My-Zsh via ZSH_CUSTOM)
├── path.zsh                             # PATH config (auto-sourced by Oh-My-Zsh via ZSH_CUSTOM)
├── Brewfile                             # Homebrew bundle: shared formulae/casks for all machines
├── Brewfile.prometheus                  # Homebrew bundle: MacBook Pro specific packages
├── Brewfile.lucifer                     # Homebrew bundle: desktop specific packages
├── macos.sh                             # macOS system preferences (Dock, Finder, keyboard, screen)
├── macos.prometheus.sh                  # MacBook Pro specific macOS overrides (hostname, energy)
├── tex.sh                               # LaTeX environment setup script
├── dirs.sh                              # Creates standard directory structure
├── clone.sh                             # Clones Git repositories (also called by LaunchAgent)
├── install_mosek.sh                     # Downloads and installs the MOSEK SDK to ~/mosek
├── vpn-LUH                              # VPN script for LUH network
├── tmux.conf                            # tmux configuration (symlinked to ~/.tmux.conf)
├── latexmkrc                            # LaTeX build config (symlinked to ~/.latexmkrc)
├── com.user.gitupdate.plist.template    # LaunchAgent template: DOTFILES_PATH substituted at install
├── templates/
│   └── flake.nix                        # Nix dev shell template for C/CMake+MOSEK projects
├── nvim/                                # Neovim config dir (symlinked to ~/.config/nvim)
└── claude/
    ├── settings.json                    # Claude Code settings (symlinked to ~/.claude/settings.json)
    └── agents/                          # Custom Claude agents (symlinked to ~/.claude/agents)
        ├── critical-text-reviewer.md    # Rigorous academic/technical writing reviewer
        ├── quantum-hpc-engineer.md      # Quantum simulation + HPC C code specialist (opus)
        ├── torvalds-code-review.md      # Brutally honest code review (opus)
        ├── unit-test-architect.md       # Comprehensive unit test design (persistent memory)
        └── workflow-critic.md           # Socratic workflow change evaluator
```

## Setup Sequence (`setup.sh`)

1. Guard: exit if not run from inside `.dotfiles/`
2. Install Oh-My-Zsh (idempotent — skips if `~/.oh-my-zsh` exists)
3. Install Homebrew (idempotent — skips if `brew` is on `$PATH`); appends shellenv to `~/.zprofile`
4. Install Nix via Determinate Systems (idempotent — skips if `nix` is on `$PATH`)
5. Enable Nix flakes: write `~/.config/nix/nix.conf` (idempotent)
6. Symlink `.zshrc` → `~/.zshrc` (idempotent — only re-links if missing or pointing to wrong target)
7. Symlink `nvim/` → `~/.config/nvim` (idempotent)
8. Symlink `tmux.conf` → `~/.tmux.conf` (idempotent)
9. Symlink `latexmkrc` → `~/.latexmkrc` (idempotent)
10. Symlink `claude/settings.json` → `~/.claude/settings.json` and `claude/agents` → `~/.claude/agents` (idempotent)
11. `brew update` + `brew bundle` from `Brewfile` (`--no-upgrade`)
12. `brew bundle` from `Brewfile.<hostname>` if it exists (`--no-upgrade`)
13. `/usr/libexec/path_helper` — injects MacTeX CLI tools into `$PATH`
14. Run `tex.sh`
15. Source `~/.zshrc` — activates new shell config for remaining steps
16. Run `dirs.sh`
17. Run `clone.sh`
18. Generate `~/Library/LaunchAgents/com.user.gitupdate.plist` from template (sed substitutes `$PWD`); `launchctl load`
19. `chmod +x` + `sudo` symlink `vpn-LUH` → `/usr/local/bin/vpn-LUH` (idempotent)
20. Run `install_mosek.sh`
21. Run `macos.sh` (if present)
22. Run `macos.<hostname>.sh` (if present)

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

Note: `com.user.gitupdate.plist` is **generated** (not symlinked) at `~/Library/LaunchAgents/` by setup.sh at install time.

## Conventions

- Scripts output `[DONE]`, `[EXISTS]`, `[WARNING]`, `[ERROR]`, or `[INFO]` status prefixes
- Scripts check for file/directory existence before creating symlinks
- LaTeX packages use `\RequirePackage{base}` to inherit common math macros
- Shell scripts use `#!/bin/zsh` except tex.sh, latex-compile.sh, install_mosek.sh, macos.sh, and macos.*.sh which use `#!/bin/bash`
- LaTeX auxiliary files go in `.build/` subdirectory, PDF stays in source directory
- Machine-specific files follow the `<basename>.<hostname>` naming convention (`hostname -s`)
