#!/bin/bash

# --- Self-Elevation Logic ---
# If the Effective User ID is not 0 (root), re-run the script with sudo
if [[ $EUID -ne 0 ]]; then
    echo -e "\e[31mPrivileged access required.\e[0m"
    # Re-run the script, passing all original arguments ($@) to the new instance
    exec sudo "$0" "$@"
fi

# Define Colors
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}"
cat << "EOF"
  _    _  ____ _______  _____ _____    ____ _______ 
 | |  | |/ __ \__   __|/ ____|  __ \ / __ \__   __|
 | |__| | |  | | | |  | (___ | |__) | |  | | | |   
 |  __  | |  | | | |   \___ \|  ___/| |  | | | |   
 | |  | | |__| | | |   ____) | |    | |__| | | |   
 |_|  |_|\____/  |_|  |_____/|_|     \____/  |_|                                                   
EOF
echo -e "${NC}" 
echo "Toolkit v1.1"
echo 

# Save the current reg domain
CURRENT_REG=$(iw reg get | grep "^country" | awk '{print $2}' | sed 's/://' | head -n 1)
echo "$CURRENT_REG" > /tmp/previous_reg_domain

# --- Regulatory Domain Selection ---
echo -e "\e[38;5;208mConfigure Regulatory Domain\e[0m"
read -p "Select Country Code [Default: US]: " REG_DOMAIN
REG_DOMAIN=${REG_DOMAIN:-US}
REG_DOMAIN=${REG_DOMAIN^^}

if [[ ! "$REG_DOMAIN" =~ ^[A-Z]{2}$ ]]; then
    echo -e "\e[31mInvalid format. Falling back to US.\e[0m"
    REG_DOMAIN="US"
fi

echo -e "\e[38;5;208mUnlocking frequencies for $REG_DOMAIN...\e[0m"
iw reg set "$REG_DOMAIN"
sleep 0.5

# --- Adapter Selection ---
echo
echo -e "\e[38;5;208mSelect Wireless Adapter:\e[0m"
AVAILABLE_INTERFACES=$(nmcli device status | grep "wifi" | grep -v "p2p-dev" | awk '{print $1}')

if [ -z "$AVAILABLE_INTERFACES" ]; then
    echo -e "\e[31mError: No Wi-Fi adapters found.\e[0m"
    exit 1
fi

PS3="> "
select WIFI_IFACE in $AVAILABLE_INTERFACES; do
    if [ -n "$WIFI_IFACE" ]; then break; fi
done

# --- Band & Channel Selection ---
echo -e "\n\e[38;5;208mSelect Frequency Band:\e[0m"
BAND_OPTIONS=("2.4 GHz" "5 GHz")
select BAND_CHOICE in "${BAND_OPTIONS[@]}"; do
    case $BAND_CHOICE in
        "2.4 GHz") 
            HOTSPOT_BAND="bg"
            SELECTED_CHANNEL="" 
            break ;;
        "5 GHz")   
            HOTSPOT_BAND="a"
            echo -en "\e[33mForce a specific non-DFS channel? (y/n): \e[0m"
            read -n 1 FORCE_DFS
            echo ""
            if [[ "$FORCE_DFS" == "y" || "$FORCE_DFS" == "Y" ]]; then
                echo -e "\e[38;5;208mSelect common non-DFS Channel:\e[0m"
                CHAN_OPTIONS=("36" "40" "44" "48" "149" "153" "157" "161")
                select CHAN_CHOICE in "${CHAN_OPTIONS[@]}"; do
                    if [ -n "$CHAN_CHOICE" ]; then
                        SELECTED_CHANNEL="$CHAN_CHOICE"
                        break
                    fi
                done
            fi
            break ;;
        *) echo "Invalid selection." ;;
    esac
done

# --- Connection Type Selection ---
echo -e "\n\e[38;5;208mConnection Type:\e[0m"
select SECURE_CHOICE in "Open" "WPA2"; do
    if [ "$SECURE_CHOICE" == "WPA2" ]; then
        while true; do
            read -sp "Enter WPA2 Password (min 8 chars): " HOTSPOT_PW
            echo ""
            [[ ${#HOTSPOT_PW} -ge 8 ]] && break || echo -e "\e[31mToo short!\e[0m"
        done
        break
    else break; fi
done
echo
read -p "Enter SSID: " HOTSPOT_SSID
CON_NAME="OpenHotspot"

# --- Cleanup & Rebuild ---
nmcli connection down "$CON_NAME" 2>/dev/null
nmcli connection delete "$CON_NAME" 2>/dev/null

echo -e "\e[38;5;208mCreating $BAND_CHOICE Hotspot ($REG_DOMAIN)...\e[0m"

# Build connection
if [ "$SECURE_CHOICE" == "WPA2" ]; then
    nmcli connection add type wifi ifname "$WIFI_IFACE" con-name "$CON_NAME" autoconnect no ssid "$HOTSPOT_SSID" mode ap \
    wifi.band "$HOTSPOT_BAND" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$HOTSPOT_PW"
else
    nmcli connection add type wifi ifname "$WIFI_IFACE" con-name "$CON_NAME" autoconnect no ssid "$HOTSPOT_SSID" mode ap \
    wifi.band "$HOTSPOT_BAND"
fi

# Apply specific channel if selected
if [ -n "$SELECTED_CHANNEL" ]; then
    echo -e "\e[32mApplying Channel $SELECTED_CHANNEL...\e[0m"
    nmcli connection modify "$CON_NAME" wifi.channel "$SELECTED_CHANNEL"
fi

nmcli connection modify "$CON_NAME" ipv4.method shared
nmcli connection up "$CON_NAME"

echo -e "\e[32mHotspot is active on $WIFI_IFACE in domain $REG_DOMAIN.\e[0m"
