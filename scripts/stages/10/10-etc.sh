#!/bin/sh

xbps-install -r "$ROOTFS_PATH" -y openssh iptables

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
