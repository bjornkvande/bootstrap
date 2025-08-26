#!/bin/bash

###########################################
# This script is used to mount the secret 
# usb drive used for storing keys on linux

set -e

# the folder where this script is located (your USB stick)
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
DEB_FILE="veracrypt-1.26.24-Ubuntu-20.04-amd64.deb"
SECRET_FILE="$BASE_DIR/secret"
MOUNT_POINT="/media/veracrypt1"

# Cleanup on exit
cleanup() {
    echo "Unmounting VeraCrypt container..."
    veracrypt -d "$MOUNT_POINT" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# install veracrypt
INSTALL_FILE="$BASE_DIR/$DEB_FILE"
if ! command -v veracrypt &> /dev/null; then
    echo "Installing VeraCrypt..."
    sudo dpkg -i "$INSTALL_FILE" || sudo apt-get -f install -y
else
    echo "VeraCrypt already installed."
fi

# create the mount point - use the same mount point VeraCrypt GUI would use
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
    sudo chown "$USER":"$USER" "$MOUNT_POINT"
fi

# mount the secret drive 
echo "Mounting secret container..."
veracrypt --text --pim=0 --keyfiles="" --protect-hidden=no --mount "$SECRET_FILE" "$MOUNT_POINT"

# 4. Keep shell open until user exits
echo "Container mounted at $MOUNT_POINT"
echo "Press Ctrl+D or type 'exit' to unmount and quit."
$SHELL