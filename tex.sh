#!/bin/bash

DOTFILES_DIR=$HOME/.dotfiles
ENGINE_DIR=$HOME/Library/TeXShop/Engines
TEXMF_DIR=$HOME/Library/texmf

# Install all LaTex dependencies using tlmgr from newline delimited list Texfile
if [ ! -f "$DOTFILES_DIR/Texfile" ]; then
  echo "[WARNING] Texfile not found in $(pwd), skipping LaTex package installation"
else
  echo "Installing LaTex dependencies..."

  # Update tlmgr first
  sudo tlmgr update --self

  # Install packages from Texfile (filter out commenst and empty lines)
  PACKAGES=$(grep -v '^\s*#' "$DOTFILES_DIR/Texfile" | sed 's/#.*//' | tr -s ' ' | tr "\n" " " | xargs)
  if [ -n "$PACKAGES" ]; then
    sudo tlmgr install $PACKAGES
    echo "[DONE] Installed LaTeX dependencies."
  else
    echo "[WARNING] No packages found in Texfile"
  fi
fi

# Create a symbolic link from pdfLaTeXWithBuild.engine to TeXShop engines
if [ -f "$DOTFILES_DIR/pdfLaTeXWithBuild.engine" ]; then
  echo "Symlinking TeXShop engine..."
  chmod +x $DOTFILES_DIR/pdfLaTeXWithBuild.engine
  mkdir -p $ENGINE_DIR
  ln -sf "$DOTFILES_DIR/pdfLaTeXWithBuild.engine" "$ENGINE_DIR/pdfLaTeXWithBuild.engine"
  echo "[DONE] Created symlink to $DOTFILES_DIR/pdfLaTeXWithBuild.engine."
else
  echo "[WARNING]: pdfLaTeXWithBuild.engine not found, skipping engine setup"
fi

# Create a symbolic link from texmf in dotfiles to $HOME/Library/texmf
if [ -d "$DOTFILES_DIR/texmf" ]; then
  if [ ! -L "$TEXMF_DIR" ]; then
    echo "Symlinking to $DOTFILES_DIR/texmf..."
    ln -sf $DOTFILES_DIR/texmf $TEXMF_DIR
  fi
  echo "[DONE] Created symlink to $DOTFILES_DIR/texmf."
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
