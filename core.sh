#!/usr/bin/env bash

#######################################################################
# This file contains functions shared between the scripts

MOUNT_POINT="/media/veracrypt1"

unmountSecretDrive() {
  if mount | grep -q "$MOUNT_POINT"; then
    echo "Unmounting VeraCrypt container..."
    veracrypt -d "$MOUNT_POINT" >/dev/null 2>&1 || true
  fi
}

mountSecretDrive() {
  # the folder where this script is located (your USB stick)
  USB_BASE_DIR="/media/bjorn/BJORN_DEV"
  DEB_FILE="veracrypt-1.26.24-Ubuntu-20.04-amd64.deb"
  SECRET_FILE="$USB_BASE_DIR/secret"

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
    if [ -f "$SECRET_FILE" ]; then
      echo "Mounting secret container..."
      veracrypt --text --pim=0 --keyfiles="" --protect-hidden=no --mount "$SECRET_FILE" "$MOUNT_POINT"
    else
      echo "$SECRET_FILE not found, skipping mount."
    fi
  fi
}

unmountDriveOnCleanup() {
  if mount | grep -q "$MOUNT_POINT"; then
    echo "Unmounting VeraCrypt container..."
    unmountSecretDrive
  fi
}
