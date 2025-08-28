#!/usr/bin/env bash

#######################################################################
# This script will mount the secret part of the USB stick with the keys

set -e

source "$(dirname "$0")/core.sh"


# unmont the drive
if [[ "$1" == "-u" && "$OSTYPE" == "linux-gnu" ]]; then
  echo "Unmounting secret USB drive..."
  unmountSecretDrive
  exit 0
fi

# mount the drive
if [ "$OSTYPE" == "linux-gnu" ]; then
  echo "Mounting secret USB drive..."
  mountSecretDrive
elif [[ "$OSTYPE" == darwin* ]]; then
  echo "Not supported on MacOS"
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

