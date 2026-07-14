#!/bin/bash

echo ""

# Checks see if the script is ran as root.
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "_-STARTING THE CONFIGURATION SCRIPT-_"
echo "-------------------------------------"


# Network configuration.
#_-_-_-_-_-_-_-_-_-_-_-_


echo ""
echo "Checking Network Configuration!"
echo ""
netplan_file="/etc/netplan/10-lxc.yaml"

# Checks to see if the old IP address is in the netplan file.
if grep -q "192.168.16.241" "$netplan_file"; then
    echo "Changing IP address from .241 to .21"

    # Swaps out the old IP address for the new IP address in the netplan file.
    sed -i 's/192.168.16.241\/24/192.168.16.21\/24/g' "$netplan_file"

    # Activates the network configuration.
    netplan apply
    netplan_status="Updated address to 192.168.16.21."
else
    netplan_status="Address is already up to date (192.168.16.21)."
fi


# /etc/hosts configuration.
#_-_-_-_-_-_-_-_-_-_-_-_-_-


echo "Checking Hosts Configuration!"
echo ""

# Finds and removes the old server1 names to prevent any duplicates.
if grep -q "server1" /etc/hosts; then
    sed -i '/server1/d' /etc/hosts
fi

# Adds the correct IP address and hostname to the hosts file.
echo "192.168.16.21 server1." >> /etc/hosts
hosts_status="Updated with 192.168.16.21 server1."


# Software installation.
#_-_-_-_-_-_-_-_-_-_-_-_


# Software installation.
echo "Checking Software Packages!"

apt-get update -y > /dev/null 2>&1

# Installs and starts Apache.
if ! dpkg -s apache2 >/dev/null 2>&1; then
    apt-get install -y apache2 > /dev/null
    apache_status="Apache was installed and started."
else
    apache_status="Apache has already been installed."
fi
systemctl enable --now apache2 2>/dev/null

# Installs and starts Squid.
if ! dpkg -s squid >/dev/null 2>&1; then
    apt-get install -y squid > /dev/null
    squid_status="Squid was installed and started."
else
    squid_status="Squid has already been installed."
fi
systemctl enable --now squid 2>/dev/null


# User configuration and SSH keys.
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_


echo "Configuring User Accounts!"
echo ""

# Sets up each user's account and keys.
configure_user() {
    username=$1
    sudo_user=$2

    # Checks to see if the user account already exists.
    if id "$username" &>/dev/null; then
        echo "User $username already exists."
    else
        echo "Creating user $username."
        # Creates the user with a home directory.
        useradd -m -s /bin/bash "$username"
    fi

    # Adds the user to the sudo group if needed.
    if [ "$sudo_user" = "yes" ]; then
        if ! id -nG "$username" | grep -qw "sudo"; then
            usermod -aG sudo "$username"
        fi
    fi

    # Creates the .ssh directory for the user.
    ssh_directory="/home/$username/.ssh"
    if [ ! -d "$ssh_directory" ]; then
        mkdir -p "$ssh_directory"
        chmod 700 "$ssh_directory"
        chown "$username:$username" "$ssh_directory"
    fi

    # Generates a RSA SSH key if it is missing.
    if [ ! -f "$ssh_directory/id_rsa" ]; then
        ssh-keygen -t rsa -b 2048 -N "" -f "$ssh_directory/id_rsa" -q
        chown "$username:$username" "$ssh_directory/id_rsa" "$ssh_directory/id_rsa.pub"
    fi

    # Generates a ED25519 SSH key if it is missing.
    if [ ! -f "$ssh_directory/id_ed25519" ]; then
        ssh-keygen -t ed25519 -N "" -f "$ssh_directory/id_ed25519" -q
        chown "$username:$username" "$ssh_directory/id_ed25519" "$ssh_directory/id_ed25519.pub"
    fi

    # Creates an authorized keys configuration file if it is missing.
    authorized_file="$ssh_directory/authorized_keys"
    if [ ! -f "$authorized_file" ]; then
        touch "$authorized_file"
        chmod 600 "$authorized_file"
        chown "$username:$username" "$authorized_file"
    fi

    # Grabs the newly made keys out of their text files.
    rsa_key=$(cat "$ssh_directory/id_rsa.pub")
    ed_key=$(cat "$ssh_directory/id_ed25519.pub")

    # Adds the public key to the authorized list if not already there.
    grep -qF "$rsa_key" "$authorized_file" || echo "$rsa_key" >> "$authorized_file"
    grep -qF "$ed_key" "$authorized_file" || echo "$ed_key" >> "$authorized_file"
}

# Runs the configuration steps for each user.
configure_user "dennis" "yes"
configure_user "aubrey" "no"
configure_user "captain" "no"
configure_user "snibbles" "no"
configure_user "brownie" "no"
configure_user "scooter" "no"
configure_user "sandy" "no"
configure_user "perrier" "no"
configure_user "cindy" "no"
configure_user "tiger" "no"
configure_user "yoda" "no"

# The extra external key required for the Dennis user.
dennis_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

# Adds the instructors key to the Dennis user list if it is missing.
grep -qF "$dennis_key" /home/dennis/.ssh/authorized_keys || echo "$dennis_key" >> /home/dennis/.ssh/authorized_keys

echo ""


# Prints a configuration report  that shows what was completed.
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-


cat << EOF
====================
Configuration Report
====================

Network Setup:   $netplan_status
Hosts File:      $hosts_status
Apache:          $apache_status
Squid:           $squid_status
User Accounts:   All required users configured with SSH keys.

EOF
