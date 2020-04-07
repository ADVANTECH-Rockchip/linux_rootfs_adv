#!/bin/bash -e

TOP_DIR=`pwd`
RK_DEBIAN="rootfs"
ADV_DEBIAN="rootfs_adv"
echo Top of tree: ${TOP_DIR}

BUILD_IN_DOCKER=$1
echo "BUILD_IN_DOCKER : $BUILD_IN_DOCKER"

# make debian base
if [ "$1" == "new" ]; then
    echo "make debian base new"
    sudo ARCH=armhf RELEASE=stretch ./mk-base-debian.sh
else
    echo "use exist debian base"
    cat $ADV_DEBIAN/debian-base/linaro-stretch-alip-*.tar.gz* > $RK_DEBIAN/linaro-stretch-alip-whole.tar.gz
fi

# make rockchip
cd $TOP_DIR/$RK_DEBIAN
sudo ARCH=armhf ./mk-rootfs-stretch.sh $BUILD_IN_DOCKER

# make adv
cd $TOP_DIR/$ADV_DEBIAN
sudo ARCH=armhf ./mk-adv.sh $BUILD_IN_DOCKER

# mk-image
cd $TOP_DIR/$RK_DEBIAN
sudo ./mk-image.sh

