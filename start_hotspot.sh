#!/bin/bash
clear

# --- Adapter Selection ---
echo -e "\e[38;5;208mSelect Wireless Adapter:\e[0m"

# Get Wi-Fi interfaces, filtering out the virtual p2p-dev handles
AVAILABLE_INTERFACES=$(nmcli device status | grep "wifi" | grep -v "p2p-dev" | awk '{print $1}')

if [ -z "$AVAILABLE_INTERFACES" ]; then
    echo -e "\e[31mError: No Wi-Fi adapters found.\e[0m"
    exit 1
fi

# Set the prompt for all 'select' menus
PS3="> "

select WIFI_IFACE in $AVAILABLE_INTERFACES; do
    if [ -n "$WIFI_IFACE" ]; then
        echo -e "\e[32mSelected Adapter: $WIFI_IFACE\e[0m"
        break
    else
        echo -e "\e[31mInvalid selection. Please enter a number from the list.\e[0m"
    fi
done

# --- Connection Type Selection ---
echo -e "\n\e[38;5;208mConnection Type:\e[0m"
SEC_OPTIONS=("open" "WPA2")

select SECURE_CHOICE in "${SEC_OPTIONS[@]}"; do
    if [ "$SECURE_CHOICE" == "WPA2" ]; then
        echo -e "\e[32mSelected Type: WPA2\e[0m"
        # Prompt for password immediately
        while true; do
            read -sp "Enter the WPA2 Password (min 8 chars): " HOTSPOT_PW
            echo ""
            if [ ${#HOTSPOT_PW} -ge 8 ]; then
                break
            else
                echo -e "\e[31mPassword too short! WPA2 requires at least 8 characters.\e[0m"
            fi
        done
        break
    elif [ "$SECURE_CHOICE" == "open" ]; then
        echo -e "\e[32mSelected Type: open\e[0m"
        break
    else
        echo -e "\e[31mInvalid selection. Please choose 1 or 2.\e[0m"
    fi
done

# --- User Input ---
echo -e "\n\e[38;5;208mEnter the desired SSID for your Hotspot:\e[0m"
read -p "> " HOTSPOT_SSID

# We will use a consistent connection name for nmcli management
CON_NAME="OpenHotspot"

# --- Cleanup ---
sudo nmcli connection down "$CON_NAME" 2>/dev/null
sudo nmcli connection delete "$CON_NAME" 2>/dev/null

echo -e "\n\e[31mOld configuration removed.\e[0m"

# --- Re-building the Connection ---
echo -e "\e[38;5;208mInitializing Connection Profile for '$HOTSPOT_SSID'...\e[0m"

if [ "$SECURE_CHOICE" == "WPA2" ]; then
    # Secure Path
    sudo nmcli connection add type wifi ifname "$WIFI_IFACE" con-name "$CON_NAME" autoconnect no ssid "$HOTSPOT_SSID" mode ap \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "$HOTSPOT_PW"
else
    # Open Path
    sudo nmcli connection add type wifi ifname "$WIFI_IFACE" con-name "$CON_NAME" autoconnect no ssid "$HOTSPOT_SSID" mode ap
fi

# --- Final Configuration ---
echo -e "\e[38;5;208mConfiguring IPv4 sharing...\e[0m"
sudo nmcli connection modify "$CON_NAME" ipv4.method shared

# Activate the Network
echo -e "\e[38;5;208mActivating the network...\e[0m"
sudo nmcli connection up "$CON_NAME"

echo -e "\e[32mHotspot '$HOTSPOT_SSID' ($SECURE_CHOICE) is now active on $WIFI_IFACE.\e[0m"
