
# 🚀 Features
* **Regulatory Domain Control:** Sets your WiFi region (e.g., US, JP, DE) to unlock local frequencies and comply with regional transmission power limits.
* **Dual-Band Support:** Easily toggle between **2.4 GHz** and **5 GHz** broadcasting.
* **Randomize MAC Address** Sets a randome MAC address for the selected wireless adapter.
* **Frequency & Channel Management:** * Support for forced non-DFS channels in the 5 GHz band (36, 40, 149, etc.) to ensure better compatibility with clients.
    * Real-time detection of the current operating channel and frequency in the monitor.
* **Auto-Detection:** Lists only valid WiFi adapters (filtering out virtual P2P interfaces).
* **Real-Time Monitoring:** Track connected devices, their IP addresses, signal strength, and live data usage (RX/TX).
* **Validation:** Ensures WPA2 passwords meet the minimum 8-character requirement.
* **Save Configuration:** Save hotspot configuration for quick and easy reuse.
* **Clean Management:** Automatically wipes old connection profiles to prevent IP conflicts and restores your original regulatory domain upon exit.
* **Graceful Teardown:** Dedicated script to stop the hotspot and restore original system network settings.

# 🛠 Prerequisites
* **Operating System:** Linux (Ubuntu, Debian, Kali, Fedora, etc.)
* **Dependencies:** * `NetworkManager` (specifically the `nmcli` tool)
    * `iw` (for regulatory settings, station dumping, and signal stats)
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
1. **Reg Domain:** Enter your country code (e.g., `US`) to unlock the correct channels.
2. **Adapter:** Select your physical wireless interface.
3. **Band/Channel:** Choose 2.4 GHz or 5 GHz. If using 5 GHz, you can optionally force a specific non-DFS channel.
4. **Security:** Choose "Open" or "WPA2" and set your SSID.

### Monitoring Connections
To see who is connected and how much data they are using in real-time:
```bash
./monitor_hotspot.sh
```

### Stopping the Hotspot
To shut down the network, remove the profile, and restore your previous regulatory domain:
```bash
sudo ./stop_hotspot.sh
```

# 🔍 Script Details

### start_hotspot.sh
Handles the core setup. It backups your current regulatory domain, configures IPv4 sharing, sets the wireless mode to `ap`, and interfaces with the system's network stack to launch the broadcast.

### monitor_hotspot.sh
A live dashboard for your active hotspot. It:
* Displays the current **SSID, Security Type, Band, and Channel**.
* Lists all connected **MAC Addresses**.
* Resolves **IP Addresses** from the neighbor table.
* Calculates **RX (Upload)** and **TX (Download)** data volumes per device in human-readable formats (KB/MB/GB).
* Shows live **Signal Strength** (dBm).

### stop_hotspot.sh
A cleanup utility that:
* Deactivates the hotspot profile.
* Deletes the configuration from NetworkManager.
* **Restores the system's original regulatory domain** from the temporary backup file.

# ⚠️ Important Notes
* **Interface Support:** Not all WiFi adapters support AP mode or 5 GHz broadcasting. Check your hardware compatibility using `iw list`.
* **Regulatory Compliance:** Ensure you set the correct country code for your location to avoid interfering with protected frequencies (like weather radar).
* **Permissions:** Since these scripts modify system network interfaces and query hardware stats, `sudo` is required for execution.

# 📜 License
This project is licensed under the MIT License - see the LICENSE file for details.


*Developed by Jack Worthen [@jackworthen](https://github.com/jackworthen)*
