#!/bin/bash

TEXMF_DIR=$HOME/Library/texmf
DOTFILES_DIR=$HOME/.dotfiles

# Install all LaTex dependencies using tlmgr from newline delimited list Texfile
echo "Installing LaTex dependencies..."
sudo tlmgr update --self
sudo tlmgr install $(grep -v '^\s*#' Texfile | sed 's/#.*//' | tr -s '' | tr "\n" " ")
echo "LaTex dependencies installed..."

#Create a symbolic link from texmf in dotfiles to $HOME/Library/texmf
if [ ! -L "$TEXMF_DIR" ]; then
  echo "Creating symbolic link from $TEXMF_DIR ..."
  ln -s $DOTFILES_DIR/texmf $TEXMF_DIR
else
  echo "Symbolic link from $TEXMF_DIR already exists"
fi

# Update TeX file database; you might need to enter your admin password
sudo mktexlsr

echo "TeX Setup complete"
