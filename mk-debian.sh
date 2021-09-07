#!/bin/bash -e

TOP_DIR=`pwd`
RK_DEBIAN="rootfs"
ADV_DEBIAN="rootfs_adv"
echo Top of tree: ${TOP_DIR}

echo "BUILD_IN_DOCKER : $BUILD_IN_DOCKER"

# make debian base
if [ "$1" == "new" ]; then
    echo "make debian base new"
    cd $TOP_DIR/$RK_DEBIAN
    sudo ARCH=armhf RELEASE=buster ./mk-base-debian.sh
else
    echo "use exist debian base"
    cat $ADV_DEBIAN/debian-base/linaro-buster-alip-*.tar.gz* > $RK_DEBIAN/linaro-buster-alip-whole.tar.gz
fi

# make rockchip
cd $TOP_DIR/$RK_DEBIAN
ARCH=armhf ./mk-rootfs-buster.sh

# make adv
cd $TOP_DIR/$ADV_DEBIAN
ARCH=armhf ./mk-adv.sh

# mk-image
cd $TOP_DIR/$RK_DEBIAN
./mk-image.sh

