#!/bin/bash -e
TARGET_ROOTFS_DIR="binary"

echo "In mk-adv-module.sh"

echo "Install/remove/adjust debian"

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR
apt-get update
apt-get install -y i2c-tools
apt-get install -y cifs-utils
apt-get install -y ppp
sed -i 's/auth/noauth/g' /etc/ppp/options
rm -rf /var/lib/apt/lists/*
EOF

