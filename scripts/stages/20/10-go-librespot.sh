#!/bin/sh

# Install the locally-built go-librespot observer binary
GLS_BIN="${SAVED_PWD}/go-librespot-armv6"
GLS_CFG="${SAVED_PWD}/go-librespot-config.yml"

if [ ! -f "$GLS_BIN" ] || [ ! -f "$GLS_CFG" ]; then
  color_echo "Missing ${GLS_BIN} or ${GLS_CFG}. Run 'just prepare' first." -Red
  exit 1
fi

install -m 0755 "$GLS_BIN" "$ROOTFS_PATH"/usr/sbin/go-librespot
cp -a "$SCRIPTS_PATH"/services/go-librespot "$ROOTFS_PATH"/etc/sv/

# iAP2 sidecar
IAP2_BIN="${SAVED_PWD}/iap2-sidecar-armv7"
if [ -f "$IAP2_BIN" ]; then
  install -m 0755 "$IAP2_BIN" "$ROOTFS_PATH"/usr/bin/iap2-sidecar
else
  color_echo "No ${IAP2_BIN} - building without iPhone volume (run mira-daemon/iap2/build.sh)" -Yellow
fi

# svlogd writes to this dir from the log/run service script
mkdir -p "$ROOTFS_PATH"/var/log/go-librespot

mkdir -p "$ROOTFS_PATH"/etc/go-librespot
install -m 0644 "$GLS_CFG" "$ROOTFS_PATH"/etc/go-librespot/config.yml

# Lyrics provider env (sourced by the go-librespot run script): developer-supplied
# lp.env wins; otherwise ship documented empty defaults for the secondary lyrics
# provider vars (daemon issue #11) so they exist on-device and can be filled in.
if [ -s "${SAVED_PWD}/lp.env" ]; then
  install -m 0600 "${SAVED_PWD}/lp.env" "$ROOTFS_PATH"/etc/go-librespot/lp.env
else
  cat > "$ROOTFS_PATH"/etc/go-librespot/lp.env <<'EOF'
# Lyrics provider env — sourced by the go-librespot run script before daemon start.
#
# Secondary lyrics provider (daemon issue #11): an empty value means the
# corresponding header is NOT sent, so leave these empty unless you run a
# second lyrics API.
#   THING_LP_SECONDARY_USER_AGENT            - X-User-Agent header value
#   THING_LP_SECONDARY_APP_VERSION_HEADER    - header name carrying the app version
#   THING_LP_SECONDARY_APP_VERSION           - value sent in that header
#   THING_LP_SECONDARY_COOKIE_HEADER         - cookie header name (e.g. Cookie)
#   THING_LP_SECONDARY_COOKIE                - cookie value for that header
# Pairing rule: APP_VERSION_HEADER+APP_VERSION and COOKIE_HEADER+COOKIE are pairs -
# set both or neither.
THING_LP_SECONDARY_USER_AGENT=
THING_LP_SECONDARY_APP_VERSION_HEADER=
THING_LP_SECONDARY_APP_VERSION=
THING_LP_SECONDARY_COOKIE_HEADER=
THING_LP_SECONDARY_COOKIE=
EOF
  chmod 0600 "$ROOTFS_PATH"/etc/go-librespot/lp.env
fi

mkdir -p "$ROOTFS_PATH"/etc/mira
echo "$IMAGE_VERSION" > "$ROOTFS_PATH"/etc/mira/version.txt

DEFAULT_SERVICES="${DEFAULT_SERVICES} go-librespot"
