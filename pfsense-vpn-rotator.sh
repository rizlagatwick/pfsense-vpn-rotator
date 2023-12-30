#!/bin/sh

# ---------------------------------------------------------------------------------
# Script Name: pfSense Client VPN Rotator (pfsense-vpn-rotator.sh)
#
# Description: Automates the rotation of OpenVPN server addresses and ports for
#              OpenVPN client configurations on pfSense systems. This script uses
#              pfSsh.php for making configuration changes, avoiding direct editing
#              of config.xml and potential file corruption. It selects a random VPN
#              server from predefined lists, updates the OpenVPN client configuration,
#              and restarts the VPN service for seamless changes. Example server lists
#              are provided for ProtonVPN AU and US.
#
# Usage:       ./pfsense-vpn-rotator.sh <vpnid>
#              Replace <vpnid> with the appropriate VPN ID.
#
# Prerequisites: Fully configured and working OpenVPN client configurations on pfSense.
#                Access to pfSense shell and /usr/local/sbin/pfSsh.php.
#                Basic understanding of shell scripting and pfSense configuration.
#
# Installation: Copy the script to a directory like /usr/local/sbin on your pfSense
#               server and make it executable using 'chmod +x pfsense-vpn-rotator.sh'.
#
# Schedule:     Use the cron package in pfSense for scheduling the script execution.
#
# Github:       https://github.com/bradsec/pfsense-vpn-rotator
# License:      MIT License
# Disclaimer:   Script provided "as is", without warranty. Use at your own risk.
# ---------------------------------------------------------------------------------

current_date_time=$(date +"%H:%M:%S %d %b %Y")
vpnid="$1"

# Define your server lists, the number should match the vpnid
server_list1="protonvpn_us_secure_core_server_list
185.159.157.122 51820
185.159.157.121 5060
185.159.157.124 1194
185.159.157.122 4569
185.159.157.121 51820
185.159.157.71 1194
185.159.157.121 1194
79.135.104.29 4569
185.159.157.130 80
185.159.157.122 5060
185.159.157.126 5060
185.159.157.147 1194
185.159.157.147 80
79.135.104.23 51820
185.159.157.122 1194
185.159.157.130 5060
185.159.157.121 80
185.159.157.126 51820
185.159.157.71 80
185.159.157.130 1194
185.159.157.126 80
185.159.157.130 4569
185.159.157.124 4569
79.135.104.29 80
185.159.157.122 80
185.159.157.147 4569
185.159.157.120 1194
185.159.157.120 5060
79.135.104.29 1194
185.159.157.123 5060
185.159.157.71 4569
185.159.157.120 80
185.159.157.147 5060
185.159.157.121 4569
185.159.157.123 80
185.159.157.126 4569
79.135.104.29 51820
79.135.104.23 4569
185.159.157.132 51820
79.135.104.29 5060
185.159.157.123 51820
79.135.104.23 80
79.135.104.23 5060
185.159.157.124 5060
185.159.157.124 51820
185.159.157.120 4569
185.159.157.71 5060
185.159.157.120 51820
185.159.157.132 1194
185.159.157.123 4569
185.159.157.132 4569
185.159.157.126 1194
185.159.157.124 80
79.135.104.23 1194
185.159.157.132 80
185.159.157.147 51820
185.159.157.132 5060
185.159.157.130 51820
185.159.157.71 51820
185.159.157.123 1194
"

server_list2="protonvpn_au_secure_core_server_list
185.159.157.253 5060
185.159.157.253 51820
185.159.157.192 51820
185.159.157.212 5060
185.159.157.252 1194
185.159.157.252 4569
185.159.157.252 5060
185.159.157.212 51820
185.159.157.211 51820
185.159.157.211 80
185.159.157.192 4569
185.159.157.253 80
185.159.157.212 80
185.159.157.253 1194
185.159.157.212 1194
185.159.157.211 1194
185.159.157.211 5060
185.159.157.212 4569
185.159.157.192 80
185.159.157.252 51820
185.159.157.253 4569
185.159.157.211 4569
185.159.157.192 1194
185.159.157.252 80
185.159.157.192 5060
"

run_pfshell_cmd_getconfig() {
    tmpfile=/tmp/getovpnconfig.cmd
    tmpfile2=/tmp/getovpnconfig.output

    # Create a file named config.input and write the desired content to it
    echo 'print_r($config['\'openvpn\'']['\'openvpn-client\'']);' >$tmpfile
    echo 'exec' >>$tmpfile
    echo 'exit' >>$tmpfile

    if ! output=$(/usr/local/sbin/pfSsh.php <$tmpfile); then
        echo "Error executing command."
        return 1
    fi

    echo "$output" >$tmpfile2
    echo "$output"
}

run_pfshell_cmd_get_server_addr() {
    local array_index="$1"

    # Check if /tmp/getovpnconfig.output exists and is readable
    if [ ! -r /tmp/getovpnconfig.output ]; then
        echo "Error: Unable to read /tmp/getovpnconfig.output."
        return 1
    fi

    # Use grep and awk to extract the server_addr for the given array_index
    # Assuming the format of the output file matches the provided sample
    server_addr=$(grep -A 20 "\[$array_index\] => Array" /tmp/getovpnconfig.output | grep "server_addr" | awk -F "=>" '{print $2}' | tr -d '[:space:]')

    if [ -z "$server_addr" ]; then
        echo "Error: server_addr not found for vpnid $vpnid."
        return 1
    fi

    echo "$server_addr"
}

run_pfshell_cmd_setconfig() {
    echo "Running pfSsh.php to set OpenVPN configuration..."
    tmpfile=/tmp/setovpnconfig.cmd
    array_index="$1"
    server_addr="$2"
    server_port="$3"

    # Create a file named config.input and write the desired content to it
    echo "\$config['openvpn']['openvpn-client'][$array_index]['description'] = 'VPNID $vpnid Updated $current_date_time';" >$tmpfile
    echo "\$config['openvpn']['openvpn-client'][$array_index]['server_addr'] = '$server_addr';" >>"$tmpfile"
    echo "\$config['openvpn']['openvpn-client'][$array_index]['server_port'] = '$server_port';" >>"$tmpfile"
    echo 'write_config("Updating VPN client");' >>$tmpfile
    echo 'exec' >>$tmpfile
    echo 'exit' >>$tmpfile

    # Execute the file and capture the output
    output=$(/usr/local/sbin/pfSsh.php <"$tmpfile")
    echo "$output"
}

# Function to find the index of the array with the matching vpnid
find_vpnid_array_index() {
    local output="$1"

    echo "$output" | awk -v vpnid="$vpnid" '
    BEGIN { array_index = 0; found = 0 }
    /\[vpnid\] => / { 
        if ($3 == vpnid) { 
            found = 1; 
            exit;
        }
        array_index++;
    }
    END { if (found) print array_index; else print -1 }
    '
}

# Function to select a random line from an IP list
select_random_server() {
    # Accept the IP list and current IP address as arguments
    local server_list="$1"
    local current_server="$2"

    # Use awk to count the number of lines in the list
    num_lines=$(echo "$server_list" | wc -l)

    # Initialize variables for IP address and port
    local server_addr=""
    local server_port=""

    # Loop until a non-blank IP address and port are found
    while [ -z "$server_addr" ] || [ -z "$server_port" ] || [ "$server_addr" = "$current_server" ]; do
        # Generate a random line number within the range of lines
        random_line=$(awk -v min=1 -v max="$num_lines" 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')

        # Use sed to extract the random line
        random_server_line=$(echo "$server_list" | sed -n "${random_line}p")

        # Split the line into IP address and port number
        server_addr=$(echo "$random_server_line" | awk '{print $1}')
        server_port=$(echo "$random_server_line" | awk '{print $2}')
    done

    # Return the selected IP address and port number
    echo "$server_addr $server_port"
}

run_vpn_service_command() {
    local action="$1" # Action can be 'start', 'stop', or 'restart'

    # Validate the action using POSIX compliant syntax
    if [ "$action" != "start" ] && [ "$action" != "stop" ] && [ "$action" != "restart" ]; then
        echo "Invalid action: $action. Action must be 'start', 'stop', or 'restart'."
        return 1
    fi

    # Execute the command
    local command="/usr/local/sbin/pfSsh.php playback svc $action openvpn client $vpnid"
    echo "Executing: $command"

    if ! output=$($command); then
        echo "Error executing command."
        return 1
    fi

    echo "Command executed successfully."
    echo "$output"
}

main() {
    echo ""
    echo " ###########################################"
    echo " ## pfSense OpenVPN Client Rotator Script ##"
    echo " ###########################################"
    echo ""

    # Get the script name
    script_name=$(basename "$0")

    # Validate that vpnid is provided and is a number between 1 and 99
    if [ -z "$vpnid" ] || ! echo "$vpnid" | grep -qE '^[1-9][0-9]?$'; then
        echo "Error: vpnid not provided or is not a number between 1 and 99."
        echo "Usage: $script_name <vpnid>"
        echo "Example: $script_name 1"
        exit 1
    fi

    # Set the current IP address
    current_server="current_server_ADDRESS"

    # Determine which IP list to use based on the argument
    vpn_server_list="server_list${vpnid}"

    # Use eval to construct the command to get the correct IP list
    if ! eval "selected_server_addr_list=\${$vpn_server_list}"; then
        echo "Error evaluating IP list."
        exit 1
    fi

    # Call run_pfshell_cmd and store the output
    echo "Fetching all OpenVPN client configurations..."
    pfssh_output=$(run_pfshell_cmd_getconfig)

    # Find the array index with the matching vpnid
    echo "Finding array index for vpnid $vpnid..."
    array_index=$(find_vpnid_array_index "$pfssh_output")

    # Check if a valid index was found
    if [ "$array_index" -ge 0 ]; then
        echo "Found OpenVPN configuration for vpnid $vpnid at array index: $array_index"
    else
        echo "No OpenVPN configuration for vpnid $vpnid found."
        exit 1
    fi

    # Get the server_addr for the given array index
    echo "Fetching current server_addr for vpnid $vpnid..."
    current_server_addr=$(run_pfshell_cmd_get_server_addr "$array_index")
    echo "The current server_addr for vpnid $vpnid is: $current_server_addr"

    # Check if the selected IP list is not empty
    if [ -n "$selected_server_addr_list" ]; then
        selected_server_addr_port=$(select_random_server "$selected_server_addr_list" "$current_server")
    else
        echo "No server_list$vpnid defined in script."
        exit 1
    fi

    # Split the returned value into IP and port
    echo "Selecting random server address from server_list$vpnid..."
    selected_server_addr=$(echo "$selected_server_addr_port" | awk '{print $1}')
    selected_server_port=$(echo "$selected_server_addr_port" | awk '{print $2}')

    # Print the selected IP and port
    echo "Selected Server Address: $selected_server_addr"
    echo "Selected Server Port: $selected_server_port"

    # Call run_pfshell_cmd_setconfig and store the output
    echo "Setting new server address and port for vpnid $vpnid..."
    pfssh_output=$(run_pfshell_cmd_setconfig "$array_index" "$selected_server_addr" "$selected_server_port")

    # Call run_vpn_service_command to restart the VPN service
    echo "Restarting OpenVPN service for vpnid $vpnid..."
    run_vpn_service_command "restart"

    # Clean up tmp files
    echo "Cleaning up temporary files..."
    rm /tmp/getovpnconfig.cmd
    rm /tmp/getovpnconfig.output

    echo "Script completed."
}

main "$@"
