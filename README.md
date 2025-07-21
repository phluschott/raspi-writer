# Raspi-Writer: Software Installer for Writers and Publishers on Raspberry Pi

`raspi-writer` is a Bash script (`install_writers_software.sh`) designed for writers, novelists, storytellers, and publishers to easily install a curated list of writing and publishing software on a Raspberry Pi. It supports Raspberry Pi 2, 4, 5, and Zero (W and newer), with a user-friendly `whiptail` interface inspired by [KM4ACK's 73Linux script](https://github.com/km4ack/73Linux). The script checks for a 64-bit OS to include Obsidian.md, disables resource-heavy apps for Pi Zero, configures GPIO-attached displays (3.5" to 1080p), and offers optional Wi-Fi hotspot setup that activates only when no known Wi-Fi networks are found. It automatically checks for the latest software versions for select tools and includes publishing software for Amazon KDP, web, and print.

## Features
- **Software Installation**: Installs a curated list of writing and publishing tools, including word processors, text editors, note-taking apps, e-book management tools, and KDP-compatible formatting software.
- **GPIO Display Support**: Configures HDMI or GPIO-attached displays (e.g., Waveshare 3.5", 4", 5", 7", 10.1", or Official Raspberry Pi 7" Touchscreen).
- **Wi-Fi Hotspot**: Optional setup for a Wi-Fi hotspot (WPA2, WPA3, WEP, or open) that activates only if no known Wi-Fi networks are detected.
- **Version Checking**: Automatically fetches the latest versions of Manuskript, CherryTree, Trelby, Xournal++, FreeMind, yWriter, Obsidian, and Scrivener using GitHub and SourceForge APIs, with fallbacks to stable versions.
- **Pi Zero Optimization**: Disables resource-heavy apps (e.g., LibreOffice, Calibre, Sigil, Kindle Create, Scrivener, TeX Live) on Pi Zero to prevent performance issues.
- **64-bit Support**: Includes Obsidian.md for 64-bit OS only.
- **Publishing Support**: Includes tools like Kindle Create, Scrivener, Pandoc, and TeX Live for formatting eBooks and print books for Amazon KDP and other platforms. Reedsy Studio is accessible via a browser for additional formatting.

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/phluschott/raspi-writer
   ```
2. Navigate to the directory:
   ```bash
   cd raspi-writer
   ```
3. Make the script executable:
   ```bash
   chmod +x install_writers_software.sh
   ```
4. Run the script as root:
   ```bash
   sudo ./install_writers_software.sh
   ```

## Usage
- **Software Selection**: Use the `whiptail` checklist to select writing and publishing software. Resource-heavy apps are disabled on Pi Zero, and 64-bit-only apps (e.g., Obsidian) are disabled on 32-bit OS.
- **Display Configuration**: Choose an HDMI or GPIO display. Small displays (e.g., 3.5" Waveshare) may have scaling issues with GUI apps; terminal-based apps are recommended.
- **Wi-Fi Hotspot**: Optionally configure a hotspot with a custom SSID, password, and authentication type. It activates on boot only if no known Wi-Fi networks are found.
- **Publishing**: Use Kindle Create, Scrivener, Calibre, Sigil, Pandoc, or TeX Live for KDP-compatible eBook and print book formatting. Access Reedsy Studio via Chromium at `https://studio.reedsy.com` for free web-based formatting.

## Notes
- The script automatically checks for the latest versions of Manuskript, CherryTree, Trelby, Xournal++, FreeMind, yWriter, Obsidian, and Scrivener using GitHub and SourceForge APIs, falling back to stable versions if the check fails.
- Installation may take 20-60 minutes, depending on your Raspberry Pi model and internet speed.
- Reedsy Studio is a web-based tool and does not require installation; access it via Chromium.
- Kindle Create requires Wine and Bottles, which may have performance overhead on lower-end devices.
- TeX Live is a large installation (several GB); ensure sufficient storage on your Raspberry Pi.
- Check `/tmp/install_<software>.log` for installation errors.
- A reboot is required after setup to apply display and hotspot configurations.
