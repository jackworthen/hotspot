WiFi Hotspot Manager

A pair of lightweight Bash scripts to quickly turn your Linux machine into a wireless access point using NetworkManager. This tool dynamically detects your wireless hardware and allows for both Open and WPA2-Encrypted connections.
🚀 Features

    Auto-Detection: Lists only valid WiFi adapters (filtering out virtual P2P interfaces).

    Dynamic Configuration: Choose between an open network or a secure WPA2 hotspot.

    Validation: Ensures WPA2 passwords meet the minimum 8-character requirement.

    Clean Management: Automatically wipes old connection profiles to prevent IP conflicts or configuration bloat.

    Graceful Teardown: Dedicated script to stop the hotspot and restore original network settings.

🛠 Prerequisites

    Operating System: Linux (Ubuntu, Debian, Kali, Fedora, etc.)

    Dependencies: NetworkManager (specifically the nmcli command-line tool).

    Hardware: A WiFi adapter that supports AP (Access Point) Mode.

📥 Installation

    Clone the repository:
    Bash

    git clone https://github.com/yourusername/your-repo-name.git
    cd your-repo-name

    Make the scripts executable:
    Bash

    chmod +x start_hotspot.sh stop_hotspot.sh

📋 Usage
Starting the Hotspot

Run the main script with sudo privileges:
Bash

sudo ./start_hotspot.sh

Follow the interactive prompts:

    Select your wireless adapter from the numbered list.

    Choose your connection type (Open vs WPA2).

    If WPA2 is chosen, enter your password (minimum 8 characters).

    Enter your desired SSID (the name other devices will see).

Stopping the Hotspot

To shut down the network and remove the configuration profile:
Bash

sudo ./stop_hotspot.sh

🔍 Script Details
start_hotspot.sh

This script handles the heavy lifting. It:

    Sets up IPv4 Sharing automatically.

    Configures the wireless mode to ap.

    Uses nmcli to interface directly with the system's network stack.

stop_hotspot.sh

A cleanup utility that:

    Deactivates the OpenHotspot connection gracefully.

    Deletes the connection profile from NetworkManager.

    Ensures no orphaned hotspot profiles remain in your system settings.

⚠️ Important Notes

    Interface Support: Not all WiFi adapters support AP mode. If the script fails to activate, check your hardware compatibility using iw list.

    Permissions: Since the script modifies system network interfaces, sudo is required for almost all operations.