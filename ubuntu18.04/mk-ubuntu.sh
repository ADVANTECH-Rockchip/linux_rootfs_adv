#!/bin/bash -e

TARGET_ROOTFS_DIR="binary"
TOP_DIR=`pwd`

echo Top of tree: ${TOP_DIR}
echo "BUILD_IN_DOCKER : $BUILD_IN_DOCKER"

# make ubuntu base
if [ "$1" == "new" ]; then
    echo "make ubuntu base new"
    ./mk-ubuntu-base.sh
else
    echo "use exist ubuntu base"
    if [ -e $TARGET_ROOTFS_DIR ]; then
        sudo rm -rf $TARGET_ROOTFS_DIR
    fi
    cat ubuntu-base/ubuntu18.04-*.tar.gz* > ubuntu18.04-whole.tar.gz
    sudo tar -xpf ubuntu18.04-whole.tar.gz
fi

# make rk
ARCH=arm64 ./mk-rk.sh

# make adv
ARCH=arm64 ./mk-adv.sh

# mk-image
./mk-image.sh
