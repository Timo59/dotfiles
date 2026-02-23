#!/bin/bash
# =============================================================================
# install_mosek.sh - MOSEK optimization SDK installer
# =============================================================================
# Downloads and installs MOSEK for convex optimization. Verifies checksum,
# extracts to ~/mosek, and runs Python installer.
#
# Note: Academic licenses are free. Place license at ~/mosek/mosek.lic
# Apple Silicon (aarch64) only.
# =============================================================================

set -euo pipefail

MOSEK_VERSION="11.0.30"
MOSEK_ARCHIVE="mosektoolsosxaarch64.tar.bz2"
MOSEK_URL="https://download.mosek.com/stable/${MOSEK_VERSION}/${MOSEK_ARCHIVE}"
MOSEK_SHA_URL="${MOSEK_URL}.sha256"
INSTALL_DIR="$HOME/mosek"

if [ ! -d "$INSTALL_DIR" ]; then
  TMPDIR=$(mktemp -d)
  trap 'rm -rf "$TMPDIR"' EXIT

  echo "[INFO] Downloading MOSEK $MOSEK_VERSION..."
  curl -L -o "$TMPDIR/$MOSEK_ARCHIVE" "$MOSEK_URL"

  echo "[INFO] Downloading SHA256 checksum..."
  curl -L -o "$TMPDIR/SHA256SUMS" "$MOSEK_SHA_URL"

  echo "[INFO] Verifying SHA256 checksum..."
  if ! grep -F "$MOSEK_ARCHIVE" "$TMPDIR/SHA256SUMS" | shasum -a 256 --check; then
    echo "[ERROR] SHA256 checksum mismatch. Aborting."
    exit 1
  fi

  echo "[INFO] Extracting MOSEK..."
  tar -xj -C "$HOME" -f "$TMPDIR/$MOSEK_ARCHIVE"

  echo "[INFO] Removing quarantine attributes..."
  xattr -dr com.apple.quarantine "$INSTALL_DIR"

  echo "[INFO] Running MOSEK Python installer..."
  python3 "$INSTALL_DIR/11.0/tools/platform/osxaarch64/bin/install.py"

  echo "[DONE] Installed MOSEK to $INSTALL_DIR"
else
  echo "[EXISTS] MOSEK installation at $INSTALL_DIR"
fi
