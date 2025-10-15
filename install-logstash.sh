#!/bin/bash

set -e

# Prompt for source directory containing pipeline config files
read -p "Enter the path to your Logstash pipeline config files [/root/darksense-collector/Logstash-Configs/]: " SOURCE_DIR
SOURCE_DIR=${SOURCE_DIR:-/root/darksense-collector/Logstash-Configs/}

# Remove old Elastic key and repo files if present
sudo rm -f /etc/apt/trusted.gpg.d/elastic.gpg
sudo rm -f /usr/share/keyrings/elastic-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/elastic-8.x.list
sudo rm -f /etc/apt/sources.list.d/elastic-9.x.list

# Install prerequisites
sudo apt-get update
sudo apt-get install -y apt-transport-https wget gnupg curl

# Add Elastic GPG key in supported format and repo (for Logstash 9.x)
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/9.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-9.x.list

# Update and install Logstash
sudo apt-get update
sudo apt-get install -y logstash

# Ensure /etc/logstash/conf.d exists
sudo mkdir -p /etc/logstash/conf.d

# Copy pipeline configs
if [ -d "$SOURCE_DIR" ]; then
    sudo cp -f "$SOURCE_DIR"/*.conf /etc/logstash/conf.d/
    # Copy pipelines.yaml to /etc/logstash/
    if [ -f "$SOURCE_DIR/pipelines.yml" ]; then
        sudo cp -f "$SOURCE_DIR/pipelines.yml" /etc/logstash/
    fi
else
    echo "ERROR: Provided source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Set permissions
sudo chown logstash:logstash /etc/logstash/conf.d/*.conf

# Restart Logstash
sudo systemctl restart logstash

echo "Logstash installation and configuration completed."
