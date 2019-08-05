#!/bin/bash -e
TARGET_ROOTFS_DIR="binary"

echo "In mk-adv.sh"

echo "Install/remove/adjust debian"

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR
apt-get update

EOF

