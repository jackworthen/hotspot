#!/bin/bash

# --- Self-Elevation Logic ---
if [[ $EUID -ne 0 ]]; then
    echo -e "\e[31mPrivileged access required.\e[0m"
    exec sudo "$0" "$@"
fi

# Define Colors & Paths
CYAN='\033[0;36m'
NC='\033[0m' 
REAL_USER=${SUDO_USER:-$USER}
CONFIG_FILE="/home/$REAL_USER/.hotspot_config"

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
echo "Toolkit v2.0"
echo 

# --- Config Loading Logic ---
LOADED_FROM_CONFIG=false
if [[ -f "$CONFIG_FILE" ]]; then
    echo -e "\e[38;5;208mManage Saved Configurations\e[0m"
    read -p "Use a saved profile? (y/n): " USE_SAVED
    
    if [[ "$USE_SAVED" =~ ^[Yy]$ ]]; then
        echo -e "\n\e[38;5;208mSelect a Profile:\e[0m"
        mapfile -t PROFILES < <(cut -d'|' -f1 "$CONFIG_FILE")
        
        PS3="> " 
        select PROFILE_NAME in "${PROFILES[@]}"; do
            if [ -n "$PROFILE_NAME" ]; then
                IFS='|' read -r HOTSPOT_SSID REG_DOMAIN MAC_CHOICE HOTSPOT_BAND SELECTED_CHANNEL SECURE_CHOICE HOTSPOT_PW < <(grep "^$PROFILE_NAME|" "$CONFIG_FILE")
                LOADED_FROM_CONFIG=true
                
                # Format variables for display
                DISPLAY_BAND=$([[ "$HOTSPOT_BAND" == "a" ]] && echo "5 GHz" || echo "2.4 GHz")
                DISPLAY_MAC=$([[ "$MAC_CHOICE" == "1" ]] && echo "Randomized" || echo "Hardware Default")
                DISPLAY_CHAN=${SELECTED_CHANNEL:-"Auto"}

                echo -e "\n\e[32mProfile '$PROFILE_NAME' loaded with settings:\e[0m"
                echo -e "------------------------------------"
                echo -e "SSID:       $HOTSPOT_SSID"
                echo -e "Reg Domain: $REG_DOMAIN"
                echo -e "MAC Policy: $DISPLAY_MAC"
                echo -e "Band:       $DISPLAY_BAND"
                echo -e "Channel:    $DISPLAY_CHAN"
                echo -e "Security:   $SECURE_CHOICE"
                echo -e "------------------------------------"
                break
            fi
        done
    fi
fi

if [ "$LOADED_FROM_CONFIG" = false ]; then
    # Save current reg domain
    CURRENT_REG=$(iw reg get | grep "^country" | awk '{print $2}' | sed 's/://' | head -n 1)
    echo "$CURRENT_REG" > /tmp/previous_reg_domain

    # --- Regulatory Domain Selection ---
    echo 
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
fi

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

if [ "$LOADED_FROM_CONFIG" = false ]; then
    # --- MAC Randomization Prompt ---
    echo -e "\n\e[38;5;208mAnonymize MAC Address?\e[0m"
    echo "1) Yes (Randomize)"
    echo "2) No (Use Hardware MAC)"
    read -p "> " MAC_CHOICE

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
                if [[ "$FORCE_DFS" =~ ^[Yy]$ ]]; then
                    echo -e "\n\e[38;5;208mSelect common non-DFS Channel:\e[0m"
                    CHAN_OPTIONS=("36" "40" "44" "48" "149" "153" "157" "161")
                    select CHAN_CHOICE in "${CHAN_OPTIONS[@]}"; do
                        if [ -n "$CHAN_CHOICE" ]; then
                            SELECTED_CHANNEL="$CHAN_CHOICE"
                            break
                        fi
                    done
                else
                    echo # Just a single newline if they say 'n'
                fi
                break ;;
            *) echo "Invalid selection." ;;
        esac
    done

    # --- Connection Type Selection ---
    echo -e "\e[38;5;208mConnection Type:\e[0m"
    select SECURE_CHOICE in "Open" "WPA2"; do
        if [ "$SECURE_CHOICE" == "WPA2" ]; then
            while true; do
                echo -e "\e[38;5;208mEnter WPA2 Password (min 8 chars):\e[0m"
                read -sp "> " HOTSPOT_PW
                echo ""
                [[ ${#HOTSPOT_PW} -ge 8 ]] && break || echo -e "\e[31mToo short!\e[0m"
            done
            break
        else break; fi
    done

    echo 
    # --- SSID Validation Loop ---
    while true; do
        echo -ne "\e[38;5;208mEnter SSID: \e[0m"
        read -p "> " HOTSPOT_SSID
        if [[ -n "$HOTSPOT_SSID" ]]; then
            break
        else
            echo -e "\e[31mError: SSID cannot be empty. Please try again.\e[0m"
        fi
    done

    # --- Save Prompt ---
    echo -en "\n\e[33mSave this configuration? (y/n): \e[0m"
    read -n 1 SAVE_CONF
    echo
    if [[ "$SAVE_CONF" =~ ^[Yy]$ ]]; then
        echo "$HOTSPOT_SSID|$REG_DOMAIN|$MAC_CHOICE|$HOTSPOT_BAND|$SELECTED_CHANNEL|$SECURE_CHOICE|$HOTSPOT_PW" >> "$CONFIG_FILE"
        chown "$REAL_USER":"$REAL_USER" "$CONFIG_FILE"
        echo -e "\e[32mConfiguration saved.\e[0m"
    fi
fi

# --- Spin up Hotspot ---
CON_NAME="OpenHotspot"
nmcli connection down "$CON_NAME" 2>/dev/null
nmcli connection delete "$CON_NAME" 2>/dev/null

echo -e "\n\e[38;5;208mApplying settings and starting hotspot...\e[0m"
iw reg set "$REG_DOMAIN"

if [ "$SECURE_CHOICE" == "WPA2" ]; then
    nmcli connection add type wifi ifname "$WIFI_IFACE" con-name "$CON_NAME" autoconnect no ssid "$HOTSPOT_SSID" mode ap \
    wifi.band "$HOTSPOT_BAND" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$HOTSPOT_PW"
else
    nmcli connection add type wifi ifname "$WIFI_IFACE" con-name "$CON_NAME" autoconnect no ssid "$HOTSPOT_SSID" mode ap \
    wifi.band "$HOTSPOT_BAND"
fi

if [ "$MAC_CHOICE" == "1" ]; then
    nmcli connection modify "$CON_NAME" 802-11-wireless.cloned-mac-address random
fi

if [ -n "$SELECTED_CHANNEL" ]; then
    nmcli connection modify "$CON_NAME" wifi.channel "$SELECTED_CHANNEL"
fi

nmcli connection modify "$CON_NAME" ipv4.method shared
nmcli connection up "$CON_NAME"

# Final Status
ACTUAL_MAC=$(ip link show "$WIFI_IFACE" | awk '/link\/ether/ {print $2}')
echo -e "\n\e[32mHotspot is active on $WIFI_IFACE\e[0m"
echo -e "\e[32mSSID: $HOTSPOT_SSID\e[0m"
echo -e "\e[32mRegulatory Domain: $REG_DOMAIN\e[0m"
echo -e "\e[32mCurrent MAC Address: $ACTUAL_MAC\e[0m"
