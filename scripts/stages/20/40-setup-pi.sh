#!/bin/sh

# epic 10: the Raspberry Pi provisioning wizard. The daemon's /api/setup-pi
# execs this script with SSH_HOST/SSH_USER/SSH_PASS in the environment when
# the settings UI triggers "Pi automatisch einrichten". The wizard transfers
# compute-server.js (read from the file next to setup-pi.sh, epic 10
# follow-up) base64-encoded to the Pi.
SETUP_PI_SCRIPT="${SAVED_PWD}/setup-pi.sh"
COMPUTE_SERVER_JS="${SAVED_PWD}/compute-server.js"

if [ ! -f "$SETUP_PI_SCRIPT" ]; then
  color_echo "Missing ${SETUP_PI_SCRIPT}. Run 'just prepare' first." -Red
  exit 1
fi

if [ ! -f "$COMPUTE_SERVER_JS" ]; then
  color_echo "Missing ${COMPUTE_SERVER_JS}. Run 'just prepare' first." -Red
  exit 1
fi

install -d "$ROOTFS_PATH"/usr/local/share/mira
install -m 0755 "$SETUP_PI_SCRIPT" "$ROOTFS_PATH"/usr/local/share/mira/setup-pi.sh
install -m 0644 "$COMPUTE_SERVER_JS" "$ROOTFS_PATH"/usr/local/share/mira/compute-server.js
