#!/bin/bash
# =============================================================================
# macos.prometheus.sh - MacBook Pro (prometheus) specific macOS settings
# =============================================================================
# Applied after macos.sh by setup.sh on hostname 'prometheus'.
# =============================================================================

# Set computer/host name
sudo scutil --set ComputerName "prometheus"
sudo scutil --set HostName "prometheus"
sudo scutil --set LocalHostName "prometheus"

# Timezone
sudo systemsetup -settimezone "Europe/Berlin" > /dev/null

# Energy: disable sleep while charging, 10 min on battery
sudo pmset -c sleep 0
sudo pmset -b sleep 10
sudo pmset -a displaysleep 15

echo "[DONE] Machine-specific macOS settings applied (prometheus)"
