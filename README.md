# Raspi-Writer: Software Installer for Writers on Raspberry Pi

`raspi-writer` is a Bash script (`install.sh`) designed for writers, novelists, storytellers, and written content creators to easily install a curated list of writing software on a Raspberry Pi. It supports Raspberry Pi 2, 4, 5, and Zero (W and newer), with a user-friendly interface inspired by KM4ACK's 73Linux script. The script checks for a 64-bit OS to include Obsidian.md, disables resource-heavy apps for Pi Zero, configures GPIO-attached displays (3.5" to 1080p), and offers optional Wi-Fi hotspot setup if no known Wi-Fi networks are found.

## Features

- **Software Selection**: Choose from 20 writing tools (e.g., LibreOffice Writer, FocusWriter, Vim, Obsidian) via a `whiptail` checkbox interface.
- **Pi Zero Compatibility**: Automatically greys out resource-heavy apps (e.g., LibreOffice, Calibre) when running on a Raspberry Pi Zero to ensure performance.
- **64-bit OS Support**: Detects 64-bit OS and offers Obsidian.md for advanced note-taking (requires 64-bit Raspberry Pi OS).
- **Display Support**: Configures GPIO-attached displays (e.g., Waveshare 3.5", Official 7" Touchscreen) or defaults to HDMI, with warnings for small displays (e.g., 3.5" or smaller) about GUI scaling issues.
- **Wi-Fi Hotspot Setup**: If no known Wi-Fi networks are detected, users can configure a hotspot with custom SSID, password, and authentication type (WPA-PSK, WPA3-PSK, WEP, or Open).
- **Error Handling**: Includes checks for root privileges, valid inputs, and installation failures, with user-friendly error messages.

## Supported Software

The script offers the following software, with resource-heavy apps marked for Pi Zero compatibility:

| Software           | Purpose                         | Resource-Heavy for Pi Zero? | 64-bit Only? |
|--------------------|---------------------------------|----------------------------|--------------|
| LibreOffice Writer | Word processor                 | Yes                        | No           |
| AbiWord            | Lightweight word processor     | No                         | No           |
| FocusWriter        | Distraction-free writing       | No                         | No           |
| Manuskript         | Writing organization           | No                         | No           |
| CherryTree         | Note-taking                    | No                         | No           |
| Trelby             | Screenwriting                  | No                         | No           |
| Gedit              | Text editor                    | No                         | No           |
| Vim                | Text editor                    | No                         | No           |
| Emacs              | Text editor                    | No                         | No           |
| Zim                | Desktop wiki for notes         | No                         | No           |
| Calibre            | E-book management              | Yes                        | No           |
| Sigil              | E-book editor                  | Yes                        | No           |
| Xournal            | Handwritten notes              | No                         | No           |
| Okular             | Document viewer                | Yes                        | No           |
| Evince             | Document viewer                | No                         | No           |
| Dia                | Diagram creation               | Yes                        | No           |
| FreeMind           | Mind mapping                   | Yes                        | No           |
| yWriter            | Novel writing                  | Yes                        | No           |
| Plume Creator      | Writing organization           | No                         | No           |
| WordGrinder        | Command-line word processor    | No                         | No           |
| Obsidian           | Note-taking and knowledge base | Yes                        | Yes          |

## Supported GPIO Displays

After software selection, the script offers configuration for common GPIO-attached displays (HDMI is supported by default):

| Display                     | Size/Resolution     | Notes                                                                 |
|-----------------------------|---------------------|----------------------------------------------------------------------|
| Waveshare 3.5" LCD (A)      | 3.5", 480x320       | Low resolution, suitable for terminal apps on Pi Zero.               |
| Waveshare 4" HDMI LCD       | 4", 800x480         | Moderate resolution, supports GUI apps, may lag on Pi Zero.          |
| Waveshare 5" HDMI LCD (B)   | 5", 800x480         | Good for GUI apps on Pi 4/5, slow on Pi Zero for heavy apps.         |
| Elecrow 5" HDMI Display     | 5", 800x480         | Similar to Waveshare 5", suitable for lightweight GUI apps.          |
| Waveshare 7" HDMI LCD (C)   | 7", 1024x600        | Higher resolution, good for Pi 4/5, not recommended for Pi Zero.     |
| Official Raspberry Pi 7" Touch | 7", 800x480       | Official support, works with all apps on Pi 4/5, slow on Pi Zero.    |
| Waveshare 10.1" HDMI LCD    | 10.1", 1280x800     | High resolution, suitable for Pi 4/5, too heavy for Pi Zero.         |
| Generic SPI TFT (e.g., ILI9341) | 2.8"-3.2", 320x240 | Very low resolution, ideal for terminal apps on Pi Zero.             |

## Requirements

- **Hardware**: Raspberry Pi 2, 4, 5, or Zero (W and newer).
- **Operating System**: Raspberry Pi OS (Debian-based, 32-bit or 64-bit for Obsidian).
- **Internet**: Required for downloading packages and AppImages.
- **Permissions**: Script must be run with `sudo` for root privileges.
- **Dependencies**: `whiptail`, `hostapd`, `dnsmasq` (installed automatically if needed).

## Installation and Usage

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/phluschott/raspi-writer.git
   cd raspi-writer
   ```

2. **Make the Script Executable**:
   ```bash
   chmod +x install.sh
   ```

3. **Run the Script**:
   ```bash
   sudo ./install.sh
   ```

4. **Follow Prompts**:
   - **Pi Zero Check**: Confirm if using a Pi Zero to disable resource-heavy apps.
   - **Software Selection**: Use checkboxes to select desired software.
   - **Display Selection**: Choose a GPIO display or select "none" for HDMI.
   - **Wi-Fi Hotspot**: If no Wi-Fi networks are found, configure a hotspot with SSID, password, and authentication type, or skip.
   - **Reboot**: Reboot the Pi after setup to apply changes.

5. **Reboot**:
   ```bash
   sudo reboot
   ```

## Notes

- **Pi Zero**: Resource-heavy apps (e.g., LibreOffice, Calibre, Obsidian) are disabled on Pi Zero to prevent performance issues.
- **Small Displays**: For 3.5" or smaller displays, the script warns about GUI scaling issues and recommends terminal-based apps (e.g., Vim, WordGrinder).
- **Hotspot Setup**: Requires `hostapd` and `dnsmasq`. Passwords must be 8+ characters. Supports WPA-PSK, WPA3-PSK, WEP, or Open authentication.
- **Obsidian**: Only available on 64-bit OS (Pi 4/5 with Raspberry Pi OS 64-bit).
- **Error Handling**: The script checks for root privileges, valid inputs, and installation failures, displaying user-friendly messages via `whiptail`.

## Contributing

Contributions are welcome! Please submit issues or pull requests on [GitHub](https://github.com/phluschott/raspi-writer). Ensure changes are compatible with Raspberry Pi OS and maintain the `whiptail` interface.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [KM4ACK's 73Linux script](https://github.com/km4ack/73Linux).
- Display configurations based on [Waveshare Wiki](https://www.waveshare.com/wiki/) and [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/).
- Software recommendations sourced from Reddit (r/raspberry_pi, r/writerDeck) and Raspberry Pi forums.
