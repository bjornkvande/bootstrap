#!/bin/bash
set -e

# make sure we can run editors using ghostty
cp .bashrc_ubuntu ~/.bashrc

# Basic update and essentials
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install nginx
echo "Installing nginx..."
sudo apt install -y nginx

# Make sure we have the correct access to the web root folder
sudo chown -R $USER:$USER /var/www/html

# Test and reload nginx
sudo nginx -t
sudo systemctl restart nginx

