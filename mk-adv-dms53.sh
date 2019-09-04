#!/bin/bash -e
TARGET_ROOTFS_DIR="binary"

echo "In mk-adv.sh"

echo "Install/remove/adjust debian"

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR
apt-get update
apt-get install -y dosfstools
apt-get install -y stress
apt-get install -y udhcpc
apt-get install -y mplayer
echo -e "root\nroot\n" | passwd root

#git clone https://github.com/ADVANTECH-Corp/advtest-burnin.git /root/advtest -b dms_sa53
EOF

