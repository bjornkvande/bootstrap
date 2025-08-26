#!/usr/bin/env bash

#######################################################################
# This script will mount the secret part of the USB stick with the keys

set -e

unmountSecretDrive() {
  if mount | grep -q "$MOUNT_POINT"; then
    echo "Unmounting VeraCrypt container..."
    veracrypt -d "$MOUNT_POINT" >/dev/null 2>&1 || true
  fi
}

mountSecretDrive() {
  # the folder where this script is located (your USB stick)
  USB_BASE_DIR="$(cd "$(dirname "$PWD")" && pwd)"
  DEB_FILE="veracrypt-1.26.24-Ubuntu-20.04-amd64.deb"
  SECRET_FILE="$USB_BASE_DIR/secret"
  MOUNT_POINT="/media/veracrypt1"

  # Cleanup on exit
  # cleanup() {
  #   if mount | grep -q "$MOUNT_POINT"; then
  #     echo "Unmounting VeraCrypt container..."
  #     unmountSecretDrive
  #   fi
  # }
  # trap cleanup EXIT

  # install veracrypt
  INSTALL_FILE="$USB_BASE_DIR/$DEB_FILE"
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
  if mount | grep -q "$MOUNT_POINT"; then
    echo "Secret container already mounted at $MOUNT_POINT."
  else
    echo "Mounting secret container..."
    veracrypt --text --pim=0 --keyfiles="" --protect-hidden=no --mount "$SECRET_FILE" "$MOUNT_POINT"
  fi
}


# try to bootstrap our new machine
if [[ "$1" == "-u" && "$OSTYPE" == "linux-gnu" ]]; then
  echo "Unmounting secret USB drive..."
  unmountSecretDrive
  exit 0
fi

if [ "$OSTYPE" == "linux-gnu" ]; then
  echo "Mounting secret USB drive..."
  mountSecretDrive
elif [[ "$OSTYPE" == darwin* ]]; then
  echo "Not supported on MacOS"
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

