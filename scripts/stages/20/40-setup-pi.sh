#!/bin/sh

# epic 10: the Raspberry Pi provisioning wizard. The daemon's /api/setup-pi
# execs this script with SSH_HOST/SSH_USER/SSH_PASS in the environment when
# the settings UI triggers "Pi automatisch einrichten"
SETUP_PI_SCRIPT="${SAVED_PWD}/setup-pi.sh"

if [ ! -f "$SETUP_PI_SCRIPT" ]; then
  color_echo "Missing ${SETUP_PI_SCRIPT}. Run 'just prepare' first." -Red
  exit 1
fi

install -d "$ROOTFS_PATH"/usr/local/share/mira
install -m 0755 "$SETUP_PI_SCRIPT" "$ROOTFS_PATH"/usr/local/share/mira/setup-pi.sh
