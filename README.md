# Raspi-Writer: Software Installer for Writers and Publishers on Raspberry Pi

`raspi-writer` is a Bash script (`install_writers_software.sh`) designed for writers, novelists, storytellers, and publishers to easily install a curated list of writing and publishing software on a Raspberry Pi. It supports Raspberry Pi 2, 4, 5, and Zero (W and newer), with a user-friendly `whiptail` interface inspired by [KM4ACK's 73Linux script](https://github.com/km4ack/73Linux). The script disables resource-heavy apps for Pi Zero, configures GPIO-attached displays (3.5" to 1080p), and offers optional Wi-Fi hotspot setup that activates only when no known Wi-Fi networks are found. It includes publishing software for web and print.

## Features
- **Software Installation**: Installs a curated list of writing and publishing tools, including word processors, text editors, note-taking apps, and e-book management tools.
- **GPIO Display Support**: Configures HDMI or GPIO-attached displays (e.g., Waveshare 3.5", 4", 5", 7", 10.1", or Official Raspberry Pi 7" Touchscreen).
- **Wi-Fi Hotspot**: Optional setup for a Wi-Fi hotspot (WPA2, WPA3, WEP, or open) that activates on boot if no known Wi-Fi networks are detected.
- **Pi Zero Optimization**: Disables resource-heavy apps (e.g., LibreOffice, Calibre, Okular) on Pi Zero to prevent performance issues.
- **Publishing Support**: Includes tools like Calibre and Pandoc for formatting eBooks and print books. Reedsy Studio is accessible via a browser for additional formatting.

## Supported Software
| Software           | Purpose                                     | Resource-Heavy for Pi Zero? |
|--------------------|---------------------------------------------|----------------------------|
| LibreOffice Writer | Word processor                             | Yes                        |
| AbiWord            | Lightweight word processor                 | No                         |
| FocusWriter        | Distraction-free writing                   | No                         |
| Gedit              | Text editor                                | No                         |
| Vim                | Text editor                                | No                         |
| Emacs              | Text editor                                | No                         |
| Zim                | Desktop wiki for notes                     | No                         |
| Calibre            | E-book management and formatting           | Yes                        |
| Okular             | Document viewer                            | Yes                        |
| NE                 | Lightweight text editor                    | No                         |
| Evince             | Document viewer                            | No                         |
| Plume Creator      | Writing organization                       | No                         |
| WordGrinder        | Command-line word processor                | No                         |
| Pandoc             | Document converter for EPUB/PDF            | No                         |

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
- **Software Selection**: Use the `whiptail` checklist to select writing and publishing software. Resource-heavy apps are disabled on Pi Zero to prevent performance issues.
- **Display Configuration**: Choose an HDMI or GPIO display. Small displays (e.g., 3.5" Waveshare) may have scaling issues with GUI apps; terminal-based apps like Vim, NE, or WordGrinder are recommended.
- **Wi-Fi Hotspot**: Optionally configure a hotspot with a custom SSID, password, and authentication type. It activates on boot only if no known Wi-Fi networks are found.
- **Publishing**: Use Calibre or Pandoc for eBook and print book formatting. Access Reedsy Studio via Chromium at `https://studio.reedsy.com` for free web-based formatting.

## Notes
- Installation may take 20-60 minutes, depending on your Raspberry Pi model and internet speed.
- Reedsy Studio is a web-based tool and does not require installation; access it via Chromium.
- Check `/tmp/install_<software>.log` for installation errors (e.g., `/tmp/install_libreoffice-writer.log`).
- A reboot is required after setup to apply display and hotspot configurations.

## Troubleshooting
- **Installation Errors**: If a software installation fails, check the log file:
  ```bash
  cat /tmp/install_<software>.log
  ```
  Ensure your package lists are up-to-date:
  ```bash
  sudo apt-get update
  sudo apt-get install -y <software>
  ```
- **Network Issues**: If installations fail, verify connectivity:
  ```bash
  ping -c 4 google.com
  ```
  Check DNS: `cat /etc/resolv.conf` (should list nameservers like `8.8.8.8`).
- **Disk Space**: Ensure sufficient storage for Calibre and other tools:
  ```bash
  df -h /
  ```
- **Architecture**: Verify your OS architecture:
  ```bash
  dpkg --print-architecture
  ```
  Most software is compatible with `armhf` (32-bit Bullseye). If issues persist, consider a 64-bit OS (`aarch64`).

## Contributing
Contributions are welcome! Submit issues or pull requests on [GitHub](https://github.com/phluschott/raspi-writer).

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
