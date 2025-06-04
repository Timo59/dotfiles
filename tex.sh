#!/bin/bash

TEXMF_DIR=$HOME/Library/texmf
DOTFILES_DIR=$HOME/.dotfiles

#Create a symbolic from $HOME/Library/texmf to the texmf file provided in the dotfiles
if [ ! -L "$TEXMF_DIR" ]; then
  echo "Creating symbolic link from $TEXMF_DIR ..."
  ln -s $DOTFILES_DIR/texmf $TEXMF_DIR
else
  echo "Symbolic link from $TEXMF_DIR already exists"
fi

echo "TeX Setup complete"
