#!/bin/bash -e
TARGET_ROOTFS_DIR="../debian/binary"

echo "in mk-adv.sh"

echo "BUILD_IN_DOCKER : $BUILD_IN_DOCKER"

#---------------Overlay--------------
echo "1.copy overlay"
sudo cp -rf overlay-adv/* $TARGET_ROOTFS_DIR/
sudo cp -rf packages-adv/$ARCH/* $TARGET_ROOTFS_DIR/packages/

#if [ "$VERSION" != "debug" ] || [ "$VERSION" != "jenkins" ]; then
#	echo -e "\033[36m Copy  overlay-debug \033[0m"
#	# adb, video, camera  test file
#	sudo cp -rf ../debian/overlay-debug/* $TARGET_ROOTFS_DIR/
#fi

sudo cp -rf adv-build/* $TARGET_ROOTFS_DIR/tmp/

# For dotnet
# if [ 0 -eq `grep -c DOTNET_ROOT $TARGET_ROOTFS_DIR/etc/bash.bashrc` ]; then
#    sudo echo 'export PATH=$PATH:/usr/local/dotnet' >> $TARGET_ROOTFS_DIR/etc/bash.bashrc
#    sudo echo 'export DOTNET_ROOT=/usr/local/dotnet' >> $TARGET_ROOTFS_DIR/etc/bash.bashrc
# fi

echo "2.install/remove/adjust debian"

finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev
cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR

#---------------Remove--------------

#---------------Install--------------
apt-get update
apt-get install -y gnome-screenshot
apt-get install -y mtd-utils
apt-get install -y i2c-tools
apt-get install -y minicom
apt-get install -y ethtool
apt-get install -y pciutils
apt-get install -y hdparm
#for rpmb
apt-get install -y mmc-utils
#for 4G
apt-get install -y libpcap0.8 ppp
apt-get install -y usb-modeswitch mobile-broadband-provider-info modemmanager

#for bt udev
apt-get install -y at
apt-get install -y bluez-hcidump

# for camera
apt-get install -y v4l-utils
apt-get install -y guvcview

# for mosquitto
apt-get install -y mosquitto mosquitto-dev libmosquitto-dev

#for sync time
apt-get install -y cron
/tmp/timesync.sh
rm /tmp/timesync.sh

#for Chinese fonts
apt-get install -y xfonts-intl-chinese xfonts-wqy ttf-wqy-microhei ttf-dejavu

# For logrotate limit log size
apt-get install -y logrotate

#for docker
dpkg -i  /packages/docker/*.deb
apt-get install -f -y

#for dotnet
# .netcore
# sudo mkdir -p /usr/local/dotnet
# sudo cat packages/dotnet/dotnet-sdk-3.1.101-linux-arm.tar.gz* > packages/dotnet/dotnet-sdk-3.1.101-linux-arm.tar.gz
# sudo tar -xzf packages/dotnet/dotnet-sdk-*.tar.gz -C /usr/local/dotnet


#---------------Adjust--------------
systemctl enable advinit.service

#for login
echo "linaro:123456" | chpasswd
echo "root:123456" | chpasswd

#locale
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/# zh_CN GB2312/zh_CN GB2312/g' /etc/locale.gen
sed -i 's/# zh_CN.GB18030 GB18030/zh_CN.GB18030 GB18030/g' /etc/locale.gen
sed -i 's/# zh_CN.GBK GBK/zh_CN.GBK GBK/g' /etc/locale.gen
sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/# zh_TW BIG5/zh_TW BIG5/g' /etc/locale.gen
sed -i 's/# zh_TW.EUC-TW EUC-TW/zh_TW.EUC-TW EUC-TW/g' /etc/locale.gen
sed -i 's/# zh_TW.UTF-8 UTF-8/zh_TW.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen

#timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "Asia/Shanghai" >/etc/timezone

#mount userdata to /userdata
rm /userdata /oem /misc -rf
mkdir /userdata
mkdir /oem
chmod 0777 /userdata
chmod 0777 /oem

ln -s /dev/disk/by-partlabel/misc /misc

# for MPV
#chown -R linaro:linaro /home/linaro/.config

#---------------Clean--------------
sudo apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf packages/docker/
rm -rf packages/dotnet/
rm -rf packages/ffmpeg/
rm -rf packages/gst-bad/
rm -rf packages/gst-base/
rm -rf packages/gst-rkmpp/
rm -rf packages/libdrm/
rm -rf packages/mpv/
rm -rf packages/openbox/
rm -rf packages/others/
rm -rf packages/rga/
rm -rf packages/video/
rm -rf packages/xserver/

EOF

sudo umount $TARGET_ROOTFS_DIR/dev

if [ "$BUILD_IN_DOCKER" == "TRUE" ]; then
	# network
	sudo mv $TARGET_ROOTFS_DIR/etc/resolv.conf_back $TARGET_ROOTFS_DIR/etc/resolv.conf
fi

