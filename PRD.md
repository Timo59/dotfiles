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

### 4. Per-Project Nix Shells (C/CMake projects only)

Nix is adopted specifically to solve recurring RPATH and library path failures when moving C/MOSEK projects between the two macOS machines and Linux compute servers. This is a structural fix — the same `flake.nix` works on macOS and Linux without modification.

**Scope**: C/CMake projects with native dependencies (MOSEK, system libraries). Python projects remain on conda; they work and are not migrated.

**For C/CMake projects:**
```nix
# flake.nix (sketch)
devShells.default = pkgs.mkShell {
  packages = [ pkgs.cmake pkgs.gcc pkgs.pkg-config pkgs.mosek ];
};
```
`nix develop` drops into a reproducible shell with all dependencies present and paths resolved by Nix — no manual RPATH configuration. Works identically on macOS and Linux servers.

**Colleague workflow**: `nix develop` is the only setup step. No manual MOSEK installation, no path debugging.

**Migration path**: existing C/CMake repos add a `flake.nix` one at a time. Nothing in the dotfiles changes; this is a per-repo concern.

**Nix installation**: via the Determinate Systems installer — not Homebrew. The installer handles the macOS-specific APFS volume at `/nix` and SIP correctly, and ships a clean uninstaller. Flakes are enabled via `~/.config/nix/nix.conf`. A conditional install block is added to `setup.sh` analogous to the Oh-My-Zsh and Homebrew blocks:
```zsh
if ! command -v nix &>/dev/null; then
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install
fi
```

**Nix and Homebrew coexist** in separate lanes: Nix for per-project C dependencies, Homebrew for system-wide GUI apps and CLI tools.

### 5. VPN Credentials in Keychain

`vpn-LUH` currently requires interactive username/password entry. Credentials are stored in the **login keychain** (not iCloud Keychain / Passwords app, which is not scriptable via the `security` CLI).

The VPN username is a separate university ID, not `$USER`.

**One-time setup (manual, per machine):**
```zsh
security add-generic-password -a "your-uni-id" -s "vpn-server.uni-hannover.de" -w "yourpassword" login.keychain
```

**`vpn-LUH` retrieves both username and password:**
```zsh
USERNAME=$(security find-generic-password -s "vpn-luh" 2>/dev/null | awk -F'"' '/"acct"/{print $4}')
PASSWORD=$(security find-generic-password -s "vpn-luh" -w 2>/dev/null)
echo "$PASSWORD" | sudo openconnect --user="$USERNAME" --passwd-on-stdin "$VPN_SERVER"
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
| 5 | Nix install block in `setup.sh` | **Pending** | Determinate Systems installer; not Homebrew; flakes enabled in `~/.config/nix/nix.conf` |
| 6 | Example `flake.nix` for a C/CMake project | **Pending** | Template for MOSEK projects; must work on macOS and Linux |
| 7 | Keychain integration in `vpn-LUH` | **Done** | Login keychain only; university ID retrieved alongside password |
| 8 | Update `README.md` | **Pending** | Document local-only setup steps and apply workflow |

---

## Open Questions

- ~~**Hostname values**~~ — **Resolved**: MacBook → `prometheus`, desktop → `lucifer`. All three `scutil` fields (`ComputerName`, `HostName`, `LocalHostName`) are set on each machine, so `hostname -s` reliably returns the short name. Override files are named `Brewfile.prometheus`, `Brewfile.lucifer`, `macos.prometheus.sh`, etc.
- ~~**Office/OneDrive divergence**~~ — **Resolved**: OneDrive restructured around `Research/` (papers by topic), `Conferences/`, `Projects/` (admin only), `LUH/`, `Private/`. Active papers on Overleaf + git bridge. Finished papers archived as static folders in OneDrive. Summary `.tex` files stay in OneDrive alongside their Literature directories. `dirs.sh` will create the topic folder structure. No code or build artifacts in OneDrive.
- ~~**Nix install method**~~ — **Resolved**: Determinate Systems installer, scoped to C/CMake projects only. Python projects stay on conda. Justified by recurring RPATH failures when moving MOSEK projects between macOS machines and Linux servers.
