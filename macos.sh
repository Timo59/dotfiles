#!/bin/bash
# =============================================================================
# macos.sh - macOS system preferences and Dock configuration
# =============================================================================
# Applies sensible macOS defaults and configures pinned Dock applications.
# Safe to re-run (idempotent). Also run at login via LaunchAgent.
# Machine-specific overrides (hostname, energy, sudo) go in macos.<hostname>.sh
# and are only applied by setup.sh.
#
# Based on https://mths.be/macos — trimmed to settings actively used.
# =============================================================================

# When run from LaunchAgent at login, wait for Dock to be ready
if ! pgrep -x Dock >/dev/null; then
    for i in $(seq 1 30); do
        pgrep -x Dock >/dev/null && break
        sleep 1
    done
    sleep 2  # Settle time: process running != plist fully loaded
fi

# Close System Settings to prevent it from overriding changes
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Fast window resize animation
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Quit printer app once jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable Gatekeeper "Are you sure you want to open this?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Set sidebar icon size to medium
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

###############################################################################
# Input: disable autocorrections annoying when typing code                   #
###############################################################################

defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Full keyboard access in modal dialogs (Tab to select buttons)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

###############################################################################
# Screen                                                                      #
###############################################################################

# Re-enable subpixel antialiasing (disabled by default since Mojave)
defaults write -g CGFontRenderingFontSmoothingDisabled -bool false
defaults write NSGlobalDomain AppleFontSmoothing -int 1

# Require password immediately after sleep
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

###############################################################################
# Finder                                                                      #
###############################################################################

# Disable window animations
defaults write com.apple.finder DisableAllAnimations -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# No warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# No .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use list view in all Finder windows
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# No warning before emptying Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Show ~/Library in Finder
chflags nohidden ~/Library
xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true

# Expand General, Open With, and Sharing & Permissions panes in Get Info
defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true

###############################################################################
# Dock: preferences                                                           #
###############################################################################

# Minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# Scale effect for minimize (faster than genie)
defaults write com.apple.dock mineffect -string "scale"

# Disable static-only mode (would hide all pinned apps, showing only running ones)
defaults write com.apple.dock static-only -bool false

# Do not show recently used apps in the Dock (quit apps are removed immediately)
defaults write com.apple.dock show-recents -bool false

# No animation when opening apps from the Dock
defaults write com.apple.dock launchanim -bool false

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Remove auto-hide delay
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.5

###############################################################################
# Dock: pinned application list                                               #
###############################################################################

DOCK_APPS=(
    "/System/Library/CoreServices/Finder.app"
    "/System/Applications/Utilities/Terminal.app"
    "/System/Applications/Mail.app"
    "/Applications/Safari.app"
    "/Applications/Obsidian.app"
    "/Applications/Spotify.app"
    "/Applications/Discord.app"
    "/System/Applications/Clock.app"
)

# Machine-specific additions
case "$(hostname -s)" in
    lucifer)  DOCK_APPS+=("/Applications/WhatsApp.app") ;;
esac

dockutil --remove all --no-restart

for app in "${DOCK_APPS[@]}"; do
    if [ -d "$app" ]; then
        dockutil --add "$app" --no-restart
    else
        echo "[WARNING] app not found, skipping: $app"
    fi
done

###############################################################################
# Machine-specific overrides                                                   #
###############################################################################

MACHINE_MACOS="$(dirname "$0")/macos.$(hostname -s).sh"
if [ -f "$MACHINE_MACOS" ]; then
    source "$MACHINE_MACOS"
fi

###############################################################################
# Apply changes                                                               #
###############################################################################

# Flush cfprefsd AFTER writes so the Dock can't save stale state on restart
killall cfprefsd 2>/dev/null || true
sleep 2
killall Dock 2>/dev/null || true
killall Finder &>/dev/null || true

echo "[DONE] macOS system preferences and Dock configured"
