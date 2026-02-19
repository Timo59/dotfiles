# PRD: Seamless Multi-Machine macOS Experience

## Problem

Two Apple machines (MacBook, desktop) have drifted from a shared dotfiles baseline because `setup.sh` only handles initial setup, not ongoing maintenance. Installing a package locally, tweaking a setting, or adding a tool on one machine never propagates to the other. There is no mechanism to converge both machines back to a declared state.

## Goal

A single dotfiles repository is the authoritative, declarative description of both machines. Running one command at any time applies all pending changes and converges the system to the declared state — like `nixos-rebuild switch` on NixOS.

## Non-Goals

- **Automatic sync without user intent**: changes must be committed before they apply. No background daemons watching for drift.
- **Secrets in the repo**: SSH keys, GPG keys, API tokens, and license files stay local and are documented as manual steps.
- **Docker for development environments**: Nix shells cover this use case better on macOS and compose naturally with NixOS servers.
- **Build artifacts**: only source files sync; outputs are compiled locally.

---

## Architecture

### Machine Identity

Each machine is identified by its hostname. Machine-specific files are suffixed with the hostname:

```
Brewfile                  # shared base (all machines)
Brewfile.macbook          # MacBook-only packages
Brewfile.desktop          # desktop/home lab packages
macos.sh                  # shared macOS defaults
macos.macbook.sh          # MacBook-specific defaults (if needed)
macos.desktop.sh          # desktop-specific defaults (if needed)
```

`setup.sh` detects `$(hostname -s)` and applies the matching overrides after the base.

### Sync Philosophy

```
make change on machine A
    → edit dotfiles file (Brewfile, macos.sh, etc.)
    → git commit + push
    → on machine B: LaunchAgent pulls at next boot → notification fires → run setup.sh
```

The LaunchAgent handles the pull half automatically. The user is responsible for committing changes; `setup.sh` is responsible for applying them and must be run manually after the notification.

**LaunchAgent behaviour** (`clone.sh`):
- Waits up to 60 s for `github.com:22` to be reachable before attempting any git operations, so offline boots or restricted networks exit cleanly without hanging.
- After pulling `.dotfiles`, compares the commit hash before and after. If they differ, logs a reminder to `/tmp/gitupdate.log` and fires a macOS notification prompting the user to run `setup.sh`.

---

## Requirements

### 1. Idempotent `setup.sh`

`setup.sh` must be safe to run at any time on an already-configured machine.

**Changes required:**
- Replace unconditional `rm ~/.zshrc` with a check: only create the symlink if it is missing or points to the wrong target.
- Fix the known bug on line 206: `.install_mosek.sh` → `./install_mosek.sh`.
- All other steps are already idempotent; verify and document this.

**Outcome**: `setup.sh` serves as both the fresh-install script and the daily apply script.

### 2. Shared Base + Per-Machine Brewfile

Current `Brewfile` becomes the shared base. Two override files are added:

- `Brewfile.macbook` — work tools (e.g. Office, Zoom, any faculty VPN tooling)
- `Brewfile.desktop` — home lab tools (e.g. `ansible`, `nmap`, server management CLIs)

`setup.sh` runs:
```zsh
brew bundle --file=Brewfile --no-upgrade
brew bundle --file="Brewfile.$(hostname -s)" --no-upgrade 2>/dev/null || true
```

`--no-upgrade` limits each run to installing missing packages only; explicit upgrades remain a deliberate `brew upgrade` or Brewfile version bump.

**Invariant**: every package ever installed via `brew install` on either machine must be reflected in one of these files before the next `setup.sh` run.

### 3. macOS System Settings as Code

A new `macos.sh` script captures system preferences as `defaults write` commands:

- Dock: size, position, auto-hide, pinned apps
- Menu bar: clock format, battery percentage, visible items
- Appearance: dark/light mode, accent color, highlight color
- Keyboard: key repeat rate, modifier key mappings
- Trackpad: scroll direction, tap-to-click, gesture config
- Finder: show extensions, default view, sidebar items
- Screenshots: save location, format

`setup.sh` calls `macos.sh` (and `macos.$(hostname -s).sh` if it exists).

**Tooling note**: capture current state with `defaults read > defaults-snapshot.txt` before writing the script, to avoid guessing key names.

### 4. Per-Project Nix Shells

System-wide installation of project-specific dependencies (MOSEK, specialised C libraries, Python packages) is replaced by per-project `flake.nix` files.

**For C/CMake projects:**
```nix
# flake.nix (sketch)
devShells.default = pkgs.mkShell {
  packages = [ pkgs.cmake pkgs.gcc pkgs.pkg-config ];
  shellHook = ''
    [ ! -f ~/.mosek/mosek.lic ] && bash ${./scripts/install_mosek.sh}
  '';
};
```
`nix develop` drops into a shell with all dependencies present. `install_mosek.sh` lives inside the project repo and is called once on first use. CMake finds MOSEK via the path set in `shellHook`.

**For Python projects:**
Nix shell manages both the interpreter and system-level deps. `uv` or `pip` with a `requirements.txt` / `pyproject.toml` handles pure-Python packages inside the shell. Virtual environments are not needed separately.

**Migration path**: existing projects add a `flake.nix` incrementally. Nothing in the dotfiles changes; this is a per-repo concern.

**Nix installation**: add `nix` to `Brewfile` (via the Determinate Systems installer or Homebrew). Both machines get it via the base Brewfile.

### 5. VPN Credentials in Keychain

`vpn-LUH.sh` currently requires interactive username/password entry. Credentials are moved to macOS Keychain:

**One-time setup (manual, per machine):**
```zsh
security add-generic-password -a "$USER" -s "vpn-luh" -w "yourpassword"
```

**`vpn-LUH.sh` retrieves them:**
```zsh
PASSWORD=$(security find-generic-password -a "$USER" -s "vpn-luh" -w)
```

Credentials never appear in the repository. The manual Keychain setup step is documented in `README.md`.

### 6. What Stays Local (documented, not synced)

| Item | Location | Restore method |
|---|---|---|
| SSH keys | `~/.ssh/` | Manual copy or 1Password SSH agent |
| GPG keys | `~/.gnupg/` | `gpg --export` / `--import` |
| MOSEK license | `~/mosek/mosek.lic` | Download from MOSEK portal |
| VPN credentials | macOS Keychain | `security add-generic-password` (see §5) |
| API tokens | macOS Keychain or `.env` files | Per-project |

---

## Deliverables

| # | Deliverable | Status | Notes |
|---|---|---|---|
| — | `clone.sh`: wait for `github.com:22` before git ops | **Done** | 60 s timeout; exits cleanly if offline |
| — | `clone.sh`: notify when `.dotfiles` updated | **Done** | macOS notification + log line |
| — | `setup.sh`: `--no-upgrade` for `brew bundle` | **Done** | Prevents slow/unintended upgrades on re-runs |
| 1 | Harden `setup.sh` | **Pending** | Fix destructive `.zshrc` symlink; fix MOSEK bug (`.install_mosek.sh` → `./install_mosek.sh`) |
| 2 | `Brewfile.macbook` + `Brewfile.desktop` | **Pending** | Audit current packages on both machines first |
| 3 | Machine-aware `brew bundle` in `setup.sh` | **Pending** | Hostname detection; apply `--no-upgrade` to both files |
| 4 | `macos.sh` | **Pending** | Capture current preferred state from the primary machine |
| 5 | Nix installed via Brewfile | **Pending** | Prerequisite for per-project shells |
| 6 | Example `flake.nix` for a C/CMake project | **Pending** | Template others can copy |
| 7 | Keychain integration in `vpn-LUH.sh` | **Pending** | |
| 8 | Update `README.md` | **Pending** | Document local-only setup steps and apply workflow |

---

## Open Questions

- **Hostname values**: what are the short hostnames (`hostname -s`) of the two machines? These determine the override filenames.
- **Office/OneDrive divergence**: are there specific OneDrive folder structures or symlinks that have drifted and need to be re-aligned as part of this work?
- **Nix install method**: Determinate Systems installer (`nix-installer`) is more reliable on macOS than the official installer. Preference?
