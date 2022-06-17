#!/bin/bash -e
TARGET_ROOTFS_DIR="binary"

sudo cp -rf overlay-rc03-v2/* $TARGET_ROOTFS_DIR/

# bt/wifi firmware
sudo mkdir -p $TARGET_ROOTFS_DIR/system/lib/modules/
sudo find ../../kernel/drivers/net/wireless/rockchip_wlan/*  -name "*.ko" | \
    xargs -n1 -i sudo cp {} $TARGET_ROOTFS_DIR/system/lib/modules/

sudo find ../../kernel/drivers/bluetooth/*  -name "*.ko" | \
    xargs -n1 -i sudo cp {} $TARGET_ROOTFS_DIR/system/lib/modules/


finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR


#sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

#------------------------------------------------------------------------------------------
cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR

#--------- install base app ---------


#---------------Adjust--------------


# custom app
cp /tmp/.profile /root/
rm -rf /home/rocktech/App/FaceTerminal/ 
cat /tmp/FaceTerminal_install.bin* > /tmp/FaceTerminal_install.bin
chmod +x /tmp/FaceTerminal_install.bin
/tmp/FaceTerminal_install.bin
rm /tmp/FaceTerminal_install.bin*

#---------------Clean--------------
rm -rf /tmp/
rm -rf /root/.cache/
rm -rf /var/cache/apt/apt-file/*
apt-get clean
rm -rf /var/lib/apt/lists/*

EOF
#------------------------------------------------------------------------------------------

#sudo umount $TARGET_ROOTFS_DIR/dev
