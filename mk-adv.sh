#!/bin/bash -e
TARGET_ROOTFS_DIR="../rootfs/binary"

echo "in mk-adv.sh"

#---------------Overlay--------------
echo "1.copy overlay"
sudo cp -rf overlay-adv/* $TARGET_ROOTFS_DIR/
sudo cp -rf packages-adv/$ARCH/* $TARGET_ROOTFS_DIR/packages/

if [ "$VERSION" != "debug" ] || [ "$VERSION" != "jenkins" ]; then
	echo -e "\033[36m Copy  overlay-debug \033[0m"
	# adb, video, camera  test file
	sudo cp -rf ../rootfs/overlay-debug/* $TARGET_ROOTFS_DIR/
fi

sudo cp -rf adv-build/* $TARGET_ROOTFS_DIR/tmp/

# For dotnet
if [ 0 -eq `grep -c DOTNET_ROOT $TARGET_ROOTFS_DIR/etc/bash.bashrc` ]; then
    sudo echo 'export PATH=$PATH:/usr/local/dotnet' >> $TARGET_ROOTFS_DIR/etc/bash.bashrc
    sudo echo 'export DOTNET_ROOT=/usr/local/dotnet' >> $TARGET_ROOTFS_DIR/etc/bash.bashrc
fi

echo "2.install/remove/adjust debian"

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR

#---------------Remove--------------

#---------------Install--------------
apt-get update
apt-get install -y gnome-screenshot
apt-get install -y mtd-utils
apt-get install -y i2c-tools
#for rpmb
apt-get install -y mmc-utils
#for 4G
apt-get install -y libpcap0.8:armhf ppp
apt-get install -y usb-modeswitch mobile-broadband-provider-info modemmanager

#for bt udev
apt-get install -y at
#for sync time
apt-get install -y cron
/tmp/timesync.sh
rm /tmp/timesync.sh

#for docker
dpkg -i  /packages/docker/*.deb
apt-get install -f -y

#for dotnet
# .netcore
sudo mkdir -p /usr/local/dotnet
sudo cat packages/dotnet/dotnet-sdk-3.1.101-linux-arm.tar.gz* > packages/dotnet/dotnet-sdk-3.1.101-linux-arm.tar.gz
sudo tar -xzf packages/dotnet/dotnet-sdk-*.tar.gz -C /usr/local/dotnet


#---------------Adjust--------------
update-rc.d advinit defaults

#for login
echo "linaro:123456" | chpasswd
echo "root:123456" | chpasswd

#mount userdata to /userdata
rm /userdata /oem /misc -rf
mkdir /userdata
mkdir /oem
chmod 0777 /userdata
chmod 0777 /oem

ln -s /dev/disk/by-partlabel/misc /misc

# for MPV
chown -R linaro:linaro /home/linaro/.config

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

