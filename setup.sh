#!/bin/zsh
# =============================================================================
# setup.sh - Main dotfiles installation script
# =============================================================================
# Primary script to set up a fresh macOS installation. Installs all required
# software, creates symlinks, and configures the development environment.
#
# Usage: Run from inside the .dotfiles directory
#   cd ~/.dotfiles && ./setup.sh
#
# What this script does:
#   1. Installs Oh-My-Zsh and Homebrew
#   2. Symlinks .zshrc to home directory
#   3. Installs Homebrew packages from Brewfile
#   4. Sets up LaTeX environment (packages, texmf, TeXShop engine)
#   5. Creates standard directory structure
#   6. Clones Git repositories
#   7. Sets up LaunchAgent for auto-updating repositories
#   8. Symlinks VPN scripts and installs MOSEK SDK
# =============================================================================

# Check if script runs from the .dotfiles directory
if [[ ! "$(basename "$PWD")" == ".dotfiles" ]]; then
  echo "[ERROR] This script must be run from inside the .dotfiles directory"
  exit 1
fi

echo "Setting up your Mac..."

# Check whether .oh-my-zsh file is in home directory and install otherwise.
# Do not run zsh when installation has finished
if ! [ -e $HOME/.oh-my-zsh ]; then
  echo 'Installing Oh-my-zsh...'
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)" bash --unattended
fi
echo "[DONE] Oh-my-zsh installed."
 
# Check for Homebrew and install if it is not installed yet
if test ! $(command -v brew); then
  echo 'Installing Homebrew...'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
echo "[DONE] Homebrew installed."

# Install Nix via Determinate Systems (not Homebrew)
if ! command -v nix &>/dev/null; then
  echo 'Installing Nix via Determinate Systems...'
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install
fi
echo "[DONE] Nix available."

# Enable Nix flakes
if [ ! -f "$HOME/.config/nix/nix.conf" ]; then
  mkdir -p "$HOME/.config/nix"
  echo "experimental-features = nix-command flakes" > "$HOME/.config/nix/nix.conf"
  echo "[DONE] Nix flakes enabled in ~/.config/nix/nix.conf"
else
  echo "[EXISTS] ~/.config/nix/nix.conf"
fi

# Symlink .zshrc (idempotent — only re-links if missing or pointing to wrong target)
if [ -f ".zshrc" ]; then
  ZSHRC_TARGET="$PWD/.zshrc"
  if [ ! -L "$HOME/.zshrc" ] || [ "$(readlink "$HOME/.zshrc")" != "$ZSHRC_TARGET" ]; then
    rm -f "$HOME/.zshrc"
    ln -s "$ZSHRC_TARGET" "$HOME/.zshrc"
    echo "[DONE] Linked .zshrc"
  else
    echo "[EXISTS] .zshrc symlink"
  fi
else
  echo "[WARNING] .zshrc not found in $(pwd)"
fi

# Symlink neovim config
if [ -d "./nvim" ]; then
  mkdir -p $HOME/.config
  if [ ! -L "$HOME/.config/nvim" ]; then
    rm -rf "$HOME/.config/nvim"
    ln -s "$PWD/nvim" "$HOME/.config/nvim"
    echo "[DONE] Linked nvim config"
  else
    echo "[EXISTS] nvim config symlink"
  fi
else
  echo "[WARNING] nvim directory not found in $(pwd)"
fi

# Symlink tmux config
if [ -f "./tmux.conf" ]; then
  if [ ! -L "$HOME/.tmux.conf" ]; then
    rm -rf "$HOME/.tmux.conf"
    ln -s "$PWD/tmux.conf" "$HOME/.tmux.conf"
    echo "[DONE] Linked tmux.conf"
  else
    echo "[EXISTS] tmux.conf symlink"
  fi
else
  echo "[WARNING] tmux.conf not found in $(pwd)"
fi

# Symlink latexmkrc (LaTeX build configuration)
if [ -f "./latexmkrc" ]; then
  if [ ! -L "$HOME/.latexmkrc" ]; then
    rm -rf "$HOME/.latexmkrc"
    ln -s "$PWD/latexmkrc" "$HOME/.latexmkrc"
    echo "[DONE] Linked latexmkrc"
  else
    echo "[EXISTS] latexmkrc symlink"
  fi
else
  echo "[WARNING] latexmkrc not found in $(pwd)"
fi

# Symlink Claude Code config (settings + custom agents)
if [ -d "./claude" ]; then
  mkdir -p "$HOME/.claude"
  if [ ! -L "$HOME/.claude/settings.json" ]; then
    rm -f "$HOME/.claude/settings.json"
    ln -s "$PWD/claude/settings.json" "$HOME/.claude/settings.json"
    echo "[DONE] Linked claude/settings.json"
  else
    echo "[EXISTS] claude/settings.json symlink"
  fi
  if [ ! -L "$HOME/.claude/agents" ]; then
    rm -rf "$HOME/.claude/agents"
    ln -s "$PWD/claude/agents" "$HOME/.claude/agents"
    echo "[DONE] Linked claude/agents"
  else
    echo "[EXISTS] claude/agents symlink"
  fi
else
  echo "[WARNING] claude directory not found in $(pwd)"
fi

# Update Homebrew recipes
brew update

# Install all dependencies with homebrew/bundle (See Brewfile)
echo "Install Homebrew dependencies..."
if [ -f "./Brewfile" ]; then
  brew bundle --file ./Brewfile --no-upgrade
  echo "[DONE] Installed Homebrew dependencies"
else
  echo "[WARNING] Brewfile not found at $(pwd), skipping Homebrew dependency installation."
fi

# Install machine-specific packages
MACHINE_BREWFILE="./Brewfile.$(hostname -s)"
if [ -f "$MACHINE_BREWFILE" ]; then
  brew bundle --file="$MACHINE_BREWFILE" --no-upgrade
  echo "[DONE] Installed machine-specific packages from $MACHINE_BREWFILE"
else
  echo "[INFO] No machine-specific Brewfile for $(hostname -s), skipping"
fi

# Add MacTex CLI to the path and manpath
eval "$(/usr/libexec/path_helper)"

# Install LaTex dependencies and link texmf
if [ -f "./tex.sh" ]; then
  chmod +x "./tex.sh"
  "./tex.sh"
else
  echo "[WARNING] tex.sh not found in $(pwd), skipping LaTeX initialization"
fi

# Reload shell config
source $HOME/.zshrc

# Create directories
if [ -f "./dirs.sh" ]; then
  chmod +x "./dirs.sh"
  ./dirs.sh
else
  echo "[WARNING] dirs.sh not found in $(pwd), skipping directory setup"
fi 

# Clone Github repositories
if [ -f "./clone.sh" ]; then
  chmod +x "./clone.sh"
  ./clone.sh
else
  echo "[WARNING] clone.sh not found in $(pwd), skipping git initialization"
fi

# Add gitupdate, which calls clone.sh to LaunchAgents and load it
if [ -f ./com.user.gitupdate.plist ]; then
  echo "Symlinking gitupdate.plist to LaunchAgents"
  
  if [ ! -L $HOME/Library/LaunchAgents/com.user.gitupdate.plist ]; then
    # Create directory for launch agents if if not present
    if [ ! -d $HOME/Library/LaunchAgents ]; then
      mkdir $HOME/Library/LaunchAgents
    fi

    ln -s $PWD/com.user.gitupdate.plist ~/Library/LaunchAgents/com.user.gitupdate.plist
    echo "[DONE] Symlinked gitupdate.plist to LaunchAgents"
  else
    echo "[EXISTS] Symlink gitupdate.plist to LaunchAgents"
  fi

  launchctl load ~/Library/LaunchAgents/com.user.gitupdate.plist

else
  echo "[WARNING] com.user.gitupdate.plist not found in $(pwd), skipping gitupdate"
fi

# Symlink vpn scripts to usr/local/bin
if [ -f "./vpn-LUH" ]; then
  echo "Symlinking vpn scripts to /usr/local/bin..."
  chmod +x ./vpn-LUH

  if [ ! -L /usr/local/bin/vpn-LUH ]; then
    # Create directory if not present
    if [ ! -d /usr/local/bin ]; then
      sudo mkdir -p /usr/local/bin
    fi

    sudo ln -sf "$PWD/vpn-LUH" /usr/local/bin/vpn-LUH
    echo "[DONE] Symlinked vpn-LUH to /usr/local/bin"
  else
    echo "[EXISTS] Symlink vpn-LUH to /usr/local/bin"
  fi
else
  echo "[WARNING] No vpn scripts found in $(pwd), skipping vpn initialization"
fi

# Install MOSEK SDK
if [ -f ./install_mosek.sh ]; then
  echo "Installing MOSEK to $HOME/mosek..."
  chmod +x ./install_mosek.sh
  ./install_mosek.sh
else
  echo "[WARNING] install_mosek.sh not found in $(pwd), skipping initialization"
fi
  

# Symlink the Mackup config file to the home directory
# ln -s ./.mackup.cfg $HOME/.mackup.cfg

# Apply macOS system settings
if [ -f "./macos.sh" ]; then
  chmod +x "./macos.sh"
  "./macos.sh"
  echo "[DONE] Applied macOS system settings"
else
  echo "[WARNING] macos.sh not found, skipping"
fi

# Apply machine-specific macOS overrides
MACHINE_MACOS="./macos.$(hostname -s).sh"
if [ -f "$MACHINE_MACOS" ]; then
  chmod +x "$MACHINE_MACOS"
  "$MACHINE_MACOS"
  echo "[DONE] Applied machine-specific macOS settings"
fi
