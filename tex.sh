#!/bin/bash

TEXMF_DIR=$HOME/Library/texmf
BIB_DIR=$TEXMF_DIR/bibtex/bib
STYLE_DIR=$TEXMF_DIR/tex/latex

if [ ! -d "$BIB_DIR" ]; then
  if [ ! -d "$STYLE_DIR" ]; then
    echo "tex: Creating directories..."
    mkdir -p "$BIB_DIR"
    mkdir -p "$STYLE_DIR"

    echo "tex:Changing ownership..."
    chown -R $(whoami) "$TEX_MF"
  fi
else
  echo "tex: Directories already exist"
fi

echo "tex: Copying .bib files to $BIB_DIR..."
cp -f texmf/*.bib "$BIB_DIR"
echo "tex: Copying .sty files to $STYLE_DIR..."
cp -f texmf/*.sty "$STYLE_DIR"

echo "Updating TeX database..."
sudo mktexlsr

echo "TeX Setup complete"
