#!/bin/bash
set -e

# make sure we can run editors using ghostty
cp .bashrc_ubuntu ~/.bashrc

# Basic update and essentials
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install nginx
echo "Installing nginx..."
sudo apt install -y nginx certbot python3-certbot-nginx

# Make sure we have the correct access to the web root folder
sudo chown -R $USER:$USER /var/www

# Install Deno if not already installed
if ! command -v deno &> /dev/null; then
  echo "Installing Deno..."
  curl -fsSL https://deno.land/install.sh | sh
fi

# Add Deno to PATH if not already in .bashrc
if ! grep -q 'DENO_INSTALL' ~/.bashrc; then
  echo 'export DENO_INSTALL="$HOME/.deno"' >> ~/.bashrc
  echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> ~/.bashrc
fi

# Reload bashrc for current session
source ~/.bashrc

# Verify installation
deno --version

# Test and reload nginx
sudo nginx -t
sudo systemctl restart nginx

