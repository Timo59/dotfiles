#!/bin/bash
# =============================================================================
# vpn-LUH.sh - University of Hannover VPN connection script
# =============================================================================
# Connects to the Leibniz University Hannover VPN using OpenConnect.
# Symlinked to /usr/local/bin for global access.
# =============================================================================

VPN_SERVER="vpn-server.uni-hannover.de"
sudo openconnect "${VPN_SERVER}"
