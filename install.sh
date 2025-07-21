#!/bin/bash

# Script to install software for writers and publishers on Raspberry Pi, configure GPIO displays, and set up a Wi-Fi hotspot
# Compatible with Raspberry Pi 2, 4, 5, and Zero (W and newer)
# Uses whiptail for user interface, inspired by KM4ACK's 73Linux script
# Checks for 64-bit OS to include Obsidian.md
# Supports HDMI displays by default and GPIO displays (3.5" to 1080p)
# Sets up Wi-Fi hotspot, activates if no known network is found
# Automatically checks for the latest software versions for select tools
# Includes publishing software for Amazon KDP, web, and print

# Exit on error
set -e

# Ensure script runs as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Check for required dependencies (whiptail, curl, jq)
for cmd in whiptail curl jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "Installing $cmd..."
        apt-get update
        apt-get install -y $cmd
    fi
done

# Check for snapd and install if missing
if ! command -v snap &> /dev/null; then
    echo "Installing snapd..."
    apt-get update
    apt-get install -y snapd
    systemctl enable --now snapd.socket
    ln -s /var/lib/snapd/snap /snap
fi

# Check for flatpak and install if missing
if ! command -v flatpak &> /dev/null; then
    echo "Installing flatpak..."
    apt-get update
    apt-get install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Check for bottles and install via Flatpak if missing
if ! flatpak list | grep -q com.usebottles.bottles; then
    echo "Installing bottles via Flatpak..."
    flatpak install -y flathub com.usebottles.bottles || {
        echo "Failed to install bottles. Check Flatpak configuration and internet connection."
        exit 1
    }
fi

# Inform user about installation time
whiptail --msgbox "Welcome to the Raspi-Writer installer!\n\nA full installation with all software may take 20-60 minutes, depending on your network speed and Raspberry Pi model (e.g., Pi Zero is slower). Ensure a stable internet connection." 12 60

# Function to get latest GitHub release URL
get_latest_github_release() {
    repo=$1
    asset_pattern=$2
    fallback_url=$3
    url=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | jq -r ".assets[] | select(.name | test(\"$asset_pattern\")) | .browser_download_url" | head -n 1)
    if [ -z "$url" ]; then
        echo "$fallback_url"
    else
        echo "$url"
    fi
}

# Function to get latest FreeMind release from SourceForge
get_latest_freemind() {
    fallback_url=$1
    url=$(curl -s "https://sourceforge.net/projects/freemind/files/freemind/" | grep -oP 'freemind/\d+\.\d+\.\d+/freemind_\d+\.\d+\.\d+-1_all\.deb' | head -n 1)
    if [ -z "$url" ]; then
        echo "$fallback_url"
    else
        echo "https://sourceforge.net/projects/freemind/files/$url"
    fi
}

# Function to get latest yWriter release from Spacejock
get_latest_ywriter() {
    fallback_url=$1
    url=$(curl -s "http://www.spacejock.com/yWriter6_Download.html" | grep -oP 'http://www\.spacejock\.com/files/yWriter\d+_Linux\.zip' | head -n 1)
    if [ -z "$url" ]; then
        echo "$fallback_url"
    else
        echo "$url"
    fi
}

# Check if OS is 64-bit
IS_64BIT=0
if uname -m | grep -q aarch64; then
    IS_64BIT=1
fi

# Check if Pi Zero is selected
IS_PI_ZERO=0
if whiptail --yesno "Is this a Raspberry Pi Zero (W or newer)?" 8 50; then
    IS_PI_ZERO=1
fi

# Fetch latest version URLs
MANUSKRIPT_URL=$(get_latest_github_release "olivierkes/manuskript" "manuskript.*\.deb" "https://github.com/olivierkes/manuskript/releases/download/0.16.1/manuskript-0.16.1.deb")
CHERRYTREE_URL=$(get_latest_github_release "giuspen/cherrytree" "cherrytree.*_all\.deb" "https://github.com/giuspen/cherrytree/releases/download/1.2.0/cherrytree_1.2.0-1_all.deb")
TRELBY_URL=$(get_latest_github_release "trelby/trelby" "trelby.*_all\.deb" "https://github.com/trelby/trelby/releases/download/2.2/trelby_2.2_all.deb")
XOURNALPP_URL=$(get_latest_github_release "xournalpp/xournalpp" "xournalpp.*Debian-bullseye\.deb" "https://github.com/xournalpp/xournalpp/releases/download/v1.2.3/xournalpp-1.2.3-Debian-bullseye.deb")
FREEMIND_URL=$(get_latest_freemind "https://sourceforge.net/projects/freemind/files/freemind/0.9.0/freemind_0.9.0-1_all.deb")
YWRITER_URL=$(get_latest_ywriter "http://www.spacejock.com/yWriter6_Linux.zip")
OBSIDIAN_URL=$(get_latest_github_release "obsidianmd/obsidian-releases" "Obsidian.*\.AppImage" "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.7.4/Obsidian-1.7.4.AppImage")
SCRIVENER_URL=$(get_latest_github_release "LiteratureAndLatte/scrivener" "Scrivener.*\.deb" "https://www.literatureandlatte.com/files/scrivener-3.3.6-amd64.deb")

# Software list (name, description, command, resource-heavy, 64-bit only)
SOFTWARE_LIST=(
    "libreoffice-writer" "LibreOffice Writer - Word processor" "sudo apt-get install -y libreoffice-writer" "1" "0"
    "abiword" "AbiWord - Lightweight word processor" "sudo apt-get install -y abiword" "0" "0"
    "focuswriter" "FocusWriter - Distraction-free writing" "sudo apt-get install -y focuswriter" "0" "0"
    "manuskript" "Manuskript - Writing organization" "sudo snap install manuskript || (wget $MANUSKRIPT_URL -O /tmp/manuskript.deb && sudo dpkg -i /tmp/manuskript.deb && sudo apt-get install -f -y)" "0" "0"
    "cherrytree" "CherryTree - Note-taking" "sudo snap install cherrytree || (wget $CHERRYTREE_URL -O /tmp/cherrytree.deb && sudo dpkg -i /tmp/cherrytree.deb && sudo apt-get install -f -y)" "0" "0"
    "trelby" "Trelby - Screenwriting" "wget $TRELBY_URL -O /tmp/trelby.deb && sudo dpkg -i /tmp/trelby.deb && sudo apt-get install -f -y" "0" "0"
    "gedit" "Gedit - Text editor" "sudo apt-get install -y gedit" "0" "0"
    "vim" "Vim - Text editor" "sudo apt-get install -y vim" "0" "0"
    "emacs" "Emacs - Text editor" "sudo apt-get install -y emacs" "0" "0"
    "zim" "Zim - Desktop wiki for notes" "sudo apt-get install -y zim" "0" "0"
    "calibre" "Calibre - E-book management and formatting" "sudo apt-get install -y calibre" "1" "0"
    "sigil" "Sigil - E-book editor for EPUB" "flatpak install -y flathub com.sigil_ebook.Sigil" "1" "0"
    "xournalpp" "Xournal - Handwritten notes" "sudo snap install xournalpp || (wget $XOURNALPP_URL -O /tmp/xournalpp.deb && sudo dpkg -i /tmp/xournalpp.deb && sudo apt-get install -f -y)" "0" "0"
    "okular" "Okular - Document viewer" "sudo apt-get install -y okular" "1" "0"
    "ne" "NE - Lightweight text editor" "sudo apt install -y ne" "0" "0"
    "evince" "Evince - Document viewer" "sudo apt-get install -y evince" "0" "0"
    "dia" "Dia - Diagram creation" "sudo apt-get install -y dia" "1" "0"
    "freemind" "FreeMind - Mind mapping" "sudo snap install freemind || (wget $FREEMIND_URL -O /tmp/freemind.deb && sudo dpkg -i /tmp/freemind.deb && sudo apt-get install -f -y)" "1" "0"
    "ywriter" "yWriter - Novel writing" "sudo apt-get install -y wine && wget $YWRITER_URL -O /tmp/ywriter.zip && unzip /tmp/ywriter.zip -d /opt/ywriter && wine /opt/ywriter/yWriter6.exe /regserver && ln -s /opt/ywriter/yWriter6.exe /usr/local/bin/ywriter" "1" "0"
    "plume-creator" "Plume Creator - Writing organization" "sudo apt-get install -y plume-creator" "0" "0"
    "wordgrinder" "WordGrinder - Command-line word processor" "sudo apt-get install -y wordgrinder" "0" "0"
    "kindle-create" "Kindle Create - KDP formatting tool" "sudo apt-get install -y wine && wget https://d2b7dn6lvfj4po.cloudfront.net/KindleCreate_1.83.3.0.exe -O /tmp/kindle-create.exe && flatpak run com.usebottles.bottles --create KindleCreate --exec /tmp/kindle-create.exe" "1" "0"
    "scrivener" "Scrivener - Writing and publishing tool" "wget $SCRIVENER_URL -O /tmp/scrivener.deb && sudo dpkg -i /tmp/scrivener.deb && sudo apt-get install -f -y" "1" "0"
    "pandoc" "Pandoc - Document converter for EPUB/PDF" "sudo apt-get install -y pandoc" "0" "0"
    "texlive" "TeX Live - Typesetting for print books" "sudo apt-get install -y texlive-full" "1" "0"
)

# Add Obsidian if 64-bit
if [ $IS_64BIT -eq 1 ]; then
    SOFTWARE_LIST+=("obsidian" "Obsidian - Note-taking and knowledge base" "wget $OBSIDIAN_URL -O /opt/Obsidian.AppImage && chmod +x /opt/Obsidian.AppImage && ln -s /opt/Obsidian.AppImage /usr/local/bin/obsidian" "1" "1")
fi

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
    # Disable 64-bit only apps if not 64-bit
    elif [ $IS_64BIT_ONLY -eq 1 ] && [ $IS_64BIT -eq 0 ]; then
        STATUS="off"
        DESC="$DESC (Disabled: Requires 64-bit OS)"
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
