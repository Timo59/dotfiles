#!/bin/bash

DOTFILES_DIR=$HOME/.dotfiles
ENGINE_DIR=$HOME/Library/TeXShop/Engines
TEXMF_DIR=$HOME/Library/texmf

# Install all LaTex dependencies using tlmgr from newline delimited list Texfile
echo "Installing LaTex dependencies..."
sudo tlmgr update --self
sudo tlmgr install $(grep -v '^\s*#' Texfile | sed 's/#.*//' | tr -s '' | tr "\n" " ")
echo "LaTex dependencies installed."

# Create a symbolic link from pdfLaTeXWithBuild.engine to TeXShop engines
echo "Symlinking TeXShop engine..."
chmod +x $DOTFILES_DIR/pdfLaTeXWithBuild.engine
mkdir -p $ENGINE_DIR
ln -sf "$DOTFILES_DIR/pdfLaTeXWithBuild.engine" "$ENGINE_DIR/pdfLaTeXWithBuild.engine"
echo "Symlink to $DOTFILES_DIR/pdfLaTeXWithBuild.engine created."

# Create a symbolic link from texmf in dotfiles to $HOME/Library/texmf
if [ ! -L "$TEXMF_DIR" ]; then
  echo "Symlinking to $DOTFILES_DIR/texmf..."
  ln -sf $DOTFILES_DIR/texmf $TEXMF_DIR
  echo "Symlink to $DOTFILES_DIR/texmf created."
else
  echo "Symlink to $DOTFILES_DIR/texmf already exists."
fi

# Update TeX file database; you might need to enter your admin password
sudo mktexlsr

echo "TeX Setup complete"
