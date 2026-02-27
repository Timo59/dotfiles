#!/bin/bash
# =============================================================================
# macos.lucifer.sh — macOS overrides for lucifer (desktop)
# =============================================================================
# Applied by setup.sh after macos.sh. Runs on lucifer only.
# =============================================================================

# Add WhatsApp to Dock (lucifer only)
dockutil --add /Applications/WhatsApp.app --no-restart

killall "Dock" &>/dev/null || true

echo "[DONE] lucifer macOS overrides applied"
