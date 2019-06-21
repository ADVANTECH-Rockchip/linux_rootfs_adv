#!/bin/bash -e
TARGET_ROOTFS_DIR="binary"

echo "In mk-adv.sh"

echo "Install/remove/adjust debian"

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR
apt-get update

apt-get install -y libssl1.0-dev
apt-get install -y libxml2-dev
apt-get install -y libxtst-dev

apt-get install -y zlib1g-dev
apt-get install -y libmosquitto-dev
apt-get install -y libcurl4-openssl-dev
apt-get install -y build-essential

apt-get install -y autoconf automake libtool

apt-get install -y cmake

apt-get install -y libjpeg-dev
apt-get install -y libbsd-dev
apt-get install -y git
apt-get install -y subversion
export HOME=/root
EOF

