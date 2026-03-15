#!/bin/bash
# =============================================================================
# macos.prometheus.sh - MacBook Pro (prometheus) specific macOS settings
# =============================================================================
# Sourced by macos.sh. Also runs at login via LaunchAgent; sudo commands
# are guarded behind an interactive-terminal check so they skip silently.
# =============================================================================

if [ -t 0 ]; then
    # Timezone
    sudo systemsetup -settimezone "Europe/Berlin" > /dev/null

    # Energy: disable sleep while charging, 10 min on battery
    sudo pmset -c sleep 0
    sudo pmset -b sleep 10
    sudo pmset -a displaysleep 15
fi

echo "[DONE] prometheus macOS overrides applied"
