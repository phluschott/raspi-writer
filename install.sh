#!/bin/bash

# Script to install software for writers and publishers on Raspberry Pi, configure GPIO displays, and set up a Wi-Fi hotspot
# Compatible with Raspberry Pi 2, 4, 5, and Zero (W and newer)
# Uses whiptail for user interface, inspired by KM4ACK's 73Linux script
# Disables resource-heavy apps for Pi Zero to prevent performance issues
# Supports HDMI displays by default and GPIO displays (3.5" to 1080p)
# Sets up Wi-Fi hotspot, activates if no known network is found
# Includes publishing software for web and print

# Exit on error
set -e

# Ensure script runs as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Check for required dependency (whiptail)
if ! command -v whiptail &> /dev/null; then
    echo "Installing whiptail..."
    apt-get update
    apt-get install -y whiptail
fi

# Inform user about installation time
whiptail --msgbox "Welcome to the Raspi-Writer installer!\n\nA full installation with all software may take 20-60 minutes, depending on your network speed and Raspberry Pi model (e.g., Pi Zero is slower). Ensure a stable internet connection." 12 60

# Check if Pi Zero is selected
IS_PI_ZERO=0
if whiptail --yesno "Is this a Raspberry Pi Zero (W or newer)?" 8 50; then
    IS_PI_ZERO=1
fi

# Software list (name, description, command, resource-heavy, 64-bit only)
SOFTWARE_LIST=(
    "libreoffice-writer" "LibreOffice Writer - Word processor" "sudo apt-get install -y libreoffice-writer" "1" "0"
    "abiword" "AbiWord - Lightweight word processor" "sudo apt-get install -y abiword" "0" "0"
    "focuswriter" "FocusWriter - Distraction-free writing" "sudo apt-get install -y focuswriter" "0" "0"
    "gedit" "Gedit - Text editor" "sudo apt-get install -y gedit" "0" "0"
    "vim" "Vim - Text editor" "sudo apt-get install -y vim" "0" "0"
    "emacs" "Emacs - Text editor" "sudo apt-get install -y emacs" "0" "0"
    "zim" "Zim - Desktop wiki for notes" "sudo apt-get install -y zim" "0" "0"
    "calibre" "Calibre - E-book management and formatting" "sudo apt-get install -y calibre" "1" "0"
    "okular" "Okular - Document viewer" "sudo apt-get install -y okular" "1" "0"
    "ne" "NE - Lightweight text editor" "sudo apt install -y ne" "0" "0"
    "evince" "Evince - Document viewer" "sudo apt-get install -y evince" "0" "0"
    "plume-creator" "Plume Creator - Writing organization" "sudo apt-get install -y plume-creator" "0" "0"
    "wordgrinder" "WordGrinder - Command-line word processor" "sudo apt-get install -y wordgrinder" "0" "0"
    "pandoc" "Pandoc - Document converter for EPUB/PDF" "sudo apt-get install -y pandoc" "0" "0"
)

# Build whiptail checklist for software
CHECKLIST=()
for ((i=0; i<${#SOFTWARE_LIST[@]}; i+=5)); do
    NAME="${SOFTWARE_LIST[i]}"
    DESC="${SOFTWARE_LIST[i+1]}"
    IS_HEAVY="${SOFTWARE_LIST[i+3]}"
    IS_64BIT_ONLY="${SOFTWARE_LIST[i+4]}"
    STATUS="off"
    # Disable resource-heavy apps for Pi Zero
    if [ $IS_PI_ZERO -eq 1 ] && [ $IS_HEAVY -eq 1 ]; then
        STATUS="off"
        DESC="$DESC (Disabled: Resource-heavy for Pi Zero)"
    fi
    CHECKLIST+=("$NAME" "$DESC" "$STATUS")
done

# Software selection
SELECTED_SOFTWARE=$(whiptail --title "Select Software for Writers and Publishers" --checklist \
    "Choose software to install (Pi Zero: heavy apps disabled)" 20 78 12 \
    "${CHECKLIST[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    echo "Cancelled by user."
    exit 1
fi

# Install selected software
# Remove quotes from SELECTED_SOFTWARE to handle multiple selections
SELECTED_SOFTWARE=$(echo $SELECTED_SOFTWARE | tr -d '"')
for SOFTWARE in $SELECTED_SOFTWARE; do
    for ((i=0; i<${#SOFTWARE_LIST[@]}; i+=5)); do
        if [ "${SOFTWARE_LIST[i]}" = "$SOFTWARE" ]; then
            echo "Installing ${SOFTWARE_LIST[i]}..."
            # Execute the installation command
            eval "${SOFTWARE_LIST[i+2]}" > /tmp/install_${SOFTWARE}.log 2>&1 || {
                whiptail --msgbox "Failed to install ${SOFTWARE_LIST[i]}. Check /tmp/install_${SOFTWARE}.log for details." 8 60
            }
            echo "${SOFTWARE_LIST[i]} installation completed."
        fi
    done
done

# GPIO Display selection
DISPLAY_LIST=(
    "none" "No GPIO display (HDMI default)" "on"
    "waveshare35a" "Waveshare 3.5\" LCD (480x320)" "off"
    "waveshare4" "Waveshare 4\" HDMI LCD (800x480)" "off"
    "waveshare5" "Waveshare 5\" HDMI LCD (800x480)" "off"
    "elecrow5" "Elecrow 5\" HDMI Display (800x480)" "off"
    "waveshare7" "Waveshare 7\" HDMI LCD (1024x600)" "off"
    "rpi7touch" "Official Raspberry Pi 7\" Touch (800x480)" "off"
    "waveshare10" "Waveshare 10.1\" HDMI LCD (1280x800)" "off"
    "ili9341" "Generic SPI TFT (e.g., 2.8\" ILI9341, 320x240)" "off"
)

SELECTED_DISPLAY=$(whiptail --title "Select GPIO Display" --radiolist \
    "Choose a GPIO display (select 'none' for HDMI)" 15 78 8 \
    "${DISPLAY_LIST[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    echo "Display selection cancelled, defaulting to HDMI."
    SELECTED_DISPLAY="none"
fi

# Configure selected display
case $SELECTED_DISPLAY in
    "waveshare35a")
        apt-get install -y waveshare35a || true
        echo "dtoverlay=waveshare35a" >> /boot/config.txt
        whiptail --msgbox "Waveshare 3.5\" LCD configured. Reboot required." 8 50
        ;;
    "waveshare4" | "waveshare5" | "elecrow5" | "waveshare7" | "waveshare10")
        echo "dtoverlay=vc4-kms-v3d" >> /boot/config.txt
        whiptail --msgbox "$SELECTED_DISPLAY configured. Reboot required." 8 50
        ;;
    "rpi7touch")
        raspi-config nonint do_touchscreen 0
        whiptail --msgbox "Official 7\" Touchscreen configured. Reboot required." 8 50
        ;;
    "ili9341")
        echo "dtoverlay=fb_ili9341" >> /boot/config.txt
        whiptail --msgbox "Generic SPI TFT configured. Reboot required." 8 50
        ;;
    "none")
        echo "Using HDMI display, no GPIO configuration needed."
        ;;
esac

# Display size warning for small displays
if [[ "$SELECTED_DISPLAY" == "waveshare35a" || "$SELECTED_DISPLAY" == "ili9341" ]]; then
    whiptail --msgbox "Small display detected. GUI apps may have scaling issues. Consider terminal-based apps like Vim or WordGrinder." 10 60
fi

# Wi-Fi hotspot setup (always offer, activate only if no known networks)
if whiptail --yesno "Set up a Wi-Fi hotspot? (Will activate only if no known Wi-Fi networks are found)" 8 60; then
    SSID=$(whiptail --inputbox "Enter Wi-Fi Hotspot SSID" 8 50 "RPi-Writers-Hotspot" 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then SSID="RPi-Writers-Hotspot"; fi

    PASSWORD=$(whiptail --passwordbox "Enter Wi-Fi Hotspot Password (8+ characters)" 8 50 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ] || [ ${#PASSWORD} -lt 8 ]; then
        whiptail --msgbox "Invalid password. Hotspot setup cancelled." 8 50
        exit 1
    fi

    AUTH_TYPE=$(whiptail --menu "Select Wi-Fi Authentication Type" 12 50 4 \
        "WPA-PSK" "WPA2 Personal" \
        "WPA3-PSK" "WPA3 Personal" \
        "OPEN" "No password" \
        "WEP" "WEP (less secure)" 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then AUTH_TYPE="WPA-PSK"; fi

    # Install hostapd and dnsmasq
    apt-get update
    apt-get install -y hostapd dnsmasq

    # Configure hostapd
    cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
driver=nl80211
ssid=$SSID
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOF

    case $AUTH_TYPE in
        "WPA-PSK"|"WPA3-PSK")
            echo "wpa=2" >> /etc/hostapd/hostapd.conf
            echo "wpa_passphrase=$PASSWORD" >> /etc/hostapd/hostapd.conf
            if [ "$AUTH_TYPE" = "WPA3-PSK" ]; then
                echo "wpa_key_mgmt=SAE" >> /etc/hostapd/hostapd.conf
                echo "ieee80211w=2" >> /etc/hostapd/hostapd.conf
            else
                echo "wpa_key_mgmt=WPA-PSK" >> /etc/hostapd/hostapd.conf
            fi
            ;;
        "WEP")
            echo "wep_default_key=0" >> /etc/hostapd/hostapd.conf
            echo "wep_key0=$PASSWORD" >> /etc/hostapd/hostapd.conf
            ;;
        "OPEN")
            ;;
    esac

    # Configure dnsmasq
    cat > /etc/dnsmasq.conf <<EOF
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF

    # Configure network
    cat > /etc/systemd/network/wlan0.network <<EOF
[Match]
Name=wlan0
[Network]
Address=192.168.4.1/24
DHCPServer=yes
EOF

    # Create script to enable hotspot only if no known Wi-Fi networks
    cat > /etc/network/if-pre-up.d/check_wifi_hotspot <<EOF
#!/bin/sh
if [ "\$IFACE" = "wlan0" ]; then
    if ! nmcli -t -f SSID dev wifi | grep -q .; then
        systemctl start hostapd
        systemctl start dnsmasq
    else
        systemctl stop hostapd
        systemctl stop dnsmasq
    fi
fi
EOF
    chmod +x /etc/network/if-pre-up.d/check_wifi_hotspot

    # Enable services
    systemctl unmask hostapd
    systemctl enable hostapd
    systemctl enable dnsmasq

    whiptail --msgbox "Wi-Fi hotspot configured (SSID: $SSID). Activates on boot if no known Wi-Fi networks are found. Reboot to apply." 8 60
else
    echo "Hotspot setup skipped."
fi

# Final message
whiptail --msgbox "Setup complete! Reboot to apply changes.\n\nNote: For Reedsy Studio, open Chromium and visit https://studio.reedsy.com to format eBooks and print books for free." 10 60
echo "Setup complete. Please reboot your Raspberry Pi."
