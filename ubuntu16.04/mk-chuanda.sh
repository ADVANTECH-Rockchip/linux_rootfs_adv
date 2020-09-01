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
apt-get update
apt-get install -y apt-file
apt-file update
apt-get install -y gstreamer0.10-*
apt-get install -y libqt5multimedia5-plugins
apt-get install -y libjasper-dev
apt-get install -y libqt5serialport5-dev
apt-get install -y tzdata
apt-get install -y ftp

# For logrotate limit log size
apt-get install -y logrotate

# For Camera
apt-get install -y v4l-utils
apt-get install -y guvcview cheese camorama

#---------------Rga--------------
dpkg -i /packages/rga/*.deb
echo -e "\033[36m Setup Video.................... \033[0m"
apt-get install -f -y

echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic main restricted" >> /etc/apt/sources.list
apt-get update

dpkg -i /packages/xserver/*.deb
apt-get install -f -y

sed -i '/bionic/'d /etc/apt/sources.list
apt-get update

#---------------Adjust--------------
systemctl enable advinit.service

#for login
useradd -s '/bin/bash' -m -G adm,sudo,plugdev,audio,video adv
echo "adv:123456" | chpasswd
echo "root:smart" | chpasswd

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

#fonts
rm /usr/share/fonts/X11/misc/wenquanyi* -rf

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

#set hostname
echo "Ubuntu16-04" > /etc/hostname
echo -e "127.0.0.1    localhost \n127.0.1.1    `cat /etc/hostname`\n" > /etc/hosts

# custom app
cd /root/
mkdir Desktop
mv /tmp/PadTest_install.bin /root/Desktop/
cd /root/Desktop/
./PadTest_install.bin
rm ./PadTest_install.bin

#---------------Clean--------------
rm -rf /packages/
sudo apt-get clean
rm -rf /var/lib/apt/lists/*
EOF


sudo umount $TARGET_ROOTFS_DIR/dev
