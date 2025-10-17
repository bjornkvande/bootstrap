#!/bin/bash
set -e

# make sure we can run editors using ghostty
cp .bashrc_ubuntu ~/.bashrc

# Basic update and essentials
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Installing essential packages
echo "Installing essential packages..."
sudo apt install -y unzip

# Install nginx
echo "Installing nginx and related packages..."
sudo apt install -y nginx certbot python3-certbot-nginx

# Make sure we have the correct access to the web root folder
sudo chown -R $USER:$USER /var/www

# Install Deno
sudo snap install deno

# Test and reload nginx
sudo nginx -t
sudo systemctl restart nginx

