#!/bin/bash -e

TARGET_ROOTFS_DIR="binary"

# make ubuntu base
if [ "$1" == "new" ]; then
    echo "make ubuntu base new"
    sudo ./mk-ubuntu-base.sh
else
    echo "use exist ubuntu base"
	if [ -e $TARGET_ROOTFS_DIR ]; then
		sudo rm -rf $TARGET_ROOTFS_DIR
	fi
    cat ubuntu-base/ubuntu16.04-*.tar.gz* > ubuntu16.04-whole.tar.gz
	sudo tar -xpf ubuntu16.04-whole.tar.gz
fi

# make chuanda
sudo ./mk-chuanda.sh

# mk-image
sudo ./mk-image.sh
