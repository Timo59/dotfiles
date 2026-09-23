# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal macOS dotfiles for automated setup. See README.md for file descriptions and setup instructions.

## Architecture

**Setup flow**: `setup.sh` orchestrates everything by calling subsidiary scripts in sequence: Oh-My-Zsh → Homebrew → Nix → symlinks (zshrc, nvim, tmux, latexmkrc, claude) → global gitignore → Brewfile packages → machine-specific Brewfile → Claude Code CLI → MacTeX path → tex.sh → source .zshrc → dirs.sh → clone.sh → LaunchAgents (generated from templates) → VPN symlink → tailscale.\<hostname\>.sh → paperbase.sh → macos.sh (which sources the machine-specific overrides itself) → failure summary.

**No step is fatal.** `setup.sh` collects non-fatal failures in a `SETUP_FAILURES` array and reprints them as a summary block at the end, exiting non-zero if any occurred. Aborting mid-run would be worse than continuing: one unavailable `mas` entry makes `brew bundle` exit non-zero, and bailing there would skip LaTeX, the repo clones, Tailscale and Paperbase. When adding a step, follow that pattern — record and continue, never `exit 1` inline.

**Shell configuration**: Oh-My-Zsh loads `.zshrc`, which sets `ZSH_CUSTOM=$DOTFILES`. This causes Oh-My-Zsh to automatically source all `*.zsh` files in this directory (aliases.zsh).

**LaTeX setup**: tex.sh installs packages from `Texfile` with `sudo tlmgr install` (system-wide, into `/usr/local/texlive/<year>basic`) and symlinks `texmf/` to `~/Library/texmf`, making custom .sty files and bibliographies available system-wide. setup.sh calls `/usr/libexec/path_helper` before tex.sh to ensure MacTeX CLI tools are on `$PATH`.

**Never use `tlmgr --usermode`.** User mode targets `~/Library/texmf`, which is a symlink into this repo, so the package tree lands in git rather than in TeX Live. The symlink itself is deliberate and must stay — it is what propagates a `.sty` or `.bib` edit to both machines on the next login pull. The fallout is contained in `.gitignore` instead: `texmf/{ls-R,tlpkg,web2c,fonts}` and the user-mode package dirs are ignored, since `mktexlsr` (run by tex.sh on every setup) regenerates `ls-R` and would otherwise produce phantom diffs forever. A package needed on both machines goes in `Texfile`, full stop.

**Neovim + tmux**: setup.sh symlinks `nvim/` to `~/.config/nvim` and `tmux.conf` to `~/.tmux.conf`. The neovim config uses VimTeX for LaTeX editing with Skim as PDF viewer, and sets `vimtex_compiler_method = "generic"` pointing at `latex-compile.sh`, which puts auxiliary files in a `.build/` subdirectory. TeXShop and its `pdfLaTeXWithBuild.engine` have been removed; neovim is the only LaTeX front end. Note that `latexmk` is *not* installed and `~/.latexmkrc` is consequently inert — `latex-compile.sh` calls `pdflatex`/`bibtex` directly.

**Claude Code CLI**: installed by `setup.sh` with the native installer (`curl -fsSL https://claude.ai/install.sh | bash`), deliberately not Homebrew. Homebrew's `claude-code` cask tracks the stable channel (~1 week behind by design) and `claude-code@latest` tracks latest, but **neither auto-updates**, so a Homebrew install drifts further behind until someone runs `brew upgrade`. The native install self-updates in the background and manages `~/.local/bin/claude` as a symlink into `~/.local/share/claude/versions/`; `.zshrc` already has `~/.local/bin` on `PATH`. This step must precede `paperbase.sh`, which needs `claude` to register its MCP server and otherwise skips that silently.

**Repository auto-sync**: `com.user.gitupdate.plist.template` is a LaunchAgent template. `setup.sh` generates the final plist at install time using `sed` (substituting the real dotfiles path), so the hardcoded path in the installed plist is always correct regardless of username or dotfiles location.

`clone.sh` pull rule: **each repo pulls the branch it is currently on, from that branch's own upstream** — not from `origin`. This matters for Orkan, whose `dev` branch tracks `gitlab`: all development lands on GitLab, and `origin`/GitHub only ever receives `main` on a release (enforced by the tracked `tools/hooks/pre-push` hook). Branches with no configured upstream fall back to `origin/<branch>`. Pulls use `--ff-only` because the LaunchAgent runs unattended at login and must never create a merge commit or leave a conflicted worktree.

**Dependency scope**: the `Brewfile`s declare the *machine baseline* only — shell, editor, git, LaTeX, VPN. Build dependencies of a single project (boost, eigen, nlohmann-json, …) belong in that project's `flake.nix`, never in a Brewfile. Installing them globally is what let the two machines drift. `direnv` is in the Brewfile precisely because it is the mechanism that makes per-project shells automatic (`use flake` in a project `.envrc`).

The same rule runs in the other direction: **build products must not be installed to a global prefix either.** `sudo make install` into `/usr/local/lib` leaks project artefacts somewhere another project can silently link them — working on one machine, failing on the other — and gives the machine unversioned state that no dotfile declares. Build into the project tree; consume through the flake's `buildInputs` or CMake `FetchContent`.

*Status note:* this policy is only partly enforced. Of the five managed repos only `optlib` has a `flake.nix`, none has an `.envrc`, and `.zshrc` has no `eval "$(direnv hook zsh)"` line — so direnv is installed but inert.

**Known outstanding:** global `eigen` and `nlohmann-json` were removed from Homebrew to bring the machine in line with this policy, but `orkan/benchmark` and its vendored `extern/qulacs` submodule still consume both and orkan has no `flake.nix`. That target does not build until orkan gets one declaring `eigen` and `nlohmann-json`. Everything else in orkan is unaffected.

Also outstanding: `/usr/local/lib` holds `libQ`, `libnlopt`, `libopt`, `liborkan` and `libtal` from past `sudo make install` runs. `brew doctor` flags them. They should be removed once the projects that produced them build into their own trees.

**Cask auto-update semantics**: `cask 'chatgpt'` and `cask 'claude'` are both marked `auto_updates` upstream, meaning Homebrew only bootstraps the first install and the app's own updater takes over — the Caskroom version going stale is expected and harmless. This is the opposite of the Claude Code CLI case above, where the Homebrew artefact does *not* self-update. Don't "fix" a stale Caskroom entry for an `auto_updates` cask.

**Paperbase client**: `paperbase.sh` configures this machine as a client of the self-hosted Paperbase instance (`https://paperbase.lan`, Raspberry Pi at `192.168.178.3`, Traefik + private CA). It symlinks `certs/homelab-root.crt` into `~/.config/paperbase/`, installs the `paperbase` CLI and `paperbase-mcp` server via **pipx** (not `pip --user`: Homebrew Python is PEP 668 externally-managed and its user scheme targets `~/Library/Python/<ver>/bin`, not `~/.local/bin`), and registers the MCP server with Claude Code and Claude Desktop. `--trust-ca` adds the CA to the System keychain and is the only step needing `sudo`. MCP servers cannot be declared in the symlinked `~/.claude/settings.json` (Claude Code 2.1.x ignores `mcpServers` there), and `~/.claude.json` holds mutable state so it must not be symlinked — hence registration goes through `claude mcp add -s user`, guarded by a `claude mcp list` check. Claude Desktop's config is merged with `jq` rather than overwritten, since the app rewrites it.

**Machine-specific configuration**: `Brewfile.<hostname>`, `macos.<hostname>.sh` and `tailscale.<hostname>.sh` allow per-machine package and settings overrides. Current machines: `prometheus` (MacBook Pro), `lucifer` (desktop). `Brewfile.<hostname>` is applied by setup.sh after the shared Brewfile; `macos.<hostname>.sh` is **sourced by `macos.sh` itself**, not called by setup.sh; `tailscale.<hostname>.sh` has no shared counterpart, so a machine without the file is simply skipped. `macos.lucifer.sh` is currently a no-op stub.

**SSH / forge access**: `ssh-setup.sh` runs *before* `setup.sh` and provisions **two** keys — `~/.ssh/id_github` and `~/.ssh/id_gitlab_luh` — with a per-host `IdentityFile` and `IdentitiesOnly yes` in `~/.ssh/config`. Both are required: `clone.sh` needs GitHub for dotfiles/orkan/TensorNetworks and GitLab for optlib/thesis, and `paperbase.sh` pip-installs straight from the GitLab repo. Separate keys rather than one shared key because the personal and university identities have separate key lists and revocation stories, and because offering the wrong key first can trip GitLab's auth attempt limit.

**Directory layout**: `dirs.sh` creates **only** `~/Code` and `~/Projects`. It deliberately does not create anything under `~/Documents`: `Conferences:Seminars`, `LUH` and `PhD` there are symlinks that OneDrive places itself, and creating them as real directories first blocks OneDrive from doing so. Note that `~/Projects` (local git checkouts, where `clone.sh` puts `thesis`) and `~/Documents/Projects` (OneDrive-synced material) are different things despite the name collision — do not "unify" them.

**Tailscale (prometheus only)**: `tailscale.prometheus.sh` configures the mesh VPN that lets the MacBook reach the home LAN from anywhere, with no port exposed on the router. `lucifer` never leaves that LAN, so no `tailscale.lucifer.sh` exists and setup.sh's dispatch is a no-op there. The script installs nothing itself — `Brewfile.prometheus` pulls the **formula** `tailscale` (daemon + CLI, deliberately not the cask/menu-bar app) — it starts the daemon with `sudo brew services start tailscale` (a root LaunchDaemon in `/Library/LaunchDaemons`, so it runs from boot; plain `brew services list` reports its status as `none`, only `sudo brew services list` shows `started`) and ensures `--accept-routes` is set. That last part matters: the formula defaults it to false, and without it `raspberry0`'s advertised `192.168.178.3/32` subnet route is ignored. Because `tailscale up` *replaces* the previous flag set rather than merging, every wanted flag must be passed on every invocation. The action is guarded on tailscaled's own health warning naming `--accept-routes` plus the `RouteAll` pref (authoritative when the advertising peer is offline), not re-run blindly. First-time login is deliberately **not** automated: enrolling needs interactive browser auth, and the alternative — a Tailscale auth key — is a secret that must never enter this repo; the script detects the logged-out state and prints the command for the human. Server side (Pi enrolled as subnet router, split-DNS for `lan` → Pi-hole at 192.168.178.3) is configured in the admin console, not here.

**Nix**: Installed via Determinate Systems (not Homebrew). Used for C/CMake project dev shells. Flakes enabled via `~/.config/nix/nix.conf`. See `templates/flake.nix` for a C/CMake+MOSEK template — MOSEK is pulled from nixpkgs (`config.allowUnfree = true`); no system-wide MOSEK installation required. License file (`~/mosek/mosek.lic`) must still be placed manually.

## Repository Structure

```
.dotfiles/
├── setup.sh                             # Main orchestrator — run once on a fresh macOS install
├── ssh-setup.sh                         # One-time SSH keys for GitHub + GitLab LUH (run before setup.sh)
├── .zshrc                               # Zsh shell config (symlinked to ~/.zshrc)
├── aliases.zsh                          # Shell aliases (auto-sourced by Oh-My-Zsh via ZSH_CUSTOM)
├── .gitignore_global                    # Machine-wide git ignores (registered via core.excludesfile in setup.sh)
├── .gitignore                           # Ignores for this repo only (Brewfile.lock.json, texmf TeX Live artefacts)
├── Brewfile                             # Homebrew bundle: machine baseline for all machines
├── Brewfile.prometheus                  # Homebrew bundle: MacBook Pro specific packages
├── Brewfile.lucifer                     # Homebrew bundle: desktop specific packages (utm, whatsapp)
├── macos.sh                             # macOS system preferences (Dock, Finder, keyboard, screen)
├── macos.prometheus.sh                  # MacBook Pro specific macOS overrides (timezone, energy)
├── macos.lucifer.sh                     # Desktop specific macOS overrides (currently a no-op stub)
├── tex.sh                               # LaTeX environment setup script
├── paperbase.sh                         # Paperbase client setup (cert, pipx install, MCP registration)
├── tailscale.prometheus.sh              # Tailscale daemon + --accept-routes; prometheus only (no lucifer file)
├── dirs.sh                              # Creates ~/Code and ~/Projects (nothing under ~/Documents — OneDrive owns those)
├── clone.sh                             # Clones Git repositories (also called by LaunchAgent)
├── vpn-LUH                              # VPN script for LUH network
├── tmux.conf                            # tmux configuration (symlinked to ~/.tmux.conf)
├── latexmkrc                            # latexmk config (symlinked to ~/.latexmkrc; latexmk is not installed — inert)
├── latex-compile.sh                     # Neovim/VimTeX compilation script (aux files in .build/)
├── Texfile                              # LaTeX packages installed system-wide by tex.sh via sudo tlmgr
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
│   └── bibtex/bib/                      # Bibliographies: classical, prelims, qaa, qaoa, qcp,
│                                        #   qsim, thesis, tn, vqa  (.bib)
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
12. `brew update` + `brew bundle` from `Brewfile` (`--no-upgrade`); failure recorded in `SETUP_FAILURES`, not fatal
13. `brew bundle` from `Brewfile.<hostname>` if it exists (`--no-upgrade`); likewise non-fatal
14. Install the Claude Code CLI via the native installer if `claude` is absent, else `claude update` (idempotent). Must precede step 24.
15. `/usr/libexec/path_helper` — injects MacTeX CLI tools into `$PATH`
16. Run `tex.sh`
17. Source `~/.zshrc` — activates new shell config for remaining steps
18. Run `dirs.sh`
19. Run `clone.sh`
20. Generate `~/Library/LaunchAgents/com.user.gitupdate.plist` from template (sed substitutes `$PWD`); `launchctl bootout` + `bootstrap`
21. Generate `com.user.dock.plist` from template — written only; launchd picks it up at next login (no `bootstrap`, unlike the other two)
22. Generate `com.user.claudecleanup.plist` from template; `chmod +x claude/claude-cleanup.sh`; `bootout` + `bootstrap`
23. `chmod +x` + `sudo` symlink `vpn-LUH` → `/usr/local/bin/vpn-LUH` (idempotent — re-links on a wrong/stale target too)
24. Run `tailscale.<hostname>.sh` if it exists (only `prometheus` has one; no-op on `lucifer`)
25. Run `paperbase.sh --trust-ca`
26. Run `macos.sh` — which **sources** `macos.<hostname>.sh` itself (setup.sh does not call it directly)
27. Print the `SETUP_FAILURES` summary; exit 1 if non-empty

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
| `texmf/` | `~/Library/texmf` (created by `tex.sh`, not `setup.sh`) |
| `vpn-LUH` | `/usr/local/bin/vpn-LUH` |

Note: the three `com.user.*.plist` files are **generated** (not symlinked) at `~/Library/LaunchAgents/` by setup.sh at install time, so the `DOTFILES_PATH` substitution is always correct.

When renaming a file that is symlinked into place, remember that the target on already-provisioned machines keeps pointing at the **old** name until `setup.sh` is re-run. Symlink checks compare `readlink` against the intended target rather than merely testing `-L`, precisely so a stale link is repaired rather than reported as `[EXISTS]`.

## Conventions

- Scripts output `[DONE]`, `[EXISTS]`, `[WARNING]`, `[ERROR]`, or `[INFO]` status prefixes
- Scripts check for file/directory existence before creating symlinks
- Steps record failures and continue; they do not abort the run (see "No step is fatal" above)
- LaTeX packages use `\RequirePackage{base}` to inherit common math macros
- Shell scripts use `#!/bin/zsh` except tex.sh, latex-compile.sh, macos.sh, and macos.*.sh which use `#!/bin/bash`
- `zsh -n` cannot parse the associative-array subscripts in `dirs.sh`/`clone.sh` (`bad math expression`). That is a limitation of the syntax check, not a bug — verify those two by running them; they are idempotent.
- LaTeX auxiliary files go in `.build/` subdirectory, PDF stays in source directory
- Machine-specific files follow the `<basename>.<hostname>` naming convention (`hostname -s`)
- Two ignore files, by scope: `.gitignore_global` holds patterns that should apply to **every repo on the machine** (registered via `core.excludesfile`); the repo-local `.gitignore` holds patterns specific to this repo only. Put a new pattern in the narrower one unless it is genuinely machine-wide.
