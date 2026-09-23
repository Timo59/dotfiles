# Dotfiles

Personal macOS dotfiles for automated setup and configuration of development environments. Based on [Dries Vints' dotfiles](https://github.com/driesvints/dotfiles).

Two machines are kept in sync from this repo: **`prometheus`** (MacBook Pro) and **`lucifer`** (desktop). Machine-specific files follow the `<basename>.<hostname>` convention.

---

## Plan of Action on a Fresh Machine

`setup.sh` is not unattended — it prompts for `sudo` around ten times and several steps need a browser. Budget **1.5–2.5 hours**, ~9 GB of downloads and ~20 GB of disk. Work through these in order.

### Before anything else

1. **Sign in to iCloud and the Mac App Store.** `mas` can only install apps already tied to the Apple ID; `Keynote` and `AusweisApp` fail otherwise.
2. **Install the Xcode Command Line Tools** — `xcode-select --install`. Homebrew and every `git clone` below need them.
3. **Generate the SSH keys:**
   ```zsh
   /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Timo59/dotfiles/main/ssh-setup.sh)"
   ```
   This creates one key per forge and walks you through adding each:
   - `~/.ssh/id_github` → GitHub (dotfiles, orkan, TensorNetworks)
   - `~/.ssh/id_gitlab_luh` → gitlab.uni-hannover.de (optlib, thesis, paperbase)

   **Both are required.** Without the GitLab key, two repos and the whole Paperbase step fail.

### The automated part

4. **Clone and run:**
   ```zsh
   git clone --recursive git@github.com:Timo59/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles && ./setup.sh
   ```
   Stay at the keyboard for the `sudo` prompts. `setup.sh` never aborts on a failed step — it records the failure and reprints every problem in a summary block at the end, so read that block before moving on.

   On a machine whose hostname is neither `prometheus` nor `lucifer`, the script asks for one first and sets it, because every machine-specific file keys off `hostname -s`.

### Manual steps afterwards

`setup.sh` cannot do these. Nothing below is optional if you want the machine fully working.

| Step | What to do |
|---|---|
| **Tailscale enrolment** (prometheus) | `sudo tailscale up --accept-routes`, then follow the printed URL. Needs an interactive browser login; automating it would require an auth key, which is a secret and must never live in this repo. |
| **MOSEK license** | Download from the [MOSEK academic portal](https://www.mosek.com/products/academic-licenses/) to `~/mosek/mosek.lic`. Not installed by `setup.sh` — MOSEK itself comes from a project's `flake.nix`. |
| **Microsoft 365** | Sign in to unlock Word / Excel / PowerPoint. |
| **Adobe account** | Sign in to Acrobat Reader. |
| **App sign-ins** | Claude, ChatGPT, Spotify, Discord, Zoom, Obsidian, OneDrive. Wait for OneDrive to finish its first sync before touching `~/Documents`. |
| **GPG keys** | `gpg --export-secret-keys` on the old machine, `gpg --import` here. |
| **VPN credentials** | `security add-generic-password -a "uni-id" -s "vpn-server.uni-hannover.de" -w "password" login.keychain` |

### Verify

```zsh
claude doctor                 # Claude Code install health
claude mcp list               # paperbase: ... ✔ Connected
paperbase search              # lists papers (needs the CA trusted)
tailscale status              # peers listed, no health warnings
brew bundle check --file ~/.dotfiles/Brewfile --verbose
ls ~/Code ~/Projects          # five repos cloned
```

### Day to day

Re-run `cd ~/.dotfiles && ./setup.sh` any time to converge the machine back to the declared state. Every step is idempotent and reports `[EXISTS]` or `[DONE]`; only missing pieces are installed. `clone.sh` runs at every login via LaunchAgent and posts a notification when this repo itself changed, which is your cue to re-run `setup.sh`.

---

## What Gets Installed

- **Oh-My-Zsh** — shell framework, loads `aliases.zsh` via `ZSH_CUSTOM`
- **Homebrew** — all packages from `Brewfile` plus `Brewfile.<hostname>`
- **Nix** — Determinate Systems installer, flakes enabled; used for per-project dev shells, not system packages
- **Claude Code CLI** — native installer (self-updating), *not* Homebrew
- **Neovim + tmux** — terminal LaTeX environment with VimTeX
- **LaTeX** — BasicTeX plus the packages listed in `Texfile`
- **Skim** — PDF viewer with SyncTeX support for neovim
- **Git repositories** — cloned from GitHub and GitLab, kept current by a LaunchAgent
- **LaunchAgents** — repo auto-update, Dock layout, Claude session cleanup
- **Paperbase client** — CA cert, pipx install, MCP registration
- **Tailscale** — mesh VPN for reaching the home LAN (`prometheus` only)

MOSEK is **not** installed by `setup.sh`. It is pulled per project from nixpkgs via `flake.nix`; only the license file is manual.

## File Overview

### Installation Scripts

| File | Description |
|------|-------------|
| `setup.sh` | Main orchestrator. Collects non-fatal failures and prints them as a summary at the end. |
| `ssh-setup.sh` | Generates one ed25519 key each for GitHub and GitLab LUH, writes the `~/.ssh/config` blocks, loads both into the Keychain. Run before `setup.sh`. |
| `clone.sh` | Clones and updates the managed repositories. Also run at login by a LaunchAgent. |
| `dirs.sh` | Creates `~/Code` and `~/Projects`. |
| `tex.sh` | Installs LaTeX packages from `Texfile` and symlinks the custom `texmf` tree. |
| `paperbase.sh` | Sets up the Paperbase client (CA cert, pipx install, MCP registration). See [Paperbase](#paperbase). |
| `tailscale.prometheus.sh` | Starts the Tailscale daemon and accepts the Pi's subnet routes. MacBook only — there is no `tailscale.lucifer.sh`. See [Tailscale](#tailscale). |
| `vpn-LUH` | Connects to the University of Hannover VPN using OpenConnect. |

### Shell Configuration

| File | Description |
|------|-------------|
| `.zshrc` | Oh-My-Zsh setup, `PATH` (llvm, `~/.local/bin`), Paperbase env vars, shell options. |
| `aliases.zsh` | Custom aliases (`copyssh`, `reloadshell`, `reloaddns`, `dotfiles`). Auto-sourced via `ZSH_CUSTOM`. |

### Package Lists

| File | Description |
|------|-------------|
| `Brewfile` | Shared Homebrew packages — the machine baseline only. Project build dependencies belong in that project's `flake.nix`, not here. |
| `Brewfile.prometheus` | MacBook-specific packages (currently: the `tailscale` formula). |
| `Brewfile.lucifer` | Desktop-specific packages (`utm`, `whatsapp`). |
| `Texfile` | LaTeX packages installed **system-wide** by `tex.sh` via `sudo tlmgr install`. |

### Configuration Files

| File | Description |
|------|-------------|
| `macos.sh` | macOS preferences (Dock, Finder, keyboard, screen) and the pinned Dock app list. Sources `macos.<hostname>.sh` itself. |
| `macos.prometheus.sh` | MacBook overrides: timezone and `pmset` energy settings, guarded behind an interactive-terminal check. |
| `macos.lucifer.sh` | Desktop overrides. Currently a no-op stub. |
| `.gitignore_global` | **Machine-wide** ignores — compiled files, OS artifacts, secrets (`*.key`, `*.pem`), IDE folders. Registered via `core.excludesfile`. |
| `.gitignore` | Ignores for *this* repo only: `Brewfile.lock.json` and the TeX Live artefacts that land in `texmf/` (see [The texmf symlink](#the-texmf-symlink)). |
| `certs/homelab-root.crt` | Public CA certificate for the home lab. Safe to commit; the private key must never live here. |
| `com.user.gitupdate.plist.template` | LaunchAgent template: runs `clone.sh` at login. |
| `com.user.dock.plist.template` | LaunchAgent template: re-applies `macos.sh` at login. |
| `com.user.claudecleanup.plist.template` | LaunchAgent template: runs `claude/claude-cleanup.sh` at login. |

All three plists are **generated** by `setup.sh` (not symlinked), so the baked-in `DOTFILES_PATH` is always correct.

### Claude Code

| File | Description |
|------|-------------|
| `claude/settings.json` | Claude Code settings: model, permissions denylist, enabled plugins. |
| `claude/agents/` | Ten custom subagents (CS/math/quantum professors, code reviewers, project manager, test architect). |
| `claude/skills/` | Custom skills (`paper-tutoring`). |
| `claude/claude-cleanup.sh` | Deletes `~/.claude/projects` entries older than 5 days. Run at login. |

MCP servers are **not** declared in `settings.json` — Claude Code ignores `mcpServers` there. They are registered with `claude mcp add -s user` by `paperbase.sh`.

### Nix

| File | Description |
|------|-------------|
| `templates/flake.nix` | Starting point for a C/CMake project with MOSEK from nixpkgs (`allowUnfree = true`). |

### LaTeX

| File | Description |
|------|-------------|
| `latexmkrc` | Global latexmk configuration (aux files in `.build/`). |
| `latex-compile.sh` | The compile script VimTeX actually calls, via `vimtex_compiler_generic`. Puts aux files in `.build/`. |

TeXShop and its `pdfLaTeXWithBuild.engine` have been removed — editing and compilation go through neovim + VimTeX only.

### Neovim + tmux

| File | Description |
|------|-------------|
| `nvim/init.lua` | Neovim config: VimTeX, Telescope, Treesitter, Comment, gitsigns, lualine, which-key. |
| `nvim/lazy-lock.json` | Plugin version pins. Tracked deliberately. |
| `tmux.conf` | tmux config with vim-like keybindings and LaTeX-focused layouts. |
| `TUTORIAL.md` | Step-by-step guide to the neovim + tmux LaTeX workflow. |

### Custom LaTeX Packages (`texmf/tex/latex/`)

| File | Description |
|------|-------------|
| `base.sty` | Foundation package with math macros (sets, operators, Dirac notation, theorems). |
| `exercise.sty` | Exercise sheets with numbered exercises and remarks. |
| `summary.sty` | Paper summaries, compact A4 layout. |
| `tn.sty` | Tensor network notation macros (MPS, MPO expansions). |

Everything else inherits the shared macros via `\RequirePackage{base}`.

### Bibliography Files (`texmf/bibtex/bib/`)

| File | Description |
|------|-------------|
| `classical.bib` | Classical computing and optimisation. |
| `prelims.bib` | Preliminaries and background material. |
| `qaa.bib` | Quantum adiabatic / amplitude algorithm references. |
| `qaoa.bib` | QAOA literature. |
| `qcp.bib` | Quantum control / QCP papers. |
| `qsim.bib` | Simulation methods. |
| `thesis.bib` | Thesis-specific references. |
| `tn.bib` | Tensor network literature. |
| `vqa.bib` | Variational quantum algorithms. |

## Directory Structure

```
~/
├── .dotfiles/          # This repository
├── .zshrc              # → .dotfiles/.zshrc
├── .tmux.conf          # → .dotfiles/tmux.conf
├── .latexmkrc          # → .dotfiles/latexmkrc
├── .claude/
│   ├── settings.json   # → .dotfiles/claude/settings.json
│   ├── agents/         # → .dotfiles/claude/agents
│   └── skills/         # → .dotfiles/claude/skills
├── .config/
│   ├── nvim/           # → .dotfiles/nvim
│   ├── nix/nix.conf    # written by setup.sh (flakes enabled)
│   └── paperbase/      # homelab-root.crt → .dotfiles/certs/
├── .local/
│   ├── bin/            # claude, paperbase, paperbase-mcp
│   └── share/claude/   # Claude Code versions
├── Code/               # Source repositories        ← created by dirs.sh
├── Projects/           # Writing/project repos      ← created by dirs.sh
├── Documents/          # OneDrive symlinks          ← NOT created by dirs.sh
│   ├── Conferences:Seminars/  → OneDrive-Personal/...
│   ├── LUH/                   → OneDrive-Personal/LUH
│   ├── PhD/                   → OneDrive-Personal/PhD
│   └── Projects/              (OneDrive-side material)
├── Library/texmf       # → .dotfiles/texmf
└── mosek/              # mosek.lic (manual)
```

**`~/Projects` and `~/Documents/Projects` are different things.** `~/Projects` holds local git checkouts and is created by `dirs.sh`. `~/Documents/Projects` is OneDrive-synced material. `dirs.sh` deliberately does **not** create anything under `~/Documents`: those entries are symlinks placed by OneDrive, and creating them as real directories first stops OneDrive from putting its link there.

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
| `texmf/` | `~/Library/texmf` |
| `vpn-LUH` | `/usr/local/bin/vpn-LUH` |

## Managed Repositories

`clone.sh` clones these and pulls them at every login. **Each repo pulls the branch it is currently on, from that branch's own upstream** — not from `origin`.

| Repository | Host | Target | Branch |
|---|---|---|---|
| `Timo59/dotfiles` | GitHub | `~/.dotfiles` | `main` |
| `Timo59/orkan` | GitHub + GitLab | `~/Code/orkan` | `dev` (tracks `gitlab/dev`) |
| `timo.ziegler/optlib` | GitLab LUH | `~/Code/optlib` | `main` |
| `Timo59/TensorNetworks` | GitHub | `~/Code/TensorNetworks` | `main` |
| `timo.ziegler/thesis` | GitLab LUH | `~/Projects/thesis` | `main` |

Pulls use `--ff-only`: the LaunchAgent runs unattended at login and must never create a merge commit or leave a conflicted worktree. Repos in detached HEAD are skipped.

**Orkan is dual-remote.** All development lands on GitLab; `origin`/GitHub only ever receives `main` on a release, enforced by the tracked `tools/hooks/pre-push` hook. `clone.sh` detects Orkan by that hook file and configures `remote.pushDefault=gitlab`, `branch.main.pushRemote=origin`, and `core.hooksPath=tools/hooks`.

Other repositories may exist under `~/Code` and `~/Projects`; anything not in the `REPOS` array is not auto-updated. To add one, edit that array.

## Customization

### Adding Homebrew Packages

```ruby
# Brewfile            — all machines
# Brewfile.prometheus — MacBook only
# Brewfile.lucifer    — desktop only

brew 'package-name'      # CLI tools
cask 'app-name'          # GUI applications
mas 'App Name', id: 123  # Mac App Store apps
```

**Scope policy:** these files declare the *machine baseline* — shell, editor, git, LaTeX, VPN. Library dependencies of a single project (boost, eigen, nlohmann-json, …) belong in that project's `flake.nix`, never in a Brewfile. Installing them globally is what let the two machines drift in the first place.

### Adding LaTeX Packages

Add the package name to `Texfile`, one per line. `tex.sh` installs them system-wide.

**Never use `tlmgr --usermode`.** User mode targets `~/Library/texmf`, which is a symlink into this repo, so the package tree lands in git instead of in TeX Live. See below.

### Adding Git Repositories

Edit the `REPOS` array in `clone.sh`.

### Adding Shell Aliases

Edit `aliases.zsh`.

## The texmf symlink

`~/Library/texmf` is a symlink to `texmf/` in this repo. That is deliberate: a change committed here propagates to both machines on the next login pull, so custom `.sty` files and bibliographies only ever get edited in one place.

The consequence is that **anything TeX writes to the user tree lands in the repo**. Two things do that, and both are ignored in `.gitignore`:

- `tlmgr --usermode install` drops a whole package tree (`fonts/`, `tlpkg/`, `web2c/`, plus the packages). Declare packages in `Texfile` instead.
- `mktexlsr` regenerates `ls-R`, the kpathsea filename cache. `tex.sh` runs it on every setup, so tracking it would only produce phantom diffs.

## macOS Preferences

`macos.sh` is called by `setup.sh` and re-applied at every login by `com.user.dock.plist`. To apply manually:

```zsh
./macos.sh
```

It **sources** `macos.<hostname>.sh` itself; `setup.sh` does not call that separately. Key settings:

- **Dock:** auto-hide with no delay, scale minimise, no launch animation, no recent apps, fixed pinned app list
- **Finder:** path bar, list view, folders first, no extension-change or empty-trash warnings
- **Keyboard:** smart quotes/dashes and autocorrect off, full keyboard access in dialogs
- **Screen:** subpixel antialiasing on, password required immediately after sleep
- **Energy** (prometheus): display sleep 15 min on AC / 5 min on battery, no system sleep on AC

## Nix

Installed by `setup.sh` via the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer) with flakes enabled. Used for per-project development shells, not system package management — that remains Homebrew.

`direnv` is in the `Brewfile` because it is the mechanism that makes those shells automatic: a project with `use flake` in its `.envrc` enters its dev shell on `cd`. This requires `eval "$(direnv hook zsh)"` in `.zshrc` and an `.envrc` in the project.

### Dev Shell Template

```zsh
cp ~/.dotfiles/templates/flake.nix ~/Code/my-project/flake.nix
cd ~/Code/my-project
nix develop   # cmake, gcc, pkg-config, BLAS/LAPACK, and MOSEK from nixpkgs
```

Place the MOSEK license at `~/mosek/mosek.lic`.

**Build products belong in the project tree.** `sudo make install` into `/usr/local/lib` breaks the self-contained model in both directions: the artefacts leak out where another project can silently link them, and the machine acquires unversioned state no dotfile declares.

## Paperbase

[Paperbase](https://paperbase.lan) is the self-hosted research-paper database running on the Raspberry Pi (`192.168.178.3`), served through Traefik with a certificate from a private CA (`Home Lab Root CA`). `paperbase.sh` configures this machine as a client:

- Symlinks `certs/homelab-root.crt` to `~/.config/paperbase/homelab-root.crt`
- Installs the `paperbase` CLI and `paperbase-mcp` server into `~/.local/bin`
- Registers `paperbase-mcp` with Claude Code (user scope) and Claude Desktop
- Trusts the CA in the System keychain (only with `--trust-ca`)

`.zshrc` exports `PAPERBASE_API_URL` and `PAPERBASE_API_CA` for the CLI. The MCP registrations repeat both values explicitly, because GUI hosts do not read the shell profile.

### The `--trust-ca` step

```zsh
./paperbase.sh              # everything except the keychain step
./paperbase.sh --trust-ca   # additionally trust the CA (prompts for sudo)
./paperbase.sh --upgrade    # also upgrade the client tools if already installed
```

`setup.sh` passes `--trust-ca`, since it already requires `sudo` elsewhere. Without the keychain step, browsers warn on `https://paperbase.lan` and `curl` needs `-k`.

### Requirements and notes

- Needs the GitLab LUH SSH key (see `ssh-setup.sh`) and the `claude` CLI, both of which `setup.sh` arranges beforehand.
- Installation uses **pipx**, not `pip install --user`: Homebrew's Python is PEP 668 externally-managed and its user scheme targets `~/Library/Python/<version>/bin` rather than `~/.local/bin`.
- The script pins `mcp<2` inside the paperbase venv. `paperbase` imports `mcp.server.fastmcp`, which mcp 2.x removed; the pin can go once the dependency is pinned upstream.
- `~/.claude.json` holds mutable state and must **not** be symlinked, which is why registration goes through `claude mcp add` rather than a tracked config file.

## Tailscale

Tailscale is a mesh VPN that gives `prometheus` access to the home LAN from anywhere, with no port exposed on the router. It is configured on the **MacBook only**: `lucifer` sits permanently on that LAN, so there is no `tailscale.lucifer.sh` and `setup.sh` skips the step there.

`tailscale.prometheus.sh`:

- Confirms the `tailscale` **formula** is installed — the daemon and CLI without the menu-bar app.
- Starts it with `sudo brew services start tailscale`, which installs a root LaunchDaemon in `/Library/LaunchDaemons` so it comes up at boot, before login.
- Runs `sudo tailscale up --accept-routes` when the routes are not being accepted.

The `--accept-routes` flag is the part that is easy to miss. The Raspberry Pi (`raspberry0`) is enrolled as a subnet router advertising `192.168.178.3/32`, but the formula defaults `--accept-routes` to false — the GUI app would set it for you — and without it the advertised route is ignored and nothing works off-LAN. Note also that `tailscale up` *replaces* the previous flag set instead of merging into it, so every wanted flag has to be passed on every invocation.

The step is guarded rather than re-run blindly: tailscaled reports a health warning naming `--accept-routes` when a peer advertises routes that are not accepted, and the `RouteAll` pref it derives that from is checked as well, so the state is still detected correctly when the Pi is offline.

First-time login is manual and deliberately so — see the [plan of action](#manual-steps-afterwards). The tailnet side (enrolling the Pi as a subnet router, approving its route, split-DNS for `lan` → Pi-hole) is configured in the admin console, not here.

Verify with:

```zsh
sudo brew services list | grep tailscale    # started (plain `brew services list` shows "none")
tailscale status                            # peers listed, no health warnings
route -n get 192.168.178.3 | grep interface # a utun interface, not Wi-Fi
tailscale ping raspberry0                   # responds
```

The route check is the meaningful one: it proves macOS actually sends traffic for the Pi into the tunnel. The others can pass while that one fails.

## LaTeX Workflow with Neovim

See `TUTORIAL.md` for the full guide.

```zsh
tmux new -s thesis
nvim ~/path/to/thesis.tex

# Inside neovim:
# ,ll  - Compile LaTeX
# ,lv  - View PDF in Skim
# ,lt  - Toggle table of contents
```

- **VimTeX** for editing, with `vimtex_compiler_method = "generic"` pointing at `latex-compile.sh`
- **Skim** for viewing, with forward and inverse search over SyncTeX
- Auxiliary files go to `.build/`, keeping source directories clean

## Credits

Originally based on [Dries Vints' dotfiles](https://github.com/driesvints/dotfiles).
