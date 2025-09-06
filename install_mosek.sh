#!/bin/bash

MOSEK_VERSION="11.0.28"
MOSEK_ARCHIVE="mosektoolsosxaarch64.tar.bz2"
MOSEK_URL="https://download.mosek.com/stable/${MOSEK_VERSION}/${MOSEK_ARCHIVE}"
MOSEK_SHA_URL="${MOSEK_URL}.sha256"
INSTALL_DIR="$HOME/mosek"

if [ ! -d "$INSTALL_DIR" ]; then
  echo "[INFO] Downloading MOSEK $MOSEK_VERSION..."
  curl -L -o "$MOSEK_ARCHIVE" "$MOSEK_URL"

  echo "[INFO] Downloading SHA256SUMS..."
  curl -L -o "SHA256SUMS" "$MOSEK_SHA_URL"

  echo "[INFO] Verifying SHA256 checksum..."
  grep "$MOSEK_ARCHIVE" "SHA256SUMS" | shasum -a 256 --check
  if [ $? -ne 0 ]; then
    echo "[ERROR] SHA256 checksum mismatch. Aborting."
    exit 1
  fi

  echo "[INFO] Extracting MOSEK..."
  tar -xj -C "$HOME" -f "$MOSEK_ARCHIVE"

  # Remove downloaded files
  rm "${MOSEK_ARCHIVE}" "SHA256SUMS"

  echo "[INFO] Removing quarantine attributes..."
  xattr -dr com.apple.quarantine "$INSTALL_DIR"

  echo "[INFO] Running MOSEK Python installer..."
  python "$INSTALL_DIR/11.0/tools/platform/osxaarch64/bin/install.py"

  echo "[DONE] Installed MOSEK to $INSTALL_DIR"
else
  echo "[EXISTS] MOSEK installation at $INSTALL_DIR"
fi
