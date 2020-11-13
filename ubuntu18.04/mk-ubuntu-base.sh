#!/bin/bash -e
TARGET_ROOTFS_DIR="binary"

if [ -e $TARGET_ROOTFS_DIR ]; then
	sudo rm -rf $TARGET_ROOTFS_DIR
fi
mkdir binary

if [ ! -e ubuntu-base-18.04.5-base-arm64.tar.gz ]; then
	echo "\033[36m Download  ubuntu-base-18.04.5-base-arm64.tar.gz first \033[0m"
fi

sudo tar -xpf ubuntu-base-18.04.5-base-arm64.tar.gz -C $TARGET_ROOTFS_DIR/

sudo cp -b /etc/resolv.conf binary/etc/resolv.conf
sudo cp /usr/bin/qemu-aarch64-static binary/usr/bin/


finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR


sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR

#--------- install base app ---------
apt-get update
apt-get install -y \
adduser \
alsa-utils \
anacron \
apt \
apt-utils \
bc \
btrfs-tools \
bzip2 \
ca-certificates \
console-setup \
cpufrequtils \
crda \
curl \
dbus-x11 \
debconf \
debconf-i18n \
debian-keyring \
dmz-cursor-theme \
dnsmasq-base \
eject \
evtest \
fbset \
file \
gconf2 \
gdisk \
gnome-keyring \
gnome-system-tools \
gstreamer1.0-libav \
gstreamer1.0-plugins-bad \
gstreamer1.0-plugins-good \
gstreamer1.0-tools \
gvfs \
hostapd \
idlestat \
ifupdown \
initramfs-tools \
input-utils \
iotop \
iperf \
iproute2 \
iptables \
iputils-ping \
isc-dhcp-client \
iw \
kbd \
kmod \
less \
lightdm \
lightdm-gtk-greeter \
locales \
lsb-release \
lsof \
lxde \
lxlauncher \
lxpolkit \
lxsession-default-apps \
lxsession-logout \
lxshortcut \
lxtask \
makedev \
mawk \
mesa-utils \
mesa-utils-extra \
mpv \
mutrace \
net-tools \
netbase \
netcat-openbsd \
network-manager-gnome \
ntpdate \
obconf \
openssh-client \
openssh-server \
parted \
pavucontrol \
policykit-1 \
powerdebug \
powertop \
procps \
psmisc \
pulseaudio-module-bluetooth \
read-edid \
resolvconf \
rfkill \
rsyslog \
ssh-import-id \
strace \
sudo \
trace-cmd \
tzdata \
udev \
unzip \
usb-modeswitch \
usbutils \
user-setup \
vim \
vim-tiny \
wget \
whiptail \
wireless-tools \
wpasupplicant \
x11-utils \
x11-xserver-utils \
xdg-user-dirs-gtk \
xfce4-power-manager-plugins \
xinit \
xorg \
xorg-docs-core \
xserver-common \
xserver-xorg \
xserver-xorg-core \
xserver-xorg-input-all \
xserver-xorg-input-evdev \
xserver-xorg-input-libinput \
xserver-xorg-input-synaptics \
xserver-xorg-input-wacom \
xserver-xorg-legacy \
xserver-xorg-video-all \
xserver-xorg-video-amdgpu \
xserver-xorg-video-ati \
xserver-xorg-video-fbdev \
xserver-xorg-video-nouveau \
xserver-xorg-video-radeon \
xserver-xorg-video-vesa \
xterm \
zip \
lxde-common \
desktop-base \
systemd-sysv


apt-get install -y chromium-browser
apt-get install -y lxdm
apt-get install -y feh

apt-get install -y xfonts-intl-chinese xfonts-wqy ttf-wqy-microhei ttf-dejavu

apt-get install -y netplan.io
# generate 10-general-init.yaml
echo "network:" > /etc/netplan/10-general-init.yaml
echo "    version: 2" >> /etc/netplan/10-general-init.yaml
echo "    renderer: NetworkManager" >> /etc/netplan/10-general-init.yaml

#--------- remove app ---------
apt-get remove -y xscreensaver
apt-get remove -y firefox
apt-get remove -y clipit

#---------------Clean--------------
apt-get clean
rm -rf /var/lib/apt/lists/*

EOF

sudo umount $TARGET_ROOTFS_DIR/dev
