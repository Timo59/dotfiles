#!/bin/zsh
# =============================================================================
# paperbase.sh - Paperbase client setup script
# =============================================================================
# Configures this machine as a client of the self-hosted Paperbase instance
# (https://paperbase.lan, Raspberry Pi at 192.168.178.3, Traefik + private CA).
#
# Installs two commands from the private GitLab repo via pipx:
#   paperbase       - Typer CLI
#   paperbase-mcp   - MCP server for Claude Code / Claude Desktop
#
# What this script does:
#   1. Symlinks the committed CA certificate to ~/.config/paperbase/
#   2. Installs the client tools with pipx (into ~/.local/bin)
#   3. Registers the MCP server with Claude Code at user scope
#   4. Merges the same MCP server into the Claude Desktop config
#   5. Optionally trusts the CA in the System keychain (--trust-ca, needs sudo)
#
# Usage:
#   ./paperbase.sh              # everything except the keychain step
#   ./paperbase.sh --trust-ca   # additionally trust the CA (prompts for sudo)
#   ./paperbase.sh --upgrade    # also upgrade the client tools if installed
#
# Requires an SSH key with access to the GitLab project (see ssh-setup.sh).
# =============================================================================

# Resolve the dotfiles directory from the script location, so this works both
# when called by setup.sh and when invoked directly from anywhere.
DOTFILES_DIR=${0:A:h}

CERT_SRC="$DOTFILES_DIR/certs/homelab-root.crt"
CERT_DIR="$HOME/.config/paperbase"
CERT_LINK="$CERT_DIR/homelab-root.crt"
CA_NAME="Home Lab Root CA"
API_URL="https://paperbase.lan"
PKG_URL="git+ssh://git@gitlab.uni-hannover.de/timo.ziegler/paperbase.git"
MCP_NAME="paperbase"
MCP_BIN="$HOME/.local/bin/paperbase-mcp"
DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

TRUST_CA=0
UPGRADE=0
for arg in "$@"; do
  case "$arg" in
    --trust-ca) TRUST_CA=1 ;;
    --upgrade)  UPGRADE=1 ;;
    --help|-h)
      sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "[WARNING] Unknown option '$arg', ignoring" ;;
  esac
done

# pipx installs into ~/.local/bin; make sure this run can see what it installs
# even if the calling shell predates the .zshrc PATH entry.
export PATH="$HOME/.local/bin:$PATH"

echo "Setting up Paperbase client..."

# -----------------------------------------------------------------------------
# 1. Symlink the CA certificate into ~/.config/paperbase
# -----------------------------------------------------------------------------
if [ -f "$CERT_SRC" ]; then
  mkdir -p "$CERT_DIR"
  # Re-link if missing, not a symlink, or pointing at a stale/wrong target
  if [ ! -L "$CERT_LINK" ] || [ "$(readlink "$CERT_LINK")" != "$CERT_SRC" ]; then
    rm -f "$CERT_LINK"
    ln -s "$CERT_SRC" "$CERT_LINK"
    echo "[DONE] Linked Paperbase CA certificate to $CERT_LINK"
  else
    echo "[EXISTS] Paperbase CA certificate symlink"
  fi
else
  echo "[ERROR] CA certificate not found at $CERT_SRC"
  exit 1
fi

# -----------------------------------------------------------------------------
# 2. Install the client tools with pipx
# -----------------------------------------------------------------------------
# pipx rather than `pip install --user`: Homebrew's Python is PEP 668
# externally-managed (pip refuses to install into it), and its user scheme
# targets ~/Library/Python/<ver>/bin instead of ~/.local/bin. pipx builds an
# isolated venv and puts both entry points in ~/.local/bin, which .zshrc adds
# to PATH.
if ! command -v pipx &>/dev/null; then
  echo "Installing pipx..."
  brew install pipx
fi

if ! command -v pipx &>/dev/null; then
  echo "[WARNING] pipx unavailable, skipping Paperbase client installation"
elif pipx list --short 2>/dev/null | awk '{print $1}' | grep -qx "paperbase"; then
  if [ "$UPGRADE" -eq 1 ]; then
    pipx upgrade paperbase
    echo "[DONE] Upgraded Paperbase client"
  else
    echo "[EXISTS] Paperbase client installed (re-run with --upgrade to update)"
  fi
else
  echo "Installing Paperbase client from GitLab..."
  if pipx install "$PKG_URL"; then
    echo "[DONE] Installed Paperbase client"
  else
    echo "[WARNING] Paperbase client installation failed (SSH access to GitLab?)"
  fi
fi

# paperbase declares an unpinned `mcp` dependency, but mcp 2.x dropped the
# mcp.server.fastmcp module that paperbase.mcp_server imports, so a fresh
# resolve installs a version the MCP server cannot start with. Pin it back
# until the dependency is pinned upstream in paperbase's pyproject.toml.
# Guarded on the import itself, so this is a no-op once the venv is healthy.
if command -v pipx &>/dev/null; then
  PIPX_VENVS="$(pipx environment --value PIPX_LOCAL_VENVS 2>/dev/null)"
  VENV_PY="$PIPX_VENVS/paperbase/bin/python"
  if [ -x "$VENV_PY" ]; then
    if "$VENV_PY" -c 'import mcp.server.fastmcp' &>/dev/null; then
      echo "[EXISTS] Compatible mcp version in the paperbase venv"
    else
      echo "Pinning mcp<2 in the paperbase venv..."
      if pipx inject --force paperbase "mcp<2" &>/dev/null; then
        echo "[DONE] Pinned mcp<2 in the paperbase venv"
      else
        echo "[WARNING] Could not pin mcp<2; paperbase-mcp may fail to start"
      fi
    fi
  fi
fi

# -----------------------------------------------------------------------------
# 3. Trust the CA in the System keychain (opt-in: needs sudo and prompts)
# -----------------------------------------------------------------------------
if [ "$TRUST_CA" -eq 1 ]; then
  if security find-certificate -c "$CA_NAME" /Library/Keychains/System.keychain &>/dev/null; then
    echo "[EXISTS] '$CA_NAME' already trusted in the System keychain"
  else
    echo "Adding '$CA_NAME' to the System keychain (requires sudo)..."
    if sudo security add-trusted-cert -d -r trustRoot \
         -k /Library/Keychains/System.keychain "$CERT_SRC"; then
      echo "[DONE] Trusted '$CA_NAME' in the System keychain"
    else
      echo "[WARNING] Could not trust '$CA_NAME'"
    fi
  fi
else
  if security find-certificate -c "$CA_NAME" /Library/Keychains/System.keychain &>/dev/null; then
    echo "[EXISTS] '$CA_NAME' trusted in the System keychain"
  else
    echo "[INFO] '$CA_NAME' not trusted yet — run './paperbase.sh --trust-ca'"
  fi
fi

# -----------------------------------------------------------------------------
# 4. Register the MCP server with Claude Code (user scope)
# -----------------------------------------------------------------------------
# User-scope MCP servers live in ~/.claude.json, which also holds mutable
# runtime state and is rewritten by Claude Code — so it must not be symlinked
# from this repo. Claude Code 2.1.x does not read `mcpServers` from
# ~/.claude/settings.json (verified), so `claude mcp add` is the only
# mechanism. Absolute paths throughout: GUI hosts inherit neither PATH nor $HOME.
if ! command -v claude &>/dev/null; then
  echo "[WARNING] claude not found, skipping MCP registration"
elif [ ! -x "$MCP_BIN" ]; then
  echo "[WARNING] $MCP_BIN not found, skipping MCP registration"
elif claude mcp list 2>/dev/null | grep -q "^${MCP_NAME}:"; then
  echo "[EXISTS] MCP server '$MCP_NAME' registered with Claude Code"
else
  if claude mcp add -s user "$MCP_NAME" \
       -e "PAPERBASE_API_URL=$API_URL" \
       -e "PAPERBASE_API_CA=$CERT_LINK" \
       -- "$MCP_BIN" &>/dev/null; then
    echo "[DONE] Registered MCP server '$MCP_NAME' with Claude Code (user scope)"
  else
    echo "[WARNING] Could not register MCP server with Claude Code"
  fi
fi

# -----------------------------------------------------------------------------
# 5. Merge the MCP server into the Claude Desktop config
# -----------------------------------------------------------------------------
# Claude Desktop rewrites this file, so merge into it rather than overwrite or
# symlink. Only write when the resulting document actually differs, so re-runs
# leave the file untouched.
if [ ! -d "$(dirname "$DESKTOP_CONFIG")" ]; then
  echo "[INFO] Claude Desktop not present, skipping its MCP registration"
elif ! command -v jq &>/dev/null; then
  echo "[WARNING] jq not found, skipping Claude Desktop MCP registration"
elif [ ! -x "$MCP_BIN" ]; then
  echo "[WARNING] $MCP_BIN not found, skipping Claude Desktop MCP registration"
else
  [ -f "$DESKTOP_CONFIG" ] || echo '{}' > "$DESKTOP_CONFIG"

  DESKTOP_TMP="$(mktemp)"
  if jq --arg name "$MCP_NAME" \
        --arg cmd "$MCP_BIN" \
        --arg url "$API_URL" \
        --arg ca "$CERT_LINK" \
        '.mcpServers[$name] = {command: $cmd, env: {PAPERBASE_API_URL: $url, PAPERBASE_API_CA: $ca}}' \
        "$DESKTOP_CONFIG" > "$DESKTOP_TMP" 2>/dev/null; then
    if cmp -s "$DESKTOP_CONFIG" "$DESKTOP_TMP"; then
      echo "[EXISTS] MCP server '$MCP_NAME' registered with Claude Desktop"
      rm -f "$DESKTOP_TMP"
    else
      cat "$DESKTOP_TMP" > "$DESKTOP_CONFIG"
      rm -f "$DESKTOP_TMP"
      echo "[DONE] Registered MCP server '$MCP_NAME' with Claude Desktop"
    fi
  else
    rm -f "$DESKTOP_TMP"
    echo "[WARNING] Could not parse $DESKTOP_CONFIG, skipping Claude Desktop registration"
  fi
fi

echo "[DONE] Paperbase client setup complete"
