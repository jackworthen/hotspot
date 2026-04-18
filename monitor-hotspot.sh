#!/bin/bash 

# --- Self-Elevation Logic ---
if [[ $EUID -ne 0 ]]; then
    echo -e "\e[31mPrivileged access required.\e[0m"
    exec sudo "$0" "$@"
fi

# --- Configuration --- 
INTERFACE=$(nmcli -t -f DEVICE,TYPE device status | grep ":wifi" | cut -d: -f1 | head -n1) 

if [ -z "$INTERFACE" ]; then 
    echo -e "\e[31mError: No active Wi-Fi interface found.\e[0m" 
    exit 1 
fi 

# --- Fetch Hotspot Info ---
CONN_NAME=$(nmcli -t -f DEVICE,NAME connection show --active | grep "^$INTERFACE:" | cut -d: -f2)
SSID=$(nmcli -t -f 802-11-wireless.ssid connection show "$CONN_NAME" | cut -d: -f2)
SEC_TYPE=$(nmcli -t -f 802-11-wireless-security.key-mgmt connection show "$CONN_NAME" | cut -d: -f2)

# Fetch Channel and Frequency Info
CHAN_INFO=$(iw dev "$INTERFACE" info)
CHANNEL=$(echo "$CHAN_INFO" | grep "channel" | awk '{print $2}')
FREQ_MHZ=$(echo "$CHAN_INFO" | grep "channel" | awk '{print $3}' | tr -d '(|MHz,')

# Determine Band based on MHz
if [ "$FREQ_MHZ" -lt 3000 ]; then
    BAND="2.4 GHz"
else
    BAND="5 GHz"
fi

# Format Security string
if [ -z "$SEC_TYPE" ] || [ "$SEC_TYPE" == "none" ]; then
    SECURITY="Open"
else
    SECURITY=$(echo "$SEC_TYPE" | tr '[:lower:]' '[:upper:]')
fi

# Function to convert bytes to human-readable format
human_readable() {
    local bytes=$1
    if [ -z "$bytes" ] || [ "$bytes" -eq 0 ]; then
        echo "0 B"
    elif [ "$bytes" -lt 1024 ]; then
        echo "${bytes} B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(echo "scale=1; $bytes/1024" | bc) KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$(echo "scale=1; $bytes/1048576" | bc) MB"
    else
        echo "$(echo "scale=1; $bytes/1073741824" | bc) GB"
    fi
}

trap "clear; exit" INT 

while true; do 
    # Removed sudo from the loop commands as script is now running as root
    STATIONS=$(iw dev "$INTERFACE" station dump | grep "Station" | awk '{print $2}' | sort -u) 
    
    if [ -z "$STATIONS" ]; then 
        COUNT=0 
    else 
        COUNT=$(echo "$STATIONS" | wc -l) 
    fi 

    clear 
    echo -e "\e[38;5;208m==============================================================================\e[0m" 
    echo -e "\e[38;5;208m SSID: $SSID ($SECURITY) | Band: $BAND (Ch: $CHANNEL) | Devices: $COUNT \e[0m" 
    echo -e "\e[38;5;208m==============================================================================\e[0m" 
    echo -e "Interface: $INTERFACE | Updated: $(date +%H:%M:%S) -- Press [Ctrl+C] to exit\n" 

    if [ "$COUNT" -eq 0 ]; then 
        echo -e "\e[31m  [!] No devices currently connected.\e[0m" 
    else 
        printf "\e[1m%-18s | %-15s | %-10s | %-10s | %-8s\e[0m\n" "MAC ADDRESS" "IP ADDRESS" "RX (UP)" "TX (DOWN)" "SIGNAL" 
        echo "------------------------------------------------------------------------------" 

        while read -r mac; do 
            if [ -n "$mac" ]; then 
                IP=$(ip neighbor show dev "$INTERFACE" | grep -i "$mac" | awk '{print $1}' | head -n1) 
                [ -z "$IP" ] && IP="Pending..." 

                STATION_INFO=$(iw dev "$INTERFACE" station get "$mac")
                
                SIGNAL=$(echo "$STATION_INFO" | grep "signal:" | awk '{print $2}' | head -n1)
                [ -z "$SIGNAL" ] && SIGNAL="N/A" 

                RX_BYTES=$(echo "$STATION_INFO" | grep "rx bytes:" | awk '{print $3}')
                TX_BYTES=$(echo "$STATION_INFO" | grep "tx bytes:" | awk '{print $3}')

                RX_HUMAN=$(human_readable "$RX_BYTES")
                TX_HUMAN=$(human_readable "$TX_BYTES")

                printf "%-18s | %-15s | %-10s | %-10s | %s dBm\n" "$mac" "$IP" "$RX_HUMAN" "$TX_HUMAN" "$SIGNAL" 
            fi 
        done <<< "$STATIONS" 
    fi 

    sleep 2 
done
