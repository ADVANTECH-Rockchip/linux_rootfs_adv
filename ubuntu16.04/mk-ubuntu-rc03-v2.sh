#!/bin/bash -e

TARGET_ROOTFS_DIR="binary"
TOP_DIR=`pwd`

echo Top of tree: ${TOP_DIR}
echo "BUILD_IN_DOCKER : $BUILD_IN_DOCKER"

# make ubuntu base
if [ -e $TARGET_ROOTFS_DIR ]; then
    sudo rm -rf $TARGET_ROOTFS_DIR
fi
cat ubuntu-rc03/ubuntu16.04-*.tar.gz* > ubuntu16.04-whole.tar.gz
sudo tar -xpf ubuntu16.04-whole.tar.gz

# make chuanda
ARCH=arm64 ./mk-rc03-v2.sh

# mk-image
./mk-image.sh
