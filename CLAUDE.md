# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal macOS dotfiles for automated setup. See README.md for file descriptions and setup instructions.

## Architecture

**Setup flow**: `setup.sh` orchestrates everything by calling subsidiary scripts in sequence: Oh-My-Zsh → Homebrew → Nix → symlinks (zshrc, nvim, tmux, latexmkrc, claude) → global gitignore → Brewfile packages → machine-specific Brewfile → MacTeX path → tex.sh → source .zshrc → dirs.sh → clone.sh → LaunchAgent (generated from template) → VPN symlink → macos.sh → machine-specific macos overrides.

**Shell configuration**: Oh-My-Zsh loads `.zshrc`, which sets `ZSH_CUSTOM=$DOTFILES`. This causes Oh-My-Zsh to automatically source all `*.zsh` files in this directory (aliases.zsh).

**LaTeX setup**: tex.sh installs packages from `Texfile`, symlinks `texmf/` to `~/Library/texmf` (making custom .sty files available system-wide), and symlinks the TeXShop engine. setup.sh calls `/usr/libexec/path_helper` before tex.sh to ensure MacTeX CLI tools are on `$PATH`.

**Neovim + tmux**: setup.sh symlinks `nvim/` to `~/.config/nvim` and `tmux.conf` to `~/.tmux.conf`. The neovim config uses VimTeX for LaTeX editing with Skim as PDF viewer. Both TeXShop and neovim use `latex-compile.sh` (or equivalent logic) which puts auxiliary files in `.build/` subdirectory.

**Repository auto-sync**: `com.user.gitupdate.plist.template` is a LaunchAgent template. `setup.sh` generates the final plist at install time using `sed` (substituting the real dotfiles path), so the hardcoded path in the installed plist is always correct regardless of username or dotfiles location.

`clone.sh` pull rule: **each repo pulls the branch it is currently on, from that branch's own upstream** — not from `origin`. This matters for Orkan, whose `dev` branch tracks `gitlab`: all development lands on GitLab, and `origin`/GitHub only ever receives `main` on a release (enforced by the tracked `tools/hooks/pre-push` hook). Branches with no configured upstream fall back to `origin/<branch>`. Pulls use `--ff-only` because the LaunchAgent runs unattended at login and must never create a merge commit or leave a conflicted worktree.

**Dependency scope**: the `Brewfile`s declare the *machine baseline* only — shell, editor, git, LaTeX, VPN. Build dependencies of a single project (boost, eigen, nlohmann-json, …) belong in that project's `flake.nix`, never in a Brewfile. Installing them globally is what let the two machines drift. `direnv` is in the Brewfile precisely because it is the mechanism that makes per-project shells automatic (`use flake` in a project `.envrc`).

**Paperbase client**: `paperbase.sh` configures this machine as a client of the self-hosted Paperbase instance (`https://paperbase.lan`, Raspberry Pi at `192.168.178.3`, Traefik + private CA). It symlinks `certs/homelab-root.crt` into `~/.config/paperbase/`, installs the `paperbase` CLI and `paperbase-mcp` server via **pipx** (not `pip --user`: Homebrew Python is PEP 668 externally-managed and its user scheme targets `~/Library/Python/<ver>/bin`, not `~/.local/bin`), and registers the MCP server with Claude Code and Claude Desktop. `--trust-ca` adds the CA to the System keychain and is the only step needing `sudo`. MCP servers cannot be declared in the symlinked `~/.claude/settings.json` (Claude Code 2.1.x ignores `mcpServers` there), and `~/.claude.json` holds mutable state so it must not be symlinked — hence registration goes through `claude mcp add -s user`, guarded by a `claude mcp list` check. Claude Desktop's config is merged with `jq` rather than overwritten, since the app rewrites it.

**Machine-specific configuration**: `Brewfile.<hostname>` and `macos.<hostname>.sh` allow per-machine package and settings overrides. Current machines: `prometheus` (MacBook Pro), `lucifer` (desktop). Both are applied after their shared counterparts.

**Nix**: Installed via Determinate Systems (not Homebrew). Used for C/CMake project dev shells. Flakes enabled via `~/.config/nix/nix.conf`. See `templates/flake.nix` for a C/CMake+MOSEK template — MOSEK is pulled from nixpkgs (`config.allowUnfree = true`); no system-wide MOSEK installation required. License file (`~/mosek/mosek.lic`) must still be placed manually.

## Repository Structure

```
.dotfiles/
├── setup.sh                             # Main orchestrator — run once on a fresh macOS install
├── ssh-setup.sh                         # One-time SSH key setup for GitHub (run before setup.sh)
├── .zshrc                               # Zsh shell config (symlinked to ~/.zshrc)
├── aliases.zsh                          # Shell aliases (auto-sourced by Oh-My-Zsh via ZSH_CUSTOM)
├── .gitignore_global                    # Machine-wide git ignores (registered via core.excludesfile in setup.sh)
├── .gitignore                           # Ignores for this repo only (Brewfile.lock.json)
├── Brewfile                             # Homebrew bundle: machine baseline for all machines
├── Brewfile.prometheus                  # Homebrew bundle: MacBook Pro specific packages
├── Brewfile.lucifer                     # Homebrew bundle: desktop specific packages (utm, whatsapp)
├── macos.sh                             # macOS system preferences (Dock, Finder, keyboard, screen)
├── macos.prometheus.sh                  # MacBook Pro specific macOS overrides (hostname, energy)
├── macos.lucifer.sh                     # Desktop specific macOS overrides (currently a no-op stub)
├── tex.sh                               # LaTeX environment setup script
├── paperbase.sh                         # Paperbase client setup (cert, pipx install, MCP registration)
├── dirs.sh                              # Creates standard directory structure
├── clone.sh                             # Clones Git repositories (also called by LaunchAgent)
├── vpn-LUH                              # VPN script for LUH network
├── tmux.conf                            # tmux configuration (symlinked to ~/.tmux.conf)
├── latexmkrc                            # LaTeX build config (symlinked to ~/.latexmkrc)
├── latex-compile.sh                     # Neovim/VimTeX compilation script (aux files in .build/)
├── pdfLaTeXWithBuild.engine             # Custom TeXShop engine (aux files in .build/)
├── Texfile                              # LaTeX packages to install via tlmgr
├── PRD.md                               # Design doc: multi-machine convergence goals
├── TUTORIAL.md                          # Guide to the neovim + tmux LaTeX workflow
├── com.user.gitupdate.plist.template    # LaunchAgent template: clone.sh at login
├── com.user.dock.plist.template         # LaunchAgent template: macos.sh (Dock layout) at login
├── com.user.claudecleanup.plist.template # LaunchAgent template: claude/claude-cleanup.sh at login
├── templates/
│   └── flake.nix                        # Nix dev shell template: C/CMake + MOSEK via nixpkgs (allowUnfree)
├── certs/                               # Public CA certificates (no private keys — *.key is gitignored)
│   └── homelab-root.crt                 # "Home Lab Root CA" (symlinked to ~/.config/paperbase/)
├── nvim/                                # Neovim config dir (symlinked to ~/.config/nvim)
├── texmf/                               # Custom LaTeX packages and bibliographies (symlinked to ~/Library/texmf)
│   ├── tex/latex/                       # Custom .sty files (base, exercise, summary, tn)
│   └── bibtex/bib/                      # Bibliography files (.bib)
└── claude/
    ├── settings.json                    # Claude Code settings (symlinked to ~/.claude/settings.json)
    ├── claude-cleanup.sh                # Login cleanup task (run by com.user.claudecleanup LaunchAgent)
    ├── skills/                          # Custom Claude skills (symlinked to ~/.claude/skills)
    │   └── paper-tutoring/SKILL.md      # Socratic tutoring on a scientific article
    └── agents/                          # Custom Claude agents (symlinked to ~/.claude/agents)
        ├── computer-science-prof.md     # Academic CS advisor (HPC ∩ ML ∩ quantum)
        ├── critical-text-reviewer.md    # Rigorous academic/technical writing reviewer
        ├── hpc-engineer.md              # HPC / SDP solver / C library architecture
        ├── math-prof.md                 # Pedantic proof and definition review
        ├── project-manager.md           # Project structure analysis and doc sync
        ├── quantum-hpc-engineer.md      # Quantum simulation + HPC C code specialist (opus)
        ├── quantum-physics-prof.md      # Quantum information / tensor network formalism
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
7. Register `.gitignore_global` via `git config --global core.excludesfile` (idempotent)
8. Symlink `nvim/` → `~/.config/nvim` (idempotent)
9. Symlink `tmux.conf` → `~/.tmux.conf` (idempotent)
10. Symlink `latexmkrc` → `~/.latexmkrc` (idempotent)
11. Symlink `claude/settings.json` → `~/.claude/settings.json`, `claude/agents` → `~/.claude/agents`, and `claude/skills` → `~/.claude/skills` (idempotent)
12. `brew update` + `brew bundle` from `Brewfile` (`--no-upgrade`)
13. `brew bundle` from `Brewfile.<hostname>` if it exists (`--no-upgrade`)
14. `/usr/libexec/path_helper` — injects MacTeX CLI tools into `$PATH`
15. Run `tex.sh`
16. Source `~/.zshrc` — activates new shell config for remaining steps
17. Run `dirs.sh`
18. Run `clone.sh`
19. Generate `~/Library/LaunchAgents/com.user.gitupdate.plist` from template (sed substitutes `$PWD`); `launchctl bootout` + `bootstrap`
20. Generate `com.user.dock.plist` from template — written only; launchd picks it up at next login (no `bootstrap`, unlike the other two)
21. Generate `com.user.claudecleanup.plist` from template; `chmod +x claude/claude-cleanup.sh`; `bootout` + `bootstrap`
22. `chmod +x` + `sudo` symlink `vpn-LUH` → `/usr/local/bin/vpn-LUH` (idempotent)
23. Run `paperbase.sh --trust-ca`
24. Run `macos.sh` — which **sources** `macos.<hostname>.sh` itself (setup.sh does not call it directly)

## Symlink Map

| Source (in `.dotfiles/`) | Target |
|---|---|
| `.zshrc` | `~/.zshrc` |
| `nvim/` | `~/.config/nvim` |
| `tmux.conf` | `~/.tmux.conf` |
| `latexmkrc` | `~/.latexmkrc` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/agents` | `~/.claude/agents` |
| `claude/skills` | `~/.claude/skills` |
| `certs/homelab-root.crt` | `~/.config/paperbase/homelab-root.crt` |
| `vpn-LUH` | `/usr/local/bin/vpn-LUH` |

Note: the three `com.user.*.plist` files are **generated** (not symlinked) at `~/Library/LaunchAgents/` by setup.sh at install time, so the `DOTFILES_PATH` substitution is always correct.

## Conventions

- Scripts output `[DONE]`, `[EXISTS]`, `[WARNING]`, `[ERROR]`, or `[INFO]` status prefixes
- Scripts check for file/directory existence before creating symlinks
- LaTeX packages use `\RequirePackage{base}` to inherit common math macros
- Shell scripts use `#!/bin/zsh` except tex.sh, latex-compile.sh, macos.sh, and macos.*.sh which use `#!/bin/bash`
- LaTeX auxiliary files go in `.build/` subdirectory, PDF stays in source directory
- Machine-specific files follow the `<basename>.<hostname>` naming convention (`hostname -s`)
- Two ignore files, by scope: `.gitignore_global` holds patterns that should apply to **every repo on the machine** (registered via `core.excludesfile`); the repo-local `.gitignore` holds patterns specific to this repo only. Put a new pattern in the narrower one unless it is genuinely machine-wide.
