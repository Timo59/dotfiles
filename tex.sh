#!/bin/bash
# =============================================================================
# tex.sh - LaTeX environment setup script
# =============================================================================
# Configures the LaTeX environment for academic writing.
#
# What this script does:
#   1. Installs LaTeX packages from Texfile using tlmgr
#   2. Symlinks texmf directory with custom packages and bibliographies
#   3. Updates the TeX file database (mktexlsr)
#
# Editing is neovim + VimTeX only; TeXShop and its pdfLaTeXWithBuild.engine
# were dropped. Compilation goes through latex-compile.sh, which VimTeX calls
# via vimtex_compiler_generic. Nothing here writes to ~/Library/TeXShop.
# =============================================================================

DOTFILES_DIR=$HOME/.dotfiles
TEXMF_DIR=$HOME/Library/texmf

# Install all LaTex dependencies using tlmgr from newline delimited list Texfile
if [ ! -f "$DOTFILES_DIR/Texfile" ]; then
  echo "[WARNING] Texfile not found in $(pwd), skipping LaTex package installation"
else
  echo "Installing LaTex dependencies..."

  # Update tlmgr first
  sudo tlmgr update --self

  # Install packages from Texfile (filter out comments and empty lines)
  PACKAGES=$(grep -v '^\s*#' "$DOTFILES_DIR/Texfile" | sed 's/#.*//' | tr -s ' ' | tr "\n" " " | xargs)
  if [ -n "$PACKAGES" ]; then
    sudo tlmgr install $PACKAGES
    echo "[DONE] Installed LaTeX dependencies."
  else
    echo "[WARNING] No packages found in Texfile"
  fi
fi

# Remove the TeXShop engine symlink left behind by older versions of this
# script. TeXShop is no longer installed (see the Brewfile) and the engine
# file is gone from the repo, so the link is dangling.
STALE_ENGINE="$HOME/Library/TeXShop/Engines/pdfLaTeXWithBuild.engine"
if [ -L "$STALE_ENGINE" ]; then
  rm -f "$STALE_ENGINE"
  echo "[DONE] Removed stale TeXShop engine symlink"
fi

# Create a symbolic link from texmf in dotfiles to $HOME/Library/texmf
if [ -d "$DOTFILES_DIR/texmf" ]; then
  if [ ! -L "$TEXMF_DIR" ]; then
    echo "Symlinking to $DOTFILES_DIR/texmf..."
    ln -sf "$DOTFILES_DIR/texmf" "$TEXMF_DIR"
    echo "[DONE] Created symlink to $DOTFILES_DIR/texmf."
  else
    echo "[EXISTS] texmf symlink at $TEXMF_DIR"
  fi
else
  echo "[WARNING] texmf directory not found, skipping texmf setup"
fi

# Update TeX file database; you might need to enter your admin password
if command -v mktexlsr &> /dev/null; then
  echo "Updating TeX file database..."
  sudo mktexlsr
  echo "[DONE] Updated TeX file database"
else
  echo "[WARNING] mktexlsr not found, skipping database update"
fi
