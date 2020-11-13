#!/bin/bash -e

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"
RK_DIR="."

echo "BUILD_IN_DOCKER : $BUILD_IN_DOCKER"

ARCH='arm64'

if [ ! $VERSION ]; then
	VERSION="debug"
fi



finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR


echo -e "\033[36m Copy overlay to rootfs \033[0m"
# copy overlay to target
sudo cp -rf $RK_DIR/overlay-rk/* $TARGET_ROOTFS_DIR/


if [ "$BUILD_IN_DOCKER" == "TRUE" ]; then
	# network
	sudo mv $TARGET_ROOTFS_DIR/etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf_back
	sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf
fi

if [ "$VERSION" == "jenkins" ]; then
	# network
	sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf
fi


echo -e "\033[36m Change root.....................\033[0m"

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR

chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
apt-get update

#---------------power management --------------
apt-get install -y busybox pm-utils triggerhappy
cp /etc/Powermanager/triggerhappy.service  /lib/systemd/system/triggerhappy.service

#---------------Others--------------
#---------Camera---------
apt-get install cheese v4l-utils -y


#---------------Debug--------------
if [ "$VERSION" == "debug" ] || [ "$VERSION" == "jenkins" ] ; then
	apt-get install -y sshfs openssh-server bash-completion
fi

#---------------Custom Script--------------
systemctl enable rockchip.service
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service
rm /lib/systemd/system/wpa_supplicant@.service

#---------------Clean--------------
rm -rf /var/lib/apt/lists/*

# remove packages

EOF

sudo umount $TARGET_ROOTFS_DIR/dev
