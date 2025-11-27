#!/usr/bin/env bash

#######################################################################
# This file contains functions shared between the scripts

# figure out if we are runnin on omarchy
# in that case, we install a lot less packages
OMARCHY_CONFIG_DIR="$HOME/.config/omarchy"
if [ -d "$OMARCHY_CONFIG_DIR" ]; then
  RUNNING_OMARCHY=true
else
  RUNNING_OMARCHY=false
fi

MOUNT_POINT="/media/veracrypt1"

if [[ "$RUNNING_OMARCHY" == true ]]; then
  MOUNT_POINT="/run/media/veracrypt1"
fi

unmountSecretDrive() {
  if mount | grep -q "$MOUNT_POINT"; then
    echo "Unmounting VeraCrypt container..."
    veracrypt -d "$MOUNT_POINT" >/dev/null 2>&1 || true
  fi
}

mountSecretDrive() {
  if [[ "$RUNNING_OMARCHY" == true ]]; then
    echo "Mounting secret drive for omarchy"
    sudo pacman -S --noconfirm veracrypt
    USB_BASE_DIR="/run/media/$USER/BJORN_DEV"
    SECRET_FILE="$USB_BASE_DIR/secret"
    if [ ! -d "$MOUNT_POINT" ]; then
      sudo mkdir -p "$MOUNT_POINT"
      sudo chown "$USER":"$USER" "$MOUNT_POINT"
    fi
    if mount | grep -q "$MOUNT_POINT"; then
      echo "Secret container already mounted at $MOUNT_POINT."
    else
      if [ -f "$SECRET_FILE" ]; then
        echo echo "Mounting secret container at $MOUNT_POINT..."
        veracrypt --text --pim=0 --keyfiles="" --protect-hidden=no --mount "$SECRET_FILE" "$MOUNT_POINT"
      else
        echo "$SECRET_FILE not found, skipping mount."
      fi
    fi
    return
  fi

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
