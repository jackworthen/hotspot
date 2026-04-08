#!/bin/bash

# 1. Deactivate the connection first (graceful shutdown)
sudo nmcli connection down OpenHotspot 2>/dev/null

# 2. Delete the profile entirely
sudo nmcli connection delete OpenHotspot

# 3. (Optional) Repeat for the Secure profile if you created one
sudo nmcli connection delete SecureHotspot 2>/dev/null

echo -e "\e[31mHotspot has been stopped and the configuration removed.\e[0m"
