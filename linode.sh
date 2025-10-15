#!/bin/bash
set -e

# make sure we can run editors using ghostty
cp .bash_profile ~/.bash_profile

# Basic update and essentials
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install nginx
echo "Installing nginx..."
sudo apt install -y nginx
# sudo cp nginx.conf /etc/nginx/nginx.conf

# Test and reload nginx
sudo nginx -t
sudo systemctl restart nginx

