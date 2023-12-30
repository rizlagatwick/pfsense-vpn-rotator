# pfSense Client VPN Rotator (`pfsense-vpn-rotator.sh`)

## Overview

`pfsense-vpn-rotator.sh` is a shell script designed for pfSense systems to automate the rotation of OpenVPN server addresses and ports for **existing** OpenVPN client configurations.

## Features

- Safely rotates VPN server configurations using the `pfSsh.php` command.
- Eliminates the risks associated with direct editing of `config.xml`.
- Automatically selects a random VPN server from predefined lists.
- Dynamically updates OpenVPN client configurations on pfSense.
- Restarts the VPN service to apply changes seamlessly.
- Supports multiple server lists based on VPN IDs.

## Why `pfSsh.php`?

The script leverages `pfSsh.php` for configuration changes rather than directly modifying `config.xml`. This approach reduces the risk of file corruption and syntax errors, ensuring the stability and integrity of your pfSense system's configuration. It's a best practice recommended for making programmable changes to pfSense configurations.

## Prerequisites

- You must have fully configured and working OpenVPN client configurations.
- pfSense 2.7.2 or later.
- Access to the pfSense shell and `/usr/local/sbin/pfSsh.php`.
- Basic understanding of shell scripting and pfSense configuration.

## Installation

1. Download and edit the script as required.
2. Ensure that your server lists (`server_list1`, `server_list2`, etc.) are correctly defined within the script. Each list should correspond to a specific VPN ID. (Example has ProtonVPN AU and US server lists)
3. Copy the script to your pfSense server (e.g., /usr/local/sbin).
4. Make the script executable: `chmod +x pfsense-vpn-rotator.sh`.

## Usage

Run the script directly from the pfSense shell or use the cron package in pfSense for scheduling the script execution.

```terminal
./pfsense-vpn-rotator.sh <vpnid>
```

Replace `<vpnid>` with the appropriate VPN ID.

## License

This script is released under the [MIT License](LICENSE).

## Disclaimer

This script is provided "as is", without warranty of any kind. Use it at your own risk. Always ensure you have backups of your configurations before running any automation scripts.
