#!/bin/zsh
# =============================================================================
# tailscale.prometheus.sh - Tailscale setup for the MacBook Pro (prometheus)
# =============================================================================
# Called by setup.sh as ./tailscale.$(hostname -s).sh, so it runs on prometheus
# only. lucifer never leaves the home LAN and reaches everything directly, so
# no Tailscale file exists for it and the dispatch is a clean no-op there.
#
# Tailscale gives prometheus access to the home LAN from anywhere without
# exposing a port on the router. Server-side setup is already done and is not
# touched here: raspberry0 is enrolled and advertises 192.168.178.3/32 as a
# subnet router, and the tailnet's split-DNS sends the `lan` domain to Pi-hole
# at 192.168.178.3.
#
# What this script does:
#   1. Checks the `tailscale` formula is installed (Brewfile.prometheus)
#   2. Starts tailscaled as a root LaunchDaemon so it comes up at boot
#   3. Ensures the Pi's advertised subnet route is accepted (--accept-routes)
#
# What it deliberately does NOT do: the first-time login. Enrolling a device
# needs interactive browser authentication, and automating it would require a
# Tailscale auth key — a secret that must never enter this repo. If the daemon
# is running but logged out, the script says so and stops.
#
# Usage:
#   ./tailscale.prometheus.sh   # also called by setup.sh
# =============================================================================

SERVICE="tailscale"

# The formula, not the cask: we want the daemon and CLI without the menu-bar
# app. Installed by Brewfile.prometheus during setup.sh.
if ! brew list --versions "$SERVICE" &>/dev/null; then
  echo "[WARNING] Homebrew formula '$SERVICE' not installed, skipping Tailscale setup"
  exit 0
fi
echo "[EXISTS] Homebrew formula '$SERVICE'"

# -----------------------------------------------------------------------------
# 1. Start tailscaled as a root LaunchDaemon
# -----------------------------------------------------------------------------
# `sudo brew services start` installs a LaunchDaemon in /Library/LaunchDaemons
# (runs from boot, before login) rather than a user LaunchAgent. The status
# must therefore be read with sudo too: plain `brew services list` lists the
# formula but always reports its status as "none".
SERVICE_STATUS="$(sudo brew services list 2>/dev/null | awk -v s="$SERVICE" '$1 == s {print $2}')"
if [ "$SERVICE_STATUS" = "started" ]; then
  echo "[EXISTS] $SERVICE service running as a root LaunchDaemon"
else
  echo "Starting $SERVICE as a root LaunchDaemon..."
  if sudo brew services start "$SERVICE"; then
    echo "[DONE] Started $SERVICE service"
  else
    echo "[ERROR] Could not start the $SERVICE service"
    exit 1
  fi
fi

# -----------------------------------------------------------------------------
# 2. Wait for the daemon to answer
# -----------------------------------------------------------------------------
# A freshly started tailscaled needs a moment before it serves the local API.
BACKEND_STATE=""
for _ in {1..15}; do
  BACKEND_STATE="$(tailscale status --json 2>/dev/null | jq -r '.BackendState // empty' 2>/dev/null)"
  [ -n "$BACKEND_STATE" ] && break
  sleep 1
done

if [ -z "$BACKEND_STATE" ]; then
  echo "[WARNING] tailscaled is not answering, skipping route configuration"
  exit 0
fi

# -----------------------------------------------------------------------------
# 3. Stop here if the device has not been enrolled yet
# -----------------------------------------------------------------------------
if [ "$BACKEND_STATE" = "NeedsLogin" ] || [ "$BACKEND_STATE" = "NoState" ]; then
  echo "[INFO] Tailscale is running but this device is not logged in."
  echo "[INFO] Enrolling needs an interactive browser login, so it is not automated."
  echo "[INFO] Run this yourself and follow the URL it prints:"
  echo "[INFO]     sudo tailscale up --accept-routes"
  exit 0
fi

# -----------------------------------------------------------------------------
# 4. Ensure the Pi's advertised subnet route is accepted
# -----------------------------------------------------------------------------
# The formula defaults --accept-routes to false (the GUI app would set it for
# you). Without it the Pi's advertised 192.168.178.3/32 is ignored and nothing
# works off-LAN. Note that `tailscale up` REPLACES the previous flag set rather
# than merging into it, so every flag we want has to be passed every time.
#
# Guarded rather than re-run blindly: tailscaled itself reports a health
# warning naming --accept-routes when a peer advertises routes we are not
# accepting. RouteAll is checked as well, since that is the pref the health
# warning is derived from and it stays authoritative even when the advertising
# peer is offline and the warning is therefore absent.
ROUTE_ALL="$(tailscale debug prefs 2>/dev/null | jq -r '.RouteAll // empty' 2>/dev/null)"
ROUTE_HEALTH="$(tailscale status --json 2>/dev/null | jq -r '.Health[]? | tostring' 2>/dev/null | grep -c -- '--accept-routes')"

NEEDS_UP=0
[ "$BACKEND_STATE" = "Stopped" ] && NEEDS_UP=1   # WantRunning is false
[ "$ROUTE_ALL" != "true" ] && NEEDS_UP=1
[ "${ROUTE_HEALTH:-0}" -gt 0 ] && NEEDS_UP=1

if [ "$NEEDS_UP" -eq 0 ]; then
  echo "[EXISTS] Tailscale up with subnet routes accepted"
else
  echo "Accepting advertised subnet routes..."
  if sudo tailscale up --accept-routes; then
    echo "[DONE] Tailscale up with --accept-routes"
  else
    echo "[WARNING] 'sudo tailscale up --accept-routes' failed"
  fi
fi

echo "[DONE] Tailscale setup complete"
