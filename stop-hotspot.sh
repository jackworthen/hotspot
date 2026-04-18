#!/bin/bash

# --- Self-Elevation Logic ---
# If the Effective User ID is not 0 (root), re-run the script with sudo
if [[ $EUID -ne 0 ]]; then
    echo -e "\e[31mPrivileged access required.\e[0m"
    exec sudo "$0" "$@"
fi

CON_NAME="OpenHotspot"
PREV_REG_FILE="/tmp/previous_reg_domain"
RESTORED=false

# 1. Handle Regulatory Domain Restoration FIRST
if [ -f "$PREV_REG_FILE" ]; then
    ORIGINAL_REG=$(cat "$PREV_REG_FILE")
    echo -e "\e[38;5;208mRestoring regulatory domain to $ORIGINAL_REG...\e[0m"
    iw reg set "$ORIGINAL_REG"
    rm "$PREV_REG_FILE"
    RESTORED=true
fi

# 2. Check for and clean up NetworkManager profiles
if nmcli connection show "$CON_NAME" >/dev/null 2>&1; then
    echo -e "\e[31mStopping active hotspot and removing configuration...\e[0m"
    nmcli connection down "$CON_NAME" 2>/dev/null
    nmcli connection delete "$CON_NAME" 2>/dev/null
    nmcli connection delete "SecureHotspot" 2>/dev/null
    echo -e "\e[32mHotspot removed successfully.\e[0m"
else
    # If no hotspot profile but we restored the reg domain
    if [ "$RESTORED" = true ]; then
         echo -e "\e[32mRegulatory domain restored (no active hotspot profile found).\e[0m"
    else
         echo -e "\e[33mNo active hotspot found and no previous domain record exists.\e[0m"
    fi
fi
