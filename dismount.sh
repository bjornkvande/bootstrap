#!/bin/bash

#############################################
# This script is used to dismount the secret 
# usb drive used for storing keys on linux

set -e

# the folder where this script is located (your USB stick)
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# check we have veracrypt installed
if ! command -v veracrypt &> /dev/null; then
    echo "VeraCrypt not installed..."
    exit 1
fi

# mount the secret drive 
MOUNT_POINT="/media/veracrypt1"
if [ -d "$MOUNT_POINT" ]; then
    echo "Dismounting secret container..."
    veracrypt -d "$MOUNT_POINT"
else
    echo "Secret container not mounted..."
fi
