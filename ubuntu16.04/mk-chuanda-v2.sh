#!/bin/bash -e
TARGET_ROOTFS_DIR="binary"

sudo cp -rf overlay-chuanda/* $TARGET_ROOTFS_DIR/

finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR


sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR

#--------- install base app ---------



#---------------Clean--------------
rm -rf /packages/
rm -rf /rk1808/
rm -rf /root/.cache/
rm -rf /var/cache/apt/apt-file/*
apt-get clean
rm -rf /var/lib/apt/lists/*

EOF


sudo umount $TARGET_ROOTFS_DIR/dev
