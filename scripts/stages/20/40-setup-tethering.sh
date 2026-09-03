#!/bin/sh

# epic 10 ticket10-6: the USB-tethering setup for the USB-connected
# Raspberry Pi. The daemon's /api/pi/tethering execs this script with
# SSH_HOST/SSH_USER (key-first, password fallback) when the onboarding
# wizard triggers the tethering setup
TETHERING_SCRIPT="${SAVED_PWD}/setup-tethering.sh"

if [ ! -f "$TETHERING_SCRIPT" ]; then
  color_echo "Missing ${TETHERING_SCRIPT}. Run 'just prepare' first." -Red
  exit 1
fi

install -d "$ROOTFS_PATH"/usr/local/share/mira
install -m 0755 "$TETHERING_SCRIPT" "$ROOTFS_PATH"/usr/local/share/mira/setup-tethering.sh
