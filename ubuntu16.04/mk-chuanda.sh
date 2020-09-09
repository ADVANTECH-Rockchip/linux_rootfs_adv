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

#for docker
dpkg -i  /packages/docker/*.deb
apt-get install -f -y

# For Camera
#apt-get install -y v4l-utils
#apt-get install -y guvcview cheese camorama

#---------------rk1808--------------
apt-get install -y build-essential python-dev python-setuptools python-pip libssl-dev openssl \
libsqlite3-dev libgdbm-dev libxft-dev libfontconfig1-dev libfreetype6-dev libpng-dev libc6-dev \
python-smbus zlib1g-dev libncurses5 libncurses5-dev libncursesw5 libbz2-dev lzma liblzma-dev libreadline-dev \
uuid-dev libffi-dev libopenblas-dev bliss mklibs libprotobuf-dev protobuf-compiler libjpeg62 libfreeimage-dev \
libgoogle-glog-dev python-yaml libhdf5-serial-dev hdf5-tools libhdf5-dev gfortran python-h5py

apt-get install -y tk8.6-dev

cd /rk1808
tar -xzvf cmake-3.10.0.tar.gz
tar -xzvf Python-3.7.6.tgz

cd /rk1808/cmake-3.10.0
./configure
make
make install

cd /rk1808/Python-3.7.6
./configure --enable-optimizations
make -j6
make install

cd /rk1808/
update-alternatives --install /usr/bin/python python /usr/bin/python2 100
update-alternatives --install /usr/bin/python python /usr/local/bin/python3.7 150

pip3 install --user -U pip && pip3 uninstall pep517 && pip3 uninstall toml && pip3 install --user -U setuptools==46.2.0
pip3 install --user Cython==0.29.17
pip3 install --user rknn-1.3.0-cp37-cp37m-linux_aarch64.whl
pip3 install --user tensorflow-1.14.0-cp37-none-linux_aarch64.whl
pip3 install --user matplotlib

#---------------Rga--------------
dpkg -i /packages/rga/*.deb
echo -e "\033[36m Setup Video.................... \033[0m"
apt-get install -f -y

echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic main restricted" >> /etc/apt/sources.list
apt-get update

dpkg -i /packages/xserver/*.deb
apt-get install -f -y

dpkg -i /packages/xserver/*.deb
apt-get install -f -y

sed -i '/bionic/'d /etc/apt/sources.list
apt-get update

#---------------Adjust--------------
systemctl enable advinit.service
systemctl enable adv-update-ota.service

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
rm -rf /rk1808/
rm -rf /root/.cache/
rm -rf /var/cache/apt/apt-file/*
apt-get clean
rm -rf /var/lib/apt/lists/*

EOF


sudo umount $TARGET_ROOTFS_DIR/dev
