#!/bin/bash

# Prompt for Hostname, Domain Name, and IPv4 Address
read -p "Enter the desired hostname: " NEW_HOSTNAME
read -p "Enter the domain name (e.g., example.com): " DOMAIN_NAME
read -p "Enter the IPv4 address to set (e.g., 192.168.1.100): " STATIC_IP

# Set Hostname
echo "$NEW_HOSTNAME" > /etc/hostname
hostnamectl set-hostname "$NEW_HOSTNAME"

# Set Domain Name in /etc/hosts
# Remove any existing lines with old hostnames to avoid duplicates
sed -i "/127.0.1.1/d" /etc/hosts
echo "127.0.1.1   $NEW_HOSTNAME.$DOMAIN_NAME $NEW_HOSTNAME" >> /etc/hosts

# Configure Netplan for static IP
# Detect netplan config file (usually in /etc/netplan/*.yaml)
NETPLAN_FILE=$(ls /etc/netplan/*.yaml | head -n 1)

# Backup original netplan file
cp "$NETPLAN_FILE" "${NETPLAN_FILE}.bak"

# Find interface name automatically
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(en|eth|eno|ens|wlan)' | head -n 1)

cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses: [$STATIC_IP/24]
      gateway4: $(echo $STATIC_IP | awk -F. '{print $1"."$2"."$3".1"}')
      nameservers:
        search: [$DOMAIN_NAME]
        addresses: [8.8.8.8,8.8.4.4]
EOF

echo "Applying netplan..."
netplan apply

echo "Setup complete! The system will now reboot."
sleep 2
reboot
