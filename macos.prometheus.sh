#!/bin/bash
# =============================================================================
# macos.prometheus.sh - MacBook Pro (prometheus) specific macOS settings
# =============================================================================
# Sourced by macos.sh. Also runs at login via LaunchAgent; sudo commands
# are guarded behind an interactive-terminal check so they skip silently.
# =============================================================================

if [ -t 0 ]; then
    # Timezone
    sudo systemsetup -settimezone "Europe/Berlin" &> /dev/null

    # Energy: display sleep must be set before system sleep to avoid
    # "display sleep should have a lower timeout" warnings from pmset.
    sudo pmset -c displaysleep 15
    sudo pmset -c sleep 0
    sudo pmset -b displaysleep 5
    sudo pmset -b sleep 10
fi

echo "[DONE] prometheus macOS overrides applied"
