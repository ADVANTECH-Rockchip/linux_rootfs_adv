#!/bin/bash -e
TARGET_ROOTFS_DIR="binary"

echo "in mk-adv.sh"

echo "BUILD_IN_DOCKER : $BUILD_IN_DOCKER"

#---------------Overlay--------------
echo "1.copy overlay"
sudo cp -rf overlay-adv/* $TARGET_ROOTFS_DIR/

echo "2.install/remove/adjust debian"

# bt/wifi firmware
sudo mkdir -p $TARGET_ROOTFS_DIR/system/lib/modules/
sudo find ../../kernel/drivers/net/wireless/rockchip_wlan/*  -name "*.ko" | \
    xargs -n1 -i sudo cp {} $TARGET_ROOTFS_DIR/system/lib/modules/


if [ "$BUILD_IN_DOCKER" == "TRUE" ]; then
    # network
    sudo mv $TARGET_ROOTFS_DIR/etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf_back
    sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf
fi

finish() {
    sudo umount $TARGET_ROOTFS_DIR/dev
    exit -1
}
trap finish ERR

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR

#---------------Remove--------------

#--------- install base app ---------
apt-get update
apt-get install -y gnome-screenshot
apt-get install -y mtd-utils
apt-get install -y i2c-tools
apt-get install -y minicom
apt-get install -y ethtool
apt-get install -y pciutils
apt-get install -y hdparm
apt-get install -y ftp
apt-get install -y mpv
#for rpmb
#apt-get install -y mmc-utils
#for 4G
apt-get install -y libpcap0.8 ppp
apt-get install -y usb-modeswitch mobile-broadband-provider-info modemmanager

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
apt-get install -y tzdata

#for docker
dpkg -i  /packages/docker/*.deb
apt-get install -f -y

# Camera
apt-get install cheese -y
dpkg -i  /packages/others/camera/*.deb
if [ "$ARCH" == "armhf" ]; then
    cp /packages/others/camera/libv4l-mplane.so /usr/lib/arm-linux-gnueabihf/libv4l/plugins/
elif [ "$ARCH" == "arm64" ]; then
    cp /packages/others/camera/libv4l-mplane.so /usr/lib/aarch64-linux-gnu/libv4l/plugins/
fi

apt-get install -y v4l-utils
apt-get install -y guvcview

# qt
apt-get install -y gdbserver
apt-get install -y libqt5webenginecore5
apt-get install -y libqt5quickwidgets5
apt-get install -y libqt5webenginewidgets5


#---------------Adjust--------------
systemctl enable advinit.service
systemctl enable adv-wifi-init.service
systemctl enable ModemManager.service
systemctl enable pppd-dns.service

systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service

#for login
useradd -s '/bin/bash' -m -G adm,sudo,plugdev,audio,video adv
echo "adv:123456" | chpasswd
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
#ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#echo "Asia/Shanghai" >/etc/timezone

#mount userdata to /userdata
rm /userdata /oem /misc -rf
mkdir /userdata
mkdir /oem
chmod 0777 /userdata
chmod 0777 /oem

ln -s /dev/disk/by-partlabel/misc /misc

#set hostname
echo "Ubuntu18-04" > /etc/hostname
echo -e "127.0.0.1    localhost \n127.0.1.1    `cat /etc/hostname`\n" > /etc/hosts



#---------------Clean--------------
apt-get clean
apt autoremove -y
rm -rf /packages/dokcer/
rm -rf /var/lib/apt/lists/*
EOF

sudo umount $TARGET_ROOTFS_DIR/dev

if [ "$BUILD_IN_DOCKER" == "TRUE" ]; then
    # network
    sudo mv $TARGET_ROOTFS_DIR/etc/resolv.conf_back $TARGET_ROOTFS_DIR/etc/resolv.conf
fi

