# 🚀 Features
* **Auto-Detection:** Lists only valid WiFi adapters (filtering out virtual P2P interfaces).
* **Dynamic Configuration:** Choose between an open network or a secure WPA2 hotspot.
* **Real-Time Monitoring:** Track connected devices, their IP addresses, signal strength, and live data usage (Upload/Download).
* **Validation:** Ensures WPA2 passwords meet the minimum 8-character requirement.
* **Clean Management:** Automatically wipes old connection profiles to prevent IP conflicts or configuration bloat.
* **Graceful Teardown:** Dedicated script to stop the hotspot and restore original network settings.

# 🛠 Prerequisites
* **Operating System:** Linux (Ubuntu, Debian, Kali, Fedora, etc.)
* **Dependencies:** * `NetworkManager` (specifically the `nmcli` tool)
    * `iw` (for station dumping and signal stats)
    * `bc` (for calculating human-readable data volumes)
* **Hardware:** A WiFi adapter that supports **AP (Access Point) Mode**.

# 📥 Installation
Clone the repository:
```bash
git clone https://github.com/yourusername/your-repo-name.git
cd your-repo-name
```

Make the scripts executable:
```bash
chmod +x start_hotspot.sh stop_hotspot.sh monitor_hotspot.sh
```

# 📋 Usage

### Starting the Hotspot
Run the main script with sudo privileges:
```bash
sudo ./start_hotspot.sh
```
Follow the interactive prompts to select your adapter, security type, and SSID.

### Monitoring Connections
To see who is connected and how much data they are using in real-time:
```bash
./monitor_hotspot.sh
```

### Stopping the Hotspot
To shut down the network and remove the configuration profile:
```bash
sudo ./stop_hotspot.sh
```

# 🔍 Script Details

### start_hotspot.sh
This script handles the heavy lifting. It sets up IPv4 Sharing automatically, configures the wireless mode to `ap`, and interfaces directly with the system's network stack.

### monitor_hotspot.sh
A live dashboard for your active hotspot. It:
* Lists all connected **MAC Addresses**.
* Resolves **IP Addresses** from the neighbor table.
* Calculates **RX (Upload)** and **TX (Download)** data volumes per device.
* Shows live **Signal Strength** (dBm).

### stop_hotspot.sh
A cleanup utility that deactivates the hotspot gracefully and ensures no orphaned connection profiles remain in your NetworkManager settings.

# ⚠️ Important Notes
* **Interface Support:** Not all WiFi adapters support AP mode. If the script fails to activate, check your hardware compatibility using `iw list`.
* **Permissions:** Since the scripts modify system network interfaces and query hardware stats, `sudo` is required for most operations.

# 📜 License
This project is licensed under the MIT License - see the LICENSE file for details.

# 👨‍💻 Author
**Jack Worthen** 🐙