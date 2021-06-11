#!/bin/bash -e
TARGET_ROOTFS_DIR="binary"

sudo cp -rf overlay-rc03/* $TARGET_ROOTFS_DIR/

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
apt-get update

#for bt udev
chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
apt-get install -y blueman
rm -f /usr/sbin/policy-rc.d
rm /etc/xdg/autostart/blueman.desktop
mv -f /etc/xdg/autostart/blueman.desktop.back /etc/xdg/autostart/blueman.desktop

apt-get install -y at
apt-get install -y bluez-hcidump

#---------------Adjust--------------
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service

# custom app
rm /etc/rc2.d/S04ondemand
rm /etc/rc3.d/S04ondemand  
rm /etc/rc4.d/S04ondemand  
rm /etc/rc5.d/S04ondemand  
rm /etc/rc2.d/S03cpufrequtils
rm /etc/rc3.d/S03cpufrequtils   
rm /etc/rc4.d/S03cpufrequtils   
rm /etc/rc5.d/S03cpufrequtils   

cp /tmp/.profile /root/

#---------------Clean--------------
rm -rf /etc/ftp_config.ini
rm -rf /tmp/
rm -rf /packages/
rm -rf /rk1808/
rm -rf /root/.cache/
rm -rf /var/cache/apt/apt-file/*
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /root/Desktop/PadTest

EOF
#------------------------------------------------------------------------------------------

#sudo umount $TARGET_ROOTFS_DIR/dev
