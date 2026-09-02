#!/bin/sh

# sshpass: the epic 10 provisioning wizard (setup-pi.sh) authenticates to the
# USB-Ethernet-connected Pi non-interactively (sshpass -e via SSHPASS env).
# The openssh package also provides /usr/bin/ssh-keygen, which the daemon
# uses on the device to lazily generate the epic 10 ticket10-3 key pair
# under /etc/mira/ssh/ - the host-key generation below already relies on it
# being present in the rootfs.
xbps-install -r "$ROOTFS_PATH" -y openssh iptables sshpass

rm -f "$ROOTFS_PATH"/etc/motd "$ROOTFS_PATH"/etc/fstab
cp "$RES_PATH"/config/motd "$ROOTFS_PATH"/etc/motd
cp "$RES_PATH"/config/fstab "$ROOTFS_PATH"/etc/fstab

ln -sf /var/local/etc/localtime "$ROOTFS_PATH"/etc/localtime

echo "$DEFAULT_HOSTNAME" > "$ROOTFS_PATH"/etc/hostname

root_pw=$(mkpasswd -m sha-512 -s "$DEFAULT_ROOT_PASSWORD")
sed -i "/^root/d" "$ROOTFS_PATH"/etc/shadow
echo "root:${root_pw}:19000:0:99999::::" >> "$ROOTFS_PATH"/etc/shadow
"$HELPERS_PATH"/chroot_exec.sh chsh -s /bin/bash root

mkdir -p "$ROOTFS_PATH"/etc/ssh
cp "$RES_PATH"/config/sshd_config "$ROOTFS_PATH"/etc/ssh/sshd_config
chmod 600 "$ROOTFS_PATH"/etc/ssh/sshd_config

mkdir -p "$ROOTFS_PATH"/root/.ssh
if [ -f "$RES_PATH"/config/ssh_authorized_keys ]; then
  cp "$RES_PATH"/config/ssh_authorized_keys "$ROOTFS_PATH"/root/.ssh/authorized_keys
  chmod 600 "$ROOTFS_PATH"/root/.ssh/authorized_keys
fi

# epic 10 ticket10-3: fixed, persistent home for the device-side SSH key
# pair the daemon generates lazily (ssh-keygen -t ed25519 -f
# /etc/mira/ssh/id_ed25519). Created at build time so the path always
# exists; 0700 because the private key lives here. The rootfs partition is
# re-flashed, so after a flash the daemon simply generates a fresh pair and
# a finished wizard run installs it on the Pi again (idempotent).
mkdir -p "$ROOTFS_PATH"/etc/mira/ssh
chmod 700 "$ROOTFS_PATH"/etc/mira/ssh

# Generate SSH host keys at build time so sshd can start even when the
# firstboot flag is not set (data partition preserved across flashes)
"$HELPERS_PATH"/chroot_exec.sh /usr/bin/ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" -q
"$HELPERS_PATH"/chroot_exec.sh /usr/bin/ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" -q

cat > "$ROOTFS_PATH"/etc/sv/sshd/conf << 'EOF'
iptables -C INPUT -i bnep0 -p tcp --dport 22 -j REJECT 2>/dev/null || \
    iptables -I INPUT -i bnep0 -p tcp --dport 22 -j REJECT || \
    echo "sshd: failed to install bnep0 ssh guard"
ip6tables -C INPUT -i bnep0 -p tcp --dport 22 -j REJECT 2>/dev/null || \
    ip6tables -I INPUT -i bnep0 -p tcp --dport 22 -j REJECT || \
    echo "sshd: failed to install bnep0 ssh guard (v6)"
EOF

DEFAULT_SERVICES="${DEFAULT_SERVICES} sshd"
