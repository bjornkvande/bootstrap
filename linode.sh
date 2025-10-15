#!/bin/bash
set -e

# Basic update and essentials
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install nginx
echo "Installing Nginx..."
sudo apt install -y nginx

# Test and reload nginx
sudo nginx -t
sudo systemctl restart nginx

